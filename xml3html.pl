#!/usr/bin/perl
#INSTALL@ /usr/local/bin/xml3html
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml
use strict;
use File::Basename;

my $dvifontpath=`find /usr/share -name 'ps2pk.map' 2>&1 | grep -v 'Permission denied' | tail -1`;
chomp $dvifontpath;
$dvifontpath=dirname($dvifontpath);

my @fontmap;

if (open (my $FM,'<','in3fontmap')){
	@fontmap=<$FM>;
	close $FM;
}
elsif (open (my $FM,'<','/usr/local/share/in3/fontmap')){
	@fontmap=<$FM>;
	close $FM;
}


my $trace=0;
my $DEBUG=0;
my @output;
my $outatol=0;
sub output{
	if ($outatol==0){
		for (@_){
			push @output, $_;
			if ($trace > 0){print STDERR "#                                                               output: $_\n";}
		}
	}
	else {
		my $top;
		for (@_){
			my $txt=$_;
			$top=pop@output;
			push @output, "$top$txt";
			if ($trace > 0){print STDERR "#                                                               output: $_\n";}
		}
	}
	$outatol=0;
}

sub outputreplace {
	(my $replace)=@_;
	pop @output;
	push @output,$replace;
}
sub outputlast {
	my $top=pop@output;
	push @output,$top;
	return $top;
}

my $progres=0;
my $progresschar=' ';
sub progress {
	$progres++;
	if ($progresschar eq ' '){$progresschar='1';}
	elsif ($progresschar eq '1'){$progresschar='2';}
	elsif ($progresschar eq '2'){$progresschar='3';}
	elsif ($progresschar eq '3'){$progresschar='4';}
	elsif ($progresschar eq '4'){$progresschar='5';}
	elsif ($progresschar eq '5'){$progresschar='6';}
	elsif ($progresschar eq '6'){$progresschar='7';}
	elsif ($progresschar eq '7'){$progresschar='8';}
	elsif ($progresschar eq '8'){$progresschar='9';}
	elsif ($progresschar eq '9'){$progresschar='0';}
	elsif ($progresschar eq '0'){$progresschar='1';}
	print STDERR "\r$progres";
	print STDERR "." x $progres;
}



# Variables for overall use
my %variables;
    $variables{'H1'}=0;
    $variables{'H2'}=0;
    $variables{'H3'}=0;
    $variables{'H4'}=0;
    $variables{'H5'}=0;
    $variables{'H6'}=0;
    $variables{'H7'}=0;
    $variables{'H8'}=0;
    $variables{'H9'}=0;
    $variables{'appendix'}=-1;
    $variables{'author'}='';
    $variables{'back'}=0;
    $variables{'blockcnt'}=0;
    $variables{'cover'}='';
    $variables{'DEBUG'}=$DEBUG;
    $variables{'do_cover'}='no';
    $variables{'do_headers'}='yes';
    $variables{'imagex'}=800;
    $variables{'imagey'}=800;
    $variables{'inlineemp'}=0;
    $variables{'interpret'}=1;
	$variables{'mapnumber'}=1;
    $variables{'markdown'}=0;
    $variables{'notes'}=0;
    $variables{'parastartdelay'}='';
    $variables{'sidechar'}='*';
    $variables{'sidesep'}=';';
    $variables{'subtitle'}='';
    $variables{'title'}='';
    $variables{'videoheight'}='300';

my @input;
my @infile;

# Variables that are picked-up in sub-states and used when higher states close
my $caption='';
my $class='';
my $coord='';
my $file='';
my $format='';
my $image;
my $level=0;
my $name;
my $ref='';
my $seq='';
my $target='';
my $text='';			
my $type;
my $value='';
my $varname='';
my $video;
my $fontname;

my $fbold=0;
my $fitalic=0;

# Control variables
my $fileline=0;
my $inline=0;
my $lastline='';
my $currentline='';
my $listlevel=0;
my $noteatend=0;
my $progressindicator=0;
my $ptableopen=0;		# Paragraph table is open. This allows using the same table for different paragraphs
my $state;
my $xmlclose=0;
my @blocktext='';
my @leftnotes;
my @listblock;
my @listtype;
	push @listtype,'none';
my @mapfields;
my @sidenotes;
# ----------------------------Charmapping ---------------------------------------
my $charmapfile;
if ( -f "/usr/local/share/in3/in3charmap$variables{'interpret'}" ){
	$charmapfile="/usr/local/share/in3/in3charmap$variables{'interpret'}";
}
else {
	$charmapfile="in3charmap$variables{'interpret'}";
}

my @charmap;
if (-f "meta.in"){
	if (open(my $META, '<','meta.in')){
		while (<$META>){
			if (/^\.in3charmap *"(.*)","(.*)","(.*)"$/){
				push @charmap,"$1	$2	$3";
			}
		}
	}
}
if ( open (my $CHARMAP,'<',$charmapfile)){
	while (<$CHARMAP>){
		if (/^\#/){ #comment line
		}
		else {
			push @charmap,$_
		}
	}
	close $CHARMAP;
}
else { print STDERR "xml3html Cannot open in3charmap\n"; }

sub rofcharmapping {
	(my $instring)=@_;
	for (@charmap){
		chomp;
		my $char;
		my $groff;
		my $html;
		($char,$groff,$html)=split '	';
		$char='UNDEFINED_CHAR' unless defined $char;
			$groff=$char unless defined $groff;
		$html=$char unless defined $html;
		if ($instring=~/$char/){
			$instring=~s/$char/$groff/g;
		}
	}
	return $instring;
}


# ----------------------------debugging ---------------------------------------
sub debug {
	if ($variables{'DEBUG'}>0){
		for (@_){
			print STDERR "debug: $_\n";
		}
	}
}


sub error {
	for (@_){
		print STDERR "$_\n";
	}
}

# ----------------------------man page ---------------------------------------
sub hellup {
	print "
	NAME: xml3html
	SYNOPSYS:
	    xml3html [ options ] [files..]
	DESCRIPTION:
	xml3html creates html pages and parts from an in3xml file.

	OPTIONS:
	-d [value]
	--debug[value]   Produce debug--output
	-c nr
	--chapter nr     Use nr as the first chapter-number
    --doheaders      Do HTML headers (default)
	--noheaders      Supress HTML headers; create includable
	                 parts only
	--docover        Create cover sheets
	--nocover        Do not create cover sheets
	";
}

