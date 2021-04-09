#!/usr/bin/perl
#
# $Id: xmltostyp.pl,v 1.5 2001-04-18 16:24:52 schwarz Exp $
#
# xmltostyp.pl		6. July 2000		Diemo Schwarz
#
# Translate SDIF types description in XML to STYP format for the SDIF-library.
#
# $Log: not supported by cvs2svn $
# Revision 1.4  2000/09/27 10:12:47  schwarz
# Ideas for datatype, datarange.
#
# Revision 1.3  2000/08/09  14:43:50  schwarz
# Put all SDIF types into XML format.  Lots of descriptions still missing.
# Full "about this document" info.
#
# Revision 1.2  2000/08/08  15:59:10  schwarz
# SDIF-TDL version 0.2 (no matrix:role attr., types-version, types-revision)
# Generation details in STYP 1NVT / HTML footer
#
# revision 1.1 date: 2000/07/27 13:32:03;  author: schwarz;
# First preliminary trial test version of SDIF types definition using XML:
# xmltostyp.pl generates library-types file sdiftypes.styp from sdiftypes.xml,
# xmltohtml.pl generates documentation file sdiftypes.html from sdiftypes.xml.
#
# TODO:
# - use DOM parser instead of XML::Node


use English;
use XML::Node;
use File::Basename;

# predeclare subs
sub out;
sub outtofile;


my $cvsrev     = '$Id: xmltostyp.pl,v 1.5 2001-04-18 16:24:52 schwarz Exp $ ';
my $tdlversion = '';
my $version    = '';
my $revision   = '';
my $framesig   = '';
my $matrixsig  = '';
my $matrixname = '';
my @columns    = ();
my @components = ();

my %matrixnames = ();
#later my %matrixroles = ();


# init xml
$xml = new XML::Node;


# header handler
$xml->register (">sdif-tdl:version",	    attr  => \$tdlversion);
$xml->register (">sdif-tdl",		    end   => 
		sub { outtofile "}\n"; } );	# end of 1TYP block
$xml->register (">sdif-tdl>types-version",  char  => \$version);
$xml->register (">sdif-tdl>types-revision", char  => \$revision);

# column handlers
$xml->register ("column:name", attr => sub { push @columns, $_[1] });

# matrix handlers, free or in frame
$xml->register ("matrix",	    start => \&header);
$xml->register ("matrix:signature", attr  => \$matrixsig);
$xml->register ("matrix:name",      attr  => \$matrixname);
$xml->register ("matrix",	    end   => \&matrix);

# matrix in frame
$xml->register (">sdif-tdl>frame>matrix:signature",    attr  => \&addmatrix);
$xml->register (">sdif-tdl>frame>matrixref:signature", attr  => \&addmatrix);
# todo: heed roles

# frame handlers
$xml->register (">sdif-tdl>frame",	     start => \&header);
$xml->register (">sdif-tdl>frame:signature", attr  => \$framesig);
$xml->register (">sdif-tdl>frame",	     end   => \&frame);

# a little grouping
$xml->register (">sdif-tdl>section",	     start => sub { out "\n"; } );


# arguments
if (@ARGV < 3)
{
    print "Usage: $PROGRAM_NAME input-sdiftypes.xml output-sdiftypes.styp output-sdiftypes.h\n";
    exit 1;
}

local ($xmlin, $stypout, $typesout) = @ARGV;
my $stypbase  = basename ($stypout);
my $typesbase = basename ($typesout);

open(STYPOUT, ">$stypout")  ||  die;

# process input file
local $styp;	# the whole styp file as a string
$xml->parsefile ($xmlin);

close STYPOUT;


# open and prepare types.h

my $comment = "This document $typesout generated " . scalar localtime() . 
    " by $PROGRAM_NAME from $xmlin";

=pod

    "Generation $ENV{USER} " . scalar localtime() . " $ENV{HOST} $ENV{PWD}"
    "Generator $PROGRAM_NAME " . scalar localtime($g[9]) . " $cvsrev
	  ->TH->t("Source file")->TD->t("$xmlin")
	  ->TD(nowrap)->t(scalar localtime($s[9]))
	  ->TD(nowrap)->t($revision)->_TR
      ->TR
	->TD(colspan => 1, bgcolor => "gray")->FONT(size => $fs)
	  ->A(href => "../index.html", target => "_parent")
	  ->B->t("Back")->_B->_A->_FONT
        ->TD(colspan => 1, bgcolor => "gray")->FONT(size => $fs)
	  ->A(href => "http://www.ircam.fr/sdif", target => "_parent")
	  ->B->t("SDIF")->e('nbsp')->t("Home")->_B->_A->_FONT
        ->TD(colspan => 1, bgcolor => "gray")->FONT(size => $fs)
	  ->A(href => "http://www.ircam.fr/anasyn", target => "_parent")
	  ->B->t("Analysis/Synthesis Team")->_B->_A->_FONT
       ->TD(colspan => 1, bgcolor => "gray")->FONT(size => $fs)
	  ->A(href => "http://www.ircam.fr", target => "_parent")
	  ->B->t("IRCAM")"

=cut

# every line in $styp becomes "line\n"\\n
$styp =~ s((.*?)\n)("$1\\n"\\\n)g;

open (H, ">$typesout")  ||  die;
print H <<"END_OF_TEXT";
/* $comment
*/
#ifndef _SDIFTYPES_H_
#define _SDIFTYPES_H_

#define SDIFTYPES_STRING \\
$styp

#endif
END_OF_TEXT

close H;

# end of main



sub header
{   # write header only once!
    if (defined $version)
    {
	my @g = stat $PROGRAM_NAME;
	my @s = stat $xmlin;
	my %nvt = (SdifTypesVersion   => $version,
		   GenerationDate     => scalar localtime,
		   GenerationUser     => $ENV{USER},
		   GenerationHost     => $ENV{HOST},
		   GenerationDir      => $ENV{PWD},
		   Generator	      => $PROGRAM_NAME,
		   GeneratorFiledate  => scalar localtime($g[9]),
		   GeneratorRevision  => $cvsrev,
		   SourceFile	      => $xmlin,
		   SourceFiledate     => scalar localtime($s[9]),
		   SourceFileRevision => $revision);

	outtofile "SDIF\n\n1NVT\n{\n";
	for my $name (sort keys %nvt)
	{
	    # replace reserved chars
	    (my $value = $nvt{$name}) =~ tr(.:;, \n\t)(_); 
	    outtofile "  $name\t$value;\n";
	}
	outtofile "}\n\n1TYP\n{\n";	# end of 1NVT block, start of 1TYP
	undef $version;
    }
}


sub addmatrix
{
    push (@components, $_[1]);
}

sub matrix
{
    out "1MTD $matrixsig { ", join (', ', @columns), " }\n";
    $matrixnames{$matrixsig} = $matrixname;
    @columns    = ();
    $matrixsig  = ''; 
    $matrixname = ''; 
}

sub frame 
{
    out "1FTD $framesig { ", map ("$_ $matrixnames{$_}; ", @components), " }\n";
    @components = ();
    $framesig   = '';
}


sub outtofile
{
    print STYPOUT @_;	# .styp file output
}

sub out
{
    outtofile @_;		# standard out -> .styp
    $styp .= join('', @_);	# types.h to be included
}
