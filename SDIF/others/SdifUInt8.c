/* $Id: SdifUInt8.c,v 3.1 1999-03-14 10:56:21 virolle Exp $
 *
 *               Copyright (c) 1998 by IRCAM - Centre Pompidou
 *                          All rights reserved.
 *
 *  For any information regarding this and other IRCAM software, please
 *  send email to:
 *                            manager@ircam.fr
 *
 *
 * code to emulate 64 bits long on 32 bits machine
 *
 * author: Dominique Virolle 1997
 *
 * remove form project Nov97
 *
 *
 */


#include "SdifUInt8.h"



#ifdef _LONG64BITS_

void SdifUInt8Set64(SdifUInt8 *res, unsigned int Hig, unsigned long Low)
{
  unsigned long ul;

  ul = (unsigned long) Hig;
  ul = ul << 32;
  *res = ul + Low;
}

#endif /* _LONG64BITS_  */










#ifdef _LONG32BITS_




/* Affectation : res = (SdifUInt8)(Hig,Low) */
void SdifUInt8Set(SdifUInt8 *res, unsigned int Hig, unsigned int Low)
{
  res->Hig = Hig;
  res->Low = Low;
}




/* copy */
void SdifUInt8Cpy(SdifUInt8 *res, SdifUInt8 source)
{
  res->Hig = source.Hig;
  res->Low = source.Low;
}




/* (a>b) */
short SdifUInt8Sup(SdifUInt8 a, SdifUInt8 b)
{
  return (a.Hig == b.Hig)
    ? ((a.Low > b.Low) ? _True : _False)
    : ((a.Hig > b.Hig) ? _True : _False);
}





/* (a<b) */
short SdifUInt8Inf(SdifUInt8 a, SdifUInt8 b)
{
  return (a.Hig == b.Hig)
    ? ((a.Low < b.Low) ? _True : _False)
    : ((a.Hig < b.Hig) ? _True : _False);
}





/* (a==b) */
short SdifUInt8Equ(SdifUInt8 a, SdifUInt8 b)
{
  return (a.Hig == b.Hig)
    ? ( (a.Low == b.Low) ? _True : _False )
    : _False;
}





/* (a>=b) */
short SdifUInt8SupEqu(SdifUInt8 a, SdifUInt8 b)
{
  return (a.Hig == b.Hig)
    ? ( (a.Low == b.Low)
	? _True
	: (a.Low > b.Low) ? _True : _False )
    : (a.Hig > b.Hig) ? _True : _False;
}





/* (a<=b) */
short SdifUInt8InfEqu(SdifUInt8 a, SdifUInt8 b)
{
  return (a.Hig == b.Hig)
    ? ( (a.Low == b.Low)
	? _True
	: (a.Low < b.Low) ? _True : _False )
    : (a.Hig < b.Hig) ? _True : _False;
}






/* res = (a+b) */
void SdifUInt8Add(SdifUInt8* res, SdifUInt8 a, SdifUInt8 b)
{
  unsigned int CarringOver;

  res->Low = a.Low + b.Low;
  CarringOver = (_MaxUInt4 - a.Low < b.Low);
  res->Hig = a.Hig + b.Hig + CarringOver;
}






/* res += UInt4Incr */ 
void SdifUInt8Incr(SdifUInt8* Res, unsigned int UInt4Incr)
{
  SdifUInt8 SdifUInt8Incr;

  SdifUInt8Set(&SdifUInt8Incr, _ZeroUInt4, UInt4Incr);
  SdifUInt8Add(Res, *Res, SdifUInt8Incr);
}






/* res -= UInt4Decr */ 
void SdifUInt8Decr(SdifUInt8* Res, unsigned int UInt4Decr)
{
  if (Res->Low >= UInt4Decr)
    Res->Low -= UInt4Decr;
  else
    {
      if (Res->Hig)
	Res->Hig --;
      Res->Low += (_MaxUInt4 - UInt4Decr) +1;
    }
}





/* res = (a-b)
 * rounds brackets are essentials around (_MaxUInt4 - b.Low)
 * to force this operation before the additions
 * else we can have _MaxUInt4 +1 which isn't representable
 */
void SdifUInt8Sub(SdifUInt8* res, SdifUInt8 a, SdifUInt8 b)
{
  unsigned int CarringUnder;

  if (SdifUInt8Inf(a,b))
    {
      fprintf(stderr, "error in SdifUInt8Sub a<b\n");
      SdifUInt8Sub(res, b, a);
      /* error */
    }
  else
    {
      CarringUnder = (a.Low < b.Low);
      res->Low = (CarringUnder)
	? ( (_MaxUInt4 - b.Low) +1 +a.Low)
	: (a.Low - b.Low);
      res->Hig = a.Hig - b.Hig - CarringUnder;
    }

  /*  Another version without CarringUnder
  else
    {
      SdifUInt8Set (res, a.Hig, a.Low);
      SdifUInt8Decr(res, b.Low);
      res->Hig -=  b.Hig;
    }
    */
}







double SdifUInt8ToDouble(SdifUInt8 i)
{
  return ((double) i.Low) + ((double) i.Hig) * ((float) _MaxUInt4 +1) ;
}





#endif /* _LONG32BITS_ */
