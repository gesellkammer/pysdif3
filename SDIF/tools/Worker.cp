#include "Worker.h"

#include <SDIF/sdif.h>
#include <vector>
#include <algorithm>


#include <sys/types.h>
#include <sys/stat.h>
#include "ProgressBar.h"

using namespace std;

extern "C" 
{
	int KERmain(int argc, char** argv);
}

pthread_mutex_t gMutex = PTHREAD_MUTEX_INITIALIZER;
vector<Worker *> gWorkers;

Worker::Worker(bool sdif_to_text,const char * file_name) :
	stop_requested(false)
{
	file_in = strdup(file_name);
	file_out = (char *)malloc(strlen(file_in)+5);
	strcpy(file_out,file_in);
	strcat(file_out,sdif_to_text ? ".txt" : ".sdif");
	finished = false;
	this->sdif_to_text = sdif_to_text;

	progress_bar = new ProgressBar();
	
	pthread_attr_t attr;
	
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_DETACHED);	
	pthread_create(&thread,&attr,Worker::launch,this);
}

Worker::~Worker()
{
	free(file_in);
	free(file_out);
	delete progress_bar;
}

void *
Worker::launch(void * arg)
{
//pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,NULL);

	Worker * data = (Worker *)arg;
	
	pthread_mutex_lock(&gMutex);
	gWorkers.push_back(data);
	pthread_mutex_unlock(&gMutex);
	
	SdifFileT *SdifF;
	
	if( data->sdif_to_text )
	{
		SdifF = SdifFOpen (data->file_in	,  eReadFile);
		if (SdifF)
		{
			SdifToText (SdifF, data->file_out);
		}
	
	}
	else
	{
		SdifF = SdifFOpen (data->file_out	,  eWriteFile);
		if (SdifF)
		{
			SdifTextToSdif(SdifF,data->file_in) ;
		}
	}
	
	pthread_mutex_lock(&gMutex);
	vector<Worker *>::iterator new_end = std::remove(gWorkers.begin(),gWorkers.end(),data);
	gWorkers.erase(new_end,gWorkers.end());
	if( gWorkers.empty() )
	{
		data->Exit(0);
	}
	pthread_mutex_unlock(&gMutex);
	pthread_exit(NULL);
}

bool
Worker::IsFinished()
{
	return finished;
}

bool
Worker::IsEqual(pthread_t t)
{
	return pthread_equal(thread,t); 
}

long
Worker::FileSize(const char * path)
{
	struct stat sb;
	stat(path,&sb);
	return sb.st_size;
}
void
Worker::ProBarString(const char * string)
{
	Worker * w = find();
	if( w )
	{
		w->progress_bar->setTitle(string);
	}
}
void
Worker::ProBarInit(float total)
{
	Worker * w = find();
	if( w )
	{
		w->progress_bar->setInteruptor(Worker::stopper,w);
		w->progress_bar->start(0.0,total);
	}
}

void
Worker::ProBarSet(float value)
{
	Worker * w = find();
	if( w )
	{
		if( w->stop_requested )
		{
			pthread_exit(NULL);
		}
		w->progress_bar->setValue(value);
	}
}

bool
Worker::AllFinished()
{
	bool all_finished = true;
	vector<Worker *>::iterator iter;
	for( iter = gWorkers.begin() ; iter != gWorkers.end() ; iter ++ )
	{
		if( ! (*iter)->IsFinished() )
		{
			all_finished = false;
			break;
		}
	}
	return all_finished;
}

void
Worker::AllRemove()
{
	vector<Worker *>::iterator iter;
	for( iter = gWorkers.begin() ; iter != gWorkers.end() ; iter ++ )
	{
		delete * iter;
	}
}

Worker * Worker::find()
{
	pthread_t s = pthread_self();
	vector<Worker *>::iterator iter;
	for( iter = gWorkers.begin() ; iter != gWorkers.end() ; iter ++ )
	{
		if( (*iter)->IsEqual(s) ) break;
	}
	if( iter != gWorkers.end() )
	{
		return * iter;
	}
	else
	{
		return NULL;
	}
}

void
Worker::stopper(void * arg)
{
	Worker * w = (Worker *)arg;
	w->stop_requested = true;
	pthread_cancel(w->thread);
	pthread_mutex_lock(&gMutex);
	gWorkers.erase(remove(gWorkers.begin(),gWorkers.end(),w));
	if( gWorkers.empty() )
	{
		w->Exit(0);
	}
	pthread_mutex_unlock(&gMutex);
}

void
Worker::Exit(int rs)
{
	QuitApplicationEventLoop();
}

