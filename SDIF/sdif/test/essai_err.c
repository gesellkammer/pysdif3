#include <stdlib.h>
#include <sdif.h>
//#include "err_excep.hpp"

//SdifExitFuncT gExiTryFunc;
//SdifExceptionFuncT  gExcepTryFunc;
//SdifExceptionFuncT function;

void  gExiTryFunc(void) //SdifSetExitFunc (SdifExitFuncT func))
{
    printf("dans gExitTryFunc \n");
}


void  gExcepTryFunc(int errnum, SdifErrorLevelET errlev, char* msg, SdifFileT* file, SdifErrorT* error, char* sourcefilename, int sourcefileline)
{
    
    printf("dans gExcepTryFunc \n");
    printf("niveau de l'erreur :%d\n",errlev);
//        printf("meme niveau de l'erreur :%d\n",error->Level);
    printf("numero de l'erreur :%d\n",errnum);
    printf("message d'anomalie :%s\n",error->UserMess);
    printf("in the file :%s\n", sourcefilename);
    printf("at the line :%d\n", sourcefileline);
    fprintf(SdifStdErr, msg);
    fflush(SdifStdErr);

}




void  gExcepWarnFunc(int errnum, SdifErrorLevelET errlev, char* msg, SdifFileT* file, SdifErrorT* error, char* sourcefilename, int sourcefileline)
{
    printf("dans gExcepWarnFunc \n");
    fprintf(SdifStdErr, msg);
    fflush(SdifStdErr);
}

// a tester avec plusieurs fichiers incorrects
int main()//int argc, char** argv)
{
    char* filename = NULL;
    size_t  bytesread = 0;
    int     eof       = 0;  /* End-of-file flag */
    ///////////////////*les variables ajoutes*/
    size_t generalHeader;
    size_t asciiChunks;
    /////////////////    
    SdifSignature sign_fich;
    ////////////////
    SdifFileT *file;

/*
  filename = argv [1];
    
  if(filename==NULL)
  {
  fprintf(stderr, "Usage: %s <filename.sdif>\n",
  argv[0]);
  return 1;
  }
*/

    // SdifSetExitFunc (gExiTryFunc);
    //SdifSetErrorFunc(function);
    SdifSetErrorFunc(gExcepTryFunc);
    // SdifSetWarningFunc(gExcepWarnFunc);
    /* when linkimg with the new SDIFExceptions :

SDIFExceptionThrower( errnum,  errlev,  msg,  file,  error, sourcefilename, sourcefileline);

    */
   
    /* boucle de lecture */
    SdifGenInit("");
//    file = SdifFOpen (filename, eReadFile);
    file = SdifFOpen ("fall.sdif", eReadFile);

     generalHeader = SdifFReadGeneralHeader(file);
     asciiChunks = SdifFReadAllASCIIChunks(file);
  
     sign_fich = SdifFCurrSignature (file);

     while (!eof  &&  SdifFLastError(file) == NULL)
     {
	 bytesread += SdifFReadFrameHeader(file);
	 if (!eof)
	 {    /* Access frame header information */
	     SdifFloat8      time     = SdifFCurrTime(file);
	     SdifSignature   sig      = SdifFCurrFrameSignature(file);
	     SdifUInt4       streamid = SdifFCurrID(file);/*index de l'objet du frame courant*/
	     SdifUInt4       nmatrix  = SdifFCurrNbMatrix(file);
	     int             m;
    
	     /*On ecrit les informations relatives a la frame : */
	     // printf("Signature de la frame : %s\n",sig);
	     printf("\nSignature de la frame : %s\n", SdifSignatureToString(sig));
	     printf("sId: %d", streamid);
	     printf(" Tps=%f", time);
	     printf(" nbreMat ds frame : %d\n",nmatrix);

	     /* Read all matrices in this frame matching the selection. */
	     for (m = 0; m < nmatrix; m++)
	     {
		 bytesread += SdifFReadMatrixHeader(file);
    
		 if (SdifFCurrMatrixIsSelected(file))
		 {    /* Access matrix header information */
		     SdifSignature   msig   = SdifFCurrMatrixSignature(file);
		     SdifInt4        nrows = SdifFCurrNbRow(file);
		     SdifInt4        ncols = SdifFCurrNbCol(file);
		     SdifDataTypeET  type  = SdifFCurrDataType(file);
    
		     int             row, col;
		     SdifFloat8      value;
                
		     printf("SigMat : %s",SdifSignatureToString(msig));
		     printf(" rows:%d  cols:%d\n", nrows, ncols);
		     /* printf("DataType : %d",SdifDataTypeKnown (type)); // retourne true (=1) si le datatype est connu*/
		     for (row = 0; row < nrows; row++)
		     {
			 bytesread += SdifFReadOneRow(file);
    
			 for (col = 1; col <= ncols; col++)
			 {
			     /* Access value by value... */
			     value = SdifFCurrOneRowCol(file, col);
    
			     /*  Do something with the data... */
			     printf("  %f ",value);
			     if(col == ncols)
				 printf("\n");
			 }
		     }
		 }
		 else
		 {
		     bytesread += SdifFSkipMatrixData(file);
		 }
            
		 bytesread += SdifFReadPadding(file, SdifFPaddingCalculate(file->Stream, bytesread));
	     } 
    
	     /* read next signature */
	     eof = SdifFGetSignature(file, &bytesread) == eEof;
	 }
     }
    printf("\n");

    if (SdifFLastError(file))   /* Check for errors */
    {
	exit (1);
    }
    
    SdifFClose(file);
    SdifGenKill();
    return 0;



}


