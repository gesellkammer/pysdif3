/* $Id: SdifUInt8.h,v 3.1 1999-03-14 10:56:22 virolle Exp $
 *
 *               Copyright (c) 1998 by IRCAM - Centre Pompidou
 *                          All rights reserved.
 *
 *  For any information regarding this and other IRCAM software, please
 *  send email to:
 *                            manager@ircam.fr
 *
 *
 * Type Unsigned Int depending on machine
 * if machine has 64 bits long then SdifUInt8 is unsigned long
 * else 64 bits are emulated with a structure of two 32 bits unsigned int 
 *
 * Use macros to assume code run on most machines
 *
 * Macros have some arguments which must be a variable name (== left value)
 * Consider that these return nothing.
 *
 * author: Dominique Virolle 1997
 *
 * remove form project Nov97
 *
 */




#ifndef _SdifUInt8_
#define _SdifUInt8_

#if defined(__mips64) || defined(__alpha)
#define _LONG64BITS_
#else
#define _LONG32BITS_
#endif

#include <stdio.h>

#ifndef _MaxUInt4
#define _MaxUInt4 0xffffffff
#endif

#define _ZeroUInt4 0x0

#ifndef _True
#define _True 1
#endif

#ifndef _False
#define _False 0
#endif


#ifdef _LONG64BITS_
typedef unsigned long SdifUInt8;

extern void SdifUInt8Set64(SdifUInt8 *res, unsigned int Hig, unsigned long Low);

#define _SdifUInt8Set(SdifUInt8Var,ValHig,ValLow)  SdifUInt8Set64((&##SdifUInt8Var),(##ValHig),(##ValLow))
#define _SdifUInt8Cpy(SdifUInt8Var, Val)           (##SdifUInt8Var) = Val
#define _SdifUInt8Incr(SdifUInt8Var,Value)         (##SdifUInt8Var) += (##Value)
#define _SdifUInt8Decr(SdifUInt8Var,Value)         (##SdifUInt8Var) -= (##Value)
#define _SdifUInt8Add(SdifUInt8Var,aVar,bVar)      (##SdifUInt8Var) =  ((##aVar)+(##bVar))
#define _SdifUInt8Sub(SdifUInt8Var,aVar,bVar)      (##SdifUInt8Var) =  ((##aVar)-(##bVar))
#define _SdifUInt8Sup(aVar,bVar)               ((##aVar) > (##bVar))
#define _SdifUInt8Inf(aVar,bVar)               ((##aVar) < (##bVar))
#define _SdifUInt8Equ(aVar,bVar)               ((##aVar) == (##bVar))
#define _SdifUInt8SupEqu(aVar,bVar)            ((##aVar) >= (##bVar))
#define _SdifUInt8InfEqu(aVar,bVar)            ((##aVar) <= (##bVar))
#define _SdifUInt8ToDouble(iVar)               ((double)(##iVar))
#define _SdifUInt8fprintf(f,iVar)              fprintf((##f),"%016lx",(##iVar))


#else

typedef struct  SdifUInt8S
{
  unsigned int Hig;
  unsigned int Low;
} SdifUInt8;




extern void   SdifUInt8Set     (SdifUInt8* res, unsigned int Hig, unsigned int Low); /* affectation */
extern void   SdifUInt8Cpy     (SdifUInt8* res, SdifUInt8 source);                   /* copy */
extern void   SdifUInt8Incr    (SdifUInt8* Res, unsigned int UInt4Incr);             /* res += UInt4Incr */
extern void   SdifUInt8Decr    (SdifUInt8* Res, unsigned int UInt4Decr);             /* res -= UInt4Decr */ 
extern void   SdifUInt8Add     (SdifUInt8* res, SdifUInt8 a, SdifUInt8 b);           /* res = (a+b) */
extern void   SdifUInt8Sub     (SdifUInt8* res, SdifUInt8 a, SdifUInt8 b);           /* res = (a-b) */
extern short  SdifUInt8Sup     (SdifUInt8 a, SdifUInt8 b);                   /* (a>b)  */
extern short  SdifUInt8Inf     (SdifUInt8 a, SdifUInt8 b);                   /* (a<b)  */
extern short  SdifUInt8Equ     (SdifUInt8 a, SdifUInt8 b);                   /* (a==b) */
extern short  SdifUInt8SupEqu  (SdifUInt8 a, SdifUInt8 b);                   /* (a>=b) */
extern short  SdifUInt8InfEqu  (SdifUInt8 a, SdifUInt8 b);                   /* (a<=b) */
extern double SdifUInt8ToDouble(SdifUInt8  i);

#define _SdifUInt8Set(SdifUInt8Var,ValHig,ValLow)  SdifUInt8Set ((&##SdifUInt8Var),(##ValHig),(##ValLow))
#define _SdifUInt8Cpy(SdifUInt8Var, Val)           SdifUInt8Cpy ((&##SdifUInt8Var),(##Val))
#define _SdifUInt8Incr(SdifUInt8Var,Value)         SdifUInt8Incr((&##SdifUInt8Var),(##Value))
#define _SdifUInt8Decr(SdifUInt8Var,Value)         SdifUInt8Decr((&##SdifUInt8Var),(##Value))
#define _SdifUInt8Add(SdifUInt8Var,aVar,bVar)      SdifUInt8Add ((&##SdifUInt8Var),(##aVar),(##bVar))
#define _SdifUInt8Sub(SdifUInt8Var,aVar,bVar)      SdifUInt8Sub ((&##SdifUInt8Var),(##aVar),(##bVar))
#define _SdifUInt8Sup(aVar,bVar)               SdifUInt8Sup ((##aVar),(##bVar))
#define _SdifUInt8Inf(aVar,bVar)               SdifUInt8Inf ((##aVar),(##bVar))
#define _SdifUInt8Equ(aVar,bVar)               SdifUInt8Equ ((##aVar),(##bVar))
#define _SdifUInt8SupEqu(aVar,bVar)            SdifUInt8SupEqu ((##aVar),(##bVar))
#define _SdifUInt8InfEqu(aVar,bVar)            SdifUInt8InfEqu ((##aVar),(##bVar))
#define _SdifUInt8ToDouble(iVar)               SdifUInt8ToDouble(##iVar)
#define _SdifUInt8fprintf(f,iVar)              fprintf((##f),"%08x%08x",((##iVar).Hig),((##iVar).Low))

#endif /* _LONG64BITs_ */

#endif /* _SdifUInt8_ */
