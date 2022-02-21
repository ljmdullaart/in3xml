#!/usr/bin/perl
#
use strict;
use utf8;
use Tk;
use Tk::Font;

my $mw = MainWindow->new();
my $font = $mw->fontCreate( 'TimesNew Roman' );
sub timesspace {
	(my $text)=@_;
	my $retval= $font->measure( $text )/4.5;
	return int($retval);
}


for (my $i=32; $i<256;$i++){
	my $str=chr($i) x 1000;
	my $width=timesspace($str);
	print chr($i) . ':' . $width . "\n";
}
