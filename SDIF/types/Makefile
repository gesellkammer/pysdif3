# $Id: Makefile,v 1.10 2009-08-10 17:29:26 diemo Exp $
#
# $Log: not supported by cvs2svn $
# Revision 1.9  2001/04/27 13:50:54  schwarz
# $@ doesn't give the first of multiple targets????????
#
# Revision 1.8  2001/04/27 13:38:36  schwarz
# Generate SdifTypes.STYP in its new place ../data.
#
# Revision 1.7  2001/04/18 16:24:52  schwarz
# Generate ../sdif/sdiftypes.h with xmltostyp.pl to include standard types
# into the code as #define'd string SDIFTYPES_STRING
# (--> no need to install SdifTypes.STYP)
# Generate ../sdif/SdifTypes.STYP directly.
# Changed usage of xmltostyp.pl, added help.
#
# Revision 1.6  2000/08/22 16:19:54  schwarz
# Generate HTML here and in doc.  clean.
#
# Revision 1.5  2000/08/17  14:34:45  schwarz
# HTML table of contents is generated!  Use file index.html to get
# the generated navigation frame toc.html and sdiftypes.html.
# More HTML tags copied through.
#
# Revision 1.4  2000/08/09  14:43:48  schwarz
# Put all SDIF types into XML format.  Lots of descriptions still missing.
# Full "about this document" info.
#
# Revision 1.3  2000/08/01  10:15:34  schwarz
# Added clean, new, .DELETE_ON_ERROR.
#
# Revision 1.2  2000/08/01  09:37:00  schwarz
# Targets for both files, use standard Perl modules.
#

ifeq ($(USER), schwarz)
  mynode	= /u/formes/schwarz/soft/perl/XML-Node-0.10
  PERLFLAGS	= -I$(mynode) -MNode
endif

PERL		= perl $(PERLFLAGS)

# where to generate html
HTMLDIR		= ../doc/standard
htmldoc		= $(HTMLDIR)/types-doc.html
htmltoc		= $(HTMLDIR)/types-toc.html

# where the generated SdifTypes.STYP and sdiftypes.h go
STYPDIR		= ../data
HTYPDIR		= ../sdif
sdiftypes_styp  = $(STYPDIR)/SdifTypes.STYP
sdiftypes_h	= $(HTYPDIR)/sdiftypes.h

genfiles	= $(sdiftypes_styp) $(sdiftypes_h) sdiftypes.html toc.html \
		  $(htmldoc) $(htmltoc)

.DELETE_ON_ERROR:	# remove targets when the command failed


all:		$(genfiles)
new:		clean all

$(sdiftypes_styp) $(sdiftypes_h):	sdiftypes.xml xmltostyp.pl
		$(PERL) xmltostyp.pl $< $(sdiftypes_styp) $(sdiftypes_h)

# generate in doc
$(htmldoc) $(htmltoc): sdiftypes.xml xmltohtml.pl $(HTMLDIR)
		$(PERL) xmltohtml.pl $< $(htmldoc) $(htmltoc)

# test: generate here
sdiftypes.html:	sdiftypes.xml xmltohtml.pl
		$(PERL) xmltohtml.pl $< $@ toc.html

# no install, sdiftypes.styp is generated where it belongs

clean:
		rm -f $(genfiles)

reload:		sdiftypes.html $(htmldoc)
		netscape -remote 'reload()'

show:		sdiftypes.html
		netscape -remote 'reload(file:$(PWD)/$<)'

test:		all
		querysdif -t sdiftypes.styp </dev/null

db:
		DEBUG=1 $(PERL) xmltohtml.pl sdiftypes.xml >sdiftypes.html
		netscape -remote 'reload(file:$(PWD)/sdiftypes.html)'

$(HTMLDIR):
		mkdir -p $@
