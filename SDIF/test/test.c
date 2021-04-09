/* $Id: test.c,v 3.2 2000-10-27 20:04:02 roebel Exp $
 *
 *               Copyright (c) 1998 by IRCAM - Centre Pompidou
 *                          All rights reserved.
 *
 *  For any information regarding this and other IRCAM software, please
 *  send email to:
 *                            manager@ircam.fr
 *
 *
 *
 *
 *
 */


#include "sdif.h"

#include <stdlib.h>
#include <stdio.h>
/* #include <fcntl.h> */
/* #include <io.h> */
#include <string.h>



int
main(int argc, char **argv)
{
  char *OutF = NULL;
  char *SdifTypesFile = NULL;

  SdifFileT *SdifF;
  SdifFileModeET openMode;


  /* test var */
  float t[8] = { 1., 2., 3., 4., 5., 6., 7.};


  SdifStdErr = stderr;

/* argument configuration (Outfilename, openmode, UserTypesFile) */
  if (argc > 1)
  {
	OutF = SdifCreateStrNCpy(argv[1], SdifStrLen(argv[1])+1);
	if (argc > 2)
	{
	  openMode = atoi(argv[2]);
	  if (argc > 3)
	    SdifTypesFile = SdifCreateStrNCpy(argv[3], SdifStrLen(argv[3])+1); 
	  else
		SdifTypesFile = SdifCreateStrNCpy("", SdifStrLen("")+1); 
	}
	else
	  openMode = eWriteFile;
  }
  else
    OutF = SdifCreateStrNCpy("stdout", SdifStrLen("stdout")+1);



  SdifPrintVersion();
  SdifGenInit(SdifTypesFile);
 

  SdifF = SdifFOpen(OutF, eWriteFile);
  SdifFOpenText(SdifF, "stderr", eWriteFile);

  SdifFSetCurrFrameHeader (SdifF, 'fram', _SdifUnknownSize, 1, 0, 1.234);
  SdifFWriteFrameHeader  (SdifF);

  SdifFSetCurrMatrixHeader(SdifF, 'mtrx', eFloat4, 1, 7);
  SdifFWriteMatrixHeader (SdifF);

  fprintf(stderr, "\n");
  SdifFPrintFrameHeader  (SdifF);
  SdifFPrintMatrixHeader (SdifF);

  SdifFSetCurrOneRow    (SdifF, t);
  SdifFPrintOneRow      (SdifF);
  SdifFWriteOneRow      (SdifF);
  SdifFSetCurrOneRowCol (SdifF, 4, 10);
  SdifFPrintOneRow      (SdifF);
  SdifFWriteOneRow      (SdifF);
  SdifFSetCurrOneRowCol (SdifF, 7, 10);
  SdifFPrintOneRow      (SdifF);
  SdifFWriteOneRow      (SdifF);
  SdifFSetCurrOneRowCol (SdifF, 7, SdifFCurrOneRowCol (SdifF, 1));
  SdifFPrintOneRow      (SdifF);
  SdifFWriteOneRow      (SdifF);

  
  SdifFClose(SdifF);

  
  SdifPrintAllType(stderr, gSdifPredefinedTypes);
  

  SdifGenKill();


  free(OutF);
  free(SdifTypesFile);
  fprintf(stdout, "%e\n", _Sdif_MIN_DOUBLE_);
  return 0;
}
