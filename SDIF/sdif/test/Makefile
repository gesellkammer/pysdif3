# $Id: Makefile,v 1.6 2002-10-29 11:08:34 schwarz Exp $
#
# SDIF/sdif/test/Makefile
#
# $Log: not supported by cvs2svn $
# Revision 1.5  2002/10/29 10:51:21  schwarz
# Reinserted old tests, they are still needed!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Made old tests compile with new autoconf'ed structure.
#
# Revision 1.4  2002/05/24 19:38:07  ftissera
# *** empty log message ***
#
# Revision 1.3  2000/05/04 14:57:29  schwarz
# test check for SdifCheckFrames funcs.
#
# Revision 1.2  1999/09/28  13:15:11  schwarz
# Test case
#
# Revision 1.1  1999/08/31  10:03:37  schwarz
# Added test code for module SdifSelect which parses an access specification to
# a chosen part of SDIF data.  Can be added to a file name.


PRJ_DIR := $(shell pwd)/../..

# Version modifiee de SDIF
# MODIF_SDIF_LIBROOT = /u/formes/ftissera/src/SDIF
MODIF_SDIF_LIBROOT = ../..
INCLUDE_DIR	   = $(MODIF_SDIF_LIBROOT)/include

SDIF_SRC_DIR	   = ..
SDIF_OBJ_DIR	   = ..
SDIF_LIB_DIR	   = ..
LIBNAME		   = sdif

CC 	 	   = gcc   
INCFLAGS 	  := -I. -I$(INCLUDE_DIR)
CFLAGS	 	  := -g  -ggdb -Wall $(CAFLAGS) $(DFLAGS) $(INCFLAGS)
LD_DIR 	 	   = -L$(MODIF_SDIF_LIBROOT)/sdif
LDFLAGS  	   = -L$(SDIF_LIB_DIR) $(LD_DIR) -l$(LIBNAME) -lm


TARGETS	= testcheck testselect essai_err


all:	$(TARGETS) test
test:	test_sel

%: 	%.c
	$(CC) $^ $(CFLAGS) $(LDFLAGS) $(LFLAGS) $(OBJS) $(LIBS) -o $@

$(SDIF_OBJ_DIR)/%.o:	$(SDIF_SRC_DIR)/%.c
	@echo "----- making $@"
	@echo "      from   $<"
	$(MAKE) -C $(SDIF_SRC_DIR)

$(SDIF_LIB_DIR)/lib$(LIBNAME).a:	$(SDIF_SRC:%=../%)
		$(MAKE) -C $(PRJ_DIR)

clean::
	$(RM) $(TARGETS) core *~



###############################################################################
#
# tests for selection
#

testselect:	testselect.c $(SDIF_OBJ_DIR)/SdifSelect.o

# test cases:
#	testselect asdf::aaaa,bbb@2+-.-3

test_sel:	testselect
	./testselect aaa::@0-



###############################################################################
#
# tests for SdifCheckFrames funcs
#

testcheck:	testcheck.c  $(SDIF_LIB_DIR)/lib$(LIBNAME).a

# test cases:
# querysdif ../../test/sdiffiles2000/pianoRes.m5.FIL.sdif
# ./testcheck ../../test/sdiffiles2000/pianoRes.m5.FIL.sdif 1REB
# Found 1REB frame, index 0.
# ./testcheck ../../test/sdiffiles2000/pianoRes.m5.FIL.sdif 1NOI 1REB
# Found 1REB frame, index 1.
# ./testcheck ../../test/sdiffiles2000/pianoRes.m5.FIL.sdif 1HRM 1HRM 1HRM
# Found no frame, index -1.



###############################################################################
#
# tests for easdif
#

essai_err: essai_err.c $(MODIF_SDIF_LIBROOT)/include/sdif.h
	$(CC) essai_err.c -o $@ $(CFLAGS) $(LDFLAGS)
