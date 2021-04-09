#ifndef _ProgressBar_h_
#define _ProgressBar_h_

class ProgressBar
{
	public:
	
	ProgressBar();
	~ProgressBar();
	

	void	setInteruptor(void (*interrupt_request_handler)(void *),void * interrupt_request_arg);
					
	void	start(float from,float to);
	void	setValue(float value);
	void	setTitle(const char * title);
	void	stop();
	void	quit();
	
	private:


	void		init();
	void		post(HICommand&	command,const char * title = NULL);
	bool					with_outer_event_loop;
	bool                   running;
	bool                   first_time;
	float                  minimum;
	float                  maximum;
	float                  current;
	int                    previous;

	WindowRef              window_ref;
	ControlRef             stop_control;
	ControlRef             pbar_control;

	EventHandlerUPP        event_handler_upp;
	EventHandlerRef        event_handler_ref;

	EventLoopIdleTimerUPP  timer_upp;
	EventLoopTimerRef      timer;

	Rect                   bounds;

	EventQueueRef          queue;
	EventTargetRef			target_ref;

	pthread_t              thread;
	pthread_cond_t         cond;
	pthread_mutex_t        mutex;
	bool                   initialised;
  
	AbsoluteTime           previous_set;

	ProcessSerialNumber    psn;
	ProcessSerialNumber    psn_front;
	void                   (*interrupt_request_handler)(void *);
	void *                 interrupt_request_arg;
	static OSStatus Handler (EventHandlerCallRef  nextHandler,
                EventRef             inEvent, 
                void*                userData);


};

#endif
