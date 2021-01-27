#!/usr/bin/perl
#INSTALL@ /usr/local/bin/mkinheader
use strict;
use warnings;

use Cwd qw();

sub hellup {
print "
mkinheader: make header/index file for in3
--help           This help
-h  --header     create an includable header
-i  --index      create an index-file
-t               Don't include the total or complete
-v               increase verbosity
";
}


my $VERBOSE=0;

my $type='header';		# Type of output to produce
my $do_total=1;			# Include the "total" file in the header/index
my $WD = Cwd::cwd();		# Basename of the current working directory
$WD=~s/.*\///;
my $all_in;				# A space-separated list of al .in files
my @in;				# all relevant lines from the in-files

for (@ARGV){
	chomp;
	if (/^$/){ $type='header';}
	elsif (/--help/){
		hellup;
	}
	elsif (/--header/){
		$type='header';
	}
	elsif (/-h/){
		$type='header';
	}
	elsif (/--index/){
		$type='index';
	}
	elsif (/-i/){
		$type='index';
	}
	elsif (/-t/){
		$do_total=0;
	}
	elsif (/-v/){$VERBOSE++;}
	else { print "$_; Unknown option $_.\n";}
}
	
if ($VERBOSE > 0){ print "######## type=$type\n";}
if ($do_total==1){
	$all_in=`ls *.in| sort -n |egrep -v '^_top.in|^_bottom.in|complete.in'| paste -sd ' '`;
}
else{
	$all_in=`ls *.in|egrep -v 'total.in|complete.in' | egrep -v '^_top.in|^_bottom.in'| sort -n| paste -sd ' '`;
}
chomp $all_in;

if ($VERBOSE > 0){ print "########all_in=$all_in=\n";}

if (open(my $IN,'-|',"egrep '^\.h[123] |\.toc|^.author|^.title|^.subtitle' $all_in")){
	@in=<$IN>;
	close $IN;
}
else {
	die 'Cannot grep .in-files';
}

my $tot_title='';
my $sub_title='';
my $author='';

for (@in){
	if (/in:.title (.*)/){ $tot_title=$1; }
	if (/in:.subtitle (.*)/){ $sub_title="$1"; }
	if (/in:.author (.*)/){ $author=$1;}
}

if ($type eq 'header'){
#	if ($tot_title ne 'Index' ){print "<h1>$tot_title</h1>\n";}
#	if ($sub_title ne '' ){print "<h2>$sub_title</h2>\n";}
#	if ($author ne ''){print "<h3>$author</h3>\n";}
}
elsif ($type eq 'index'){
	if (( -d 'roff' ) && ($do_total==1)) {
		print ".link complete.pdf (pdf)\n";
	}
	elsif (( -d 'pdf' ) && ($do_total==1)) {
		print ".link total.pdf (pdf)\n";
	}
	if (( -d 'epub' ) && ($do_total==1)){
		print ".link $WD.epub (epub)\n";
	}
	if (( -d 'www' ) && ($do_total==1)){
		print ".link total.html (1 page)\n";
	}
	if ($tot_title ne '' ){print ".title $tot_title\n";}
	if ($sub_title ne '' ){print ".subtitle $sub_title\n";}
	if ($author ne ''){print ".author $author\n";}
	if ( -f "index.top"){
		if (open(my $IT,'<',"index.top")){
			while (<$IT>){print;}
			close $IT;
		}
	}
}


my $charmapfile;
if ( -f "/usr/local/share/in3charmap1" ){
	$charmapfile="/usr/local/share/in3charmap1";
}
else {
	$charmapfile="in3charmap1";
}

my @charmap;
if ( open (my $CHARMAP,'<',$charmapfile)){
	@charmap=<$CHARMAP>;
	close $CHARMAP;
}
else { print STDERR "Cannot open in3charmap1"; }
sub charmapper {
	(my $input)=@_;
	for (@charmap){
		chomp;
		(my $char,my $groff,my $html)=split '	';
		$char='NOCHAR' unless defined $char;
		$groff=$char unless defined $groff;
		$html=$char unless defined $html;
		$input=~s/$char/$html/g;
	}
	return $input;
}


