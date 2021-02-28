#!/usr/bin/perl
#
#INSTALL@ /usr/local/bin/in3xmlmerge

my $csvfile='';
my $xmlfile='';
my $fieldflag=0;

sub usage {
	print "xmlmerge\n";
	print " Merges all .in3 xml files with .merge requests with their csv\n";
	print " csv  : ; separated file; first line=field names\n";
	print " xml  : xml version of the document (default: stdin)\n";
	print "xmlmerge -f\n";
	print " Print the name of the fields\n";
}

for (@ARGV){
	if (1==0){}
	elsif (/^--*h/){
		usage();
	}
	elsif (/^-f/){
		$fieldflag=1;
	}
}


sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

my %variables;
my @linefields;
my @fields;
my @csv;

sub readcsv {
	my ($csvfile)=@_;
	print STDERR "Trying $csvfile ...";
	undef @fields;
	if (open (my $CSV,'<',$csvfile)){
		@csv=<$CSV>;
		close $CSV;
		for (@csv){chomp;}
		@fields=split (';',$csv[0]);
		return 0;
	}
	else {
		return 1;
	}
}


opendir my $dir, "." or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;
my $OFILE;

for (@files){
	chomp;
	if (/\.in$/){
		my $stem=$_; 
		$stem=~s/.in$//;
		undef  @xml;
		if (open($XML,'<',"in3xml/$stem.xml")){
			@xml=<$XML>;
			close $XML;
		}
		else {
			print STDERR " Cannot open in3xml/$stem.xml\n";
			$xml[0]='<?xml version="1.0"?>';
			$xml[1]='<!DOCTYPE in3xml SYSTEM "/usr/local/share/in3/in3xml.dtd">';
			$xml[2]='<in3xml>';
			$xml[3]='</in3xml>';
		}
		if (readcsv("$stem.csv")==0){
			for (my $csvline=1;$csvline<=$#csv;$csvline++){
				undef @linefields;
				chomp $csv[$csvline];
				@linefields=split(';',$csv[$csvline]);
	
				for (my $i=0;$i<=$#linefields;$i++){
					if (defined($linefields[$i])){
						$variables{$fields[$i]}=$linefields[$i];
					}
					else {
						$variables{$fields[$i]}='';
					}
				} # Variables contains values for this line in the CSV
				if (defined ($variables{'file'})){}
				else { $variables{'file'}="$stem.$csvline";}
				if (open ($OFILE,'>',"merge/$variables{'file'}.xml")){
					my $state=0;
					for (@xml){
						chomp;
						if ($state==0){
							if (/<merge>/){
								$state=1;
							}
							else {
								print $OFILE "$_\n";
							}
						}
						elsif ($state==1){
							if (/<\/merge>/){
								$state=0;
							}
							else {
								if (defined $variables{$_}){
									print $OFILE "$variables{$_}\n";
								}
								else {
									print $OFILE "UNDEFINED $_\n";
								}
							}
						}
					}
					close $OFILE;
				}
				else {
					print STDERR "Cannot open $variables{'file'} for writing\n";
				}
			


			}
		}
		else {
			print STDERR "No csv file for $stem\n";
		}
	}
	else {
		# Not a .in file
	}
}

opendir my $dir, "merge" or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

for (@files){
	if (/\.xml$/){
		my $stem=$_; $stem=~s/.xml$//;
		system ("cat merge/$stem.xml  | xml3roff > merge/$stem.roff");
        system ("cat merge/$stem.roff | preconv  > merge/$stem.tbl" );
        system ("cat merge/$stem.tbl  | tbl      > merge/$stem.pic" );
        system ("cat merge/$stem.pic  | pic      > merge/$stem.eqn" );
        system ("cat merge/$stem.eqn  | eqn      > merge/$stem.rof" );
        system ("cat merge/$stem.rof  | groff -min -Kutf8 -Tpdf -pdfmark  -rN4 > merge/$stem.pdf" );
		system ("cat merge/$stem.xml  | xml3html > merge/$stem.html");
		system ("cat merge/$stem.xml  | xml3html   --no-headers > merge/$stem.htm");
	}
}
if ( -l 'merge/block' ) {}
else {
	system('ln -s $(realpath block) merge/block');
}
