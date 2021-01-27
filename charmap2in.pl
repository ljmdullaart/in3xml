#!/usr/bin/perl
#

my @charmap;
if (open(my $CH,'<','in3charmap1')){
	@charmap=<$CH>;
}
else {die "Cannot open in3charmap1";}


print ".header\n\n";
print ".h1 In3 character map\n\n";
print ".h2 Percent translations\n\n";
print "	.b %% +	.b char	.b groff	.b html\n";
for (@charmap){
	if (/^%([^	]*)	/){
		print "	$1	";
		print;
	}
}
print "\n\n";
print ".page\n\n";
print ".h2 Characterset\n\n";
my $i=3;
for (@charmap){
	if (/^%([^	]*)	/){}
	elsif (/^#/){}
	else {
		if ($i==0){
			print "\n\n.page\n\n";
			print "	.b char	.b groff	.b html\n";
		}
		print "	";
		print;
		$i++;
		if ($i>35){$i=0;}
	}
}

print "\n\n";
