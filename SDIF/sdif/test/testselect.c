/* $Id: testselect.c,v 1.4 2002-10-29 11:07:51 schwarz Exp $
 *
 * testselect		30. August 1999		Diemo Schwarz
 *
 * Test functions from SdifSelect.c
 *
 * $Log: not supported by cvs2svn $
 * Revision 1.3  1999/10/07 15:13:01  schwarz
 * Added SdifSelectGetFirst<type>, SdifSelectGetNext(Int|Real).
 *
 * Revision 1.2  1999/09/20  13:23:09  schwarz
 * First finished version, API to be improved.
 *
 * Revision 1.1  1999/08/31  10:03:38  schwarz
 * Added test code for module SdifSelect which parses an access specification to a
 * chosen part of SDIF data.  Can be added to a file name.
 *
 */

#include <stdio.h>
#include <sdif.h>

int main (int argc, char *argv [])
{
    SdifSelectionT		sel;
    SdifSelectElementIntT	intrange;
    SdifSelectElementRealT	realrange;
    SdifSignature		sig;
    char			*arg = argc > 1  ?  argv [1]  :  NULL;
    
    printf ("%s %s\n", argv [0], arg);
    SdifGenInit ("");
    
    SdifGetFilenameAndSelection (arg, &sel);
    
    printf ("selection: file %s  basename %s", sel.filename, sel.basename);
    
    SdifListInitLoop (sel.stream);
    while (SdifSelectGetNextIntRange (sel.stream, &intrange, 1))
	printf ("\n  stream\t%d - %d ", intrange.value, intrange.range);

    SdifListInitLoop (sel.frame);
    while ((sig = SdifSelectGetNextSignature (sel.frame)))
	printf ("\n  frame\t'%s' ", SdifSignatureToString (sig));

    SdifListInitLoop (sel.matrix);
    while ((sig = SdifSelectGetNextSignature (sel.matrix)))
	printf ("\n  matrix\t'%s' ", SdifSignatureToString (sig));

    SdifListInitLoop (sel.column);
    while (SdifSelectGetNextIntRange (sel.column, &intrange, 1))
	printf ("\n  column\t%d - %d ", intrange.value, intrange.range);

    SdifListInitLoop (sel.row);
    while (SdifSelectGetNextIntRange (sel.row, &intrange, 1))
	printf ("\n  row\t%d - %d ", intrange.value, intrange.range);

    SdifListInitLoop (sel.time);
    while (SdifSelectGetNextRealRange (sel.time, &realrange, 1))
	printf ("\n  time\t%f - %f ", realrange.value, realrange.range);

    printf ("\n\n");

    SdifPrintSelection (stdout, &sel, 0);
	
    SdifGenKill ();

    return 0;
}
