#!/usr/bin/perl
#
# $Id: xmltohtml.pl,v 1.12 2001-06-08 18:46:58 schwarz Exp $
#
# xmltohtml.pl		6. July 2000		Diemo Schwarz
#
# Translate SDIF types description in XML to HTML.
#
# $Log: not supported by cvs2svn $
# Revision 1.11  2001/05/02 15:21:33  schwarz
# Added top-level description for section descriptions.
# Tweaked table-disguised-as-heading layout.
#
# Revision 1.10  2000/08/22 16:21:48  schwarz
# Allow attributes to HTML-like tags.
# Back/Home/etc. links at bottom.
# Nicer toc.
#
# Revision 1.9  2000/08/18  17:53:28  schwarz
# Proper handling of single HTML tags (empty tags in XML).
#
# Revision 1.8  2000/08/17  14:44:16  schwarz
# Matrix status copied.
#
# Revision 1.7  2000/08/17  14:34:46  schwarz
# HTML table of contents is generated!  Use file index.html to get
# the generated navigation frame toc.html and sdiftypes.html.
# More HTML tags copied through.
#
# Revision 1.6  2000/08/16  16:10:15  schwarz
# Added var sub sup to XML tags to be copied to HTML.
#
# Revision 1.5  2000/08/09  14:55:35  schwarz
# Bloody comment header.
#
# Revision 1.4  2000/08/09  14:43:50  schwarz
# Put all SDIF types into XML format.  Lots of descriptions still missing.
# Full "about this document" info.
#
# Revision 1.3  2000/08/08  15:59:09  schwarz
# SDIF-TDL version 0.2 (no matrix:role attribute, types-version, types-revision
# Generation details in STYP 1NVT / HTML footer.
#
# revision 1.2 date: 2000/08/01 09:36:03;  author: schwarz;
# Coloured section headings.
#
# revision 1.1 date: 2000/07/27 13:32:03;  author: schwarz;
# First preliminary trial test version of SDIF types definition using XML:
# xmltostyp.pl generates library-types file sdiftypes.styp from sdiftypes.xml,
# xmltohtml.pl generates documentation file sdiftypes.html from sdiftypes.xml.

# TODO:
# - table for matrix, frames
# - use DOM parser instead of XML::Node
# - generate LaTeX->hevea->html???
# - if not above, then generate table of contents
# - status for matrices


use English;
use XML::Node;
use HTML::Stream qw(:funcs);
use File::Basename;


# html setup
my @singlehtmltags = qw(p br);
my @copiedhtmltags = qw(i b strong emph code var sub sup pre a);
my %tagmap = (# section => 'H2', 
	      map { (uc $_, uc $_, lc $_, uc $_ ) } @copiedhtmltags);
my %tagsing = (map { (uc $_, uc $_, lc $_, uc $_ ) } @singlehtmltags);


# init
my $cvsrev     = '$Id: xmltohtml.pl,v 1.12 2001-06-08 18:46:58 schwarz Exp $ ';
my $tdlversion = '';
my $version    = 'unknown';
my $revision   = '';
my $framesig   = '';
my $framename  = '';
my $framestat  = '';
my $matrixsig  = '';
my $matrixname = '';
my $matrixstat = '';
my $rownum     = '';
my $rowmin     = '';
my $rowmax     = '';
my $colname    = '';
my $colunit    = '';
my $refsig     = '';
my $refocc     = '';
my $text       = '';	# text for all descriptions and refs
my $lang       = '';
my @htmlattr   = ();
my @columns    = ();
my @components = ();

my %matrixnames = ();
#later my %matrixroles = ();
my $doc;
local $lastlevel = 1;


# arguments
my ($xmlin, $docout, $tocout) = @ARGV;
my $docbase = basename ($docout);

# open files, create objects
if ($docout eq '-')
{
    $doc = *STDOUT;
}
else
{
    open (DOC, ">$docout")  ||  die;
    $doc = *DOC;
}
open (TOC, ">$tocout")  ||  die;

$h   = new HTML::Stream $doc;
$toc = new HTML::Stream \*TOC;
$xml = new XML::Node;


#
# register XML handlers
#

# header handler
$xml->register (">sdif-tdl", 		    start => \&header);
$xml->register (">sdif-tdl", 		    end   => \&footer);
$xml->register (">sdif-tdl:version",	    attr  => \$tdlversion);
$xml->register (">sdif-tdl>types-version",  char  => sub { 
    $h->I->t("SDIF Types Version: ")->_I->t($_[1])->P; });
$xml->register (">sdif-tdl>types-revision", char  => \$revision);
$xml->register (">sdif-tdl>types-revision", end   => sub { 
    $h->I->t("SDIF Types CVS Revision: ")->_I->CODE->t($revision)->_CODE->P;});