if ($type eq 'header'){
	print "<table CLASS=\"toc\">\n";
	if (open (my $HL,'-|',"grep '^\.headerlink ' *.in | sort -u")){
		while (<$HL>){
			chomp;
			s/.*headerlink *//;
			my $linkdest=$_;
			my $linktxt=$_;
			$linkdest=~s/ .*//;
			$linktxt=~s/^[^ ]* //; 
			$linktxt=charmapper($linktxt);
 			print "	<tr class=tocrow><td><a href=\"$linkdest\">";
			print "<span CLASS=tocitem>$linktxt</span></a></td></tr>\n";
		}
	}
	print "</table>\n";
}
if ($type eq 'header'){
	print "<table CLASS=\"toc\">\n";
	print "	<tr class=toc><td><a href=\"index.html\"><span CLASS=toc>Index</span></a></td></tr>\n"; 
	if ( -d 'roff' ){
		print "	<tr class=tocrow><td><a href=\"complete.pdf\">";
		print "<span CLASS=tocitem>PDF</span></a></td></tr>\n";
	}
	elsif (-d 'pdf'){
		print "	<tr class=tocrow><td><a href=\"total.pdf\">";
		print "<span CLASS=tocitem>PDF</span></a></td></tr>\n";
	}
}

	

my $prev_c=0;
my $s=0;
my $p=0;
my $appendix=0;
for (@in){
	chomp;
	my $inline=$_;
	if ($type eq 'header'){
		$inline=charmapper($inline);
	}
	chomp $inline;
	my $c='';;
	if ($inline=~/^index/){ $prev_c=0;}
	elsif ($inline=~/^total/){ $prev_c=0;}
	elsif ($inline=~/^complete/){ $prev_c=0;}
	elsif ($inline=~/^([0-9]*)_(.*).in:.h([12]) (.*)/){
		$c=$1;
		my $file="$1_$2.html";
		my $pdf="$1_$2.pdf";
		my $level=$3;
		my $title=$4;
		if ($VERBOSE>0){print "#chapter:$c file:$file level:$level title:$title\n";}
		if ($c != $prev_c){ $s=0; $p=0; $prev_c=$c; }
		if ($level==1){
			if ($type eq 'header'){
 				print "	<tr class=tocrow><td><a href=\"$file#a$c\">";
				print "<span CLASS=tocitem> $c $title</span></a></td></tr>\n";
			}
			if ($type eq 'index'){print ".br\n.link $file#a$c. $c $title\n";}
		}
		elsif ($level==2){
			$s++; $p=0;
#			if ($type eq 'header'){ print "	<tr class=tocrow><td>&nbsp;</td><td colspan=2><a href=\"$file#a$c.$s\"><span CLASS=tocitem>$c.$s $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print ".br\n.link $file#a$c.$s. $c.$s $title\n";}
		}
		elsif ($level==3){
			$p++;
#			if ($type eq 'header'){ print "	<tr class=tocrow><td>&nbsp;</td><td>&nbsp;</td><td><a href=\"$file#a$c.$s.$p\"><span CLASS=tocitem>$c.$s.$p $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print ".br\n.link $file#a$c.$s.$p. $c.$s.$p $title\n";}
		}
	}
	elsif ($inline=~/(.*).in:\.h([12]) (.*)/){
		my $file="$1.html";
		my $level=$2;
		my $title=$3;
		if ($level==1){
			$c++;
			if ($c != $prev_c){ $s=0; $p=0; $prev_c=$c; }
			if ($type eq 'header'){ print "	<tr class=tocrow><td><a href=\"$file#a$c\"><span CLASS=tocitem> $c $title</span></a></td></tr>\n"; }
			if ($type eq 'index'){print ".br\n.link $file#a$c $c $title\n";}
		}
		elsif ($level==2){
			$s++; $p=0;
			if ($type eq 'index'){print ".br\n.link $file#a$c.$s $c.$s $title\n";}
		}
		elsif ($level==3){
			$p++;
			if ($type eq 'index'){print ".br\n.link $file#a$c.$s.$p $c.$s.$p $title\n";}
		}
	}
	elsif ($inline=~/.in:\.toc([123])/){
		my $level=$1;
		s/.*\.toc.//;
		if  ($type eq 'index') {
		 	print ".hu $level $_\n";
		}
	}
	elsif ($inline=~/.in:\.toc /){
		s/.*\.toc *//;
		if ($type eq 'index'){
			print "$_\n";
		}
	}
}
if ($type eq 'header'){
	print "</table>\n";
}
else {
	if ( -f "index.bottom"){
		if (open(my $IT,'<',"index.bottom")){
			while (<$IT>){print;}
			close $IT;
		}
	}
	
}
