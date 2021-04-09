//============================================================================
//      main.cp            
//      Ker Initialisation Ressource
//
//============================================================================


#include <Carbon/Carbon.h>
#include <ApplicationServices/ApplicationServices.h>
#include <XpGuiCalls.h>
#include "Worker.h"
#include <SDIF/sdif.h>

#include <unistd.h>
#include <pthread.h>


//============================================================================
//      main
//============================================================================

extern "C" 
{
	int KERmain(int argc, char** argv);
}


//============================================================================
//      gGuiCallbacks
//============================================================================

XpGuiCallbacksRec gGuiCallbacks =
{       2L,             // version
        13,             // nb procs
        Worker::Exit /*procExit*/,
        NULL /*procGetenv*/,
        NULL /*procPutToStdio*/,
        NULL /*procSetFileAttribute*/,
        Worker::FileSize /*procFileSize*/,
        NULL /*procFreeMemory*/,
        NULL /*procVersionDemo*/,
        NULL /*procWatchCursor*/,
		Worker::ProBarString /*procProBarString*/,
        Worker::ProBarInit /*procProBarInit*/,
        Worker::ProBarSet /*procProBarSet*/,
        NULL /*procSignal*/,
        NULL /*procSetErrorMsg*/
};

using namespace std;

pascal OSErr OpenCallback (const AppleEvent * theAppleEvent, AppleEvent * reply, SInt32 handlerRefCon)
{
  OSStatus status;
  AEDescList docList;
  DescType returnedType;
  SInt32 numberOfItems;
  FSRef fs_ref;
  Size actualSize;
  SInt32 index;	
  DescType keyWord;
  char	path[2048];
  CFStringRef string_ref;
  bool stt;
  
  string_ref = CFBundleGetIdentifier(CFBundleGetMainBundle());
  
  CFStringGetCString(string_ref,path,sizeof(path),kCFStringEncodingMacRoman );
  
  stt = strcmp(path,"fr.ircam.sdiftotext") == 0;

  status = AEGetParamDesc(theAppleEvent,keyDirectObject,typeAEList,&docList);
  if(status == noErr)
  {
    status = AEGetAttributePtr(theAppleEvent,keyMissedKeywordAttr,typeWildCard,&returnedType,NULL,0,&actualSize);
    if(status == errAEDescNotFound)
      status = noErr;
    else if(status == noErr)
      status = errAEParamMissed;

    if(status == noErr)
    {
      status = AECountItems(&docList,&numberOfItems);
      if(status == noErr)
      {
        for(index=1 ; index<=numberOfItems ; index++)
        {
          status = AEGetNthPtr(&docList,index,typeFSRef,&keyWord,&returnedType,&fs_ref,sizeof(fs_ref),&actualSize);
          if(status == noErr)
          {
         	status = FSRefMakePath(&fs_ref,(UInt8 *)path,sizeof(path));
          	new Worker(stt,path);
          }
        }
      }
    }
  }
  return status;
}

int main(int argc,char ** argv)
{
	SInt32	err;

	// this means, it has been launched with Apple's 'LaunchApplication'
	if( argc == 2 and strncmp(argv[1],"-psn_",5) == 0 )
	{
		argv ++ ;
		argc -- ;
		SdifGenInit (NULL);
	}
	else
	{
		return KERmain(argc,argv);
	}

	AEEventHandlerUPP gOpenCallback = NewAEEventHandlerUPP(OpenCallback);
	err = AEInstallEventHandler(kCoreEventClass,kAEOpenDocuments,gOpenCallback, 0,false);
	if( err != 0 )
	{
		fprintf(stderr,"Could not install Open handler\n");
		exit(err);
	}	

	RunApplicationEventLoop();

	err = AERemoveEventHandler(kCoreEventClass,kAEOpenDocuments,gOpenCallback,FALSE);
  
	DisposeAEEventHandlerUPP(gOpenCallback);

	Worker::AllRemove();
	
	SdifGenKill (); 

	exit(0);
}

