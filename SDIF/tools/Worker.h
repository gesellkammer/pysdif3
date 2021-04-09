
#ifndef _WORKER_
#define _WORKER_

#include <pthread.h>
#include "ProgressBar.h"

class Worker
{
	public:
	
		Worker(bool sdif_to_text,const char * file_name);
		~Worker();

		bool IsFinished();
		bool IsEqual(pthread_t t);
		
		static void AllRemove();
		static bool	AllFinished();
		
	static	long	FileSize(const char * file_name);
	static	void	ProBarString(const char * string);
	static	void	ProBarInit(float total);
	static	void	ProBarSet(float value);
	static	void	Exit(int rs);			
	private:
	
	
	static void * launch(void * arg);
	static Worker * find();
	static void stopper(void * arg);

	bool	sdif_to_text;
	bool	stop_requested;
	bool	finished;
	char *	file_in;
	char *	file_out;
	
	pthread_t	thread;
	
	ProgressBar *	progress_bar;
		
};

#endif