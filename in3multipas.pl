#!/usr/bin/perl
#INSTALL@ /usr/local/bin/in3multipass
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml

use File::Basename;
use strict;
use warnings;
use Text::CSV;

my $otrace=0;

# __     __         _       _     _
# \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___
#  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
#   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
#    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
#

my %variables;
	$variables{'COVER'}='no';
	$variables{'FIRST'}=0;
	$variables{'H1'}=0;
	$variables{'H2'}=0;
	$variables{'H3'}=0;
	$variables{'H4'}=0;
	$variables{'H5'}=0;
	$variables{'H6'}=0;
	$variables{'H7'}=0;
	$variables{'H8'}=0;
	$variables{'H9'}=0;
	$variables{'TOC'}=0;
	$variables{'appendix'}=90;
	$variables{'author'}='';
	$variables{'back'}=0;
	$variables{'blocknumber'}=0;
	$variables{'blocktype'}='';
	$variables{'cellalign'}='left';
	$variables{'cover'}='';
	$variables{'endnote_next'}=1;
	$variables{'endnotestyle'}='(#)';
	$variables{'endnoteheader'}='.hu1 Notes';
	$variables{'equation'}=0;
	$variables{'figure'}=0;
	$variables{'filename'}='stdin';
	$variables{'inlineemp'}=0;
	$variables{'keywords'}='';
	$variables{'leftnotechar'}='';
	$variables{'markdown'}=0;
	$variables{'metaname'}='meta.in';
	$variables{'notenumber'}=0;
	$variables{'notestring'}='(%NUM)';
	$variables{'seqpre'}=0;
	$variables{'seqimg'}=0;
	$variables{'seqpic'}=0;
	$variables{'seqeqn'}=0;
	$variables{'seqgnuplot'}=0;
	$variables{'seqmusic'}=0;
	$variables{'seqtexeqn'}=0;
	$variables{'seqequation'}=0;
	$variables{'seqfigure'}=0;
	$variables{'sidechar'}='*';
	$variables{'sidenumber'}=0;
	$variables{'sideref'}='';
	$variables{'sidesep'}=';';
	$variables{'subtitle'}='';
	$variables{'table'}=0;
	$variables{'title'}='';
	$variables{'date-nl'}=`date '+%d-%m-%Y'`;
	$variables{'date-us'}=`date '+%m-%d-%Y'`;
	$variables{'date-iso'}=`date '+%Y-%m-%d'`;

	$variables{'blockname'}=$variables{'filename'};
	$variables{'DEBUG'}=0;


my @passin;
my @passout;
my @inlinenr;
my @outlinenr;
my $passname='none';
my $inline=0;
my @supercipher=('&#8304;','&#0185;','&#0178;','&#0179;','&#8308;','&#8309;','&#8310;','&#8311;','&#8312;','&#8313;');
sub supernum{
	(my $in)=@_;
	my $retval='';
	while ($in>0){
		my $j=int($in/10);
		my $i=$in-10*$j;
		$retval=$supercipher[$i] . $retval;
		$in=$j;
	}
	return $retval;
}


my $progchar='-';

my $progressindicator=0;
sub progress {
	if ($progressindicator>0){
		if ($progchar eq '-'){$progchar='/'; }
		elsif ($progchar eq '/'){$progchar='|'; }
		elsif ($progchar eq '|'){$progchar='\\'; }
		elsif ($progchar eq '\\'){$progchar='-'; }
		print STDERR "$progchar\r";
	}
}

#  ___                   _                                       _
# |_ _|_ __  _ __  _   _| |_   _ __  _ __ ___   ___ ___  ___ ___(_)_ __   __ _
#  | || '_ \| '_ \| | | | __| | '_ \| '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` |
#  | || | | | |_) | |_| | |_  | |_) | | | (_) | (_|  __/\__ \__ \ | | | | (_| |
# |___|_| |_| .__/ \__,_|\__| | .__/|_|  \___/ \___\___||___/___/_|_| |_|\__, |
#           |_|               |_|                                        |___/

my @input;
my @realin;
my $lineindex=0;
for (@ARGV){
	if (/^--(meta.*)/){$variables{"metaname"}=$1;}
}