# row/column handlers
$xml->register ("rows:num",    attr => \$rownum);
$xml->register ("rows:min",    attr => \$rowmin);
$xml->register ("rows:max",    attr => \$rowmax);
$xml->register ("rows",        start=> \&row_start);
$xml->register ("rows",        char => \&out_char);
$xml->register ("rows",        end  => \&row_end);
$xml->register ("column",      start=> \&column_start);
$xml->register ("column",      char => \&out_char);
$xml->register ("column",      end  => \&column_end);
$xml->register ("column:name", attr => \$colname);
$xml->register ("column:unit", attr => \$colunit);

# matrix handlers, free or in frame
$xml->register ("matrix:signature", attr => \$matrixsig);
$xml->register ("matrix:name",      attr => \$matrixname);
$xml->register ("matrix:status",    attr => \$matrixstat);
$xml->register ("matrix",	    start=> \&matrix_start);
$xml->register ("matrix",	    end  => \&matrix_end);

# matrix in frame
$xml->register (">sdif-tdl>frame>matrixref:occurrence", attr  => \$refocc);
$xml->register (">sdif-tdl>frame>matrixref",            start => \&addmatrix);
$xml->register (">sdif-tdl>frame>matrixref",            char  => \&out_char);
# todo: heed roles

# frame handlers
$xml->register (">sdif-tdl>frame:signature", attr => \$framesig);
$xml->register (">sdif-tdl>frame:name",      attr => \$framename);
$xml->register (">sdif-tdl>frame:status",    attr => \$framestat);
$xml->register (">sdif-tdl>frame",	     start=> \&frame_start);
$xml->register (">sdif-tdl>frame",	     end  => \&frame_end);

# references in text
$xml->register ("matrixref:signature", attr  => \$refsig);
$xml->register ("matrixref",	       char  => \&matrixref_char);
$xml->register ("frameref:signature",  attr  => \$refsig);
$xml->register ("frameref",	       char  => \&frameref_char);
		# no tags in ref text!

# matrix, frame, column descriptions
$xml->register ("description", start => \&description_start);
$xml->register ("description", char  => \&out_char);
$xml->register ("description", end   => \&description_end);
$xml->register ("description:language", attr => \$lang);
$xml->register ("description:title",    attr => \$desctitle);

# section and section description
$xml->register ("section",     char  => \&section);
$xml->register (">sdif-tdl>description", 
			       start => \&section_description_start);
$xml->register (">sdif-tdl>description", 
			       end   => \&section_description_end);


# register XML->HTML tag mapping handlers
for (keys %tagmap)
{
    $xml->register ($_, start => \&tagmap_start);
    $xml->register ($_, char  => \&out_char);
    $xml->register ($_, end   => \&tagmap_end);
}
for (keys %tagsing)
{
    $xml->register ($_, start => \&tagmap_start);
}

# register html attributes
$xml->register ("a:href", attr => \&html_attr);
$xml->register ("a:target", attr => \&html_attr);


# process input file
$xml->parsefile ($xmlin);

# close
close $doc;
close TOC;

# end of main




sub tagmap_start
{
    $h->tag ($_[1], @htmlattr);
    @htmlattr = ();
}

sub tagmap_end
{
    $h->tag ("_$_[1]"); 
}

sub html_attr
{
    push (@htmlattr, $xml->{CURRENT_ATTR}, $_[1]);
}


sub out_char
{
    $h->t($_[1]);
}

sub header
{
    $h->HTML->TITLE->t("Standard SDIF Types")->_TITLE
      ->BODY(bgcolor => "#ffffff")->H1->t("Standard SDIF Types")->_H1;
    $toc->HTML->TITLE->t("Standard SDIF Types Table of Contents")->_TITLE
	->BODY(bgcolor => "#ffffff");
    toc ('', "Contents", 0);
    $toc->FONT(size => -1)->P;
}

sub footer
{
    my @g = stat $PROGRAM_NAME;
    my @s = stat $xmlin;
    my $fs = "+0";

    $h->BR->BR->BR->ADDRESS->tag('BASEFONT', size => 1)
      ->A(name => "Section_About This Document")
      ->TABLE(cellspacing => 0, cellpadding => 3)->TR
	  ->TD(colspan => 4, bgcolor => "gray")
	      ->FONT(size => +4)->B->t("About This Document")->_B->_FONT
      ->TR(align => 'left', valign => 'top')
	  ->TD(colspan => 4)
	      ->t("This document $docbase generated " . scalar localtime() . 
		  " by $PROGRAM_NAME from $xmlin")
      ->TR(align => 'left', valign => 'top')
	  ->TH->t("Generation")->TD->t($ENV{USER})
	  ->TD(nowrap)->t(scalar localtime())
	  ->TD(nowrap)->t("$ENV{HOST} $ENV{PWD}")->_TR
      ->TR(align => 'left', valign => 'top')
	  ->TH->t("Generator")->TD->t($PROGRAM_NAME)
	  ->TD(nowrap)->t(scalar localtime($g[9]))
	  ->TD(nowrap)->t($cvsrev)->_TR
      ->TR(align => 'left', valign => 'top')
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
	  ->B->t("IRCAM")->_B->_A->_FONT
      ->_TABLE->_A
      ->_ADDRESS;
    $h->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR->BR;
    $h->_BODY->_HTML;

    toc ("Section_About This Document", "About This Document", 1);
    $toc->_DL->_FONT->_BODY->_HTML;

}


