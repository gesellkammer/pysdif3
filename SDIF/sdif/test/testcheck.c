/* $Id: testcheck.c,v 1.2 2002-10-29 11:07:51 schwarz Exp $
 *
 * testcheck		2. May 2000		Diemo Schwarz
 *
 * Test functions from SdifCheck.
 *
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2000/05/04 14:57:29  schwarz
 * test check for SdifCheckFrames funcs.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sdif.h>

int main (int argc, char *argv [])
{
    SdifSignature	result, sigi [100];
    SdifSignatureTabT   *sigs;
    char		*filename;
    int			i, resulti;

    if (argc < 3)
    {
	fprintf (stderr, "usage: testcheck filename[::selection] signature...\n");
	exit (0);
    }

    SdifGenInit ("");
    sigs = SdifCreateSignatureTab (1);

    filename = argv [1];
    for (i = 2; i < argc; i++)
    {
	SdifAddToSignatureTab (sigs, SdifStringToSignature (argv [i]));
	sigi [i - 2] = SdifStringToSignature (argv [i]);
    }
    sigi [i - 2] = eEmptySignature;

    result  = SdifCheckFileFramesTab   (filename, sigs);
    resulti = SdifCheckFileFramesIndex (filename, sigi);

    printf ("Found %s frame, index %d.\n", 
	    result  ?  SdifSignatureToString (result)  :  "no", resulti);

    SdifKillSignatureTab (sigs);
    SdifGenKill ();

    return 0;
}