if ( -f "meta.in" ){
	my $file;
	if (-f $variables{"metaname"}){
		$file=$variables{"metaname"};
	}
	else {
		$file="meta.in";
	}
	$variables{'filename'}=$file;
	if (open(my $IN,'<',$file)){
		while (<$IN>){
			chomp;
			push @realin,$_;
			push @passin,$_;
			push @inlinenr,"$variables{'filename'}:$lineindex";
			if ($otrace>0){ print "READ LINE FROM $file: $_\n";}
			$lineindex++;
		}
		push @realin,'';
		push @passin,$_;
		push @inlinenr,"$variables{'filename'}:$lineindex";
		close $IN;
	}
}
if ($#ARGV<0){
	$variables{'filename'}='stdin';
	while (<>){
		push @realin,$_;
		push @passin,$_;
		push @inlinenr,"$variables{'filename'}:$lineindex";
		$lineindex++;
	}
}
else {
	my $what='';
	for (@ARGV){
		if ($otrace>0){ print STDERR "ARGUMENT: $_\n";}
		if ($what eq ''){
			if (/^--$/){ while (<STDIN>){push @input,$_;}}
			elsif (/^--debug([0-9]+)/){ $variables{"DEBUG"}=$1; }
			elsif (/^--debug=([0-9]+)/){ $variables{"DEBUG"}=$1; }
			elsif (/^-d$/){$what='debug';}
			elsif (/^--debug$/){$what='debug';}
			elsif (/^-c([0-9]+)/){ $variables{"H1"}=$1-1;}
			elsif (/^--chapter([0-9]+)/){ $variables{"H1"}=$1-1;}
			elsif (/^--chapter=([0-9]+)/){ $variables{"H1"}=$1-1;}
			elsif (/^-c$/){$what='chapter';}
			elsif (/^--chapter$/){$what='chapter';}
			elsif (/^-i([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^--interpret([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^--interpret=([0-9]+)/){ $variables{"interpret"}=$1;}
			elsif (/^-i$/){$what='interpret';}
			elsif (/^--interpret$/){$what='interpret';}
			elsif (/^-t/){$otrace=1;}
			elsif (/^--trace/){$otrace=1;}
			elsif (/^-m/){$variables{"markdown"}=1;}
			elsif (/^--markdown/){$variables{"markdown"}=1;}
			elsif (/^--(meta.*)/){$variables{"metaname"}=$1;}
			elsif (/^-+h/){ hellup(); }
			elsif (/^-p/){ $progressindicator=1;}
			elsif (/^-/){ print STDERR "$_ is not known as a flag; ignored.\n";}
			else {
				my $file=$_;
				$variables{'filename'}=$file;
				if ($otrace>0){ print "Processing $file\n";}
				my $ch;	# Chapter number from filename
				if ($file=~/^([0-9]+)_/){$ch=$1-1;} else {$ch=0;}
				if (-f "meta.$file"){
					if (open(my $IN,'<',"meta.$file")){
						while (<$IN>){
							chomp;
							push @realin,$_;
							push @passin,$_;
							push @inlinenr,"$variables{'filename'}:$lineindex";
							if ($otrace>0){ print "READ LINE FROM meta.$file: $_\n";}
							$lineindex++;
						}
						push @realin,'';
						push @passin,$_;
						push @inlinenr,"$variables{'filename'}:$lineindex";
						close $IN;
					}
				}
				if (open(my $IN,'<',$file)){
					if ($ch>0){
						if ($otrace>0){ print "Chapter:$ch\n";}
						push @passin,".set H1 $ch";
						push @passin,'';
						$variables{"H1"}=$ch;
						push @inlinenr,"-1";
						push @inlinenr,"-1";
					}
					while (<$IN>){
						chomp;
						push @realin,$_;
						push @passin,$_;
						push @inlinenr,"$variables{'filename'}:$lineindex";
						if ($otrace>0){ print "READ LINE FROM $file: $_\n";}
						$lineindex++;
					}
					push @realin,'';
					push @passin,$_;
					push @inlinenr,"$variables{'filename'}:$lineindex";
					close $IN;
				}
				else {print STDERR "Cannot open $_; ignored.\n";}
			}
		}
		elsif ($what eq 'debug'){
			if (/([0-9]+)/){ $variables{"DEBUG"}=$1;}
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
}

if ($variables{'DEBUG'} > 0){
	print STDERR "DEBUG LEVEL $variables{'DEBUG'}\n";
}

if ($otrace>0){
	for (my $i=0; $i<+$#passin;$i++){
		$passin[$i]='' unless defined $passin[$i];
		print "INPUT: $inlinenr[$i] '$passin[$i]'\n";
	}
}
#                                   _   _                         _
#  ___ _   _ _ __  _ __   ___  _ __| |_(_)_ __   __ _   ___ _   _| |__  ___
# / __| | | | '_ \| '_ \ / _ \| '__| __| | '_ \ / _` | / __| | | | '_ \/ __|
# \__ \ |_| | |_) | |_) | (_) | |  | |_| | | | | (_| | \__ \ |_| | |_) \__ \
# |___/\__,_| .__/| .__/ \___/|_|   \__|_|_| |_|\__, | |___/\__,_|_.__/|___/
#           |_|   |_|                           |___/

my $deb_supporting=1; 	# Supporting subroutines
my $deb_pipetable=2; 	# pipe table debugging
my $deb_markup=4;		# Mark-up debugging
sub debug {
	(my $level,my $str)=@_;
	chomp $str;
	if (($variables{'DEBUG'} & $level)>0){
		print STDERR  "$passname: $str\n";
		
	}
}
sub pushout {
	(my $txt)=@_;
	if (defined $txt){}
	else {
		$txt='' unless defined $txt;
		debug($deb_supporting,"\$txt is undefined");
	}
	push @passout,$txt;
	push @outlinenr,$inlinenr[$lineindex];
	if ($otrace>0){
		my $i=0;
		#print "$passname: $txt\n";
		if ($inlinenr[$lineindex]=~/:([0-9]*)/){$i=$1;}
		my $t1=$realin[$i];
		my $t2=$txt;
		$t1=~s/	/    /g;
		$t2=~s/	/    /g;
		printf("TRACE-%s-%s  %-45.45s | %-20.20s |%-45.45s\n",$variables{'filename'},$passname,$t1,$inlinenr[$i],$t2);
	}
}
sub addout {
	(my $txt)=@_;
	if (defined $txt){}
	else {
		$txt='' unless defined $txt;
		debug($deb_supporting,"\$txt is undefined");
	}
	$passout[-1] .= $txt;
}
	


sub endpass {
	undef @passin;
	undef @inlinenr;
	@passin=@passout;
	@inlinenr=@outlinenr;
	undef @passout;
	undef @outlinenr;
	$lineindex=-1;
}




sub varset{
	(my $line)=@_;
	$line='' unless defined $line;
	if (0==1){}
	elsif ($line=~/^\.appendix *([0-9][0-9]*)/){
		$variables{'appendix'}=$1;
	}
	elsif ($line=~/^\.appendix/){
		print STDERR "varset appeix: %line\n";
		$variables{'appendix'}=1;
	}
	elsif ($line=~/^\.author *(.*)/){
		$variables{'author'}=$1;
	}
	elsif ($line=~/^\.back/){
		$variables{'back'}=1;
	}
	elsif ($line=~/^\.contents/){
		$variables{'TOC'}=1;
	}
	elsif ($line=~/^\.COVER *(.*)/){
		$variables{'COVER'}='yes';
	}
	elsif ($line=~/^\.cover *(.*)/){
		$variables{'cover'}=$1;
	}
	elsif ($line=~/^\.keywords *(.*)/){
		$variables{'keywords'}=$1;
	}
	elsif ($line=~/^\.set *([\w]+) *(.*)/){
		$variables{$1}=$2;
	}
	elsif ($line=~/^\.side  *char  *(.*)/){
		$variables{'sidechar'}=$1;
	}
	elsif ($line=~/^\.side  *separator  *(.*)/){
		$variables{'sidesep'}=$1;
	}
	elsif ($line=~/^\.subtitle *(.*)/){
		$variables{'subtitle'}=$1;
	}
	elsif ($line=~/^\.title *(.*)/){
		$variables{'title'}=$1;
	}
	elsif ($line=~/^\.TOC$/){
		$variables{'TOC'}=1;
	}
	if ($inlinenr[$lineindex]=~/(.*):/){$variables{'filename'}=$1;}
}
sub varpush{
	(my $var,my $val)=@_;
	pushout('<set>');
	pushout('<variable>');
	pushout($var);
	pushout('</variable>');
	pushout('<value>');
	pushout($val);
	pushout('</value>');
	pushout('</set>');
}

#        _            _        _     _      
#  _ __ (_)_ __   ___| |_ __ _| |__ | | ___ 
# | '_ \| | '_ \ / _ \ __/ _` | '_ \| |/ _ \
# | |_) | | |_) |  __/ || (_| | |_) | |  __/
# | .__/|_| .__/ \___|\__\__,_|_.__/|_|\___|
# |_|     |_|              
sub in3length {
	(my $instring)=@_;
	my @string;
	while (length $instring>0){
		if ($instring=~/^(\&\w+;)(.*)/){ push @string, $1; $instring=$2; }
		#elsif ($instring=~/^(\%\w+;)(.*)/){ push @string, $1; $instring=$2; }
		elsif ($instring=~/^(.)(.*)/){ push @string, $1; $instring=$2; }
		else { print STDERR "in3length: parsing $instring from $_[0] failed\n"; }
	}
	my $retval=$#string;
	undef @string;
	return $retval;
}
sub in3substr {
	(my $instring,my $from,my $l)=@_;
	my $debstr=$instring;
	my @string;
	while (length $instring>0){
		if ($instring=~/^(\&\w+;)(.*)/){ push @string, $1; $instring=$2; }
		#elsif ($instring=~/^(\%\w+;)(.*)/){ push @string, $1; $instring=$2; }
		elsif ($instring=~/^(.)(.*)/){ push @string, $1; $instring=$2; }
		else {
			debug ($deb_pipetable, "in3length: parsing $instring from $_[0] failed\n");
		}
	}
	if ($from+$l >$#string+1){
		debug ($deb_pipetable, "in3substr: from=$from l=$l but $debstr = $#string\n");
	}
	my $retval='';
	for (my $i=0; ($i<$l) && ($from+$i<=$#string);$i++){
		$retval=$retval . $string[$from+$i] if defined $string[$from+$i];
	}
	undef @string;
	return $retval;
}
sub in3setsubstr {
	(my $instring,my $position,my $tochar)=@_;
	my @string;
	my $debstr=$instring;
	while (length $instring>0){
		if ($instring=~/^(\&\w+;)(.*)/){ push @string, $1; $instring=$2; }
		#elsif ($instring=~/^(\%\w+;)(.*)/){ push @string, $1; $instring=$2; }
		elsif ($instring=~/^(.)(.*)/){ push @string, $1; $instring=$2; }
		else {
			debug ($deb_pipetable, "in3setsubstr parsing $instring from $_[0] failed\n");
		}
	}
	if ($position>$#string){
		debug ($deb_pipetable, "in3setsubstr: position=$position, but $debstr = $#string\n");
	}
	$string[$position]=$tochar;
	my $retval='';
	for (@string){
		$retval=$retval . $_ if defined $_;
	}
	undef @string;
	return $retval;
}


my @pipetable;
my $ptMAX=1024;
sub pipetablepass{
	$passname='pipetablepass';
	my $prevline='';
	my $intable=0;
	my $inlist=0;
	my $inblock=0;
	my $inpre=0;
	my $inptable=0;
	foreach (@passin){
		varset($_);
		chomp;
		$lineindex++;
		$_='' unless defined $_;
		if ($inpre==1){
			pushout ($_);
			if (/^\.pre/){ $inpre=0;}
		}
		elsif ($inblock==1){
			pushout ($_);
			if (/^\.block/){ $inblock=0;}
		}
		elsif (/^$/){
			if ($inptable == 1){
				my $cols=' ' x $ptMAX;
				for (@pipetable){
					my $line=$_;
					for (my $i=0; $i<in3length($line)+1; $i++){
						my $thischar=in3substr($line,$i,1);
						if ($thischar eq '|'){
							debug ($deb_pipetable, "thischar=$thischar i=$i");
							substr($cols,$i,1)='|';
						}
					}
				}
				$cols=~s/ *$//;
				debug ($deb_pipetable, "Cols=$cols");
				my $rows=' ' x $ptMAX;
				for (my $i=0;$i<=$#pipetable;$i++){
					if ($pipetable[$i]=~/----/){
						substr($rows,$i,1)='-';
					}
				}
				$rows=~s/ *$//;
				debug ($deb_pipetable, "Rows=$rows");
				my $celltext='';
				my $tableline='';
				for (my $i=0;  $i<$#pipetable;$i++){
					if ($pipetable[$i]=~/^[-\|]*$/){}   # drop all lines that are just drawing characters
					else {
						debug ($deb_pipetable, "Examining $pipetable[$i]");
						my $j=0;
						my $lencol=length($cols);
						while ($j<length($cols)-1){
							debug ($deb_pipetable, "j=$j length cols=$lencol");
							my $chr=in3substr($pipetable[$i],$j,1);
							if ($chr=~/[\|-]/){}
							else {
								my $celltext='';
								my $top=$i;
								my $bottom=$i;
								my $left=$j;
								my $right=$j;
								while (
									($right < length ($cols)) &&
								   	!(in3substr($pipetable[$i],$right,1)=~/\|/) &&
								   	!(in3substr($pipetable[$i],$right,4)=~/----/)
								){
									my $chr=in3substr($pipetable[$i],$right,1);
									debug ($deb_pipetable, "cellwidth $pipetable[$i] r=$right c=$chr");
									$right++;
								}
								my $hlen=$right-$left;
								while (
									($bottom < length ($rows)) &&
								   	!(in3substr($pipetable[$bottom],$left,1)=~/\|/) &&
								   	!(in3substr($pipetable[$bottom],$left,4)=~/----/)
								){
									my $chr=in3substr($pipetable[$bottom],$left,1);
									debug ($deb_pipetable, "cellheight $pipetable[$bottom] b=$bottom c=$chr l=$left");
									$bottom++;
								}
								my $vlen=$bottom-$top;
								debug ($deb_pipetable, "left=$left, right=$right, top=$top, bottom=$bottom hlen=$hlen vlen=$vlen");
								for (my $l=$top; $l<$bottom;$l++){
									if ($celltext eq ''){
										$celltext= in3substr($pipetable[$l],$left,$hlen);
									}
									else {
										$celltext=$celltext . '%n%' .  in3substr($pipetable[$l],$left,$hlen);
									}
								}
								$celltext=~s/^ *//;
								$celltext=~s/ *$//;
								$celltext=~s/ *%n% */%n%/g;
								while ($celltext=~/^%n%/){$celltext=~s/^%n%//;}
								while ($celltext=~/%n%$/){$celltext=~s/%n%$//;}
								my $cs=(substr($cols,$left,$hlen)=~tr/|//)+1;
								my $rs=(substr($rows,$top,$vlen)=~tr/-//)+1;
								$tableline=$tableline .  "	";
								if ($cs>1){$tableline=$tableline .  "&lt;cs=$cs&gt;&lt;format=center&gt;";}
								if ($rs>1){$tableline=$tableline .  "&lt;rs=$rs&gt;";}
								$tableline=$tableline .  $celltext;
								for (my $l=$top; $l<$bottom;$l++){
									for (my $m=$left; $m<$right;$m++){
										$pipetable[$l]=in3setsubstr($pipetable[$l],$m,'|');
									}
								}
								$j=$j+$hlen;
							}
							$j++;
						}
						pushout ($tableline) unless ($tableline eq '');
						$tableline='';
					}
				}
				$inptable=0;
				undef @pipetable;
			}
			else {
				pushout ($_);
			}
		}
		elsif (/^\|-/){
			$inptable=1;
			push @pipetable,$_;
		}
		elsif ($inptable == 1){

			push @pipetable,$_;
		}
		else {
			if (/^\.pre/){$inpre=1;}
			if (/^\.block /){$inblock =1;}
			pushout ($_);
		}
		$prevline=$_;
	}
	endpass();
}

#      _                               _   _
#   __| | ___ _ __  _ __ ___  ___ __ _| |_(_) ___  _ __  ___
#  / _` |/ _ \ '_ \| '__/ _ \/ __/ _` | __| |/ _ \| '_ \/ __|
# | (_| |  __/ |_) | | |  __/ (_| (_| | |_| | (_) | | | \__ \
#  \__,_|\___| .__/|_|  \___|\___\__,_|\__|_|\___/|_| |_|___/
#            |_|
sub depricatepass{
	$passname='depricatepass';
	my $prevline='';
	my $intable=0;
	my $inlist=0;
	foreach (@passin){
		$lineindex++;
		$_='' unless defined $_;
		if (/^$/){
			$intable=0;
			$inlist=0;
		}
		elsif (/^[ 	]*$/){
			print STDERR "Near $inlinenr[$lineindex] line with only tabs and spaces\n";
		}

		varset($_);
		chomp;
		if (/^\.$/){	#deprecated . to separate paragraphs
			pushout ('.P');
		}
		elsif (/^\.head/){	#deprecated header without blankline before
			if ($prevline ne ''){
				pushout ('');
			}
			pushout ($_);
		}
		#elsif (/[	 ]*^[-#@] /){
		#	if ($inlist==0){
		#		if ($prevline ne ''){
		#			pushout ('');
		#		}
		#	}
		#	$inlist=1;
		#	pushout ($_);
		#}
		#elsif (/^	/){	#deprecated table directly against text
		#	if ($intable==0){
		#		if ($prevline ne ''){
		#			pushout ('');
		#		}
		#	}
		#	$intable=1;
		#	pushout ($_);
		#}
		elsif (/^\.h[0-9]/){	#deprecated header without blankline before
			if ($inlist==0){
				if ($prevline ne ''){
					pushout ('');
				}
			}
			$inlist=1;
			pushout ($_);
		}
		else {
			pushout ($_);
		}
		$prevline=$_;
	}
	endpass();
}
#                 _       _  __
# __  ___ __ ___ | |     (_)/ _|_   _   _ __   __ _ ___ ___
# \ \/ / '_ ` _ \| |_____| | |_| | | | | '_ \ / _` / __/ __|
#  >  <| | | | | | |_____| |  _| |_| | | |_) | (_| \__ \__ \
# /_/\_\_| |_| |_|_|     |_|_|  \__, | | .__/ \__,_|___/___/
#                               |___/  |_|

my %pcttranslate;
sub xmlifypass {
	my $from='';
	my $dest='';
	if (open (my $PCT, "<", "/usr/local/share/in3/in3charmap11" )){
		while (<$PCT>){
			chomp;
			s/#.*//;
			($from, $dest)=split '	';
			if ((defined $from) && (defined $dest)){
				if ( "$from" ne ""){
					$pcttranslate{$from}=$dest;
				}
			}
		}
		close $PCT;
	}
	else {
		$pcttranslate{'€'}='%eu;';
	}



	$passname='xmlifypass';
	foreach (@passin){
		$lineindex++;
		varset($_);
		chomp;
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		s/"/&quot;/g;
		s/'/&apos;/g;
		s/\\/&#0092;/g;
		my $key;
		foreach $key (keys %pcttranslate){
			s/$key/$pcttranslate{$key}/g;
		}
		pushout ($_);
	}
	endpass();
}

#                  _       _     _
# __   ____ _ _ __(_) __ _| |__ | | ___  ___   _ __   __ _ ___ ___
# \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __| | '_ \ / _` / __/ __|
#  \ V / (_| | |  | | (_| | |_) | |  __/\__ \ | |_) | (_| \__ \__ \
#   \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/ | .__/ \__,_|___/___/
#                                             |_|
# Extract variables from the document and fill-in dumpvars                                             
sub varpass{
	$passname='varpass';
	for (@passin){
		$lineindex++;
		if (/^\.title *(.*)/){ varpush('title',$1); }
		elsif (/^\.subtitle *(.*)/){ varpush('subtitle',$1); }
		elsif (/^\.keywords *(.*)/){ varpush('keywords',$1); }
		elsif (/^\.cover *(.*)/){ varpush('cover',$1); }
		elsif (/^\.author *(.*)/){ varpush('author',$1); }
		elsif (/^\.appendix *(.*)/){ varpush('appendix',$1); }
		elsif (/^\.back *(.*)/){ varpush('back',1); }
		elsif (/^\.TOC$/){ varpush('TOC',1); }
		elsif (/^\.COVER$/){ varpush('COVER','yes'); }
		elsif (/^\.FIRST$/){ varpush('FIRST',1); }
		elsif (/^\.contents/){ varpush('TOC',1); }
		elsif (/^\.side *separator *(.*)/){varpush('sidesep',$1);}
		elsif (/^\.side *char *(.*)/){varpush('sidechar',$1);}
		elsif (/^\.set *([\w]+) *(.*)/){ varpush($1,$2); }
		elsif (/^\.dumpvar (.*)/){ pushout($variables{$1});}
		elsif (/^\.dumpvar/){
			pushout('<block>');
			pushout('<type>');
			pushout('"lst"');
			pushout('</type>');
			pushout('<-- dumpvar -->');
			pushout('<text>');
			for (keys %variables){
				pushout("\"$_=$variables{$_}\"");
			}
			pushout('</text>');
			pushout('</text>');
			pushout('</block>');
		}
		elsif (/^\.merge (.*)/){
			pushout('<merge>');
			pushout("$1");
			pushout('</merge>');
		}
		else { pushout($_); }
	}
	endpass();
}

#  _            _           _
# (_)_ __   ___| |_   _  __| | ___
# | | '_ \ / __| | | | |/ _` |/ _ \
# | | | | | (__| | |_| | (_| |  __/
# |_|_| |_|\___|_|\__,_|\__,_|\___|
#
sub includepass {
	$passname='includepass';
	for (@passin){
		$_='' unless defined $_;
		chomp;
		varset($_);
		$lineindex++;
		varset($_);
		if (/^\.headerlink/){}
		elsif (/^\.in3charmap/){}
		elsif (/^\.header/){
			pushout('<header>');
			pushout('</header>');
		}
		elsif (/^\.include  *([^ ]*)/) {
			my $incl=$1;
			if (open(my $INC,'<',$incl)){
				while (my $inclline=<$INC>){
					pushout($inclline);
				}
				close $INC;
			}
		}
		elsif (/^\.csvfile/){
			my $csv_file_name='NO_FILE_NAME';
			my $csv_separator=',';
			if (/^\.csvfile  *(.*)  *([,;:|])/){
				$csv_file_name=$1;
				$csv_separator=$2;
			}
			elsif (/^\.csvfile  *(.*)/){
				$csv_file_name=$1;
			}
			if (open (my $CSVFILE,'<',$csv_file_name)){
				pushout('<table>');
				my $csvlines=0;
				while (my $csv_string=<$CSVFILE>){
					my @csvfields=();
					my $csv=Text::CSV->new({ sep_char => $csv_separator });
					my $rowcells=0;
					if ($csv->parse($csv_string)) {
						pushout('<row>');
						@csvfields=$csv->fields();
						for (@csvfields){
							pushout('<cell format="left">');
							pushout($_);
							pushout('</cell>');
						}
						$rowcells++;
						pushout('</row>');
					}
					$csvlines++;
				}
				if ($csvlines==0){
					pushout('<row>');
					pushout('<cell format="left">');
					pushout('Empty file');
					pushout('</cell>');
					pushout('</row>');
				}
				pushout('</table>');
				close $CSVFILE;
			}
		}
		else { pushout($_); }
	}
	endpass();
}

#                       _       _
#  _ __ ___   __ _ _ __| | ____| | _____      ___ __
# | '_ ` _ \ / _` | '__| |/ / _` |/ _ \ \ /\ / / '_ \
# | | | | | | (_| | |  |   < (_| | (_) \ V  V /| | | |
# |_| |_| |_|\__,_|_|  |_|\_\__,_|\___/ \_/\_/ |_| |_|
#
#   __                            _   _   _
#  / _| ___  _ __ _ __ ___   __ _| |_| |_(_)_ __   __ _
# | |_ / _ \| '__| '_ ` _ \ / _` | __| __| | '_ \ / _` |
# |  _| (_) | |  | | | | | | (_| | |_| |_| | | | | (_| |
# |_|  \___/|_|  |_| |_| |_|\__,_|\__|\__|_|_| |_|\__, |
#                                                 |___/

sub mdformatpass {
	$passname='mdformatpass';
	for (@passin){
		my $line=$_;
		chomp;
		varset($_);
		$lineindex++;
		my $mx=0;
		my @mdline1;
		my @mdline2;
		push @mdline1,$line;
		if ($variables{'markdown'}+$variables{'inlineemp'}>0){
			my $repl=1;
			while ($repl>0){
				$repl=0;
				for (@mdline1){
					if (/^(.*) \*([^*]+)\* (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<bold>';
						push @mdline2,$2;
						push @mdline2,'</bold>';
						push @mdline2,$3;
					}
					elsif (/^\*([^*]+)\* (.*)/){
						$repl++;
						push @mdline2,'<bold>';
						push @mdline2,$1;
						push @mdline2,'</bold>';
						push @mdline2,$2;
					}
					elsif (/^(.*) \*([^*]+)\*$/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<bold>';
						push @mdline2,$2;
						push @mdline2,'</bold>';
					}
					elsif (/^(.*) _([^_]+)_ (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<underline>';
						push @mdline2,$2;
						push @mdline2,'</underline>';
						push @mdline2,$3;
					}
					elsif (/^_([^_]+)_ (.*)/){
						$repl++;
						push @mdline2,'<underline>';
						push @mdline2,$1;
						push @mdline2,'</underline>';
						push @mdline2,$2;
					}
					elsif (/^(.*) _([^_]+)_/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<underline>';
						push @mdline2,$2;
						push @mdline2,'</underline>';
					}
					elsif (/^(.*) `([^`]+)` (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<fixed>';
						push @mdline2,$2;
						push @mdline2,'</fixed>';
						push @mdline2,$3;
					}
					elsif (/^`([^`]+)` (.*)/){
						$repl++;
						push @mdline2,'<fixed>';
						push @mdline2,$1;
						push @mdline2,'</fixed>';
						push @mdline2,$2;
					}
					elsif (/^(.*) `([^`]+)`/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<fixed>';
						push @mdline2,$2;
						push @mdline2,'</fixed>';
					}
					elsif (/^(.*) \/\/([^\/]+)\/\/ (.*)/){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<italic>';
						push @mdline2,$2;
						push @mdline2,'</italic>';
						push @mdline2,$3;
					}
					elsif (/^\/\/([^\/]+)\/\/ (.*)/){
						$repl++;
						push @mdline2,'<italic>';
						push @mdline2,$1;
						push @mdline2,'</italic>';
						push @mdline2,$2;
					}
					elsif (/^(.*) \/\/([^\/]+)\/\//){
						$repl++;
						push @mdline2,$1;
						push @mdline2,'<italic>';
						push @mdline2,$2;
						push @mdline2,'</italic>';
					}
					else {
						push @mdline2,$_;
					}
				} #end md format loop
				undef @mdline1;
				@mdline1=@mdline2;
				undef @mdline2;
			} # while replaced loop
			for (@mdline1){
				pushout($_);
			}
		}
		else {
			pushout($line);
		}
	}
	endpass();
}

#                       _       _
#  _ __ ___   __ _ _ __| | ____| | _____      ___ __
# | '_ ` _ \ / _` | '__| |/ / _` |/ _ \ \ /\ / / '_ \
# | | | | | | (_| | |  |   < (_| | (_) \ V  V /| | | |
# |_| |_| |_|\__,_|_|  |_|\_\__,_|\___/ \_/\_/ |_| |_|
#
#                      _                   _
#   ___ ___  _ __  ___| |_ _ __ _   _  ___| |_ ___
#  / __/ _ \| '_ \/ __| __| '__| | | |/ __| __/ __|
# | (_| (_) | | | \__ \ |_| |  | |_| | (__| |_\__ \
#  \___\___/|_| |_|___/\__|_|   \__,_|\___|\__|___/
#
sub markdownpass {
	$passname='markdownpass';
	for (@passin){
		my $line=$_;
		$line='' unless defined $line;
		chomp;
		varset($_);
		$lineindex++;
		my $mx=0;
		if ($variables{'markdown'}>0){
			$mx=$#passout;
			#ATX headings
			if (/^ {0,3}###### /){ s/^ {0,3}######/.h6/;s/ *######$//; pushout($_); debug ($deb_markup,'atx h6');}
			elsif (/^ {0,3}##### /){ s/^ {0,3}#####/.h5/;s/ *#####$//; pushout($_); debug ($deb_markup,'atx h5');}
			elsif (/^ {0,3}#### /){ s/^ {0,3}####/.h4/;s/ *####$//; pushout($_); debug ($deb_markup,'atx h4');}
			elsif (/^ {0,3}### /){ s/^ {0,3}###/.h3/;s/ *###$//; pushout($_); debug ($deb_markup,'atx h3');}
			elsif (/^ {0,3}## /){ s/^ {0,3}##/.h2/;s/ *##$//; pushout($_); debug ($deb_markup,'atx h2');}
			elsif (/^ {0,3}#.*#$/){ s/^ {0,3}#/.h1/;s/ *#$//; pushout($_); debug ($deb_markup,'atx h1');}
			# Setex heading and thematic breaks
			elsif (/^ {0,3}===/){
				debug ($deb_markup,'setex h1');
				if ($passout[$mx]=~/^\./){ pushout($line);}
				elsif ($passout[$mx]=~/^\-/){ pushout($line);}
				elsif ($passout[$mx]=~/^$/){ pushout($line);}
				else { $passout[$mx]=".h1 $passout[$mx]";}
			}
			elsif (/^ {0,3}---/){
				debug ($deb_markup,'setex h2');
				if ($passout[$mx]=~/^\./){ pushout('.hr');}
				elsif ($passout[$mx]=~/^\-/){ pushout('.hr');}
				elsif ($passout[$mx]=~/^$/){ pushout('.hr');}
				else { $passout[$mx]=".h2 $passout[$mx]";}
			}
			# pre-formatted blocks
			elsif (/^```/){ pushout('.pre');debug ($deb_markup,'pre');}
			#elsif (/^>(.*)/){ pushout(".lst $1");debug ($deb_markup,'lst');} # interferes with Liliypond
			# lists
			elsif (/^(\t)*[0-9]+\.[ 	](.*)/){  pushout("$1# $2"); debug ($deb_markup,'numlist');}
			elsif (/^(\t)*[a-z]\.[ 	](.*)/){  pushout("$1@ $2"); debug ($deb_markup,'alphalist');}
			elsif (/^(\t*)-[ 	](.*)/){  pushout("$1- $2"); debug ($deb_markup,'dashlist');}
			else { pushout($line); debug ($deb_markup,'rest output'); }
		}
		else { pushout($line);debug ($deb_markup,"markdown=0 for $line");}
	}
	endpass();
}

		


#  _ __ ___   __ _ _ __  
# | '_ ` _ \ / _` | '_ \ 
# | | | | | | (_| | |_) |
# |_| |_| |_|\__,_| .__/ 
#                 |_|
#

sub mappass {
	$passname='mappass';
	my $inmap=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if ($inmap==0){
			if (/^\.map/){
				pushout('<map>');
				$inmap=1;
				if (/^\.map image (.*)/){
					pushout('<file>');
					pushout($1);
					pushout('</file>');
				}
				elsif (/^\.map field ([^ ]+) ([,0123456789]+)/){
					pushout('<field>');
					pushout('<target>');
					pushout($1);
					pushout('</target>');
					pushout('<coord>');
					pushout($2);
					pushout('</coord>');
					pushout('</field>');
				}
			}
			else { pushout($_); }
		}
		else {
			if (/^\.map image (.*)/){
				pushout('<file>');
				pushout($1);
				pushout('</file>');
			}
			elsif (/^\.map field ([^ ]+) ([,0123456789]+)/){
				pushout('<field>');
				pushout('<target>');
				pushout($1);
				pushout('</target>');
				pushout('<coord>');
				pushout($2);
				pushout('</coord>');
				pushout('</field>');
			}
			else {
				pushout('</map>');
				pushout($_);
				$inmap=0;
			}
		}
	}
	endpass();
}


#                 _             _            
#   ___ _ __   __| |_ __   ___ | |_ ___  ___ 
#  / _ \ '_ \ / _` | '_ \ / _ \| __/ _ \/ __|
# |  __/ | | | (_| | | | | (_) | ||  __/\__ \
#  \___|_| |_|\__,_|_| |_|\___/ \__\___||___/
#  
my @endnotes;
my $endnote_nr=0;
my $endnote_flag=0;
my $endnotestyle=$variables{'endnotestyle'};


sub endnotepass {
	$passname='endnotepass';
	my $in_endnote=0;
	for (@passin){
		varset($_);
		$lineindex++;
		my $line=$_;
		$line='' unless defined $line;
		if ($in_endnote==0){
			if ($line=~/^\.set  *endnotestyle *(..*)/){
				$endnotestyle=$1
			}
			elsif ($line=~/^\.set  *endnote_nr *(..*)/){
				$endnote_nr=$1
			}
			elsif ($line=~/^\.endnote  *start/){
				$in_endnote=1;
				$variables{'endnote_prev'}=$endnote_nr;
				$endnote_nr++;
				$endnote_flag++;
				my $gonote="go$endnote_flag";
				my $backnote="back$endnote_flag";
				$variables{'endnote_nr'}=$endnote_nr;
				$variables{'endnote_next'}=$endnote_nr+1;
				my $letter=chr($endnote_nr+96);
				my $onum="%o$endnote_nr;";
				my $endnote_ref=$endnotestyle;
				$endnote_ref=~s/#/$endnote_nr/;
				$endnote_ref=~s/@/$letter/;
				$endnote_ref=~s/\*/$onum/;
				$variables{'endnote_ref'}=$endnote_ref;
				pushout("<link>");
				pushout("<target>");
				pushout("#$gonote");
				pushout("</target>");
				pushout("<text>");
				pushout($endnote_ref);
				pushout("</text>");
				pushout("</link>");
				pushout("<destination>");
				pushout($backnote);
				pushout("</destination>");
				push @endnotes,'';
				push @endnotes," <link>";
				push @endnotes,"<target>";
				push @endnotes,"#$backnote";
				push @endnotes,"</target>";
				push @endnotes,"<text>";
				push @endnotes,$endnote_ref;
				push @endnotes,"</text>";
				push @endnotes,"</link>";
				push @endnotes,"<destination>";
				
				push @endnotes,"$gonote";
				push @endnotes,"</destination>";
			}
			else { pushout($line); }
		}
		else {
			if ($line=~/^\.endnote  *end/){
				$in_endnote=0;
			}
			else {
				push @endnotes,$line;
			}
		}
	}
	if ($endnote_flag>0){
		pushout('');
		pushout($variables{'endnoteheader'});
		pushout('');
		for my $el (@endnotes){
			pushout($el);
		}
		pushout('');
	}
		
	endpass();
}
			
			
		


#  _     _            _
# | |__ | | ___   ___| | _____
# | '_ \| |/ _ \ / __| |/ / __|
# | |_) | | (_) | (__|   <\__ \
# |_.__/|_|\___/ \___|_|\_\___/
#
sub blockpass {
	$passname='blockpass';
	my $inblk=0;
	my $inpre=0;
	my @thisblock;
	my $blockname='';
	for (@passin){
		varset($_);
		$lineindex++;
		my $line=$_;
		$line='' unless defined $line;
		if ($inblk+$inpre==0){
			if ($line=~/^\.block (.*)/){
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				$blockname="$variables{'filename'}.$variables{'blocknumber'}";
				my $blktype=$1;
				$variables{'blocktype'}=$blktype;
				if (defined $variables{"seq$blktype"})
					{$variables{"seq$blktype"}++;
				}
				else {
					$variables{"seq$blktype"}=1;
				}
				progress();
				pushout("<block>");
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout("\"$blktype\""); pushout("</type>");
				$inblk=1;
				undef @thisblock;
			}
			elsif ($line=~/^\.pre/){
				$blockname="$variables{'filename'}.$variables{'blocknumber'}";
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				$blockname="$variables{'filename'}.$variables{'blocknumber'}";
				pushout("<block>");
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout('"pre"'); pushout("</type>");
				$inpre=1;
				undef @thisblock;
			}
			else { pushout($line); }
		}
		elsif ($inpre==1){
			if ($line=~/^\.pre/){
				pushout("<blocktext>");
				for (@thisblock){
					pushout("\"$_\"");
				}
				pushout("</blocktext>");
				pushout("</block>");
				$inpre=0;
			}
			else { push @thisblock,$line; }
		}
		elsif ($inblk==1){
			if (/^\.block format (.*)/){
				pushout("<format>"); pushout("\"$1\""); pushout("</format>");
			}
			elsif (/^\.block caption (.*)/){
				pushout("<caption>"); pushout("\"$1\""); pushout("</caption>");
			}
			elsif (/^\.block/){
				pushout("<blocktext>");
				for (@thisblock){
					pushout("\"$_\"");
				}
				pushout("</blocktext>");
				pushout("</block>");
				$inblk=0;
			}
			else { push @thisblock,$line; }
		}
	}
	endpass();
}
#  _             _ _              _     _            _        
# (_)_ __       | (_)_ __   ___  | |__ | | ___   ___| | _____ 
# | | '_ \ _____| | | '_ \ / _ \ | '_ \| |/ _ \ / __| |/ / __|
# | | | | |_____| | | | | |  __/ | |_) | | (_) | (__|   <\__ \
# |_|_| |_|     |_|_|_| |_|\___| |_.__/|_|\___/ \___|_|\_\___/
# 
sub inlinepass {
	$passname='inlinepass';
	for (@passin){
		varset($_);
		$lineindex++;
		chomp;
		if (/^\.eqn /){ s/^\.eqn/.inline eqn/;}
		if (/^\.inline ([a-z]+) (.*)/){
			my $content=$2;
			my $inlinetype=$1;
			$variables{'blocknumber'}=$variables{'blocknumber'}+1;
			my $blockname="$variables{'filename'}.$variables{'blocknumber'}";
			progress();
			pushout("<block>");
			pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
			pushout("<type>");
			pushout("\"$inlinetype\"");
			pushout("</type>");
			pushout("<blocktext>");
			my @contlines=split ('%n%',$content);
			for (@contlines){
				pushout("\"$_\"");
			}
			pushout("</blocktext>");
			pushout("</block>");
		}
		else { pushout($_); }
	}
	endpass();
}

#  _                    _ _                 
# | |__   ___  __ _  __| (_)_ __   __ _ ___ 
# | '_ \ / _ \/ _` |/ _` | | '_ \ / _` / __|
# | | | |  __/ (_| | (_| | | | | | (_| \__ \
# |_| |_|\___|\__,_|\__,_|_|_| |_|\__, |___/
#                                 |___/   
# (chapter section paragraph)                                 
sub headingpass {
	$passname='headingpass';
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.hu (.*)/){
			my $level=0;
			my $text=$1;
			my $seq='';
			pushout("");
			pushout("<heading>");
			pushout("<level>");
			pushout("\"$level\"");
			pushout("</level>");
			pushout("<seq>");
			pushout("\"$seq\"");
			pushout("</seq>");
			pushout("<text>");
			pushout("\"$text\"");
			pushout("</text>");
			pushout("</heading>");
			pushout("");
		}
		elsif (/^\.hu([0-9]) (.*)/){
			my $level=$1;
			my $text=$2;
			my $seq='';
			$variables{"H$level"}++;
			for (my $i=$level+1;$i<10;$i++){$variables{"H$i"}=0;}
			pushout("");
			pushout("<heading>");
			pushout("<level>");
			pushout("\"$level\"");
			pushout("</level>");
			pushout("<seq>");
			pushout("\"$seq\"");
			pushout("</seq>");
			pushout("<text>");
			pushout("\"$text\"");
			pushout("</text>");
			pushout("</heading>");
			pushout("");
		}
		elsif (/^\.h([0-9]) (.*)/){
			my $level=$1;
			my $text=$2;
			$variables{"H$level"}++;
			my $seq='';
			my @alpha = (' ','A'..'Z');
			if ($variables{"H1"}>$variables{"appendix"}){
				$seq=$alpha[$variables{"H1"}-$variables{"appendix"}];
			}
			else {
				$seq=$variables{"H1"};
			}
			$seq=$seq.'.';
			for (my $i=2;$i<=$level;$i++){$seq=$seq.$variables{"H$i"}.'.';}
			for (my $i=$level+1;$i<10;$i++){$variables{"H$i"}=0;}
			pushout("");
			pushout("<heading>");
			pushout("<level>");
			pushout("\"$level\"");
			pushout("</level>");
			pushout("<seq>");
			pushout("\"$seq\"");
			pushout("</seq>");
			pushout("<text>");
			pushout("\"$text\"");
			pushout("</text>");
			pushout("</heading>");
			pushout("");
		}
		else { pushout($_); }
	}
	endpass();
}
#  _   _            _                _        _   _ _            
# | | | | ___  _ __(_)_______  _ __ | |_ __ _| | | (_)_ __   ___ 
# | |_| |/ _ \| '__| |_  / _ \| '_ \| __/ _` | | | | | '_ \ / _ \
# |  _  | (_) | |  | |/ / (_) | | | | || (_| | | | | | | | |  __/
# |_| |_|\___/|_|  |_/___\___/|_| |_|\__\__,_|_| |_|_|_| |_|\___|
# 
sub hrpass {
	$passname='hrpass';
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.hr/){
			pushout("<hr>");
			pushout("</hr>");
		}
		elsif (/^\.page/){
			pushout("<page>");
			pushout("</page>");
		}
		elsif (/^\.space/){
			pushout("<space>");
			pushout("</space>");
		}
		elsif (/^\.P/){
			pushout("<blank>");
			pushout("</blank>");
		}
		else {
			pushout($_);
		}
	}
	endpass();
}

#  _
# | |_ ___   ___
# | __/ _ \ / __|
# | || (_) | (__
#  \__\___/ \___|
#
sub tocpass {
	$passname='tocpass';
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.toc[0-9]* (.*)/){
			pushout("<toc>");
			pushout($1);
			pushout("</toc>");
		}
		elsif (/^\.toc/){
			pushout("<toc>");
			pushout("</toc>");
		}
		else {
			pushout($_);
		}
	}
	endpass();
}



#  _ _     _       
# | (_)___| |_ ___ 
# | | / __| __/ __|
# | | \__ \ |_\__ \
# |_|_|___/\__|___/
# 
sub listpass {
	$passname='listpass';
	my $listlevel=0;
	my $newlevel=0;
	my $content='';
	for (@passin){
		varset($_);
		$content=$_;
		$lineindex++;
		if (/^(\t*)([-@#])[ 	]+(.*)/){
			if ( defined $2){
				$newlevel=length("$1.$2")-1;
			}
			else { $newlevel=$listlevel; }
			my $content=$3;
			my $listtype;
			if ($2 eq '-'){ $listtype='dash';}
			elsif ($2 eq '#'){ $listtype='num';}
			elsif ($2 eq '@'){ $listtype='alpha';}
			if ($newlevel>$listlevel){
				pushout("<list>");
				pushout("<type>");
				pushout("\"$listtype\"");
				pushout("</type>");
				$listlevel=$newlevel;
			}
			elsif($newlevel<$listlevel){
				pushout("</list>");
				$listlevel=$newlevel;
			}
			pushout("<item>");
			if ($content=~/%\\n/){
				$content=~s/\%\&\#0092;n/%\\n/g;
				my @cellines=split /%n%/ , $content;
				for (@cellines){pushout($_);}
				undef @cellines;
			}
			else { pushout($content);}
			pushout("</item>");
		}
		elsif (/^$/){      #not a list-initiator
			while ($listlevel >0){
				pushout('</list>');
				$listlevel--;
			}
			$listlevel=0;
			$newlevel=0;
			 
			pushout($_);
		}
		else {   # not a list initiator, and not an empty line
			if ($listlevel>0){
				my $max=$#passout;
				pop @passout;
				$inline=1;
				if ($content=~/%\\n/){
					my @cellines=split /%n%/ , $content;
					for (@cellines){pushout($_);}
					undef @cellines;
				}
				else { pushout($content);}
				$content='';
				pushout("</item>");
				$inline=0;
			}
			else {
				pushout($_);
			}
		}

	}
	endpass();
}


#  _____     _     _           
# |_   _|_ _| |__ | | ___  ___ 
#   | |/ _` | '_ \| |/ _ \/ __|
#   | | (_| | |_) | |  __/\__ \
#   |_|\__,_|_.__/|_|\___||___/
# 
sub tablepass {
	$passname='tablepass';
	my $intable=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^	/){
			if ($intable==0){
				pushout("<table>");
				$intable=1;
			}
			s/^	//;
			my @row=split '	';
			pushout("<row>");
			my $cellopen='';
			for (@row) {
				# The construction of <cs=..> is wrong. It is an xml-contruction
				# in the in-language. Therefore we need to fiddle with the &lt; 
				# and &gt;
				my $content=$_;
				$cellopen='<cell';
				if ($content=~/&lt;rs=([0-9]+)&gt;/){
					$cellopen="$cellopen rowspan=\"$1\"";
				}
				if ($content=~/&lt;cs=([0-9]+)&gt;/){
					$cellopen="$cellopen colspan=\"$1\"";
				}
				if ($content=~/&lt;format=([a-z]+)&gt;/){
					$cellopen="$cellopen format=\"$1\"";
				}
				else {
					$cellopen="$cellopen format=\"$variables{'cellalign'}\"";
				}

				$content=~s/&lt;rs=[0-9]+&gt;//;
				$content=~s/&lt;cs=[0-9]+&gt;//;
				$content=~s/&lt;format=[a-z]+&gt;//;
				pushout ("$cellopen>");
				if ($content=~/%n%/){
					my @cellines=split /%n%/ , $content;
					for (@cellines){pushout($_);}
					undef @cellines;
				}
				else { pushout($content);}
				pushout ("</cell>");
			}
			pushout("</row>");
		}
		else {
			if ($intable==1){
				pushout("</table>");
				$intable=0;
			}
			pushout($_);
		}
	}
	endpass();
}

#                _       __ _ _      
#   ___ ___   __| | ___ / _(_) | ___ 
#  / __/ _ \ / _` |/ _ \ |_| | |/ _ \
# | (_| (_) | (_| |  __/  _| | |  __/
#  \___\___/ \__,_|\___|_| |_|_|\___|
# 
sub codefilepass {
	$passname='codefilepass';
	my $inlst=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.codefile (.*)/){
			if (open (my $CODEFILE,'<',$1)){
				pushout("<block>");
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				my $blockname="$variables{'filename'}.$variables{'blocknumber'}";
				progress();
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout('"lst"'); pushout("</type>");
				pushout("<blocktext>");
				while (<$CODEFILE>){
					chomp;
					s/&/&amp;/g;
					s/</&lt;/g;
					s/>/&gt;/g;
					s/"/&quot;/g;
					s/'/&apos;/g;
					s/\\/&#0092;/g;
					pushout("\"$_\"");
				}
				pushout("</blocktext>");
				pushout("</block>");
			}
			else {
				pushout("FILE: $1");
			}
		}
		else {
			pushout($_);
		}

	}
	endpass();
}



#  _ _     _   _                 
# | (_)___| |_(_)_ __   __ _ ___ 
# | | / __| __| | '_ \ / _` / __|
# | | \__ \ |_| | | | | (_| \__ \
# |_|_|___/\__|_|_| |_|\__, |___/
#                      |___/ 

sub lstpass {
	$passname='lstpass';
	my $inlst=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if (/^\.lst/){
			if ($inlst==0){
				pushout("<block>");
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				my $blockname="$variables{'filename'}.$variables{'blocknumber'}";
				progress();
				pushout("<name>"); pushout("\"$blockname\""); pushout("</name>");
				pushout("<type>"); pushout('"lst"'); pushout("</type>");
				pushout("<blocktext>");
			}
			$inlst=1;
			s/^\.lst//;  # in two substitute, because of empty ,lst lines
			s/^ //;
			pushout("\"$_\"");
		}
		else {

			if ($inlst>0){
				pushout("</blocktext>");
				pushout("</block>");
			}
			$inlst=0;
			pushout($_);
		}

	}
	endpass();
}
#                                              _         
#  _ __   __ _ _ __ __ _  __ _ _ __ __ _ _ __ | |__  ___ 
# | '_ \ / _` | '__/ _` |/ _` | '__/ _` | '_ \| '_ \/ __|
# | |_) | (_| | | | (_| | (_| | | | (_| | |_) | | | \__ \
# | .__/ \__,_|_|  \__,_|\__, |_|  \__,_| .__/|_| |_|___/
# |_|                    |___/          |_|  
#
sub parapass{
	$passname='parapass';
	my $construct='';
	my @parablock;
	my @leftnote;
	my @sidenote;
	my $inpara=0;
	my $level=0;
	for (@passin){
		varset($_);
		$lineindex++;
		if ($inpara==0){
			if (/^<(.*)>$/){	# Anything that is already handled is seen as a 
								# stand-alone construct. That may be a problem for 
								# inline's at the beginning of a paragaph.
				my $match=$1;
				if ($level==0){
					$construct=$match;
					$level++;
					pushout($_);
				}
				elsif ("$construct" eq $match){
					$level++;
					pushout($_);
				}
				elsif ("/$construct" eq $match){
					$level--;
					if ($level<=0){
						$construct='';
					}
					pushout($_);
				}
				else {
					pushout($_);
				}
			} #end  <> in the inputline
			elsif (/^[ 	]*$/){
					pushout($_);
				}
			else {
				if ($level==0){
					$inpara=1;
					push @parablock,$_;
				}
				else {
					$inpara=0;
					pushout($_);
				}
			}
		}
		else { 							# Inpara==1 ; we've detected a paragraph block 
			if (/^[ 	]*$/){
				# Empty line marks the end of a paragraph
				if ($#parablock>=0){	# paragraph-block is not empty
					# Collect all side and left notes from the paragraph block
					for (@parablock){
						if (/^([^	]+)\t.*/){
							push @leftnote,$1;
							#s/^([\w%\?,\. ;:\(\)]+)\t//;
							s/^([^	]+)\t//;
						}
						if (/^\.side *char (.*)/){}
						elsif (/^\.side *separator (.*)/){}
						elsif (/^\.side (.*)/){
							push @sidenote,$1;
						}
					}
					pushout('<paragraph>');
					if ($#leftnote>=0){
						pushout('<leftnote>');
						for (@leftnote){ pushout($_);}
						pushout('</leftnote>');
					}
					if ($#sidenote>=0){
						pushout('<sidenote>');
						for (my $i=0; $i<=$#sidenote;$i++){
							my $ref=$variables{'sideref'};
							my $j=$i+1;
							my $a=('a' .. 'z' )[$i];
							my $A=('A' .. 'Z' )[$i];
							my $J=supernum($j);
							$ref=~s/%num/$J/;
							$ref=~s/%NUM/$j/;
							$ref=~s/%alpha/$a/;
							$ref=~s/%ALPHA/$A/;
							pushout("$ref$sidenote[$i]$variables{'sidesep'}");
						}
						pushout('</sidenote>');
					}
					pushout('<text>');
					my $j=1;
					for (@parablock){
						my $mx=$#passout;
						if (/^\w+\t(.*)/){
							pushout($1);
						}
						elsif (/^\.side (.*)/){
							my $ref=$variables{'sidechar'};
							my $a=('a' .. 'z' )[$j-1];
							my $A=('A' .. 'Z' )[$j-1];
							my $J=supernum($j);
							$ref=~s/%num/$J/;
							$ref=~s/%NUM/$j/;
							$ref=~s/%alpha/$a/;
							$ref=~s/%ALPHA/$A/;
							$j=$j+1;
							$passout[$mx]="$passout[$mx]$ref";
						}
						else {
							pushout($_);
						}
					}
					pushout('</text>');
					pushout('</paragraph>');
					undef @parablock;
					undef @sidenote;
					undef @leftnote;
					$inpara=0;
				}
				else {		# In paragraph, end of paragraph block, but the block is empty?
							# This should not happen.
					pushout("");
				}
			}
			else {			# In paragraph block, not an end-of-paragraph (not ^$)
				push @parablock,$_;
			}
		}
	}
	endpass();
}
#                                           _       
#   ___ ___  _ __ ___  _ __ ___   ___ _ __ | |_ ___ 
#  / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \ '_ \| __/ __|
# | (_| (_) | | | | | | | | | | |  __/ | | | |_\__ \
#  \___\___/|_| |_| |_|_| |_| |_|\___|_| |_|\__|___/
#
sub commentpass {
	$passname='commentpass';
	my $inblock=0;
	for (@passin){
		my $line=$_;
		if (/^\.block .*/){$inblock=1;}
		elsif (/^\.block/){$inblock=0;}
		varset($line);
		$lineindex++;
		if (/^#DEP (.*)/){
			if ($inblock==0){}
			else { pushout($_); }
		}
		elsif (/^#!(.*)/){
			if ($inblock==0){pushout("<!-- $1 -->");}
			else { pushout($_); }
		}
		elsif (/^#--(.*)/){
			if ($inblock==0){pushout("<!-- $1 -->");}
			else { pushout($_); }
		}
		else {
			pushout($_);
		}
	}
	endpass();
}
#  _             _                       __                            _   
# (_)_ __       | |_ _   _ _ __   ___   / _| ___  _ __ _ __ ___   __ _| |_ 
# | | '_ \ _____| __| | | | '_ \ / _ \ | |_ / _ \| '__| '_ ` _ \ / _` | __|
# | | | | |_____| |_| |_| | |_) |  __/ |  _| (_) | |  | | | | | | (_| | |_ 
# |_|_| |_|      \__|\__, | .__/ \___| |_|  \___/|_|  |_| |_| |_|\__,_|\__|
#                    |___/|_| 
#

sub imgconvert{
	(my $image)=@_;
	my $retval=$image;
	return $retval;
}

sub formatpass {
	$passname='formatpass';
	for (@passin){
		my $line=$_;
		varset($line);
		$lineindex++;
		if (/^\.fix (.*)/){pushout('<fixed>'); pushout($1); pushout('</fixed>'); }
		elsif ($line=~/^\.fixed (.*)/){pushout('<fixed>'); pushout($1); pushout('</fixed>'); }
		elsif ($line=~/^\.fixednospace (.*)/){pushout('<fixednospace>'); pushout($1); pushout('</fixednospace>'); }
		elsif ($line=~/^\.font (\w*) (.*)/){pushout("<font type=\"$1\">"); pushout($2); pushout('</font>'); }
		elsif ($line=~/^\.center (.*)/){pushout('<center>'); pushout($1); pushout('</center>'); }
		elsif ($line=~/^\.underline (.*)/){pushout('<underline>'); pushout($1); pushout('</underline>'); }
		elsif ($line=~/^\.u (.*)/){pushout('<underline>'); pushout($1); pushout('</underline>'); }
		elsif ($line=~/^\.unospace (.*)/){pushout('<underlinenospace>'); pushout($1); pushout('</underlinenospace>'); }
		elsif ($line=~/^\.bold (.*)/){pushout('<bold>'); pushout($1); pushout('</bold>'); }
		elsif ($line=~/^\.b (.*)/){pushout('<bold>'); pushout($1); pushout('</bold>'); }
		elsif ($line=~/^\.bnospace (.*)/){pushout('<boldnospace>'); pushout($1); pushout('</boldnospace>'); }
		elsif ($line=~/^\.i (.*)/){pushout('<italic>'); pushout($1); pushout('</italic>'); }
		elsif ($line=~/^\.inospace (.*)/){pushout('<italicnospace>'); pushout($1); pushout('</italicnospace>'); }
		elsif ($line=~/^\.italic (.*)/){pushout('<italic>'); pushout($1); pushout('</italic>'); }
		elsif ($line=~/^\.sub (.*)/){pushout('<subscript>'); pushout($1); pushout('</subscript>'); }
		elsif ($line=~/^\.sup (.*)/){pushout('<superscript>'); pushout($1); pushout('</superscript>'); }
		elsif ($line=~/^\.br/){pushout('<break>'); pushout('</break>'); }
		elsif ($line=~/^\.link (\S*) (.*)/){
			pushout('<link>');
			pushout('<target>');
			pushout("\"$1\"");
			pushout('</target>');
			pushout('<text>');
			pushout("\"$2\"");
			pushout('</text>');
			pushout('</link>');
		}
		elsif ($line=~/^\.link ([^ ]*)/){
			pushout('<link>');
			pushout('<target>');
			pushout("\"$1\"");
			pushout('</target>');
			pushout('</link>');
		}
		elsif ($line=~/^\.img +([HFQLR][EIUA][FGAL][A-Z]+) +([^ ]+)/){
			my $fmt=lc $1;
			my $imgname=imgconvert($2);
			pushout('<image>');
			pushout('<format>');
			pushout($fmt);
			pushout('</format>');
			if ($line=~/^\.img +([HFQLR][EIUA][FGAL][A-Z]+) +([^ ]+) +(.+)/){
				pushout('<caption>');
				pushout($3);
				pushout('</caption>');
			}				
			pushout('<file>');
			pushout("\"$imgname\"");
			pushout('</file>');
			pushout('</image>');
		}
		elsif ($line=~/^\.img ([^ ]*)/){
			my $imgname=imgconvert($1);
			pushout('<image>');
			if ($line=~/^\.img +([^ ]+) +(.+)/){
				pushout('<caption>');
				pushout($2);
				pushout('</caption>');
			}				
			pushout('<file>');
			pushout("\"$imgname\"");
			pushout('</file>');
			pushout('</image>');
		}
		elsif ($line=~/^\.video ([^ ]*)/){
			pushout('<video>');
			pushout('<file>');
			pushout("\"$1\"");
			pushout('</file>');
			pushout('</video>');
		}
		else { pushout($_);}
	}
	endpass();
}
#   __             _               _            
#  / _| ___   ___ | |_ _ __   ___ | |_ ___  ___ 
# | |_ / _ \ / _ \| __| '_ \ / _ \| __/ _ \/ __|
# |  _| (_) | (_) | |_| | | | (_) | ||  __/\__ \
# |_|  \___/ \___/ \__|_| |_|\___/ \__\___||___/
#  
sub footnotepass {
	$passname='footnotepass';
	for (@passin){
		my $line=$_;
		varset($line);
		$lineindex++;
		if (/^\.note (.*)/){
			my $content=$1;
			my $mx=$#passout;
			my $ref=$variables{'notestring'};
			$variables{'notenumber'}++;
			my $J=$variables{'notenumber'};
			my $a=('a' .. 'z' )[$J-1];
			my $A=('A' .. 'Z' )[$J-1];
			my $j='';
			$ref=~s/%NUM/$J/;
			$ref=~s/%alpha/$a/;
			$ref=~s/%ALPHA/$A/;
			$passout[$mx]="$passout[$mx]$ref";
			pushout('<note>');
			pushout('<ref>'); pushout($ref); pushout('</ref>');
			pushout('<seq>'); pushout($variables{'notenumber'});pushout('</seq>');
			pushout('<notetext>');
			if ($content=~/%n%/){
				my @cellines=split /%n%/ , $content;
				for (@cellines){pushout($_);}
				undef @cellines;
			}
			else { pushout($content);}
			pushout('</notetext>');
			pushout('</note>');
		}
		else { pushout($_);}
	}
	endpass();
}

sub noppass{
	$passname='nop-pass';
	for (@passin){
		my $line=$_;
		varset($line);
		$lineindex++;
		if (/^\.nop/){
		}
		else { pushout($_);}
	}
	endpass();
}

#      _                  _       _
#  ___| |_ __ _ _ __   __| | __ _| | ___  _ __   ___
# / __| __/ _` | '_ \ / _` |/ _` | |/ _ \| '_ \ / _ \
# \__ \ || (_| | | | | (_| | (_| | | (_) | | | |  __/
# |___/\__\__,_|_| |_|\__,_|\__,_|_|\___/|_| |_|\___|
#
sub standalonepass {	# make images, videos or blocks that occupy a 
	 					# complete paragraph stand-alone
	$passname='standalonepass';
	my @parablock;
	my $inpara=0;
	my $inblk=0;
	my $invideo=0;
	my $intoc=0;
	my $inimg=0;
	my $inmap=0;
	my $inset=0;
	my $inpage=0;
	my $dontstrip=0;
	my $line;
	for (@passin){
		$line=$_;
		varset($line);
		$lineindex++;
		if (/^<paragraph>$/){
			$inpara=1;
			push @parablock,$line;
		}
		elsif ($inpara>0){
			if (/^<\/paragraph>$/){
				push @parablock,$line;
				for (@parablock){
					if (/^<paragraph>/){}
					elsif (/^<.paragraph>/){}
					elsif (/^<text>/){}
					elsif (/^<.text>/){}
					elsif (/^<block>/){ $inblk=1; }
					elsif (/^<.block>/){ $inblk=0; }
					elsif (/^<image>/){ $inimg=1; }
					elsif (/^<.map>/){ $inmap=0; }
					elsif (/^<map>/){ $inmap=1; }
					elsif (/^<.image>/){ $inimg=0; }
					elsif (/^<video>/){ $invideo=1; }
					elsif (/^<.video>/){ $invideo=0; }
					elsif (/^<set>/){ $inset=1; }
					elsif (/^<.set>/){ $inset=0; }
					elsif (/^<page>/){ $inset=1; }
					elsif (/^<.page>/){ $inset=0; }
					elsif (/^<toc>/){ $intoc=1; }
					elsif (/^<.toc>/){ $intoc=0; }
					elsif ($inmap+$inimg+$inblk+$invideo+$intoc+$inset+$inpage>0){ }
					else {
						$dontstrip=1;
				   	}
				}
				if ($dontstrip==0){
					for (@parablock){
						if (/^<paragraph>/){}
						elsif (/^<.paragraph>/){}
						elsif (/^<text>/){if ($inimg+$inblk+$invideo>0){ pushout($_);}}
						elsif (/^<.text>/){if ($inimg+$inblk+$invideo>0){ pushout($_);}}
						elsif (/^<block>/){ $inblk=1; pushout($_);}
						elsif (/^<.block>/){ $inblk=0; pushout($_);}
						elsif (/^<image>/){ $inimg=1; pushout($_);}
						elsif (/^<.image>/){ $inimg=0; pushout($_);}
						elsif (/^<map>/){ $inimg=1; pushout($_);}
						elsif (/^<.map>/){ $inmap=0; pushout($_);}
						elsif (/^<set>/){ $inset=1; pushout($_);}
						elsif (/^<.set>/){ $inset=0; pushout($_);}
						elsif (/^<page>/){ $inset=1; pushout($_);}
						elsif (/^<.page>/){ $inset=0; pushout($_);}
						elsif (/^<toc>/){ $intoc=1; pushout($_);}
						elsif (/^<.toc>/){ $intoc=0; pushout($_);}
						elsif (/^<video>/){ $invideo=1; pushout($_);}
						elsif (/^<.video>/){ $invideo=0; pushout($_);}
						elsif ($inmap+$inimg+$inblk+$invideo+$inset+$intoc+$inpage>0){ pushout($_);}
						else { $dontstrip=1; print STDERR "MEUH? dontstrip==0, but 1 anyway?\n";}
					}
				}
				else {
					for (@parablock){
						pushout($_);
					}
				}
				undef @parablock;
				$inpara=0;
				$inblk=0;
				$invideo=0;
				$inimg=0;
				$dontstrip=0;
			}
			else {
				push @parablock,$line;
			}
		}
		else {
			pushout($line);
		}
	}
	endpass();
}

#                  _          _     _            _    
#  _ __ ___   __ _| | _____  | |__ | | ___   ___| | __
# | '_ ` _ \ / _` | |/ / _ \ | '_ \| |/ _ \ / __| |/ /
# | | | | | | (_| |   <  __/ | |_) | | (_) | (__|   < 
# |_| |_| |_|\__,_|_|\_\___| |_.__/|_|\___/ \___|_|\_\
#                                                     
#                  _             _   
#   ___ ___  _ __ | |_ ___ _ __ | |_ 
#  / __/ _ \| '_ \| __/ _ \ '_ \| __|
# | (_| (_) | | | | ||  __/ | | | |_ 
#  \___\___/|_| |_|\__\___|_| |_|\__|
#  
sub blockmakepass {
	$passname='blockmakepass';
	my $inblock=0;
	my $intype=0;
	my $intext=0;
	my $informat=0;
	my $inname=0;
	my $type;
	my @thisblock;
	for (@passin){
		my $blk="block/$variables{'filename'}.$variables{'blocknumber'}";
		my $baseblk="$variables{'blockname'}.$variables{'blocknumber'}";
		my $line=$_;
		varset($line);
		if ($inblock>0){
			if ($inname>0){
				if ($line=~/^<\/name>/) {$inname=0;}
				else {
					$blk=$_;
					$baseblk=basename($blk);
				}
			}
			elsif ($informat>0){
				if ($line=~/^<\/format>/) {$informat=0;}
			}
			elsif ($intype>0){
				if ($line=~/^<\/type>/) {$intype=0;}
				else { $type=$line; $type=~s/^"//; $type=~s/"$//; $type=~s/ .*//; }
			}
			elsif ($intext>0){
				if ($line=~/^<\/text>/) {$intext=0;}
				else { 
					my $t=$line;
					if ($t=~/^"/){
						$t=~s/^"//;
						$t=~s/"$//;
					}
					push @thisblock, $t;
				}
			}
			elsif ($line=~/^<type>/){$intype=1;}
			elsif ($line=~/^<text>/){$intext=1;}
			elsif ($line=~/^<format>/){$informat=1;}
			elsif ($line=~/^<name>/){$inname=1;}
			elsif ($line=~/^<\/block>/){
				$variables{'blocknumber'}=$variables{'blocknumber'}+1;
				if ($#thisblock>=0){
					if (open (my $BLOCK,'>',"$blk.blk")){
						for (@thisblock){
							print $BLOCK "$_\n";
						}
						close $BLOCK;
					}
					else {
						print STDERR "Cannot open $blk.blk\n";
						$type='none';
					}
				}
				else {
					print STDERR "Block $variables{'blocknumber'} has empty text\n";
					$type='empty';
				}
				if ($type eq 'pre'){
					system ("pango-view --font=mono -qo $blk.png $blk.blk\n");
					pushout('<image>');
					pushout("$blk.png ");
					pushout('</image>');
				}
				elsif ($type eq 'lst'){
					system ("pango-view --font=mono -qo $blk.png $blk.blk\n");
					pushout('<image>');
					pushout("$blk.png ");
					pushout('</image>');
				}
				elsif ($type=~/^class/){
					system ("pango-view --font=mono -qo $blk.png $blk.blk\n");
					pushout('<image>');
					pushout("$blk.png ");
					pushout('</image>');
				}
			    elsif ($type eq 'eqn'){
					my $density=1000;
					if (open my $EQN, '>',"$blk.eqn"){
						print $EQN ".EQ\n";
						for (@thisblock){
							print $EQN "$_\n";
						}
						print $EQN ".EN\n";
						close $EQN;
						system ("eqn $blk.eqn > $blk.groff");
						system ("groff $blk.groff > $blk.ps");
						system ("ps2pdf $blk.ps $blk.pdf");
						system ("convert -trim -density $density $blk.pdf $blk.png");
						pushout('<image>');
						pushout("$blk.png ");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.eqn\n"; }

				}
			    elsif ($type eq 'pic'){
					my $density=1000;
					if (open my $PIC, '>',"$blk.pic"){
						print $PIC ".PS\n";
						for (@thisblock){
							print $PIC "$_\n";
						}
						print $PIC ".PE\n";
						close $PIC;
						system ("pic $blk.pic > $blk.groff");
						system ("groff $blk.groff > $blk.ps");
						system ("ps2pdf $blk.ps $blk.pdf");
						system ("convert -trim -density $density $blk.pdf $blk.png");
						pushout('<image>');
						pushout("$blk.png ");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.pic\n"; }

				}
			    elsif ($type eq 'piechart'){
					if (open (my $PIECHART, '>',"$blk.piechart")){
						for (@thisblock){
							print $PIECHART "$_\n";
						}
						close $PIECHART;
						system(" piechart $blk.piechart --order value,explode,color,legend > $blk.svg");
						pushout('<image>');
						pushout("$blk.svg");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.piechart\n"; }
				}
			    elsif ($type eq 'gnuplot'){
					if (open (my $GNUPLOT, '>',"$blk.gnuplot")){
						print $GNUPLOT "set terminal png size 800,800 enhanced font \"Helvetica,8\"";
						print $GNUPLOT "\nset output '$blk.png'\n";
						for (@thisblock){
							print $GNUPLOT "$_\n";
						}
						close $GNUPLOT;
						system("gnuplot $blk.gnuplot");
						pushout('<image>');
						pushout("$blk.png");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.gnuplot\n"; }
				}
			    elsif ($type eq 'music'){
					if (open (my $MUSIC, '>',"$blk.ly")){
						print $MUSIC "\\version \"2.18.2\"\n";
						print $MUSIC "\\book {\n";
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
						for (@thisblock){
							print $MUSIC "$_\n";
						}
						print $MUSIC "}\n";
						close $MUSIC;
						system ("lilypond --png  -dresolution=500  $blk.ly");
						system ("cp $baseblk.png $blk.png");
						system ("convert -trim $blk.png $blk.tmp.png");
						system ("mv $blk.tmp.png $blk.png");
						pushout('<image>');
						pushout("$blk.png");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.ly\n"; }
				}
			    elsif ($type eq 'texeqn'){
					my $density='1000x1000';
					if (open (my $TEXEQN,'>',"$blk.tex")){
						print $TEXEQN "\\documentclass{article}\n";
						print $TEXEQN "\\usepackage{amsmath}\n";
						print $TEXEQN "\\usepackage{amssymb}\n";
						print $TEXEQN "\\usepackage{algorithm2e}\n";
						print $TEXEQN "\\begin{document}\n";
						print $TEXEQN "\\begin{titlepage}\n";
						print $TEXEQN "\\begin{equation*}\n";
						for (@thisblock){
							print $TEXEQN "$_\n";
						}
						print $TEXEQN "\\end{equation*}\n";
						print $TEXEQN "\\end{titlepage}\n";
						print $TEXEQN "\\end{document}\n";
						close $TEXEQN;
						system("cd block; echo '' | latex $baseblk.tex > /dev/null 2>/dev/null");
						#system("convert  -trim  -density $density $blk.dvi $blk.png");
						system("dvipng -o $blk.png -D $density  $blk.dvi ");
						pushout('<image>');
						pushout("$blk.png");
						pushout('</image>');
					}
					else { print STDERR "Cannot open $blk.tex\n";}
				}
				else {
					print STDERR "Unhandled block type='$type':\n";
					# for (@thisblock){
					# print STDERR "    $_\n";
					# }
				}
				undef @thisblock;
				$inblock=0;
				$type='none';
			}
			pushout($line);
		}
		elsif ($line=~/^<block>/){			
			pushout($line);
			$inblock=1;
			$type='pre';
			undef @thisblock;
		}
		else {
			pushout($line);
		}
	}
	endpass();
}



$lineindex=-1;
depricatepass();
xmlifypass();
includepass();
markdownpass(); progress;
endnotepass(); progress;
blockpass(); progress;
inlinepass(); progress;
listpass(); progress;
pipetablepass();progress;
tablepass(); progress;
blockpass(); progress;
inlinepass(); progress;
lstpass(); progress;
headingpass(); progress;
codefilepass(); progress;
mappass(); progress;
parapass(); progress;
hrpass(); progress;
tocpass(); progress;
footnotepass(); progress;
mdformatpass(); progress;
formatpass(); progress;

varpass(); progress;
standalonepass(); progress;
commentpass(); progress;
# blockmakepass();
noppass();

print "<?xml version=\"1.0\"?>\n";
print "<!DOCTYPE in3xml SYSTEM \"/usr/local/share/in3/in3xml.dtd\">\n";
print "<in3xml>\n";
# Here there are a number of global variables that may not have been set
# expilitly, but may be needed by the output processors.
foreach ('appendix','COVER'){
	print "<set>\n";
	print "<variable>\n";
	print "$_\n";
	print "</variable>\n";
	print "<value>\n"; 
	print $variables{"$_"};
	print "\n";
   	print "</value>\n";
	print "</set>\n";
}

for (@passin){
	print "$_\n";
}
print "</in3xml>\n";

