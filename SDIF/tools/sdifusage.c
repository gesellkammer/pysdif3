/*--------------------------------------------------------------------------*/
/*	SdifParser.c															*/
/*	Adrien Lefevre - IRCAM - 09/97											*/
/*--------------------------------------------------------------------------*/

#include "sdif_portability.h"

#include "sdif.h"

/*--------------------------------------------------------------------------*/
/*	usage																	*/
/*--------------------------------------------------------------------------*/

void usage(void);
void usage(void)
{
	fprintf(stderr, "SDIF Help:\n");
	fprintf(stderr, "sdif       -h\n");	
	fprintf(stderr, "sdiftotext -i<Path:InputSdifFileName> -o<Path:OutputTextFileName>\n");
	fprintf(stderr, "tosdif     -i<Path:InputTextFileName> -o<Path:OutputSdifFileName>\n");
	fprintf(stderr, "sdifextract\n");
	fprintf(stderr, "querysdif\n");
	fprintf(stderr, "\n");
}

/*--------------------------------------------------------------------------*/
/*	KERmain / main															*/
/*--------------------------------------------------------------------------*/

#if HOST_OS_MAC

int KERmain(int argc, char** argv);
int KERmain(int argc, char** argv)

#else

int main(int argc, char** argv);
int main(int argc, char** argv)

#endif
{
	usage();
	return 0;
}


































