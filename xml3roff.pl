#!/usr/bin/perl
#INSTALL@ /usr/local/bin/xml3roff
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml
#
#
use strict;
use File::Basename;
my $DEBUG=0;
my $trace=0;

my %fontmeasure;
my $fontaverage;
my $fontfile="/usr/local/share/in3/TI.measure";
if (open ( my $FONT,'<',$fontfile)){
	while (<$FONT>){
		if(/^.\t[0-9]*/){
			chomp;
			(my $char,my $width)=split '	';
			$fontmeasure{$char}=$width;
		}
	}
	close $FONT;
}
else {
	print STDERR "Cannot open font measure file $fontfile\n";
}
$fontmeasure{' '}=250;

sub timesspace{
	(my $text)=@_;
	$text=~s/&lt;/</g;
	$text=~s/&gt;/>/g;
	$text=~s/&quot;/"/g;
	$text=~s/&apos;/'/g;
	$text=~s/&amp;/&/g;
	$text=~s/&#0092;/\\/g;
	my @str=split (//,$text);
	my $total=0;
	for (@str){
		if (defined($fontmeasure{$_})){
			$total=$total+$fontmeasure{$_};
		}
		else {
			$total=$total+350;
		}
	}
	undef @str;
	return $total/250;
}

my @fontmap;

if (open (my $FM,'<','in3fontmap')){
    @fontmap=<$FM>;
    close $FM;
}
elsif (open (my $FM,'<','/usr/local/share/in3/fontmap')){
    @fontmap=<$FM>;
    close $FM;
}


my @output;
my $outatol=0;
sub output{
	if ($outatol==0){
		for (@_){
			my $txt=$_;
			push @output, $txt;
			if ($trace > 0){print STDERR "#                                                               output: $_\n";}
		}
	}
	else {
		for (@_){
			my $txt=$_;
			my $top=pop @output;
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
sub nodupoutput {
	(my $te)=@_;
	my $mx=$#output;
	if ($output[$mx] ne $te){ push @output,$te;}
}




sub error {
	for (@_){
		print STDERR "$_\n";
	}
}

my $print5=999999;

sub prt5 {
	(my $line)=@_;
	if ($print5 < 5 ){
		print STDERR "CONTEXT - $line\n";
		$print5++
	}
}


#for (@output){
#	if (/^\.FS/){$print5=0;}
#	prt5($_);
#}



# Variables for overall use
my %variables;
    $variables{"COVER"}=0;
    $variables{"FIRST"}=0;
    $variables{"H1"}=0;
    $variables{"H2"}=0;
    $variables{"H3"}=0;
    $variables{"H4"}=0;
    $variables{"H5"}=0;
    $variables{"H6"}=0;
    $variables{"H7"}=0;
    $variables{"H8"}=0;
    $variables{"H9"}=0;
    $variables{"need"}=4;
    $variables{"TOC"}=0;
    $variables{"appendix"}=-1;
    $variables{"author"}='';
    $variables{"back"}=0;
    $variables{"blockcnt"}=0;
    $variables{"cover"}='';
    $variables{"COVER"}='no';
    $variables{"do_headers"}='yes';
    $variables{"tableexpand"}='no';
    $variables{"imagex"}=800;
    $variables{"imagey"}=800;
    $variables{"subtitle"}='';
    $variables{"title"}='';
    $variables{'debug'}=$DEBUG;
    $variables{'inlineemp'}=0;
    $variables{'interpret'}=1;
    $variables{'markdown'}=0;
    $variables{'notes'}=0;
    $variables{'picheight'}=5;
    $variables{'preauthor'}=0;
    $variables{'sidechar'}='*';
    $variables{'sidesep'}=';';


my @input;
my @infile;

# Variables that are picked-up in sub-states and may be  used when higher states close
my $caption='';
my $class='';
my $coord='';
my $file='';
my $format;
my $image;
my $level=0;
my $name='';			
my $ref='';
my $seq='';
my $target='';
my $text='';			
my $type;
my $value='';
my $varname='';
my $video;
my $fontname='';
my $qtyspace=1;

# Control variables
my $firstrow=1;
my $currentline='';
my $fileline=0;
my $inline=0;
my $lastline='';
my $listlevel=0;
my $pcellopen=0;
my $progressindicator=0;
my $ptableopen=0;		# Paragraph table is open. This allows using the same table for different paragraphs
my @blocktext='';
my @footnote;
my @leftnotes;
my @listblock;
my @listtype;
	push @listtype,'none';
my @sidenotes;

sub debug {
	if ($variables{'debug'} >0){
		for (@_){
			print STDERR "debug: $_\n";
		}
	}
}

my $what='';
for (@ARGV){
	if ($what eq ''){
		if (/^--$/){ while (<STDIN>){push @input,$_;}}
		elsif (/^--debug([0-9]+)/){ $variables{"DEBUG"}=$1; }
		elsif (/^--debug=([0-9]+)/){ $variables{"DEBUG"}=$1; }
		elsif (/^-d$/){$what='debug';}
		elsif (/^--debug$/){$what='debug';}
		elsif (/^-c([0-9]+)/){ $variables{"H1"}=$1;$variables{"COVER"}='no';}
		elsif (/^--chapter([0-9]+)/){ $variables{"H1"}=$1-1;$variables{"COVER"}='no';}
		elsif (/^--chapter=([0-9]+)/){ $variables{"H1"}=$1-1;$variables{"COVER"}='no';}
		elsif (/^-c$/){$what='chapter';$variables{"COVER"}='no';}
		elsif (/^--chapter$/){$what='chapter';$variables{"COVER"}='no';}
		elsif (/^--doheaders/){$variables{"do_headers"}='yes';}
		elsif (/^--do_headers/){$variables{"do_headers"}='yes';}
		elsif (/^--cover/){$variables{"COVER"}='yes';}
		elsif (/^-cover/){$variables{"COVER"}='yes';}
		elsif (/^--docover/){$variables{"COVER"}='yes';}
		elsif (/^-docover/){$variables{"COVER"}='yes';}
		elsif (/^--COVER/){$variables{"COVER"}='yes';}
		elsif (/^-COVER/){$variables{"COVER"}='yes';}
		elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^--interpret([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^--interpret=([0-9]+)/){ $variables{"interpret"}=$1;}
		elsif (/^-i$/){$what='interpret';}
		elsif (/^--interpret$/){$what='interpret';}
		elsif (/^-m/){$variables{"markdown"}=1;}
		elsif (/^--markdown/){$variables{"markdown"}=1;}
		elsif (/^--noheaders/){$variables{"do_headers"}='no';}
		elsif (/^--no_headers/){$variables{"do_headers"}='no';}
		elsif (/^--nocover/){$variables{"COVER"}='no';}
		elsif (/^--no_cover/){$variables{"COVER"}='no';}
		elsif (/^-+h/){ hellup(); }
		elsif (/^-t/){ $trace=1;}
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
					push @infile,"$file:$fileline";
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
	$fileline=0;
	while (<STDIN>){
		$fileline++;
		push @input,$_;
		push @infile,"STDIN:$fileline";
	}
}
if ($trace>0){ print STDERR "dots at start of line..";}
for (@input){
if (/^\./){s/^\./\\[char46]/;}
if (/^ \./){s/^ \./\\[char46]/;}
#if (/^\"./){s/^"/"\\[char46]/;}
}
if ($trace>0){ print STDERR "removed\n";}

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

#   __                            _                                  _
#  / _| ___  _ __ _ __ ___   __ _| |_ _ __ ___  __ _ _   _  ___  ___| |_
# | |_ / _ \| '__| '_ ` _ \ / _` | __| '__/ _ \/ _` | | | |/ _ \/ __| __|
# |  _| (_) | |  | | | | | | (_| | |_| | |  __/ (_| | |_| |  __/\__ \ |_
# |_|  \___/|_|  |_| |_| |_|\__,_|\__|_|  \___|\__, |\__,_|\___||___/\__|
#                                                 |_|

sub formatrequest {
	if (!($input[$linenumber] =~/<.*>/) && !($input[$linenumber] =~/\(.*\)/)){
		if ($input[$linenumber]=~/=====*&gt;(.*)/){
			$currentline=$currentline . $1;
		}
		else {
			$currentline=$currentline . $input[$linenumber];
		}
	}
	if ($input[$linenumber] =~/^([^=]*)=====*&gt;(.*)/){
		my $pre=$1;
		my $post=$2;
		$lastline=~s/\\\[..\]/a/g;
		my $l=timesspace($lastline)-timesspace($pre);
		my $spaces='\\ ' x $l;
		# output ("lastline=$lastline ($l)");
		$input[$linenumber] =~s/^====*&gt;/$spaces/;
		$currentline="$lastline $post";
		#output ($spaces);
	}
	if ($input[$linenumber] =~/<underline>/){
		state_push('underline');
	}
	elsif ($input[$linenumber] =~/<italic>/){
		state_push('italic');
	}
	elsif ($input[$linenumber] =~/<italicnospace>/){
		state_push('italicnospace');
	}
	elsif ($input[$linenumber] =~/<bold>/){
		state_push('bold');
	}
	elsif ($input[$linenumber] =~/<boldnospace>/){
		state_push('boldnospace');
	}
	elsif ($input[$linenumber] =~/<center>/){
		state_push('center');
	}
	elsif ($input[$linenumber] =~/<lst>/){
		state_push('lst');
	}
	elsif ($input[$linenumber] =~/<space>/){
		$qtyspace=1;
		state_push('space');
	}
	elsif ($input[$linenumber] =~/<hr>/){
		state_push('hr');
	}
	elsif ($input[$linenumber] =~/<break>/){
		state_push('break');
	}
	elsif ($input[$linenumber] =~/<blank>/){
		state_push('blank');
	}
	elsif ($input[$linenumber] =~/<subscript>/){
		state_push('subscript');
	}
	elsif ($input[$linenumber] =~/<fixed>/){
		state_push('fixed');
	}
	elsif ($input[$linenumber] =~/<fixednospace>/){
		state_push('fixednospace');
	}
	elsif ($input[$linenumber] =~/<font *type="*(.*)"*>/){
		$fontname=$1;
		state_push('font');
	}
	elsif ($input[$linenumber] =~/<video>/){
		$video='';
		$file='';
		$text='';
		state_push('video');
	}
	elsif ($input[$linenumber] =~/<image>/){
		$image='';
		$file='';
		$text='';
		state_push('image');
	}
	elsif ($input[$linenumber] =~/<block>/){
		$type='pre';
		$image='';
		$class='';
		undef@blocktext;
		state_push('block');
	}
	elsif ($input[$linenumber] =~/<note>/){
		undef @footnote;
		$seq='';
		$ref='';
		state_push('note');
	}
	elsif ($input[$linenumber] =~/<link>/){
		$target='';
		$text='';
		state_push('link');
	}
	elsif ($input[$linenumber] =~/<set>/){
		state_push('set');
	}
	else {
		output ($input[$linenumber]);
	}

}

#  _
# (_)_ __ ___   __ _  __ _  ___  ___
# | | '_ ` _ \ / _` |/ _` |/ _ \/ __|
# | | | | | | | (_| | (_| |  __/\__ \
# |_|_| |_| |_|\__,_|\__, |\___||___/
#                    |___/

sub outimage {
	(my $img, my $iformat)=@_;
	my $scale=100;
	if ($iformat=~/scale=([0-9]+)/){ $scale=$1;}
	my $imagename='';
	$img=~s/"//g;
	$imagename=basename($img);
	$imagename=~s/\.\w+$/.eps/;
	my $dvifile=$img; $dvifile=~s/\.\w+$/.dvi/;
	my $imgstem=$imagename; $imgstem=~s/\.\w+$//;
	debug ("IMAGE VARS img=$img imagename=$imagename dvifile=$dvifile imgstem=$imgstem");
	if ($img=~/\.eps$/){
		debug ("img=eps");
		if ($img ne  "block/$imagename"){
			system ("rm -f  block/$imagename");
			system ("eps2eps -B1 $img block/$imagename");
		}
	}
	elsif ($img=~/\.dvi$/){
		debug ("img=dvi");
		debug ("DVI block $imgstem.dvi");
		system ("dvips -E  $img -o block/$imagename");
	}
	elsif ($img=~/\.dia$/){
		debug ("img=dia");
		debug ("DIA block $imgstem.dia");
		system ("in3fileconv $img block/$imagename");
	}
	elsif ($img=~/\.svg$/){
		debug ("img=svg");
		debug ("SVG block $imgstem.svg");
		system ("cairosvg -f ps --width 800  $img -o block/i$imagename");
		system ("eps2eps block/i$imagename block/$imagename");
	}
	else {
		debug ("img=other");
		system ("in3fileconv $img block/$imagename");
	}
	# We now have an image in block/$imagename as .eps
	if (1==2){
		#try that later
	}
	elsif ($type=~/music/) {
		debug ("IMAGE TYPE=music");
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$x=$x*$scale/100;
		$y=$y*$scale/100;
		debug("Music SIZE $x $y");
		if (($iformat=~/inline/)||($inline>0)){
			my $up=$y/4;
			output ("\\v'0.3'");
			output (".dospark block/$imagename $x $y");
			output ("\\v'-0.3'");
		}
		else {
			output ('.sp 1');
			output ('.ce 1');
			output (".dospark block/$imagename $x $y");
		}
		if ($caption ne ''){
			output (".ce 1");
			output (".I \"$caption\"");
			$caption='';
		}
	}
	elsif ($type=~/texeqn/) {
		debug ("IMAGE TYPE=texeqn");
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$x=$x*$scale/100;
		$y=$y*$scale/100;
		debug("Techeqn SIZE $x $y");
		if (($iformat=~/inline/)||($inline>0)){
			my $up=$y/4;
			output ("\\v'0.1'");
			output (".dospark block/$imagename $x $y");
			output ("\\v'-0.1'");
		}
		else {
			output ('.sp 1');
			output ('.ce 1');
			output (".dospark block/$imagename $x $y");
		}
		if ($caption ne ''){
			output (".ce 1");
			output (".I \"$caption\"");
			$caption='';
		}
	}
	elsif ($type=~/pic/) {
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		my $myscale=$scale;
		if ($x>$variables{'imagex'}){$myscale=$variables{'imagex'}*$scale/$x;}
		my $y2=$y*$myscale/$variables{'imagey'};
		if ($y2>$variables{'imagey'}){$myscale=$variables{'imagey'}*$scale/$y;}

		$y=$y*$myscale/700;
		$x=$x*$myscale/700;
		my $up=$y/100;
		my $need=$y*5;
		#output ("\\v'$up"."c'");
		if (($iformat=~/inline/)|| ($inline>0)){
			output ("\\v'$up".'v\'');
			output (".dospark block/$imagename $x $y");
			output ("\\v'-$up".'v\'');
		}
		else {
			output (".ne $need".'p');
			output ('.ce 1');
			$x=$x*4; $y=$y*4;
			output (".PSPIC block/$imagename $x $y");
		}
		#output (".PSPIC block/$imagename $x");
		if ($caption ne ''){
			output (".ce 1");
			output (".I \"$caption\"");
			$caption='';
		}
	}
	elsif ($img=~/\.dia$/) {
		debug ("IMAGE TYPE=dia");
		print STDERR "dia --export $img block/$imagename\n\n";
		system("in3fileconv $img block/$imagename");
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		$x=$x*$scale/500;
		$y=$y*$scale/500;
		debug("dia SIZE $x $y");
		if (($iformat=~/inline/)||($inline>0)){
			my $up=$y/4;
			output ("\\v'0.2'");
			output (".dospark block/$imagename $x $y");
			output ("\\v'-0.2'");
		}
		else {
			output ('.sp 1');
			output ('.ce 1');
			output (".dospark block/$imagename $x $y");
		}
		if ($caption ne ''){
			output (".ce 1");
			output (".I \"$caption\"");
			$caption='';
		}
	}
	else {
		system ("in3fileconv $img block/$imagename");
		my $imgsize=`imageinfo --geom block/$imagename`;
		my $x; my $y; my $xn;
		($x,$y)=split ('x',$imgsize);
		my $y_from_x=$y/$x;
		my $myscale=$scale;
		my $extra='';
		if ($x>$variables{'imagex'}){$myscale=$variables{'imagex'}*$scale/$x;}
		#if ($iformat =~ /full/){ $myscale=50000/$x;$extra=' 14c';}
		#if ($iformat =~ /half/){ $myscale=25000/$x;$extra=' 7c';}
		#if ($iformat =~ /quart/){ $myscale=12500/$x;$extra=' 3.5c';}
		if ($iformat =~ /full/){ $x=500; $y=$x*$y_from_x;}
		elsif ($iformat =~ /half/){ $x=250; $y=$x*$y_from_x;}
		elsif ($iformat =~ /quart/){ $x=125; $y=$x*$y_from_x;}
		else {
			my $y2=$y*$myscale/$variables{'imagey'};
			if ($y2>$variables{'imagey'}){$myscale=$variables{'imagey'}*$scale/$y;}
			$y=$y*$myscale/500;
			$x=$x*$myscale/500;
		}
		my $up=$y/100;
		my $need=$y*2;
		#output ("\\v'$up"."c'");
		if (($iformat=~/inline/)|| ($inline>0)){
			output ("\\v'$up".'v\'');
			output (".dospark block/$imagename $x $y");
			output ("\\v'-$up".'v\'');
		}
		elsif ($iformat=~/cover/){
			output ("\\v'$up".'v\'');
			output (".dospark block/$imagename $x $y");
			output ("\\v'-$up".'v\'');
		}
		elsif($format =~/left/){
			output (".ne $need".'p');
			output (".lfloat2 block/$imagename \"$caption\"");
			$caption='';
		}
		elsif($format =~/right/){
			output (".ne $need".'p');
			output (".rfloat2 block/$imagename \"$caption\"");
			$caption='';
		}
		else {
			output (".ne $need".'p');
			output ('.ce 1');
			#if ($img=~/\.svg$/){
			#	$x=$x*2; $y=$y*2;
			#}
			#elsif ($img=~/\.eps$/){
			#	$x=$x*2; $y=$y*2;
			#}
			#else {
			#	$x=$x*4; $y=$y*4;
			#}
			output (".dospark block/$imagename $x $y");
		}
		#else {
			#output (".PSPIC block/$imagename $x");
		#}
		if ($caption ne ''){
			output (".ce 1");
			output (".I \"$caption\"");
			$caption='';
		}
	}
}


sub close_paratable {

	$outatol=0;
	if ($ptableopen>0){
		if ($pcellopen>0){
			if ($variables{'notes'}==1){
				output ('T}');
			}
			else{
				output ('T}@T{');
				if (($variables{'notes'}&2)>0){
					my $notestr='';
					for (@sidenotes){$notestr.=$_;}
					output ($notestr);
					output ('T}');
				}
			}
			$pcellopen=0;
		}
		output ('.TE');
		$ptableopen=0;
	}
}

#  _        _     _        _             _         _                    _
# | |_ __ _| |__ | | ___  | | ___   ___ | | ____ _| |__   ___  __ _  __| |
# | __/ _` | '_ \| |/ _ \ | |/ _ \ / _ \| |/ / _` | '_ \ / _ \/ _` |/ _` |
# | || (_| | |_) | |  __/ | | (_) | (_) |   < (_| | | | |  __/ (_| | (_| |
#  \__\__,_|_.__/|_|\___| |_|\___/ \___/|_|\_\__,_|_| |_|\___|\__,_|\__,_|
#

my @thistable;
my $maxrow=0;
my $maxcol=0;
my $tablerow=0;
my $tablecol=0;
my @colwidth;
my $cellstring;
# tbl needs a definition before a table can be created.
sub table_lookahead{
	(my $start)=@_;
	my $localline=$start;
	my $substate='none';
	undef @thistable;
	undef @colwidth;
	while ($substate ne 'end'){
		chomp $input[$localline];
		if ($localline >$#input){
			$substate='end';
		}
		elsif ($substate eq 'none'){
			if ($input[$localline] =~ /<table>/){
				$maxrow=0;
				$maxcol=0;
				$tablerow=-1;
				$tablecol=-1;
				$substate='table';
			}
			elsif ($input[$localline] =~ /<\/table>/){
				$substate='end';
			}
		}
		elsif ($substate eq 'table'){
			if ($input[$localline] =~ /<row>/){
				$tablerow++;
				$tablecol=-1;
				if ($tablerow>$maxrow){$maxrow=$tablerow;}
				$substate='row';
			}
			elsif ($input[$localline] =~ /<\/table>/){
				$substate='end';
			}
		}
		elsif ($substate eq 'row'){
			if ($input[$localline] =~ /<\/row>/){
				$substate='table';
			}
			elsif ($input[$localline] =~ /<cell.*>/){
				my $txtf='text';
				$cellstring='';
				if ($input[$localline] =~ /format="([a-z]+)"/){$txtf=$1;}

				$tablecol++;
				while ($thistable[$tablerow][$tablecol]=~/[rc][owl]*s[pan]*/){
					$tablecol++;
				}
				if ("$thistable[$tablerow][$tablecol]" eq ""){
					$thistable[$tablerow][$tablecol]="$txtf";
				}
				if ($input[$localline] =~ /<cell[^>]*c[ol]*s[pan]*="*([0-9]+)/){
					my $span=$1;
					for (my $i=1; $i<$span; $i++){
						$thistable[$tablerow][$tablecol+$i]="colspan";
					}
				}
				if ($input[$localline] =~ /<cell.*r[ow]*s[pan]*="*([0-9]+)/){
					my $span=$1;
					for (my $i=1; $i<$span; $i++){
						$thistable[$tablerow+$i][$tablecol]="rowspan";
						if ($input[$localline] =~ /<cell[^>]*c[ol]*s[pan]*="*([0-9]+)/){
							my $subspan=$1;
							for (my $j=1; $j<$subspan; $j++){
								$thistable[$tablerow+$i][$tablecol+$j]="colspan";
							}
						}
					}
				}
				if ("$thistable[$tablerow][$tablecol]" eq ""){
					$thistable[$tablerow][$tablecol]=$txtf;
				}
				if ($tablecol>$maxcol){$maxcol=$tablecol;}
				$substate='cell';
				$cellstring='';
			}
		}
		elsif ($substate eq 'cell'){
			if ($input[$localline] =~ /<\/cell>/){
				$substate='row';
				$cellstring='';
			}
			elsif ($input[$localline] =~ /<\/row>/){   # This would be a violation of the XML
				$substate='table';
			}
			elsif ($input[$localline] =~ /<\/table>/){   # This would be a violation of the XML
				$substate='end';
			}
			else {
				$cellstring="$cellstring$input[$localline]";
				if ($colwidth[$tablecol] <= length($cellstring)){$colwidth[$tablecol] =length($cellstring);}

			}
		}
		$localline++;
	}
	my $vspace=$maxrow+5;
	my $largestcol=0;
	my $largestcolval=0;
	for (my $i=0; $i<=$maxcol; $i++){
		if ($largestcolval<=$colwidth[$i]){
			$largestcol=$i;
			$largestcolval=$colwidth[$i];
		}
		my $xpcol=$variables{'expandcol'}-1;
		$xpcol=9999 unless defined $xpcol;
		if ($i == $xpcol){
			$largestcol=$i;
			$largestcolval=$colwidth[$i];
		}
	
	}
	nodupoutput (".ne $vspace".'v');
	my @colwidths=();
	for (my $j=0; $j<=$maxcol; $j++){
		$colwidths[$j]='';
	}
	if ($variables{'tableexpand'} eq 'yes'){
		$colwidths[$variables{'expandcol'}-1]='x';
	}
	#output (".ig TX");
	#output ('Columnsizes');
	#if (defined ($variables{'colwidth'})){
		#output ($variables{'colwidth'});
		#if ($variables{'colwidth'}=~/,/){
			#my @incw=split (',',$variables{'colwidth'});
			#for my $i (0 .. $#incw){
				#$colwidths[$i]=$incw[$i];
			#}
		#}
	#	
	#}
	#else {
	#}
	#for (my $j=0; $j<=$maxcol; $j++){
		#output("col $j : $colwidths[$j]");
	#}
	#output (".TX");
	for (my $j=0; $j<=$maxcol; $j++){
		if ($colwidths[$j]=~/^[0-9]+$/){
			output(".nr %$colwidths[$j] \\n(.lu*$colwidths[$j]u/100");
			$colwidths[$j]="w(\\n[%$colwidths[$j]]u)";
			#output ($colwidths[$j]);
		}
	}
	if (defined ($variables{'tableheader'}) && ($variables{'tableheader'} eq 'yes')){
		output ('.TS H');
	}
	else {
		output ('.TS');
	}
	$firstrow=1;
	output ('allbox,center;');
	for (my $i=0; $i<=$maxrow; $i++){
		my $rowfmt='';
		for (my $j=0; $j<=$maxcol; $j++){
			if ($thistable[$i][$j]=~/rowspan/){
				$rowfmt="$rowfmt ^";
			}
			elsif ($thistable[$i][$j]=~/colspan/){
				$rowfmt="$rowfmt s";
			}
			else {
				if ($thistable[$i][$j]=~/([a-z]+)/){
					if ($1 eq 'center'){ $rowfmt="$rowfmt c";}
					elsif ($1 eq 'left'){ $rowfmt="$rowfmt l";}
					elsif ($1 eq 'text'){ $rowfmt="$rowfmt l";}
					elsif ($1 eq 'right'){ $rowfmt="$rowfmt r";}
					elsif ($1 eq 'num'){ $rowfmt="$rowfmt n";}
					$rowfmt="$rowfmt$colwidths[$j]";
					#if (defined ($variables{'colwidth'})){
						#if ($variables{'colwidth'}=~','){
							#my @clw=split(',',$variables{'colwidth'});
						#}
						#	
					#}
					#elsif (($i==0)&&($j==$largestcol)&&($variables{'tableexpand'} eq 'yes')){$rowfmt=$rowfmt . 'x';}
					#elsif (($i==0)&&($j==1)&&($variables{'tableexpand'} eq 'yes')){$rowfmt=$rowfmt . 'x';}
				}
				else {
					$rowfmt="$rowfmt l";
					if (($i==0)&&($j+1==$largestcol)&&($variables{'tableexpand'} eq 'yes')){$rowfmt=$rowfmt . 'x';}
					elsif (($i==0)&&($j==1)&&($variables{'tableexpand'} eq 'yes')){$rowfmt=$rowfmt . 'x';}
				}
			}
		}
		$rowfmt=~s/^ //;
		if ($i==$tablerow){$rowfmt="$rowfmt.";}
		output ($rowfmt);
	}
	$maxrow=0;
	$maxcol=0;
}


my @thiscell;

#                  _         _
#  _ __ ___   __ _(_)_ __   | | ___   ___  _ __
# | '_ ` _ \ / _` | | '_ \  | |/ _ \ / _ \| '_ \
# | | | | | | (_| | | | | | | | (_) | (_) | |_) |
# |_| |_| |_|\__,_|_|_| |_| |_|\___/ \___/| .__/
#                                         |_|


if ($trace>0){ print STDERR "Start mainloop\n";}
$linenumber=0;
while ( $linenumber <= $#input){
	chomp $input[$linenumber];
	#$input[$linenumber]=~s/^ \./\\$./;
	$input[$linenumber]=~s/^[ 	]*//;
	my $state=state_tos();
	if ($trace>0){printf STDERR "# %10.10s - %8.8d : %s\n",($state,$linenumber,$input[$linenumber]);}
	if ($input[$linenumber] =~/<!--.*-->/){}

	elsif ($state  eq 'outside'){
		if ($input[$linenumber] =~/<in3xml>/){
			state_push('in3xml');
		}
	}
	elsif ($state  eq 'in3xml'){
		if ($input[$linenumber] =~/<\/in3xml>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<author>/){
			state_push('author');
		}
		elsif ($input[$linenumber] =~/<blank>/){
			state_push('blank');
		}
		elsif ($input[$linenumber] =~/<block>/){	# note: these are stand alone blocks
			close_paratable();
			$type='pre';
			$image='';
			$class='';
			$inline=0;
			undef@blocktext;
			state_push('block');
		}
		elsif ($input[$linenumber] =~/<break>/){
			state_push('break');
		}
		elsif ($input[$linenumber] =~/<cover>/){
			state_push('cover');
		}
		elsif($input[$linenumber] =~/<header>/){
			close_paratable();
			state_push('headerfile');
		}
		elsif ($input[$linenumber] =~/<headerlink>/){
			state_push('headerlink');
		}
		elsif ($input[$linenumber] =~/<heading>/){
			$variables{'notes'}=$variables{'notes'}&2;
			close_paratable();
			state_push('heading');
		}
		elsif ($input[$linenumber] =~/<hr>/){
			state_push('hr');
		}
		elsif ($input[$linenumber] =~/<image>/){
			close_paratable();
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<include>/){
			state_push('include');
		}
		elsif ($input[$linenumber] =~/<lst>/){
			close_paratable();
			$outatol=0;
			output ('.P');
			state_push('lst');
		}
		elsif ($input[$linenumber] =~/<map>/){
			close_paratable();
			state_push('map');
		}
		elsif ($input[$linenumber] =~/<page>/){
			state_push('page');
		}
		elsif ($input[$linenumber] =~/<set>/){
			state_push('set');
		}
		elsif ($input[$linenumber] =~/<subtitle>/){
			state_push('subtitle');
		}
		elsif ($input[$linenumber] =~/<table>/){
			$inline=1;
			$variables{'notes'}=$variables{'notes'}&2;
			close_paratable();
			table_lookahead($linenumber);
			$tablerow=0;
			$tablecol=0;
			state_push('table');
		}
		elsif ($input[$linenumber] =~/<title>/){
			state_push('title');
		}
		elsif ($input[$linenumber] =~/<toc>/){
			close_paratable();
			output(".bp");
			output(".ps +12");
			output(".ls 3");
			output(".P");
			output("");
			state_push('toc');
		}
		elsif ($input[$linenumber] =~/<video>/){
			close_paratable();
			state_push('video');
		}
		elsif ($input[$linenumber] =~/<([acdhlmnopritu]*)list>/){
			$type='';
			if ($1 ne ''){
				$type=$1;
			}
			$listlevel=1; # Should always have been 0 because we're in state in3xml.
			undef @listtype;
			$listtype[0]='none';
			$variables{'notes'}=$variables{'notes'}&2;
			close_paratable();
			# find the type at this level
			$listlevel=1;
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
						debug("List-type assignment: listtype[$listlevel]=$input[$i]");
					}
				}
				$i++;
			}
			if (($variables{'notes'} &2)>0){
				output ('.ll 12.5c');
			}
			else {
				output ('.ll 6.5i');
			}
			if ($listtype[$listlevel]=~/dash/){ output ('.DL');}
			elsif ($listtype[$listlevel]=~/num/){ output ('.AL 1');}
			elsif ($listtype[$listlevel]=~/alpha/){ output ('.AL a');}
			else { output ('.DL');}
			$inline=1;
			state_push('list');
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
			my $prevnotes=$variables{'notes'};
			$inline=1;
			my $endpara=$linenumber;
			if ($variables{'back'}>0){
				$variables{'back'}=0;
				$variables{'notes'}=$variables{'notes'}&2;
			}
			# Collect all side and left notes
			while (($endpara<=$#input) && !($input[$endpara] =~/<\/paragraph>/)){
				if ($intext>0){
					if ($input[$endpara] =~/<\/text>/){
						$intext=0;
					}
					else {
						push @paratext,$input[$endpara];
					}
				}
				elsif ($inside>0){
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
						chomp $input[$endpara];
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
				close_paratable
			}
			if ($variables{'notes'}==0){
				$outatol=0;
    				output (".ne $variables{'need'}");
				output ('.P');
			}
			elsif ($ptableopen==0){    
				output ('.TS');
				output ('tab(@);');
				if ($variables{'notes'}==1) { output ('lw(2c) lw(12.4c).');}
				if ($variables{'notes'}==2) { output ('lw(12.4c) lp6w(2c)v-5.');}
				if ($variables{'notes'}==3) { output ('lw(2c) lw(10.1c) lp6w(2c)v-5.');}
				output ('T{');
				if (($variables{'notes'}&1)>0){
					for (@leftnotes){ output ($_);}
					output ('T}@T{');
					undef @leftnotes;
				}
				$ptableopen=1;
			}
			elsif ($variables{'notes'}>0){
				output ('T{');
				if (($variables{'notes'}&1)>0){
					for (@leftnotes){ output ($_);}
					output ('T}@T{');
					undef @leftnotes;
				}
			}		# The output document is now always in the correct state to
					# process the text part of the paragraph.
			$pcellopen=1;
			state_push('paragraph');
		}
		elsif($input[$linenumber] =~/^$/){}
		else {
			error ("in3xml: Plain text outside constructs in $linenumber: $input[$linenumber]");
		}
	}
	elsif ($state  eq 'list'){
		if ($input[$linenumber] =~/<\/[dashnumotlpr]*list>/){
			if ($listtype[$listlevel] eq 'dash'){ output ('.LE 1');}
			elsif ($listtype[$listlevel] eq 'num'){ output ('.LE 1');}
			elsif ($listtype[$listlevel] eq 'alpha'){ output ('.LE 1');}
			else { output ('.LE 1');}
			$listlevel--;
			if ($listlevel==0){
			   	$inline=0;
				output ('.ll 6.5i');
			}
			state_pop;
		}
		elsif($input[$linenumber] =~/<list>/){
			$listlevel++;
			# find the type at this level
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
						debug("List-type assignment: listtype[$listlevel]=$input[$i]");
					}
				}
				$i++;
			}
			if ($listtype[$listlevel]=~/dash/){ output ('.DL');}
			elsif ($listtype[$listlevel]=~/num/){ output ('.AL 1');}
			elsif ($listtype[$listlevel]=~/alpha/){ output ('.AL a');}
			else { output ('.DL');}
			state_push('list');
		}
		elsif($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif($input[$linenumber] =~/<item>/){
			output ('.LI');
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
			state_pop;
		}
		else {
			$inline=1;
			formatrequest();
		}
	}
	elsif ($state  eq 'note'){
		if ($input[$linenumber] =~/<\/note>/){
			if ($ref eq ''){
				output ('.FS');
			}
			else {
				output (".FS '$ref'");
			}
			output($ref);
			for (@footnote){
				output ($_);
			}
			output ('.FE');
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

	}
	elsif ($state  eq 'notetext'){
		if ($input[$linenumber] =~/<\/notetext>/){
			state_pop();
		}
		else {
			push @footnote,$input[$linenumber];
		}
	}
	elsif ($state  eq 'block'){
		if ($input[$linenumber] =~/<\/block>/){
			if ($name eq ''){ $name="no_name.".int(rand(9999)); }
			for (@blocktext){
				s/&lt;/</g;
				s/&gt;/>/g;
				s/&quot;/"/g;
				s/&apos;/'/g;
				s/&amp;/&/g;
				s/&#0092;/\\/g;
			}
			my $blk="block/$name";
			if ($type eq 'pre'){
				close_paratable();
				output ('.ne 4v','.sp 1','.B1','.ft 6','.ps -4','.vs -4','.nf','.sp 1');
				for (@blocktext){
					s/\\/%backslash;/g;
					s/^"//;
					s/"$//;
					s/&/&amp;/g;		# change xml back because we're un-xmling at the end
					s/</&lt;/g;
					s/>/&gt;/g;
					s/"/&quot;/g;
					s/'/&apos;/g;
					s/&#0092;/\\/g;
					output('.br',$_);
				}
				output ('.sp 1',,'.ps','.vs','.ft','.fi','.B2');
				if ($caption ne ''){
					output (".I \"$caption\"");
					$caption='';
				}
			}
			elsif ($type eq 'lst'){
				close_paratable();
				output ('.ne 4v','.ft 6','.ps -4','.nf','.vs -4');
				for (@blocktext){
					s/\\/%backslash;/g;
					s/^"//;
					s/"$//;
					s/&/&amp;/g;		# change xml back because we're un-xmling at the end
					s/</&lt;/g;
					s/>/&gt;/g;
					s/"/&quot;/g;
					s/'/&apos;/g;
					s/&#0092;/\\/g;
					output('.br',$_);
				}
				output ('.vs','.ps','.ft','.fi');
				if ($caption ne ''){
					output (".I \"$caption\"");
					$caption='';
				}
			}
			elsif ($type eq 'pic'){
				if ($inline==0){
					output (".PS $variables{'picheight'}");
					for (@blocktext){
						s/^"//;
						s/"$//;
						output($_);
					}
					output ('.PE');
				}
				if ($caption ne ''){
					output (".ce 1");
					output (".I \"$caption\"");
					$caption='';
				}
				else { # This is a hack because pic does not provide in-line images.
					my $mscale=100;
					if ($format=~/scale=([0-9]+)/){
						$mscale=$1;
						$format=~s/scale=[0-9]+//;
					}
					$mscale=$mscale*2;   # CHECK  for inline scale!
					if ($image eq ''){
						my $density=1000;
						if (open my $PIC, '>',"$blk.pic"){
							print $PIC ".PS\n";
							for (@blocktext){
								if (/^".*"$/){
									s/^"//;
									s/"$//;
								}
								print $PIC "$_\n";
							}
							print $PIC ".PE\n";
							close $PIC;
							system ("pic $blk.pic > $blk.groff");
							system ("groff $blk.groff > $blk.ps");
							system ("eps2eps -B1  $blk.ps $blk.eps");
							$mscale=2*$mscale;
							outimage("$blk.eps", $format." scale=$mscale ");
						}
						else {
							error ("Cannot open $blk.pic"); 
						}
					}
					else {
						outimage("$image", $format." scale=$mscale ");
						$format='';
						$image='';
					}
					undef @blocktext;
				}
			}
			elsif ($type eq 'eqn'){
				if ($inline == 0){ output ('.ce 1');}
				output ('.EQ');
				for (@blocktext){
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('.EN');
				if ($caption ne ''){
					output (".ce 1");
					output (".I \"$caption\"");
					$caption='';
				}
			}
			elsif ($type eq 'piechart'){
				my $mscale=1000;
				if ($format=~/scale=([0-9]+)/){
					$mscale=$1;
					$format=~s/scale=[0-9]+//;
				}
				$mscale=$mscale/4;   # CHECK  for inline scale!
				my $density=1000;
				if (open my $PLOT, '>',"$blk.piechart"){
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
						}
						s/	/,/g;
						print $PLOT "$_\n";
					}
					system(" piechart $blk.piechart --order value,explode,color,legend > $blk.svg");
					if ($format=~/full/){
						outimage("$blk.svg", $format." full");
					}
					elsif ($format=~/half/){
						outimage("$blk.svg", $format." half ");
					}
					else {
						outimage("$blk.svg", $format." scale=$mscale ");
					}
				}
				else {
					error ("Cannot open $blk.piechart"); 
				}
					
			}
			elsif ($type eq 'gnuplot'){
				my $mscale=1000;
				if ($format=~/scale=([0-9]+)/){
					$mscale=$1;
					$format=~s/scale=[0-9]+//;
				}
				$mscale=$mscale/4;   # CHECK  for inline scale!
				my $density=1000;
				if (open my $PLOT, '>',"$blk.gnuplot"){
					print $PLOT 'set terminal postscript eps';
					print $PLOT "\nset output '$blk.eps'\n";
					for (@blocktext){
						chomp;
						if (/^".*"$/){
							s/^"//;
							s/"$//;
						}
						print $PLOT "$_\n";
					}
					close $PLOT;
					system("gnuplot $blk.gnuplot");
					#system ("eps2eps -B1  $blk.ps $blk.eps");
					if ($format=~/full/){
						outimage("$blk.eps", $format." full");
					}
					elsif ($format=~/half/){
						outimage("$blk.eps", $format." half ");
					}
					else {
						outimage("$blk.eps", $format." scale=$mscale ");
					}
				}
				else {
					error ("Cannot open $blk.gnuplot"); 
				}
			}
			elsif ($type eq 'music'){
					my $mscale=100;
					if ($format=~/scale=([0-9]+)/){
						$mscale=$1;
						$format=~s/scale=[0-9]+//;
					}
					$mscale=$mscale/2;
					system ("rm  -f $blk.eps");
					if (open (my $MUSIC, '>',"$blk.ly")){
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
							}
							print $MUSIC "$_\n";
						}
						#print $MUSIC "}\n";
						close $MUSIC;
						system ("cd block; lilypond --eps  -dresolution=500 -dpreview ../$blk.ly");
						system ("sed -i 's/\(%%BeginProcSet: .*\)/\1 0 0/' $blk.eps");
						system ("sed -i 's/%%IncludeResource: ProcSet (FontSetInit)/%%IncludeResource: ProcSet (FontSetInit) 0 0/' $blk.eps");


						outimage("$blk.eps", $format." scale=$mscale ");
					}
					else {
						error("Cannot open $blk");
					}
					$format='';
					$image='';
					undef @blocktext;
			
			}
			elsif ($type=~/texeqn/){
				my $mscale=100;
				if ($format=~/scale=([0-9]+)/){
					$mscale=$1;
					$format=~s/scale=[0-9]+//;
				}
				system ("rm  -f $blk.dvi");
				if (open (my $TEXEQN, '>',"$blk.tex")){
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
						}
						print $TEXEQN "$_\n";
					}
					print $TEXEQN "\\end{equation*}\n";
					print $TEXEQN "\\end{titlepage}\n";
					print $TEXEQN "\\end{document}\n";
					close $TEXEQN;
					system("cd block; echo '' |latex ../$blk.tex -output-directory=block -aux-directory=block > /dev/null 2>/dev/null");
					#system("convert  -trim  -density 500  $blk.dvi  $blk.eps");
					system("dvips -E -o $blk.eps $blk.dvi");
					outimage("$blk.eps", $format." scale=$mscale ");
				}
				$format='';
				$image='';
				undef @blocktext;
			}


			elsif ($type=~/^class(.*)/){ ######################LATER!
				$class=$1;
				output ('.br');
				output (".ev class$1");
				for (@blocktext){
					s/^"//;
					s/"$//;
					output($_);
				}
				output ('.br');
				output ('.ev');
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
			$name='';
			$image='';
			$format='';
			undef @blocktext;
			state_pop();
		} #end state block: end of block
		elsif ($input[$linenumber] =~/<caption>/){
			state_push('caption');
		}
		elsif ($input[$linenumber] =~/<type>/){
			state_push('type');
		}
		elsif ($input[$linenumber] =~/<image>/){
			state_push('image');
		}
		elsif ($input[$linenumber] =~/<name>/){
			state_push('name');
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
			$tablecol++;
			state_pop();
		}
		else {
			formatrequest();
		}
	}
	elsif ($state  eq 'row'){
		if ($input[$linenumber] =~/<\/row>/){
			output ('T}');
			if (defined ($variables{'tableheader'}) && ($variables{'tableheader'} eq 'yes') && ($firstrow==1)){
				output ('.TH');
				$firstrow=0;
			}
			$tablerow++;
			state_pop();
		}
		elsif ($input[$linenumber] =~/<cell/){
			undef @thiscell;
			if ($tablecol==0){
				output ('T{');
			}
			else {
				output ('T}	T{');
			}
			if ($thistable[$tablerow][$tablecol]=~/rowspan/){
				output 'span';
				output ('T}	T{');
			}
			state_push('cell');
		}
		else { error ("Table row: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'table'){
		if ($input[$linenumber] =~/<\/table>/){
			output ('.TE');
			output ('.sp 1');
			undef @thistable;
			state_pop();
		}
		elsif ($input[$linenumber] =~/<row>/){
			$tablecol=0;
			state_push('row');
		}
		else { error ("Table: text outside cells $input[$linenumber]");}
	}
	elsif ($state  eq 'paragraph'){
		if ($input[$linenumber] =~/<\/paragraph>/){
			$inline=0;
			if ($variables{'notes'}==0){
				$outatol=0;
				output ('.P');
			}
			elsif (($pcellopen>0) && ($variables{'notes'}==1)){
				output ('T}');
			}
			elsif($pcellopen>0) {
				output ('T}@T{');
				output('.na');
				if (($variables{'notes'}&2)>0){
					for (@sidenotes){ output ($_); }
					output('.ad');
					output ('T}');
				}
			}		# Table is always closed at the end.
			else {
				print STDERR "Already closed paragraph\n";
			}
			$pcellopen=0;
			state_pop();
		}
		elsif($input[$linenumber] =~/<leftnote>/){
			state_push('leftnote');
		}
		elsif ($input[$linenumber] =~/<side[note]*>/){
			state_push('side');
		}
		elsif ($input[$linenumber] =~/<text>/){}	# ignore the <text> tags for the moment
		elsif ($input[$linenumber] =~/<\/text>/){}	# this is not correct.
		else {
			formatrequest();
		}
	}
	elsif ($state  eq 'italicnospace'){
		if ($input[$linenumber] =~/<\/italicnospace>/){
			state_pop();
		}
		else {
			$outatol=1;
			output ("\\fI$input[$linenumber]\\fP");
			$outatol=1;
		}
	}
	elsif ($state  eq 'italic'){
		if ($input[$linenumber] =~/<\/italic>/){
			state_pop();
		}
		else {
			output (".I \"$input[$linenumber]\"");
		}
	}
	elsif ($state  eq 'bold'){
		if ($input[$linenumber] =~/<\/bold>/){
			state_pop();
		}
		else {
			output (".B \"$input[$linenumber]\"");
		}
	}
	elsif ($state  eq 'boldnospace'){
		if ($input[$linenumber] =~/<\/boldnospace>/){
			state_pop();
		}
		else {
			$outatol=1;
			output ("\\fB$input[$linenumber]\\fP");
			$outatol=1;
		}
	}
	elsif ($state  eq 'center'){
		if ($input[$linenumber] =~/<\/center>/){
			state_pop();
		}
		else {
			output (".ce 1");
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'subscript'){
		if ($input[$linenumber] =~/<\/subscript>/){
			state_pop();
		}
		else {
			$outatol=1;
			output ('\\*<',$input[$linenumber],'\\*>');
			$outatol=1;
		}
	}
	elsif ($state  eq 'font'){
		if ($input[$linenumber] =~/<\/font>/){
			state_pop();
		}
		else {
			my $fontfam;
			my $fontsize;
			my $dot='.';
			if ($fontname=~/([A-Za-z]*)([0-9]*)"*$/){
				$fontfam=$1;
				$fontsize=$2;
			}
			else {
				print STDERR "Cannot parse font name $fontname\n";
			}
			for (@fontmap){
				chomp;
				(my $in3font,my $rofffont,my $webfont)=split '	';
				if ($fontfam eq $in3font){
					$fontfam=$rofffont;
				}
			}
			my $vspace=$fontsize*1.5;
			if ($fontname=~/([A-Za-z]+)([0-9]+)"*$/){
				output ("$dot"."ft $fontfam","$dot"."ps $fontsize","$dot"."vs $vspace",$input[$linenumber],"$dot"."vs","$dot"."ps","$dot"."ft");
			}
			elsif ($fontname=~/([A-Za-z]+)"*$/){
				output ("$dot"."ft $fontfam",$input[$linenumber],"$dot"."ft");
			}
			elsif ($fontname=~/([0-9]+)"*$/){
				output ("$dot"."ps $fontsize",$input[$linenumber],"$dot"."ps");
			}
			else {
				print STDERR "Font specifier $fontname unknown\n";
			}
		}
	}
	elsif ($state  eq 'fixed'){
		if ($input[$linenumber] =~/<\/fixed>/){
			state_pop();
		}
		else {
			output ('.ft 6',$input[$linenumber],'.ft');
		}
	}
	elsif ($state  eq 'fixednospace'){
		if ($input[$linenumber] =~/<\/fixednospace>/){
			state_pop();
		}
		else {
			$outatol=1;
			output ("\\f6$input[$linenumber]\\f[]");
			$outatol=1;
		}
	}
	elsif ($state  eq 'break'){
		if ($input[$linenumber] =~/<\/break>/){
			output ('.br');
			state_pop();
		}
	}
	elsif ($state  eq 'blank'){
		if ($input[$linenumber] =~/<\/blank>/){
			output ('.br');
			output (' ');
			output ('.br');
			state_pop();
		}
	}
	elsif ($state  eq 'page'){
		if ($input[$linenumber] =~/<\/page>/){
			output ('.SK');
			state_pop();
		}
	}
	elsif ($state  eq 'space'){
		if ($input[$linenumber] =~/<\/space>/){
			#$outatol=1;
			for (my $i=0; $i<$qtyspace; $i++){
				output ('\0');
			}
			state_pop();
		}
		elsif (/([0-9][0-9]*)/){
			$qtyspace=$1;
		}
	}
	elsif ($state  eq 'hr'){
		if ($input[$linenumber] =~/<\/hr>/){
			output ('.br');
			output ('\\l\'15c\'');
			output ('.br');
			state_pop();
		}
	}
	elsif ($state  eq 'underline'){
		if ($input[$linenumber] =~/<\/underline>/){
			state_pop();
		}
		else {
			output (".underline \"$input[$linenumber]\"");
		}
	}
	elsif ($state  eq 'toc'){
		if ($input[$linenumber] =~/<\/toc>/){
			output ('.P');
			output ('.ps +0');
			output ('.ls 1');
			output ('.P');
			output ('');
			state_pop();
		}
		else {
			output ($input[$linenumber]);
		}
	}
	elsif ($state  eq 'lst'){
		if ($input[$linenumber] =~/<\/lst>/){
			output ('.br');
			state_pop();
		}
		else {
			$input[$linenumber] =~s/^"//g;
			$input[$linenumber] =~s/"$//g;
			output ('.br','.ft 6','.ps -2',$input[$linenumber],'.ps','.ft');
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
			if ($level==1){ $variables{"H1"}++;$variables{"H2"}=0;$variables{"H3"}=0;$variables{"H4"}=0;$variables{"H5"}=0;$variables{"H6"}=0;}
			if ($level==2){ $variables{"H2"}++;$variables{"H3"}=0;$variables{"H4"}=0;$variables{"H5"}=0;$variables{"H6"}=0;}
			if ($level==3){ $variables{"H3"}++;$variables{"H4"}=0;$variables{"H5"}=0;$variables{"H6"}=0;}
			if ($level==4){ $variables{"H4"}++;$variables{"H5"}=0;$variables{"H6"}=0;}
			if ($level==5){ $variables{"H5"}++;$variables{"H6"}=0;}
			if ($level==6){ $variables{"H6"}++;}
			if ($level==0){
				output (".ne 10v");
				output (".HU \"$text\"");
			}
			elsif ($seq eq ''){
				if ($level>0){
					output (".nr Hu $level");
				}
				my $room=10-$level+5;
				output (".ne $room"."v");
				output (".HU \"$text\"");
			}
			elsif ($variables{"appendix"}==-1){
				my $v=15/$level;
				output (".ne $v".'v');
				output (".H $level \"$text\"");
			}
			elsif (($variables{"H1"}>$variables{"appendix"}) && ($level==1)){
				my $v=15/$level;
				output (".ne $v".'v');
				output (".APP \"\" \"$text\"");
			}
			else {
				my $v=15/$level;
				output (".ne $v".'v');
				output (".H $level \"$text\"");
			}
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
	elsif ($state  eq 'blocktext'){
		if ($input[$linenumber] =~/<\/text>/){
			state_pop();
		}
		elsif ($input[$linenumber] =~/<\/blocktext>/){
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
				my $imgfile=basename($file);
				my $epsfile=basename($file);
				$epsfile=~s/\.[^.]*$/.eps/;
				$imgfile=~s/\.\w+$/.jpg/;
				system("rm -f '$imgfile'");
				system("ffmpeg -ss 00:00:05 -i '$file' -vframes 1 -q:v 2 '$imgfile' 2>/dev/null");
				outimage("$imgfile",'');
			}
			$file='';
			$text='';
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
	elsif ($state eq 'map'){
		if ($input[$linenumber] =~/<\/map>/){
			if ($file ne ''){
				outimage ($file,'full');
			}
			$file='';
			state_pop();
		}
		elsif ($input[$linenumber] =~/<file>/){
			$file='';
			state_push('file');
		}
		elsif ($input[$linenumber] =~/<field>/){
			$target='';
			$coord='';
			state_push('field');
		}
	}
	elsif ($state  eq 'field'){
		if ($input[$linenumber] =~/<\/field>/){
			state_pop();
		}
		# We ignore the target/coord section
	}
	elsif ($state  eq 'image'){
		if ($input[$linenumber] =~/<\/image>/){
			if ($file ne ''){
				if ($text eq ''){ $text=$file;}
				outimage($file,$format);
				$text='';
				$file='';
				$format='';
				$image='';
			}
			state_pop();
		}
		elsif ($input[$linenumber]=~/<text>/){
			state_push('text');
		}
		elsif ($input[$linenumber]=~/<caption>/){
			state_push('caption');
		}
		elsif ($input[$linenumber]=~/<format>/){
			state_push('format');
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
			chomp $caption;
			$caption=~s/^[ 	]*" *//;
			$caption=~s/ *"$//;
		}
	}
	elsif ($state  eq 'type'){
		if ($input[$linenumber] =~/<\/type>/){
			state_pop();
		}
		else {
			$type=$input[$linenumber];
			chomp $type;
			$type=~s/^[ 	]*" *//;
			$type=~s/ *"$//;
		}
	}
	elsif ($state  eq 'target'){
		if ($input[$linenumber] =~/<\/target>/){
			state_pop();
		}
		else {
			$target=$input[$linenumber];
		}
	}
	elsif ($state  eq 'name'){
		if ($input[$linenumber] =~/<\/name>/){
			$name=~s/^"//;
			$name=~s/"$//;
			state_pop();
		}
		else {
			$name=$input[$linenumber];
		}
	}
	elsif ($state  eq 'format'){
		if ($input[$linenumber] =~/<\/format>/){
			$format=~s/^"//;
			$format=~s/"$//;
			state_pop();
		}
		else {
			$format=$input[$linenumber];
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
			$ref=~s/^"//;
			$ref=~s/"$//;
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
		if ($input[$linenumber] =~/<\/headerfile>/){
			state_pop();
		}
		else {
			if ($input[$linenumber] =~/\.roff$/){
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
				if ($text eq ''){
					$text=$target;
				}
				output ('.ft 6','.ps -2',$text,'.ps','.ft');
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
			}
			if ($varname eq 'H1'){ output (".nr H1 $value"); }
			if ($varname eq 'H2'){ output (".nr H2 $value"); }
			if ($varname eq 'H3'){ output (".nr H3 $value"); }
			if ($varname eq 'H4'){ output (".nr H4 $value"); }
			if ($varname eq 'H5'){ output (".nr H5 $value"); }
			if ($varname eq 'H6'){ output (".nr H6 $value"); }
			if ($varname eq 'H7'){ output (".nr H7 $value"); }
			$value='';
			$varname='';
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

close_paratable();

if ($trace > 0){
	for my $k (keys %variables){
		print STDERR "# Variable $k = $variables{$k}\n";
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
else { print STDERR "in3tbl Cannot open in3charmap\n"; }

sub unxmlstr {
	(my $str)=@_;
	$str=~s/&lt;/</g;
	$str=~s/&gt;/>/g;
	$str=~s/&quot;/"/g;
	$str=~s/&apos;/'/g;
	$str=~s/&amp;/&/g;
	$str=~s/&#0092;/\\\\/g;
	for (@charmap){
		chomp;
		my $char;
		my $groff;
		my $html;
		($char,$groff,$html)=split '	';
		$char='UNDEFINED_CHAR' unless defined $char;
		$groff=$char unless defined $groff;
		$html=$char unless defined $html;
		if ($str=~/$char/){
			$str=~s/$char/$groff/g;
		}
		#elsif ($str=~/$html/){
		#$str=~s/$html/$groff/g;
		#}
	}
	return $str;
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


for my $i (0..$#output){
	$output[$i]=~s/&lt;/</g;
	$output[$i]=~s/&gt;/>/g;
	$output[$i]=~s/&quot;/"/g;
	$output[$i]=~s/&apos;/'/g;
	$output[$i]=~s/&amp;/&/g;
	$output[$i]=~s/&#0092;/\\\\/g;
	$output[$i]=~s/^%\.;/\\&./;
	$output[$i]=~s/%backslash;/\\\\/g;
}

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
			$output[$i]=~s/$char/$groff/g;
		}
		elsif ($output[$i]=~/$html/){
			$output[$i]=~s/$html/$groff/g;
		}
	}
}

for my $i (0..$#output){
	for my $i (0..$#output){
		if ($output[$i]=~/\%\%;/){
			$output[$i]=~s/\%\%;/\%/g;
		}
		elsif ($output[$i]=~/\%pct;/){
			$output[$i]=~s/\%pct;/\%/g;
		}
	}
}

if ( -f "stylesheet.mm" ) {
	if (open(my $STYLE,'<',"stylesheet.mm")){
		while (<$STYLE>){ print;}
		close $STYLE;
	}
	else {
		print STDERR "Cannot read stylesheet.mm\n";
	}
}
debug("variables{'COVER'}=$variables{'COVER'}\n");
debug("variables{'cover'}=$variables{'cover'}\n");
debug("variables{'title'}=$variables{'title'}\n");

if ($variables{'COVER'} eq 'yes'){
	print ".nr NOFOOT 1\n";
	print ".NOHEAD\n";
	if ($variables{'cover'} ne ''){
		my $cover=$variables{'cover'};
		$cover=~s/\.[^\.]+$/.eps/;
		if (! -f  "block/$cover"){
			system("in3fileconv $variables{'cover'} $cover");
		}
		print ".sp 1i\n";
		print ".PSPIC -C  block/$cover 6.25i\n";
		print ".PGNG\n";
		print ".SK\n";
	}
	print "\\&\n";
	print ".if e .SK\n";

	if ($variables{'title'}  eq '' ){
		print ".SK\n";
	}
	else {
		print ".PGNG\n";
		print ".ie o .bp\n";
		$variables{'title'}=unxmlstr($variables{'title'});
		$variables{'subtitle'}=unxmlstr($variables{'subtitle'});
		$variables{'author'}=unxmlstr($variables{'author'});
		print ".ps +10\n";

		print "\\~\n";
		print ".sp 4c\n";
		print ".ls 2\n";
		print ".ce 1\n";
		print "$variables{'title'}\n";
		print ".ps\n";
		print ".P\n";
		print ".ls 1\n";
		print ".sp 2c\n";
		print ".ps +8\n";
		print ".ls 2\n";
		print ".ce 1\n";
		print "$variables{'subtitle'}\n";
		print ".ps\n";
		print ".P\n";
		print ".ls 1\n";
		print ".sp 8c\n";
		print ".sp 1c\n";
		print ".ps +8\n";
		print ".ls 2\n";
		print ".ce 1\n";
		print "$variables{'author'}\n";
		print ".ps\n";
		print ".P\n";
		print ".ls 1\n";
		print ".PGNH\n";
		print ".SK\n";
		print ".DOHEAD\n";
		print ".nr P 0\n";
		print ".SK\n";
	}
	print ".DOHEAD\n";
	print ".nr NOFOOT 0\n";
}


my $a='';
for (@output){
	#s/&lt;/</g;
	#s/&gt;/>/g;
	#s/&quot;/"/g;
	#s/&apos;/'/g;
	#s/&amp;/&/g;
	#s/&#0092;/\\\\/g;
	#s/^%\.;/\\&./;
	#s/%backslash;/\\\\/g;
	if (($a eq '.P') && ($_ eq '.P')){}
	else {
		my $a=$_;
		while ($a=~/(.*)\\f\[(\w+)\](.+)\\f\[\](\s*)\\f\[\g2\](.*)/){
			$a="$1\\f\[$2]$3$4$5";
		}
		print "$a\n";
	}
}

if ($variables{'TOC'}>0){
	print ".TC\n";
}