my $what='';
for (@ARGV){
	debug ("Argument parsing $_");
	if ($what eq ''){
		if (/^--$/){ while (<STDIN>){push @input,$_;}}
		elsif (/^-d([0-9]+)/){ $variables{'DEBUG'}=$1; }
		elsif (/^--debug([0-9]+)/){ $variables{'DEBUG'}=$1; }
		elsif (/^--debug=([0-9]+)/){ $variables{'DEBUG'}=$1; }
		elsif (/^-d$/){$what='debug';}
		elsif (/^--debug$/){$what='debug';}
		elsif (/^-c([0-9]+)/){ $variables{'H1'}=$1;$variables{'do_cover'}='no';}
		elsif (/^--chapter([0-9]+)/){ $variables{'H1'}=$1-1;$variables{'do_cover'}='no';}
		elsif (/^--chapter=([0-9]+)/){ $variables{"H1"}=$1-1;$variables{"do_cover"}='no';}
		elsif (/^-c$/){$what='chapter';$variables{"do_cover"}='no';}
		elsif (/^--chapter$/){$what='chapter';$variables{"do_cover"}='no';}
		elsif (/^--doheaders/){$variables{"do_headers"}='yes';}
		elsif (/^--do_headers/){$variables{"do_headers"}='yes';}
		elsif (/^--docover/){$variables{"do_cover"}='yes';}
		elsif (/^--do_cover/){$variables{"do_cover"}='yes';}
		elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^--interpret([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^--interpret=([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^-i$/){$what='interpret';}
		elsif (/^--interpret$/){$what='interpret';}
		elsif (/^-m/){$variables{"markdown"}=1;}
		elsif (/^--markdown/){$variables{"markdown"}=1;}
		elsif (/^--noheaders/){$variables{"do_headers"}='no';}
		elsif (/^--no-headers/){$variables{"do_headers"}='no';}
		elsif (/^--no_headers/){$variables{"do_headers"}='no';}
		elsif (/^--nocover/){$variables{"do_cover"}='no';}
		elsif (/^--no_cover/){$variables{"do_cover"}='no';}
		elsif (/^-+h/){ hellup(); }
		elsif (/^-p/){ $progressindicator=1;}
		elsif (/^-/){ print STDERR "$_ is not known as a flag; ignored.\n";}
		else {
			my $file=$_;
			my $ch;	# Chapter number from filename
			if ($file=~/^([0-9]+)_/){$ch=$1-1;} else {$ch=0;}
			if (open(my $IN,'<',$file)){
				$fileline=0;
				if ($ch>0){
					push @input,".set H1 $ch";
					$variables{"H1"}=$ch;
					push @infile,'INTERNAL';
				}
				while (<$IN>){
					push @input,$_;
					$fileline++;
					push @infile,"$file.$fileline";
				}
				close $IN;
			}
			else {print STDERR "Cannot open $_; ignored.\n";}
		}
	}
	elsif ($what eq 'debug'){
		if (/([0-9]+)/){ $variables{"H1"}=$1;}
		else {print STDERR "Can't find a numeric value for 'DEBUG' in $_; ignored the debug set.\n";}
		$what='';
	}
	elsif ($what eq 'chapter'){
		if (/([0-9]+)/){ $variables{"H1"}=$1-1;}
		else {print STDERR "Can't find a numeric value for chapter in $_; ignored the chapter set.\n";}
		$what='';
	}
	elsif ($what eq 'interpret'){
		if (/([0-9]+)/){ $variables{"interpret"}=$1;}
		else {print STDERR "Can't find a numeric value for interpretation in $_; ignored the interpretation set.\n";}
		$what='';
	}
	else { print STDERR "This should not be possible. (1)\n"; $what=''; }
}

if ($#input<0){
	debug ("No input lines");
	$fileline=0;
	while (<STDIN>){
		$fileline++;
		push @input,$_;
		push @infile,"STDIN.$fileline";
	}
}

#      _        _         _                   _
#  ___| |_ __ _| |_ ___  | | _____  ___ _ __ (_)_ __   __ _
# / __| __/ _` | __/ _ \ | |/ / _ \/ _ \ '_ \| | '_ \ / _` |
# \__ \ || (_| | ||  __/ |   <  __/  __/ |_) | | | | | (_| |
# |___/\__\__,_|\__\___| |_|\_\___|\___| .__/|_|_| |_|\__, |
#                                      |_|            |___/

my @states;
sub state_tos {
	return $states[$#states]
}
sub state_push {
	for (@_){
		push @states,$_;
	}
}
sub state_pop {
	my $retval=pop @states;
	return $retval;
}
state_push('outside');


my $linenumber=0;

for $linenumber (0 .. $#input){
	if ($input[$linenumber] =~/<side[note]*>/){ $variables{'notes'}=2;}
}

#
#   ___ ___  _ __ ___  _ __ ___   ___  _ __
#  / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \| '_ \
# | (_| (_) | | | | | | | | | | | (_) | | | |
#  \___\___/|_| |_| |_|_| |_| |_|\___/|_| |_|
#
#   __                            _
#  / _| ___  _ __ _ __ ___   __ _| |_ ___
# | |_ / _ \| '__| '_ ` _ \ / _` | __/ __|
# |  _| (_) | |  | | | | | | (_| | |_\__ \
# |_|  \___/|_|  |_| |_| |_|\__,_|\__|___/
#

sub formatrequest {
	(my $input)=@_;
	if ($input=~/=====*&gt;(.*)/){
		output ('<span style="visibility: hidden">');
		output ($lastline);
		output ('</span>');
		if ($currentline eq ''){
			$currentline="$lastline $1";
		}
		else {
			$currentline="$currentline $1";
		}
		$input=$1;
	}
	else {
		if ($input=~/^\(.*\)$/){}
		else {
			$currentline="$currentline $input";
		}
	}

	if ($input =~/<underline>/){
		output('<u>');
		state_push('underline');
	}
	elsif ($input =~/<italic>/){
		output('<i>');
		state_push('italic');
	}
	elsif ($input =~/<italicnospace>/){
		$outatol=1;
		output('<i>');
		$outatol=1;
		state_push('italicnospace');
	}
	elsif ($input =~/<bold>/){
		output('<b>');
		state_push('bold');
	}
	elsif ($input =~/<center>/){
		output('<div style="text-align: center;">');
		state_push('center');
	}
	elsif ($input =~/<lst>/){
		state_push('lst');
	}
	elsif ($input =~/<blank>/){
		state_push('blank');
	}
	elsif ($input =~/<space>/){
		state_push('space');
	}
	elsif ($input =~/<hr>/){
		state_push('hr');
	}
	elsif ($input =~/<font *type="*(.*)"*>/){
		$fontname=$1;
		my $fontfam;
		my $fontsize;
		if ($fontname=~/([A-Za-z]*)([0-9]*)/){
			$fontfam=$1;
			$fontsize=$2/10;
		}
		else {
			print STDERR "Cannot parse font name $fontname\n";
		}
		if ($fontfam=~/italic/){ $fitalic=1; $fontfam=~s/italic//;}
		if ($fontfam=~/bold/){ $fbold=1; $fontfam=~s/bold//;}
		for (@fontmap){
			(my $in3font,my $rofffont,my $webfont)=split '	';
			if ($fontfam eq $in3font){
				$fontfam=$webfont;
			}
		}

		if ($fontname=~/([A-Za-z]+)([0-9]+)/){
			output ("<span style=\"font-family:$fontfam; font-size:$fontsize"."em\">");
			if ($fbold>0){output ('<b>');}
			if ($fitalic>0){output ('<i>');}
		}
		elsif ($fontname=~/([A-Za-z]+)/){
			output ("<span style=\"font-family:$fontfam\">");
			if ($fbold>0){output ('<b>');}
			if ($fitalic>0){output ('<i>');}
		}
		elsif ($fontname=~/([0-9]+)/){
			if ($fitalic>0){output ('<i>');}
			if ($fbold>0){output ('<b>');}
			output ("<span style=\"font-size:$fontsize"."em\">");
		}
		state_push('font');
	}
	elsif ($input =~/<fixed>/){
		output('<tt>');
		state_push('fixed');
	}
	elsif ($input =~/<fixednospace>/){
		$outatol=1;
		output('<tt>');
		$outatol=1;
		state_push('fixednospace');
	}
	elsif ($input =~/<subscript>/){
		$outatol=1;
		output('<sub>');
		$outatol=1;
		state_push('subscript');
	}
	elsif ($input =~/<video>/){
		$video='';
		$file='';
		$text='';
		state_push('video');
	}
	elsif ($input =~/<image>/){
		$image='';
		$file='';
		$text='';
		$format='';
		state_push('image');
	}
	elsif ($input =~/<block>/){
		$type='pre';
		$image='';
		$class='';
		$caption='';
		undef@blocktext;
		state_push('block');
	}
	elsif ($input =~/<link>/){
		state_push('link');
	}
	elsif ($input =~/<break>/){
		state_push('break');
	}
	elsif ($input =~/<set>/){
		state_push('set');
	}
	else {
		output ($input);
	}

}

#  _
# (_)_ __ ___   __ _  __ _  ___  ___
# | | '_ ` _ \ / _` |/ _` |/ _ \/ __|
# | | | | | | | (_| | (_| |  __/\__ \
# |_|_| |_| |_|\__,_|\__, |\___||___/
#                    |___/

sub outimage {
	(my $img,my $flag)=@_;
	$flag=''  unless defined $flag;
	chomp $img;
	$img=~s/ *$//;
	my $baseimg=basename($img);
	my $blockimg="block/$baseimg";
	if ($blockimg=~/(.*)\.png/){}
	elsif ($blockimg=~/(.*)\.svg/){}
	else {
		$blockimg=~s/\.[^\.]*$/.png/;
	}
	system ("in3fileconv $img $blockimg");
	my $imgsize=` imageinfo --geom $blockimg`;
	chomp $imgsize;
	my $scale=100; #percent
	my $x; my $y;
	($x, $y)=split ('x',$imgsize);
	if ($x>$variables{'imagex'}){
		if ($scale > (100*$variables{'imagex'})/$x){ $scale=(100*$variables{'imagex'})/$x;}
	}
	if ($y>$variables{'imagey'}){
		if ($scale > (100*$variables{'imagey'})/$x){ $scale=(100*$variables{'imagey'})/$y;}
	}
	my $align='';
	#if ($inline>0){$scale=24;}
	my $width=($x*$scale)/175;
	my $height=($y*$scale)/175;
	if ($format =~/inttwice/){ $width=$width*2; $height=$height*2; }
	if ($format =~/inttrice/){ $width=$width*2; $height=$height*3; }
	my $align=$y*2;
	if ($inline>0){
		$width=$width*1.1;
		output ("<img src=\"$blockimg\" alt=\"$img\" width=\"$width\" style=\"vertical-align:-$align%;\">");
	}
	elsif ($format=~/left/){
		if ($format=~/quart/){
			$width=$width/2;
			output ('<div style="text-align: center; width:25%;float:left;">');
			output ("<img src=\"$blockimg\" alt=\"$img\" style=\"vertical-align: middle;\">");
			if ( $caption ne '' ) {
				output ("<br><i>$caption</i>");
			}
			output ('</div>');
		}
		elsif ($format=~/half/){
			$width=$width/2;
			output ('<div style="text-align: center;width:50%;float:left;">');
			output ("<img src=\"$blockimg\" alt=\"$img\" style=\"vertical-align: middle;\">");
			if ( $caption ne '' ) {
				output ("<br><i>$caption</i>");
			}
			output ('</div>');
		}
		else {
			if ($width> 500){$width=$width/1.2;}
			output ('<div style="text-align: center;float:left;">');
			output ("<img src=\"$blockimg\" alt=\"$img\" width=$width  style=\"vertical-align: middle;\">");
			if ( $caption ne '' ) {
				output ("<br><i>$caption</i>");
			}
			output ('</div>');
		}

	}
	elsif ($format=~/right/){
		if ($format=~/quart/){
			$width=$width/2;
			output ('<div style="text-align: center; width:25%;float:right;">');
			output ("<img src=\"$blockimg\" alt=\"$img\" style=\"vertical-align: middle;\">");

			if ( $caption ne '' ) {
				output ("<br><i>$caption</i>");
			}
			output ('</div>');
		}
		elsif ($format=~/half/){
			$width=$width/2;
			output ('<div style="text-align: center;width:50%;float:right;">');
			output ("<img src=\"$blockimg\" alt=\"$img\" style=\"vertical-align: middle;\">");
			if ( $caption ne '' ) {
				output ("<br><i>$caption</i>");
			}
			output ('</div>');
		}
		else {
			if ($width> 500){$width=$width/1.2;}
			output ('<div style="text-align: center;float:right;">');
			output ("<img src=\"$blockimg\" alt=\"$img\" width=$width  style=\"vertical-align: middle;\">");
			if ( $caption ne '' ) {
				output ("<br><i>$caption</i>");
			}
			output ('</div>');
		}
	}
	elsif ($format=~/full/){
		output ('<div style="text-align: center">');
		if ($flag=~/nowidth/){
			output ("<img src=\"$blockimg\" alt=\"$img\" >");
		}
		else {
			output ("<img src=\"$blockimg\" alt=\"$img\" width=$width >");
		}
		if ( $caption ne '' ) {
			output ("<br><i>$caption</i>");
		}
		output ('</div>');
	}
	elsif ($format=~/quart/){
		$width=$width/2;
		output ('<div style="text-align: center">');
		output ("<img src=\"$blockimg\" alt=\"$img\" width=25% >");
		if ( $caption ne '' ) {
			output ("<br><i>$caption</i>");
		}
		output ('</div>');
	}
	elsif ($format=~/half/){
		$width=$width/2;
		output ('<div style="text-align: center">');
		output ("<img src=\"$blockimg\" alt=\"$img\" width=50% >");
		if ( $caption ne '' ) {
			output ("<br><i>$caption</i>");
		}
		output ('</div>');
	}
	else {
		if ($width> 500){$width=$width/1.2;}
		output ('<div style="text-align: center">');
		if ($flag=~/nowidth/){
			output ("<img src=\"$blockimg\" alt=\"$img\" >");
		}
		else {
			output ("<img src=\"$blockimg\" alt=\"$img\" width=$width >");
		}
		if ( $caption ne '' ) {
			output ("<br><i>$caption</i>");
		}
		output ('</div>');
	}
	progress();

}

#                  _         _
#  _ __ ___   __ _(_)_ __   | | ___   ___  _ __
# | '_ ` _ \ / _` | | '_ \  | |/ _ \ / _ \| '_ \
# | | | | | | (_| | | | | | | | (_) | (_) | |_) |
# |_| |_| |_|\__,_|_|_| |_| |_|\___/ \___/| .__/
#                                         |_|

$linenumber=0;
while ( $linenumber <= $#input){
	chomp $input[$linenumber];
	$input[$linenumber]=~s/^[ 	]*//;
	$state=state_tos();
	debug ("$state $linenumber | $input[$linenumber]");
	if ($trace>0){printf STDERR "# %10.10s - %8.8d : %s\n",($state,$linenumber,$input[$linenumber]);}
	if ($input[$linenumber] =~/<!--.*-->/){}

	elsif ($state  eq 'outside'){
		if ($input[$linenumber] =~/<in3xml>/){
			$xmlclose=$linenumber;
			while (!($input[$xmlclose]=~/<\/in3xml>/) && ($xmlclose<$#input)){
				$xmlclose++;
			}
			state_push('in3xml');
		}
	}
	elsif ($state  eq 'in3xml'){
		if ($input[$linenumber] =~/<\/in3xml>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<title>/){
			state_push('title');
		}
		elsif ($input[$linenumber] =~/<subtitle>/){
			state_push('subtitle');
		}
		elsif ($input[$linenumber] =~/<page>/){
			state_push('page');
		}
		elsif ($input[$linenumber] =~/<author>/){
			state_push('author');
		}
		elsif ($input[$linenumber] =~/<video>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			state_push('video');
		}
		elsif ($input[$linenumber] =~/<map>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			$file='';
			undef @mapfields;
			state_push('map');
		}
		elsif ($input[$linenumber] =~/<image>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			$text='';
			$file='';
			$format='';
			$image='';
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<cover>/){
			state_push('cover');
		}
		elsif ($input[$linenumber] =~/<headerlink>/){
			state_push('headerlink');
		}
		elsif ($input[$linenumber] =~/<set>/){
			state_push('set');
		}
		elsif ($input[$linenumber] =~/<toc>/){
			state_push('toc');
		}
		elsif ($input[$linenumber] =~/<heading>/){
			$variables{'notes'}=$variables{'notes'}&2;
			if ($ptableopen>0){ output ('</table>'); $ptableopen=0; }
			state_push('heading');
		}
		elsif ($input[$linenumber] =~/<table>/){
			$inline=1;
			$variables{'notes'}=$variables{'notes'}&2;
			if ($ptableopen>0){ output ('</table>'); $ptableopen=0; }
			output ('<table border class=table>');
			output ('<tbody>');
			state_push('table');
		}
		elsif ($input[$linenumber] =~/<([acdhlmnopstu]*)list>/){
			$type='';
			if ($1 ne ''){
				$type=$1;
			}
			$listlevel=1; # Should always have been 0 because we're in state in3xml.
			undef @listtype;
			$listtype[0]='none';
			$variables{'notes'}=$variables{'notes'}&2;
			if ($ptableopen>0){ output ('</table>'); $ptableopen=0; }
			# find the type at this level
			my $typelevel=$listlevel;
			my $i=$linenumber+1;
			my $intype=0;
			$listtype[$listlevel]='none';
			if ($type ne ''){ $listtype[1]=$type; }
			while (($listtype[$listlevel] eq 'none') && ($i<=$#input) && ($typelevel>=$listlevel)){
				chomp $input[$i];
				if ($input[$i]=~/<([acdhlmnopstu]*)list>/){
					$listlevel++;
				}
				elsif ($input[$i]=~/<\/[acdhlmnopstu]*list>/){
					$listlevel--;
				}
				elsif($input[$i]=~/<type>/){
					$intype=1;
				}
				elsif($input[$i]=~/<\/type>/){
					$intype=0;
				}
				elsif ($intype>0){
					if ($input[$i]=~/(dash|dot|alpha|num|roman)/){
						$listtype[$listlevel]=$input[$i];
						chomp $listtype[$listlevel];
						$listtype[$listlevel]=~s/"//g;
					}
				}
				$i++;
			} 
			if ($listtype[$listlevel] eq 'dash'){ output ('<ul>');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('<ol type=1>');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('<ol type=a>');}
			elsif ($listtype[$listlevel] eq 'none'){ output ('<EMPTY>');}
			$inline=1;
			state_push('list');
		}
		elsif ($input[$linenumber] =~/<include>/){
			state_push('include');
		}
		elsif ($input[$linenumber] =~/<lst>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			output ('<br>');
			state_push('lst');
		}
		elsif ($input[$linenumber] =~/<paragraph>/){
			if ($currentline ne ''){$lastline=$currentline;}
			$currentline='';
			my @paratext;
			undef @sidenotes;
			undef @leftnotes;
			undef @paratext;
			my $inside=0;
			my $inleft=0;
			my $intext=0;
			$inline=1;
			my $prevnotes=$variables{'notes'};
			my $endpara=$linenumber;
			# Collect all side notes
			if ($variables{'back'}>0){
				if ($ptableopen>0){ output('</table>');$ptableopen=0;}
				$variables{'back'}=0;
				$variables{'notes'}=$variables{'notes'}&2;
			}
			while (($endpara<=$#input) && !($input[$endpara] =~/<\/paragraph>/)){
				if ($intext>0){
					if ($input[$endpara] =~/<\/text>/){
						$intext=0;
					}
					else {
						push @paratext,$input[$endpara];
					}
				}
				if ($inside>0){
					if ($input[$endpara] =~/<\/side[note]*>/){
						$inside=0;
					}
					else {
						chomp $input[$endpara];
						$input[$endpara]=~s/_/ /;
						push @sidenotes,$input[$endpara];
					}
				}
				elsif ($inleft>0){
					if ($input[$endpara] =~/<\/leftnote>/){
						$inleft=0;
					}
					else {
						push @leftnotes,$input[$endpara];
					}
				}
				elsif ($input[$endpara] =~/<leftnote>/){
					$variables{'notes'}=$variables{'notes'}|1;
					$inleft=1;
				}
				elsif ($input[$endpara] =~/<side[note]*>/){
					$variables{'notes'}=$variables{'notes'}|2;
					$inside=1;
				}
				elsif ($input[$endpara] =~/<text>/){
					$intext=1;
				}
				$endpara++;
			}
			if ($prevnotes != $variables{'notes'}){
				if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			}
			output ("<!-- paragraph type $variables{'notes'} -->");
			if ($variables{'notes'}==0){
				output ('<p class="paragraph">');
				if ( $variables{'parastartdelay'} ne ''){
					output ($variables{'parastartdelay'});
					$variables{'parastartdelay'}='';
				}
			}
			elsif ($ptableopen==0){
				output('<table class=paragraph>');
				$ptableopen=1;
			}
			if ($variables{'notes'}>0){
				output ('<tr>');
			}
			if (($variables{'notes'}&1)>0){
				output ('<td class=leftnote>');
				for (@leftnotes){ output ($_);}
				output ('</td>');
				undef @leftnotes;
			}
			if ($variables{'notes'}>0){
				output ('<td class=paragraph>');
				if ( $variables{'parastartdelay'} ne ''){
					output ($variables{'parastartdelay'});
					$variables{'parastartdelay'}='';
				}
			}
			state_push('paragraph');
		}
		elsif ($input[$linenumber] =~/<block>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			$type='pre';
			$image='';
			$class='';
			undef@blocktext;
			state_push('block');
		}
		elsif ($input[$linenumber] =~/<header>/){
			state_push('headerfile');
		}
		elsif ($input[$linenumber] =~/<blank>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			state_push('blank');
		}
		elsif ($input[$linenumber] =~/<space>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			state_push('space');
		}
		elsif ($input[$linenumber] =~/<hr>/){
			if ($ptableopen>0){ output('</table>');$ptableopen=0;}
			state_push('hr');
		}
		elsif($input[$linenumber] =~/^$/){}
		else {
			error ("in3xml: Plain text outside constructs in $linenumber: $input[$linenumber]");
		}
	}
	elsif ($state  eq 'list'){
		if ($input[$linenumber] =~/<\/[dashnumotlpr]*list>/){
			if ($listtype[$listlevel] eq 'dash'){ output ('</ul>');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('</ol>');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('</ol>');}
			elsif ($listtype[$listlevel] eq 'none'){ output ('<EMPTY>');}
			$listlevel--;
			if ($listlevel==0){ $inline=0;}
			state_pop;
		}
		elsif($input[$linenumber] =~/<list>/){
			$listlevel++;
			my $typelevel=$listlevel;
			my $i=$linenumber+1;
			my $intype=0;
			$listtype[$listlevel]='none';
			while (($listtype[$listlevel] eq 'none') && ($i<=$#input) && ($typelevel>=$listlevel)){
				if ($input[$i]=~/<[acdhlmnopritu]*list>/){
					$typelevel++;
				}
				elsif ($input[$i]=~/<\/[acdhlmnopritu]*list>/){
					$typelevel--;
				}
				elsif ($input[$i]=~/<type>/){
					$intype=1;
				}
				elsif ($input[$i]=~/<\/type>/){
					$intype=0;
				}
				elsif ($intype>0){
					if ($typelevel==$listlevel){
						chomp $input[$i];
						$listtype[$listlevel]=$input[$i];
						$listtype[$listlevel]=~s/"//g;
						debug("List-type assignment: listtype[$listlevel]=$input[$i]");
					}
				}
				$i++;
			}
			if ($listtype[$listlevel] eq 'dash'){ output ('<ul>');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('<ol type=1>');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('<ol type=a>');}
			elsif ($listtype[$listlevel] eq 'none'){ output ('<EMPTY>');}
			state_push('list');
		}
		elsif($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif($input[$linenumber] =~/<item>/){
			output ('<li>');
			output ('<div class=list>');
			$inline=1;
			state_push('item');
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'item'){
		$inline=1;
		if ($input[$linenumber] =~/<\/item>/){
			output ('</div>');
			output ('</li>');
			state_pop;
		}
		else {
			$inline=1;
			formatrequest($input[$linenumber]);
		}
	}
	elsif ($state  eq 'block'){
		if ($input[$linenumber] =~/<\/block>/){
			for (@blocktext){
				s/&lt;/</g;
				s/&gt;/>/g;
				s/&quot;/"/g;
				s/&apos;/'/g;
				s/&amp;/&/g;
				s/&#0092;/\\/g;
			}
			if ($type eq 'pre'){
				if ($ptableopen>0){ output('</table>');$ptableopen=0;}
				output ('<pre>');
				for (@blocktext){
					s/&/&amp;/g;
					s/ /&nbsp;/g;
					s/^"//;
					s/"$//;
					s/</&lt;/g;
					s/>/&gt;/g;
					s/&#0092;/\\/g;
					output($_);
				}
				output ('</pre>');
			}
			elsif ($type eq 'lst'){
				if ($ptableopen>0){ output('</table>');$ptableopen=0;}
				for (@blocktext){
					s/&/&amp;/g;
					s/ /&nbsp;/g;
					s/	/&nbsp;&nbsp;&nbsp;&nbsp;/g;
					s/^"//;
					s/"$//;
					s/</&lt;/g;
					s/>/&gt;/g;
					s/&#0092;/\\/g;
					output("<br><span class=\"lst\">&nbsp;$_</span>");
				}
			}
			elsif ($type=~/^class(.*)/){
				$class=$1;
				output ('<br>');
				output ("<div class=\"$class\">");
				for (@blocktext){
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('<br>');
				output ('</div>');
			}
			elsif ($type=~/piechart(.*)/){
				my $mscale=100;
				$mscale=$mscale;   # CHECK  for inline scale!
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open my $PLOT, '>',"$blk.piechart"){
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
							s/&#0092;/\\/g;
						}
						s/	/,/g;
						print $PLOT "$_\n";
					}
					close $PLOT;
					progress();
					system(" piechart $blk.piechart --order value,explode,color,legend > $blk.svg");
					if ($inline==0){
						output ('<div style="text-align: center">');
					}
					#output("<img src=\"$blk.svg\"  width=\"$x\">");
					outimage ("$blk.svg");
					if ($inline==0){
						output ('</div>');
					}
				}
				else {
					error ("Cannot open $blk.piechart"); 
				}
			}
			elsif ($type=~/gnuplot(.*)/){
				my $mscale=100;
				#if ($format=~/scale=([0-9]+)/){
				#	$mscale=$1;
				#	$format=~s/scale=[0-9]+//;
				#}
				$mscale=$mscale;   # CHECK  for inline scale!
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open my $PLOT, '>',"$blk.gnuplot"){
					print $PLOT "set terminal svg size $x,$y enhanced font \"Helvetica,16\"\n";
					print $PLOT "set output '$blk.svg'\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
							s/&#0092;/\\/g;
						}
						print $PLOT "$_\n";
					}
					close $PLOT;
					progress();
					system("gnuplot $blk.gnuplot >/dev/null 2>/dev/null");
					#system ("eps2eps -B1  $blk.ps $blk.eps");
					if ($inline==0){
						output ('<div style="text-align: center">');
					}
					#output("<img src=\"$blk.svg\"  width=\"$x\">");
					outimage ("$blk.svg");
					
					if ($inline==0){
						output ('</div>');
					}
				}
				else {
					error ("Cannot open $blk.gnuplot"); 
				}
			}
			elsif ($type=~/texeqn/){
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $TEXEQN,'>',"$blk.tex")){
					print $TEXEQN "\\documentclass{article}\n";
					print $TEXEQN "\\usepackage{amsmath}\n";
					print $TEXEQN "\\usepackage{amssymb}\n";
					print $TEXEQN "\\usepackage{algorithm2e}\n";
					print $TEXEQN "\\begin{document}\n";
					print $TEXEQN "\\begin{titlepage}\n";
					print $TEXEQN "\\begin{equation*}\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
							s/&#0092;/\\/g;
						}
						print $TEXEQN "$_\n";
					}
					print $TEXEQN "\\end{equation*}\n";
					print $TEXEQN "\\end{titlepage}\n";
					print $TEXEQN "\\end{document}\n";
					close $TEXEQN;
					progress();
            		system("cd block; echo '' | latex ../$blk.tex > /dev/null 2>/dev/null");
					#system("convert  -trim  -density $density  $blk.dvi  $blk.png");
            		system("in3fileconv $blk.dvi $blk.svg >/dev/null 2>/dev/null");
					my $imgsize=` imageinfo --geom $blk.svg`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/1300;
					my $ysize=$yn.'em';
					$yn=$yn/8;
					my $yalign=$yn.'em';
					if ($inline==0){
						output ('<div style="text-align: center">');
					}
					#output("<img src=\"$blk.svg\" alt=\"$blk\" style=\"height:$ysize;vertical-align:-$yalign;\">");
					outimage ("$blk.svg","nowidth");
					if ($inline==0){
						output ('</div>');
					}
				}
				else {
					print STDERR "in3html cannot open $blk\n";
				}
			}
			elsif ($type=~/eqn/){	# must be after the texeqn obviously
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				$format="inttrice$format";
				if (open (my $EQN,'>',"$blk.eqn")){
					print $EQN ".EQ\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
							s/&#0092;/\\/g;
						}
						my $prt=rofcharmapping($_);
						print $EQN "$prt\n";
					}
					print $EQN ".EN\n";
					close $EQN;
					progress();
					system ("in3fileconv $blk.eqn $blk.svg >/dev/null 2>/dev/null");
					my $imgsize=` imageinfo --geom $blk.svg`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/2000;
					my $ysize=$yn.'em';
					$yn=$yn/8;
					my $yalign=$yn.'em';
					if ($inline==0){
						output ('<div style="text-align: center">');
					}
					#output("<img src=\"$blk.svg\" alt=\"$blk\" style=\"height:$ysize;vertical-align:-$yalign;\">");
					outimage ("$blk.svg");
					if ($inline==0){
						output ('</div>');
					}
				}
				else { error ("Cannot open $blk.eqn");}
			}
			elsif ($type=~/pic/){
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $PIC,'>',"$blk.pic")){
					print $PIC ".PS\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
							s/&#0092;/\\/g;
						}
						my $prt=rofcharmapping($_);
						print $PIC "$prt\n";
					}
					print $PIC ".PE\n";
					close $PIC;
					progress();
					system ("pic $blk.pic > $blk.groff 2> /dev/null");
					system ("groff $blk.groff > $blk.ps 2> /dev/null");
					system ("ps2pdf $blk.ps  $blk.pdf 2> /dev/null");
					system ("convert -trim -density $density $blk.pdf  $blk.png >/dev/null 2> /dev/null");
					my $imgsize=` imageinfo --geom $blk.png`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/10000;
					if ($inline>0){$yn=$yn/3;}
					my $ysize=$yn.'em';
					if ($inline==0){
						output ('<div style="text-align: center">');
					}
					#output("<img src=\"$blk.png\" alt=\"$blk\" style=\"height:$ysize;\">");
					outimage ("$blk.png");
					if ($inline==0){
						output ('</div>');
					}
				}
				else { error ("Cannot open $blk.pic");}
			}
			elsif ($type=~/music/){
				my $mscale=100;
				my $blk="block/$name";
				my $density=1000;
				my $x=800*$mscale/100;
				my $y=600*$mscale/100;
				if (open (my $MUSIC,'>',"$blk.music")){
					print $MUSIC "\\version \"2.18.2\"\n";
					#print $MUSIC "\\book {\n";
					print $MUSIC "\\paper {\n";
					print $MUSIC "indent = 0\\mm\n";
					print $MUSIC "line-width = 110\\mm\n";
					print $MUSIC "oddHeaderMarkup = \"\"\n";
					print $MUSIC "evenHeaderMarkup = \"\"\n";
					print $MUSIC "oddFooterMarkup = \"\"\n";
					print $MUSIC "evenFooterMarkup = \"\"\n";
					print $MUSIC "}\n";
					print $MUSIC "\\header {\n";
					print $MUSIC "tagline = \"\"\n";
					print $MUSIC "}\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
							s/&#0092;/\\/g;
						}
						print $MUSIC "$_\n";
					}
					#print $MUSIC "}\n";
					close $MUSIC;
					progress();
					system ("cd block; lilypond --png  -dresolution=500  ../$blk.music 2>/dev/null" );
					system ("mv $blk.png $blk.fs.png");
					system ("convert -trim $blk.fs.png $blk.png >/dev/null 2>/dev/null");

					my $imgsize=` imageinfo --geom $blk.png`;
					my $x; my $y; my $yn;
					($x,$y)=split ('x',$imgsize);
					$yn=$y*$mscale/10000;
					my $ysize=$yn.'em';

					if ($inline==0){
						output ('<div style="text-align: center">');
					}
					#output("<img src=\"$blk.png\" alt=\"$blk\" style=\"height:$ysize;\">");
					outimage ("$blk.png");

					if ($inline==0){
						output ('</div>');
					}
				}
				else { error ("Cannot open $blk.pic");}
			}
			else {
				if ($image ne '' ){
					outimage($image);
					$image='';
				}
				else { error ("Block type $type without image"); }
			}
			$class='';
			$type='';
			$image='';
			undef @blocktext;
			state_pop();
		} #end state block: end of block
		elsif ($input[$linenumber] =~/<caption>/){
			state_push('caption');
		}
		elsif ($input[$linenumber] =~/<name>/){
			state_push('name');
		}
		elsif ($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif ($input[$linenumber] =~/<image>/){
			$text='';
			$file='';
			$format='';
			$image='';
			$caption='';
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<blocktext>/){
			state_push('blocktext');
		}
		elsif ($input[$linenumber] =~/<format>/){
			state_push('format');
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('blocktext');
		}
	} #end state block
	elsif ($state  eq 'cell'){
		$inline=1;
		if ($input[$linenumber] =~/<\/cell>/){
			$inline=0;
			output ('</div>');
			output ('</td>');
			state_pop();
		}
		else {
			formatrequest($input[$linenumber]);
		}
	}
	elsif ($state  eq 'row'){
		if ($input[$linenumber] =~/<\/row>/){
			output ('</tr>');
			state_pop();
		}
		elsif ($input[$linenumber] =~/<cell/){
			my $rs=0;
			my $cs=0;
			my $tdstr='<td';
			my $fmt="class=cell";
			if ($input[$linenumber] =~/cs="*([0-9]+)/){$cs=$1;}
			if ($input[$linenumber] =~/colspan="*([0-9]+)/){$cs=$1;}
			if ($input[$linenumber] =~/rs="*([0-9]+)/){$rs=$1;}
			if ($input[$linenumber] =~/rowspan="*([0-9]+)/){$rs=$1;}
			if ($input[$linenumber] =~/format="([a-z]+)"/){
				if ($1 eq 'center'){ $fmt='style="text-align:center;"';}
				elsif ($1 eq 'left'){ $fmt='style="text-align:left;"';}
				elsif ($1 eq 'right'){ $fmt='style="text-align:right;"';}
				elsif ($1 eq 'num'){ $fmt='style="text-align:right;"';}
			}
			if ($rs>0){ $tdstr="$tdstr rowspan=\"$rs\"";}
			if ($cs>0){ $tdstr="$tdstr colspan=\"$cs\"";}
			$tdstr="$tdstr class=table>";
			output ($tdstr);
			output ("<div $fmt>");
			state_push('cell');
		}
		else { error ("Table row: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'table'){
		if ($input[$linenumber] =~/<\/table>/){
			output ('</tbody>');
			output ('</table>');
			state_pop();
		}
		elsif ($input[$linenumber] =~/<row>/){
			output ('<tr>');
			state_push('row');
		}
		else { error ("Table: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'paragraph'){
		if ($input[$linenumber] =~/<\/paragraph>/){
			$inline=0;
			if ($variables{'notes'}==0){
				output ('</p>');
			}
			else{
				output ('</td>');
				if (($variables{'notes'}&2)>0){
					output ('<td class=sidenote>');
					for (@sidenotes){ output ($_); }
					output ('</td>');
				}
				output ('</tr>');
			}
			state_pop();
		}
		elsif($input[$linenumber] =~/<leftnote>/){
			state_push('leftnote');
		}
		elsif ($input[$linenumber] =~/<side[note]*>/){
			state_push('side');
		}
		elsif ($input[$linenumber] =~/<note>/){
			state_push('note');
		}
		elsif ($input[$linenumber] =~/<text>/){}	#Text-markers are currently ignored. 
		elsif ($input[$linenumber] =~/<\/text>/){}
		else {
			formatrequest($input[$linenumber]);
		}
	}
	elsif ($state  eq 'italicnospace'){
		if ($input[$linenumber] =~/<\/italicnospace>/){
			$outatol=1;
			output ('</i>');
			state_pop();
			$outatol=1;
		}
		else {
			$outatol=1;
			output ($input[$linenumber]);
			$outatol=1;
		}
	}
	elsif ($state  eq 'italic'){
		if ($input[$linenumber] =~/<\/italic>/){
			output ('</i>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'bold'){
		if ($input[$linenumber] =~/<\/bold>/){
			output ('</b>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'center'){
		if ($input[$linenumber] =~/<\/center>/){
			output ('</div>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'subscript'){
		if ($input[$linenumber] =~/<\/subscript>/){
			$outatol=1;
			output ('</sub>');
			$outatol=1;
			state_pop();
		}
		else {
			$outatol=1;
			output ($input[$linenumber]);
			$outatol=1;
		}
	}
	elsif ($state  eq 'font'){
		if ($input[$linenumber] =~/<\/font>/){
			if ($fitalic>0){output ('</i>');}
			if ($fbold>0){output ('</b>');}
			$fitalic=0;
			$fbold=0;
			output ('</span>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'fixednospace'){
		if ($input[$linenumber] =~/<\/fixednospace>/){
			$outatol=1;
			output ('</tt>');
			$outatol=1;
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'fixed'){
		if ($input[$linenumber] =~/<\/fixed>/){
			output ('</tt>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'underline'){
		if ($input[$linenumber] =~/<\/underline>/){
			output ('</u>');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'lst'){
		if ($input[$linenumber] =~/<\/lst>/){
			state_pop();
		}
		else {
			$input[$linenumber] =~s/ /&nbsp;/g;
			$input[$linenumber] =~s/	/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$input[$linenumber] =~s/^"//g;
			$input[$linenumber] =~s/"$//g;
			output ('<span class="fixed">',$input[$linenumber],'</span>');
		}
	}
	elsif ($state  eq 'side'){
		if ($input[$linenumber] =~/<\/side[note]*>/){
			state_pop();
		}
	}
	elsif ($state  eq 'leftnote'){
		if ($input[$linenumber] =~/<\/leftnote>/){
			state_pop();
		}
	}
	elsif ($state  eq 'heading'){
		if ($input[$linenumber] =~/<\/heading>/){
			if ($level==0){$level=1;}
			if ($seq ne ''){
				output ("<h$level id=\"a$seq\">");
				output($seq);
			}
			else {
				output ("<h$level>");
			}
			if ($text ne ''){ output($text);}
			output ("</h$level>");
			$level=0;
			$seq='';
			$text='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<level>/){
			state_push('level');
		}
		elsif ($input[$linenumber] =~/<seq>/){
			state_push('seq');
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('text');
		}
		else {
			error ("heading Header accepts level, seq, or text: $input[$linenumber]");
		}
	}
	elsif ($state  eq 'notetext'){
		if ($input[$linenumber] =~/<\/notetext>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<\/text>/){
			state_pop();
		}
		else {
			if ($noteatend==0){
				$noteatend=1;
				splice @input,$xmlclose,1,'<hr>',@input[$xmlclose];$xmlclose++;
				splice @input,$xmlclose,1,'</hr>',@input[$xmlclose];$xmlclose++;
				splice @input,$xmlclose,1,'<paragraph>',@input[$xmlclose];$xmlclose++;
				splice @input,$xmlclose,1,'<text>',@input[$xmlclose];$xmlclose++;
				splice @input,$xmlclose,1,'</text>',@input[$xmlclose];$xmlclose++;
				splice @input,$xmlclose,1,'</paragraph>',@input[$xmlclose];$xmlclose++;
			}
			if ($ref ne ''){
				splice @input,$xmlclose-2,1,$ref,@input[$xmlclose-2];$xmlclose++;
			}
			splice @input,$xmlclose-2,1,$input[$linenumber],@input[$xmlclose-2];$xmlclose++;
		}
	}
	elsif ($state  eq 'blocktext'){
		if ($input[$linenumber] =~/<\/blocktext>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<\/text>/){
			state_pop();
		}
		else {
			push @blocktext,$input[$linenumber];
		}
	}
	elsif ($state  eq 'video'){
		if ($input[$linenumber] =~/<\/video>/){
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				my $basefile=basename($file);
				system ("cp $file web/$basefile");
				my $size=`ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $file`;
				(my $x,my $y)=split('x',$size);
				my $videoheight=$variables{'videoheight'};
				my $videowidth=$variables{'videoheight'}*$x/$y;
				if ($inline==0){
					output ('<br>');
					output("<div style=\"text-align: center;\">");
				}
				else {
					$videoheight=$videoheight/4;
					$videowidth=$videowidth/4;
				}
				output ("<video controls height=\"$videoheight"."px\" width=\"$videowidth"."px\">","<source src=\"$basefile\">",$text,"</video>");
				if ($inline==0){
					output ('<br>');
					output ('</div>');
				}
				$text='';
				$file='';
			}
			state_pop();
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<file>/){
			state_push('file');
		}
		else {
			error ("Video: text out of block");
		}
	}
	elsif ($state  eq 'note'){
		if ($input[$linenumber] =~/<\/note>/){
			state_pop();
		}
		elsif($input[$linenumber] =~/<ref>/){
			state_push('ref');
		}
		elsif($input[$linenumber] =~/<seq>/){
			state_push('seq');
		}
		elsif($input[$linenumber] =~/<notetext>/){
			state_push('notetext');
		}
		else {
			error ("Note text out of scope: $input[$linenumber]");
		}

	}
	elsif ($state  eq 'map'){
		if ($input[$linenumber] =~/<\/map>/){
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				my $basefile=basename($file);
				if ($inline==0){
					output ('<div style="text-align: center">');
				}
				output ("<img src=\"block/$basefile\" alt=\"$file\" usemap=#map$variables{'mapnumber'}>");
				output ("<map name=map$variables{'mapnumber'}>");
				for (@mapfields){ output ($_);}
				output ('</map>');
				if ($inline==0){
					output ('</div>');
				}
				system("in3fileconv $file block/$basefile");
				$text='';
				$file='';
				$image='';
			}
			state_pop();
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<field>/){
			state_push('field');
		}
		elsif ($input[$linenumber]=~/<file>/){
			state_push('file');
		}
		else {
			$image=$input[$linenumber];
		}
	}
	elsif ($state  eq 'image'){
		if ($input[$linenumber] =~/<\/image>/){
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				outimage($file);
				$text='';
				$file='';
				$format='';
				$image='';
				$caption='';
			}
			state_pop();
		}
		elsif ($input[$linenumber]=~/<caption>/){
			state_push('caption');
		}
		elsif ($input[$linenumber]=~/<format>/){
			state_push('format');
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<file>/){
			state_push('file');
		}
		else {
			$image=$input[$linenumber];
		}
	}
	elsif ($state  eq 'caption'){
		if ($input[$linenumber] =~/<\/caption>/){
			state_pop();
		}
		else {
			$caption=$input[$linenumber];
			$caption=~s/^"//;
			$caption=~s/"$//;
		}
	}
	elsif ($state  eq 'name'){
		if ($input[$linenumber] =~/<\/name>/){
			state_pop();
		}
		else {
			$name=$input[$linenumber];
			$name=~s/^"//;
			$name=~s/"$//;
		}
	}
	elsif ($state  eq 'type'){
		if ($input[$linenumber] =~/<\/type>/){
			state_pop();
		}
		else {
			$type=$input[$linenumber];
			$type=~s/^"//;
			$type=~s/"$//;
		}
	}
	elsif ($state  eq 'field'){
		if ($input[$linenumber] =~/<\/field>/){
			if (($coord ne '') && ($target ne '')){
				push @mapfields,"<area shape=\"rect\" coords=\"$coord\" href=\"$target\">";
			}
			$coord='';
			$target='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<coord>/){
			state_push('coord');
		}
		elsif ($input[$linenumber] =~/<target>/){
			state_push('target');
		}
		elsif ($input[$linenumber] =~/<file>/){
			state_push('file');
		}
		else { error("Undefined field in field $input[$linenumber]");}
	}
	elsif ($state  eq 'coord'){
		if ($input[$linenumber] =~/<\/coord>/){
			state_pop();
		}
		else {
			$coord=$input[$linenumber];
		}
	}
	elsif ($state  eq 'target'){
		if ($input[$linenumber] =~/<\/target>/){
			state_pop();
		}
		else {
			$target=$input[$linenumber];
			$target=~s/^"//;
			$target=~s/"$//;

		}
	}
	elsif ($state  eq 'text'){
		if ($input[$linenumber] =~/<\/text>/){
			$text=~s/^"//;
			$text=~s/"$//;
			state_pop();
		}
		else {
			$text=$input[$linenumber];
		}
	}
	elsif ($state  eq 'ref'){
		if ($input[$linenumber] =~/<\/ref>/){
			state_pop();
		}
		else {
			$ref=$input[$linenumber];
		}
	}
	elsif ($state  eq 'seq'){
		if ($input[$linenumber] =~/<\/seq>/){
			$seq=~s/^"//;
			$seq=~s/"$//;
			state_pop();
		}
		else {
			$seq=$input[$linenumber];
		}
	}
	elsif ($state  eq 'level'){
		if ($input[$linenumber] =~/<\/level>/){
			$level=~s/^"//;
			$level=~s/"$//;
			state_pop();
		}
		else {
			$level=$input[$linenumber];
		}
	}
	elsif ($state  eq 'title'){
		if ($input[$linenumber] =~/<\/title>/){
			state_pop();
		}
		else {
			$variables{'title'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'subtitle'){
		if ($input[$linenumber] =~/<\/subtitle>/){
			state_pop();
		}
		else {
			$variables{'subtitle'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'format'){
		if ($input[$linenumber] =~/<\/format>/){
			$format=~s/"$//;
			$format=~s/^"//;
			state_pop();
		}
		else {
			$format=$input[$linenumber];
		}
	}
	elsif ($state  eq 'author'){
		if ($input[$linenumber] =~/<\/author>/){
			state_pop();
		}
		else {
			$variables{'author'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'cover'){
		if ($input[$linenumber] =~/<\/cover>/){
			state_pop();
		}
		else {
			$variables{'cover'}=$input[$linenumber];
		}
	}
	elsif ($state  eq 'headerfile'){
		if ($input[$linenumber] =~/<\/header>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<\/headerfile>/){
			state_pop();
		}
		else {
			if ($input[$linenumber] =~/\.html*$/){
				if (open(my $HD, '<',$input[$linenumber])){
					while (<$HD>){
						chomp;
						output ($_);
					}
				}
				else {
					error("Cannot open $input[$linenumber]");
				}
			}
		}
	}
	elsif ($state  eq 'blank'){
		if ($input[$linenumber] =~/<\/blank>/){
			output('<br>&nbsp;<br>');
			state_pop();
		}
		else {
		}
	}
	elsif ($state  eq 'page'){
		if ($input[$linenumber] =~/<\/page>/){
			output('<hr>');
			state_pop();
		}
		else {
		}
	}
	elsif ($state  eq 'space'){
		if ($input[$linenumber] =~/<\/space>/){
			output(' ');
			state_pop();
		}
		else {
		}
	}
	elsif ($state  eq 'hr'){
		if ($input[$linenumber] =~/<\/hr>/){
			output('<hr>');
			state_pop();
		}
		else {
		}
	}
	elsif ($state  eq 'headerlink'){
		if ($input[$linenumber] =~/<\/headerlink>/){
			state_pop();
		}
		else {
			# Header links are for the header only; they are ignored in normal text
		}
	}
	elsif ($state  eq 'link'){
		if ($input[$linenumber] =~/<\/link>/){
			if ($target ne ''){
				output ("<a href=\"$target\">");
				if ($text ne ''){
					output ($text);
				}
				else {
					output ($target);
				}
				output ('</a>');
			}
			else {
				error ("Link without a target");
			}
			$target='';
			$text='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber] =~/<target>/){
			state_push('target');
		}
		else {
			error("link: text outside text/target");
		}
	}
	elsif ($state  eq 'set'){
		if ($input[$linenumber] =~/<\/set>/){
			if ($varname ne ''){
				$variables{$varname}=$value;
				output ("<!-- variables{$varname}=$value -->");
				$value='';
				$varname='';
			}
			state_pop();
		}
		elsif ($input[$linenumber] =~/<variable>/){
			state_push('set_var');
		}
		elsif ($input[$linenumber] =~/<value>/){
			state_push('value');
		}
		else {
			error("set: set can only have variable or value");
		}
	}
	elsif ($state  eq 'set_var'){
		if ($input[$linenumber] =~/<\/variable>/){
			state_pop();
		}
		else {
			$varname=$input[$linenumber];
		}
	}
	elsif ($state  eq 'value'){
		if ($input[$linenumber] =~/<\/value>/){
			state_pop();
		}
		else {
			$value=$input[$linenumber];
		}
	}
	elsif ($state  eq 'toc'){
		if ($input[$linenumber] =~/<\/toc>/){
			state_pop();
		}
		else {
			output ('<h1 class="toc">');
			output ($input[$linenumber]);
			output ('</h1>');
		}
	}
	elsif ($state  eq 'break'){
		if ($input[$linenumber] =~/<\/break>/){
			output('<br>');
			state_pop();
		}
		else {
			$type=$input[$linenumber];
		}
	}
	elsif ($state  eq 'file'){
		if ($input[$linenumber] =~/<\/file>/){
			$file=~s/^"//;
			$file=~s/"$//;
			state_pop();
		}
		else {
			$file=$input[$linenumber];
		}
	}
	elsif ($state  eq 'include'){
		if ($input[$linenumber] =~/<\/include>/){
			if ($file ne ''){
				if (open (my $FILE,'<',$file)){
					while (<$FILE>){
						chomp;
						output ($_);
					}
					close $FILE;
				}
				else {error("Cannot open $file for include");}
			}
			state_pop;
		}
		elsif ($input[$linenumber] =~/<file>/){
			state_push('file');
		}
	}
	$state=state_tos();
	$linenumber++;
}
if ($ptableopen>0){ output('</table>');$ptableopen=0;}


if ($trace > 0){
	for my $k (keys %variables){
		print "# Variable $k = $variables{$k}\n";
	}
}
if ($variables{"do_headers"} eq 'yes'){
	my $secby10=int(time()/10);
	print "<!DOCTYPE html>\n";
	print "<html lang=\"en\">\n";
	print "<head>\n";
	print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n";
	#print "<link href='https://fonts.googleapis.com/css?family=Roboto%20Condensed' rel='stylesheet' type=\"text/css\">\n";
	#print "<link href='https://fonts.googleapis.com/css?family=Poppins' rel='stylesheet' type=\"text/css\">\n";
	#print "<link href='https://fonts.googleapis.com/css?family=Pinyon%20Script' rel='stylesheet' type=\"text/css\">\n";
	print "<title>$variables{'title'}</title>\n";
	print "<style>
        .img-full { width:100%; height: auto;margin: 0 0 10px 10px;}
        .img-half { width:100%; height: auto;margin: 0 0 10px 10px;}
        .img-halfleft { width:50%; height: auto;float:left;margin: 0 0 10px 10px;}
        .img-halfright { width:50%; height: auto;float:right;margin: 0 0 10px 10px;}
        .img-quart { width:25%; height: auto;margin: 0 0 10px 10px;}
        .img-quartleft { width:25%; height: auto;float:left;margin: 0 0 10px 10px;}
        .img-quartright { width:25%; height: auto;float:right;margin: 0 0 10px 10px;}
	</style>\n";
	if (-f "stylesheet.css"){
		print "<link rel=\"stylesheet\" href=\"stylesheet.css\" type=\"text/css\">\n";
	}
	if (-f "in3style.css"){
		print "<link rel=\"stylesheet\" href=\"in3style.css\" type=\"text/css\">";
	}
	print "</head>\n";
	print "<body>\n";
	print "<!-- $secby10 -->\n";
}

for my $i (0..$#output){
	while ($output[$i]=~/%var\[(\w.*)\](\+*);/){
		my $var=$1;
		my $incr=$2;
		if (!defined($variables{$var})){
			$variables{$var}=0;
		}
		$output[$i]=~s/%var\[(\w.*)\](\+*);/$variables{$var}/g;
		if ($incr ne ''){ $variables{$var}++;}
	}
}

my $charmapfile;
if ( -f "/usr/local/share/in3/in3charmap$variables{'interpret'}" ){
	$charmapfile="/usr/local/share/in3/in3charmap$variables{'interpret'}";
}
else {
	$charmapfile="in3charmap$variables{'interpret'}";
}

my @charmap;
if (-f "meta.in"){
	if (open(my $META, '<','meta.in')){
		while (<$META>){
			if (/^\.in3charmap *"(.*)","(.*)","(.*)"$/){
				push @charmap,"$1	$2	$3";
			}
		}
	}
}

if ( open (my $CHARMAP,'<',$charmapfile)){
	while (<$CHARMAP>){
		if (/^\#/){ #comment line
		}
		else {
			push @charmap,$_
		}
	}
	close $CHARMAP;
}
else { print STDERR "xml3html Cannot open in3charmap\n"; }


for (@charmap){
	chomp;
	my $char;
	my $groff;
	my $html;
	($char,$groff,$html)=split '	';
	$char='UNDEFINED_CHAR' unless defined $char;
	$groff=$char unless defined $groff;
	$html=$char unless defined $html;
	for my $i (0..$#output){
		if ($output[$i]=~/$char/){
			$output[$i]=~s/$char/$html/g;
		}
	}
}

if ($variables{'COVER'} eq 'yes'){
	if ($variables{'cover'} ne ''){
		print "<img src=\"block/$variables{'cover'}\" alt=\"$variables{'cover'}\">\n";
		if (-f $variables{'cover'}){
			system ("cp $variables{'cover'} block");
		}
	}
}


for (@output){
	s/%\.;/./;
	print "$_\n";
}

if ($variables{"do_headers"} eq 'yes'){
	print "</body>\n";
}

if (-f "stylesheet.css"){
	system('cp stylesheet.css web');
}
print STDERR "\n";
