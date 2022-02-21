#!/usr/bin/perl
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml
#INSTALL@ /usr/local/bin/fontlength
use strict;


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
	(my $intxt)=@_;
	my @str=split (//,$intxt);
	my $total=0;
	for (@str){
		if (defined($fontmeasure{$_})){
			$total=$total+$fontmeasure{$_};
		}
		else {
			$total=$total+250;
		}
	}
	undef @str;
	return $total;
}



my @str;
while (<>){
	my $total=timesspace($_);
	print "$total\n";
}