sub row_start
{
    $h->DL->DT->I->t("Rows:");
    $rownum  &&  $h->t(" number=$rownum");
    $h->_I->DD;

    $rownum = '';
};

sub row_end
{
    $h->_DD->_DL;

    push @columns, $colname;
    $colname = '';
    $colunit = '';
};

sub column_start
{
    !$colhead  && $h->DL->DT->I->t("Columns:")->_I->_DL->OL;
    $h->LI->B->t("$colname ")->_B;
    $colunit  &&  $h->I->t("[$colunit] ")->_I;
    $colhead = 1;
};

sub column_end
{
    push @columns, $colname;
    $colname = '';
    $colunit = '';
};

sub matrix_start
{
    $h->BR->A(name => "Matrix_$matrixsig")
      ->H3->t("Matrix $matrixsig $matrixname")->_H3->_A;
    $matrixstat  &&  $h->DL->DT->I->t("Status:")->_I->DD->t($matrixstat)->_DD->_DL;    
    $matrixstat = '';
    toc ("Matrix_$matrixsig", "Matrix $matrixsig $matrixname", 2);
}

sub matrix_end
{
    $colhead     &&  $h->_OL;
    $text  &&  $h->DL->DT->I->t("Description:")->_I->DD->t($text)->_DD->_DL;
    $h->HR;
    # todo: text before columns

    $matrixnames{$matrixsig} = $matrixname;
    @columns    = ();
    $matrixsig  = ''; 
    $matrixname = ''; 
    $text = '';
    $colhead = 0;
}


sub matrixref
{
    $h->A(href => "#Matrix_$matrixref")->t("Matrix $matrixsig $matrixname")->_A;
    $matrixref = '';
}

sub frame_start
{
    $h->BR->A(name => "Frame_$framesig")
      ->H3->t("Frame $framesig $framename")->_H3->_A;
    $framestat  &&  $h->DL->DT->I->t("Status:")->_I->DD->t($framestat)->_DD->_DL;
    toc ("Frame_$framesig", "Frame $framesig $framename", 2);
    $framestat = '';
}

sub frame_end
{
    $mathead  &&  $h->_UL->_DL;
    $mathead = 0;
    $h->HR;

    $framesig   = '';
    $framename  = '';
    $text  = '';

}

sub addmatrix
{
    !$mathead  &&  $h->DL->DT->I->t("Matrices:")->_I->DD->UL;
    $h->LI->A(href => "#Matrix_$refsig")->t("$refsig $matrixnames{$refsig}")->_A;
    $h->I->t(" $refocc ")->_I;

    $mathead = 1;
    $refsig = '';
    $refocc = '';
    $text = '';
}

sub matrixref_char
{
    $h->A(href => "#Matrix_$refsig")->t($_[1])->_A;    
    $refsig = '';
}

sub frameref_char
{
    $h->A(href => "#Frame_$refsig")->t($_[1])->_A;    
    $refsig = '';
}

sub description_start
{
    $h->DL->DT->I->t("Description" . ($lang ? " (language = $lang)" : "") . 
		     ":")->_I->DD;
    $text = '';
    $lang = '';
}

sub description_end
{
    $h->_DD->_DL;
}

sub section_description_start
{
    $h->H3->t(($desctitle ? $desctitle : "Description") 
	    . ($lang      ? " (language = $lang)" : ""))->_H3;
    $text = '';
    $desctitle = '';
    $lang = '';
}

sub section_description_end
{
    $h->P->HR;
}


sub section
{
    chomp $_[1];
    #simple: $h->H2->t($_[1])->_H2;
    $h->BR->BR->A(name => "Section_$_[1]")
      ->TABLE(bgcolor => 'yellow', cellspacing => 0, cellpadding => 3, 
	      width   => '100%')
      ->TR->TD->FONT(size => +5)->B->t($_[1])->_B->_FONT->_TD->_TR->_TABLE->_A;
    toc ("Section_$_[1]", $_[1], 1);
}


sub toc
{
    my ($target, $text, $level) = @_;
    my @levtag  = ('B', 'B' , 'LI');

    if ($level < $lastlevel)
    {
	$toc->P;
    }
    if ($level > $lastlevel)
    {
#	$toc->DL(compact);
    }
    $toc->A(target => "doc", href => "$docbase#$target");
    $toc->tag($levtag[$level])		if $levtag[$level];
    $toc->t($text);
    $toc->tag("_$levtag[$level]")	if $levtag[$level];

    $lastlevel = $level;
}
