

#include "ProgressBar.h"
#include <pthread.h>

enum
{
	kEventParamTitle = 'Titl'
};

ProgressBar::ProgressBar() :
	event_handler_ref(NULL), event_handler_upp(NULL)
{
	init();
}

ProgressBar::~ProgressBar()
{
	RemoveEventHandler(event_handler_ref);
	DisposeEventHandlerUPP(event_handler_upp);
}

OSStatus
ProgressBar::Handler (EventHandlerCallRef  nextHandler,
                EventRef             inEvent, 
                void*                userData)
{
	ProgressBar * data = (ProgressBar *)userData;
	OSStatus result = eventNotHandledErr;
 
	UInt32 kind = GetEventKind( inEvent );



	switch ( GetEventClass( inEvent ) )
	{
		case kEventClassCommand:
		{
			HICommand cmd;
   
			GetEventParameter( inEvent, kEventParamDirectObject, typeHICommand, NULL, sizeof(cmd), NULL, &cmd );
		
			switch ( kind )     
			{
				case kEventCommandProcess:
				switch ( cmd.commandID )
				{
					case 'Titl':
					{
						CFStringRef string;
						GetEventParameter( inEvent, kEventParamTitle, typeCFStringRef, NULL, sizeof(string), NULL, &string );
						SetWindowTitleWithCFString (data->window_ref, string);
						result = noErr;
					}
					break;
					
					case 'Strt':
					{
						SetFrontProcess(&data->psn);
						ShowWindow(data->window_ref);
						result = noErr;
					}
					break;
					
					case 'Set ':
					{
						SetControl32BitValue( data->pbar_control ,(int)((data->current - data->minimum) / (data->maximum - data->minimum) * 1000));
						result = noErr;
					}
					break;
					
					case 'Stop':
					{
						if( (cmd.attributes != 1) && data->interrupt_request_handler )
						{
							FILE * f = fopen("/dev/console","w");
							(*data->interrupt_request_handler)(data->interrupt_request_arg);
							//data->finish();
						} 
						HideWindow(data->window_ref);
						GetWindowBounds(data->window_ref,kWindowStructureRgn,&data->bounds);
						SetFrontProcess(&data->psn_front);
						result = noErr;
					}
					break;
					
					case 'Quit':
					{
						QuitApplicationEventLoop();
					}
					break;
				}
			}
         }
	}
	
	return result;
}


void
ProgressBar::setInteruptor(void (*interrupt_request_handler)(void *),void * interrupt_request_arg)
{
	this->interrupt_request_handler = interrupt_request_handler;
	this->interrupt_request_arg = interrupt_request_arg;
}


void
ProgressBar::init()
{
	OSStatus	status;					 
	IBNibRef     nibRef;
    OSStatus    err;

    err = CreateNibReference(CFSTR("main"), &nibRef);
    
    err = CreateWindowFromNib(nibRef, CFSTR("MainWindow"), &window_ref);

	ControlID  pbar_ctrl_id = { 'PBAR', 1 };

    GetControlByID( window_ref, &pbar_ctrl_id, &pbar_control );

	GetCurrentProcess(&psn);
	GetFrontProcess(&psn_front);
	
	Microseconds(&previous_set);

    event_handler_upp = NewEventHandlerUPP(ProgressBar::Handler);
	
	const EventTypeSpec kWindowEvents[] = {{ kEventClassCommand,kEventCommandProcess } };
	target_ref = GetWindowEventTarget(window_ref);
    status = InstallEventHandler (target_ref,event_handler_upp,
						sizeof(kWindowEvents)/sizeof(kWindowEvents[0]),
						kWindowEvents,this, &event_handler_ref);

	queue = GetMainEventQueue();
}

void 
ProgressBar::start(float from,float to)
{
	minimum = from;
	maximum = to;
	current = minimum;
	
	EventRef event;
	HICommand cmd = {0,'Strt'};

	post(cmd);
}

void
ProgressBar::post(HICommand& command,const char * title)
{
	OSStatus  status;
	EventRef event;
	CFStringRef string;
	if( title )  string = CFStringCreateWithCString(kCFAllocatorDefault,title,kCFStringEncodingMacRoman);
	CreateEvent (nil, kEventClassCommand, kEventCommandProcess,0,0,&event);
	status = SetEventParameter (event,kEventParamDirectObject, typeHICommand,sizeof(command),&command);
	status = SetEventParameter(event, kEventParamPostTarget,typeEventTargetRef, sizeof(EventTargetRef),&target_ref);
	if( title ) status = SetEventParameter (event,kEventParamTitle, typeCFStringRef,sizeof(string),&string);
	status = PostEventToQueue(queue,event,kEventPriorityStandard );
	ReleaseEvent(event);
	if( title ) CFRelease(string);
}

void 
ProgressBar::setValue(float value)
{
	current = value;
	
	UnsignedWide t;
	Microseconds(&t);
	AbsoluteTime currTime = UpTime ();
    float delta = (float) AbsoluteDeltaToDuration (currTime, previous_set);
	previous_set = currTime;  // reset for next time interval
	if (0 > delta)  // if negative microseconds
    {
	  delta /= -1000000.0;
	}
    else        // else milliseconds
    {
	  delta /= 1000.0;
	}
	
	if( delta < .1 )
	{
//	  return;
    }

	HICommand cmd = {0,'Set '};
	post(cmd);
}

void 
ProgressBar::stop()
{
	HICommand cmd = {1,'Stop'};
	post(cmd);
}

void 
ProgressBar::quit()
{
	HICommand cmd = {0,'Quit'};
	post(cmd);
}

void 
ProgressBar::setTitle(const char * title)
{
	HICommand cmd = {0,'Titl'};
	post(cmd,title);
}
