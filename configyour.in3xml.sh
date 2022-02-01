#!/bin/bash
#INSTALL@ /usr/local/bin/configyour.in3xml
if [ -x /usr/local/bin/my_banner ] ; then
    banner=/usr/local/bin/my_banner
else
    banner=banner
fi

LOG=configyour.log

WWW=web
PDF=roff
HTM=htm
XML=in3xml
EPUB=ebook

echo "Configyour.in3xml starting" >> $LOG
$banner in3xml >> Makefile

not_applicable (){
	echo 'tag/in3xml: |tag' >> Makefile
	echo '	touch tag/in3xml' >> Makefile
	echo 'tag/clean.in3xml: |tag' >> Makefile
	echo '	touch tag/clean.in3xml' >> Makefile
	echo 'Not applicable' >> $LOG
	exit 0
}

# Test if applicable; if not call `not_applicable' 

if [ ! -d $XML ] ; then
	echo "No $XML directory" >> $LOG
	not_applicable
fi

if ls *.in >/dev/null 2>/dev/null ; then
	echo '# in3xml --- main targets' >> Makefile
else

	echo 'No .in files in directory' >> $LOG
	not_applicable
fi

if [ -f meta.in ] ; then 
	META=yes
else
	META=no
fi
if [ -f stylesheet.mm ] ; then
	if grep -q "^\.NOHEAD" stylesheet.mm ; then
		dohead=' -rN4  '
	else
		dohead=''
	fi
else
	dohead=''
fi

if [ ! -d block ] ; then
	mkdir block
fi
if [ -d $WWW ] ; then

	if [ ! -L $WWW/block ] ; then
		ln -s $(realpath block) $WWW/block
		echo "Linked block"
	fi
fi

echo " WWW=$WWW" >>$LOG
echo " PDF=$PDF" >>$LOG
echo " HTM=$HTM" >>$LOG
echo " XML=$XML" >>$LOG
echo " EPUB=$EPUb" >>$LOG

#                  _         _                       _
#  _ __ ___   __ _(_)_ __   | |_ __ _ _ __ __ _  ___| |_ ___
# | '_ ` _ \ / _` | | '_ \  | __/ _` | '__/ _` |/ _ \ __/ __|
# | | | | | | (_| | | | | | | || (_| | | | (_| |  __/ |_\__ \
# |_| |_| |_|\__,_|_|_| |_|  \__\__,_|_|  \__, |\___|\__|___/
#                                         |___/

echo -n 'tag/in3xml: tag/in3xml.xml' >> Makefile
if [ -d $WWW ] ; then
	echo -n " tag/in3xml.$WWW" >> Makefile
else
	echo "No $WWW" >>$LOG
fi
if [ -d $PDF ] ; then
	echo -n " tag/in3xml.$PDF" >> Makefile
else
	echo "No $PDF" >>$LOG
fi
if [ -d $HTM ] ; then
	echo -n " tag/in3xml.$HTM" >> Makefile
else
	echo "No $HTM" >>$LOG
fi
if [ -d $EPUB ] ; then
	echo -n " tag/in3xml.$EPUB" >> Makefile
else
	echo "No $EPUB" >>$LOG
fi
echo " |tag" >> Makefile
echo "	touch tag/in3xml" >> Makefile
echo "tag/clean.in3xml: |tag" >> Makefile
echo "	rm -f tag/in3xml.*"  >> Makefile
echo "	rm -f $WWW/*"  >> Makefile
echo "	rm -f $PDF/*"  >> Makefile
echo "	rm -f $HTM/*"  >> Makefile
echo "	rm -f $EPUB/*"  >> Makefile
echo "	rm -f $XML/*"  >> Makefile
echo "	touch tag/clean.in3xml" >> Makefile

#  _           _                __  _                    _
# (_)_ __   __| | _____  __    / / | |__   ___  __ _  __| | ___ _ __
# | | '_ \ / _` |/ _ \ \/ /   / /  | '_ \ / _ \/ _` |/ _` |/ _ \ '__|
# | | | | | (_| |  __/>  <   / /   | | | |  __/ (_| | (_| |  __/ |
# |_|_| |_|\__,_|\___/_/\_\ /_/    |_| |_|\___|\__,_|\__,_|\___|_|
#

index_top_bottom=' '
if [ -f index.top ] ; then
	index_top_bottom=index.top
fi
if [ -f index.bottom ] ; then
	index_top_bottom="$index_top_bottom index.bottom"
fi

if grep 'index.in:' Makefile ; then
	echo -n "Someone else already made index/headers" >>$LOG
else
	echo  "index.in:">> $LOG
	echo  -n "index.in: $index_top_bottom" >> Makefile
	for infile in *.in ; do
		stem=${infile%.in}
		if [ "$infile" = "total.in" ] ; then
			:
		elif [ "$infile" = "index.in" ] ; then
			:
		elif [ "$infile" = "meta.in" ] ; then
			:
		else
			echo -n " $infile" >> Makefile
		fi
	done
	echo >> Makefile
	echo "	mkinheader -i > index.in" >> Makefile
	touch index.in
fi



#                            _      _         _
#   ___ ___  _ __ ___  _ __ | | ___| |_ ___  (_)_ __
#  / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __/ _ \ | | '_ \
# | (_| (_) | | | | | | |_) | |  __/ ||  __/_| | | | |
#  \___\___/|_| |_| |_| .__/|_|\___|\__\___(_)_|_| |_|
#                     |_|

echo  'complete.in:' >> $LOG
echo  -n 'complete.in:' >> Makefile
for infile in *.in ; do
	stem=${infile%.in}
	if [ "$infile" = "complete.in" ] ; then
		:
	elif [ "$infile" = "total.in" ] ; then
		:
	elif [ "$infile" = "index.in" ] ; then
		:
	elif [ "$infile" = "meta.in" ] ; then
		:
	else
		echo -n " $infile" >> Makefile
	fi
done
echo >> Makefile
touch "complete.in"
echo -n "complete.in:" >>$LOG

echo  "	rm -f complete.in">> Makefile
echo -n "	awk 'FNR==1{print \"\"}{print}' ">> Makefile
i=0
for infile in $(ls *.in| sort -n) ; do
	i=$((i+1))
	stem=${infile%.in}
	if [ "$infile" = "complete.in" ] ; then
		:
	elif [ "$infile" = "total.in" ] ; then
		:
	elif [ "$infile" = "index.in" ] ; then
		:
	elif [ "$infile" = "meta.in" ] ; then
		:
	else
		echo -n " $infile" >> Makefile
		echo -n " $infile" >> $LOG
		if [ $i = 0 ] ; then
			cat $infile >> complete.in
		else
			awk 'FNR==1{print ""}{print}' $infile >> complete.in
		fi
		
	fi
done
echo ' | grep -vh '^\.header' > complete.in' >> Makefile
echo '' >>$LOG

#                 _   _                       _
# __  ___ __ ___ | | | |_ __ _ _ __ __ _  ___| |_ ___
# \ \/ / '_ ` _ \| | | __/ _` | '__/ _` |/ _ \ __/ __|
#  >  <| | | | | | | | || (_| | | | (_| |  __/ |_\__ \
# /_/\_\_| |_| |_|_|  \__\__,_|_|  \__, |\___|\__|___/
#                                  |___/

echo "XML targets:">>$LOG
echo -n "tag/in3xml.xml:" >> Makefile
for infile in *.in ; do
	stem=${infile%.in}
	if [ "$infile" = "meta.in" ] ; then
		:
	elif [ "$infile" = "total.in" ] ; then
		:
	else
		echo -n " $XML/$stem.xml" >> Makefile
	fi
done
echo ' |tag'>> Makefile
echo "	touch tag/$XML.xml" >> Makefile

for infile in *.in ; do
	stem=${infile%.in}
	if [ "$infile" = "meta.in" ] ; then
		:
	elif [ "$infile" = "total.in" ] ; then
		:
	elif [ "$infile" = "complete.in" ] ; then
		echo -n "$XML/$stem.xml: $infile " >> Makefile
		if [ -f metacomplete.in ] ; then
			echo " metacomplete.in " >> Makefile
		elif [ -f meta.in ] ; then
			echo " meta.in " >> Makefile
		else
			echo >> Makefile
		fi
		if [ -f metacomplete.in ] ; then
			echo "	in3multipass --metacomplete.in  $infile > $XML/$stem.xml" >> Makefile
		else
			echo "	in3multipass $infile > $XML/$stem.xml" >> Makefile
		fi
		echo "	xmllint --postvalid $XML/$stem.xml > /dev/null" >> Makefile
		echo "    $XML/$stem.xml" >> $LOG
	else
		echo -n "$XML/$stem.xml: $infile " >> Makefile
		if [ $META = yes ] ; then
			echo " meta.in" >> Makefile
		else
			echo >> Makefile
		fi
		echo "	in3multipass $infile > $XML/$stem.xml" >> Makefile
		echo "	xmllint --postvalid $XML/$stem.xml > /dev/null" >> Makefile
		echo "    $XML/$stem.xml" >> $LOG
	fi
done
echo >> Makefile

#  _     _             _   _                       _
# | |__ | |_ _ __ ___ | | | |_ __ _ _ __ __ _  ___| |_ ___
# | '_ \| __| '_ ` _ \| | | __/ _` | '__/ _` |/ _ \ __/ __|
# | | | | |_| | | | | | | | || (_| | | | (_| |  __/ |_\__ \
# |_| |_|\__|_| |_| |_|_|  \__\__,_|_|  \__, |\___|\__|___/
#                                       |___/

if [ -d $WWW ] ; then
	echo "$WWW/block: |block">> Makefile
	echo "	- ln -s $(realpath block) $WWW" >> Makefile
	echo "WWW targets in $WWW:" >> $LOG
	echo -n "tag/in3xml.$WWW: tag/in3xml.xml" >> Makefile
	for infile in *.in ; do		# the *.in are the only guaranteed availables
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		elif [ "$infile" = "total.in" ] ; then
			:
		else
			echo -n " $WWW/$stem.html" >> Makefile
		fi
	done
	echo ' |tag'>> Makefile
	echo "	touch tag/in3xml.$WWW" >> Makefile

	for infile in *.in ; do
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		elif [ "$infile" = "total.in" ] ; then
			:
		else
			echo "$WWW/$stem.html: $XML/$stem.xml | $WWW/block" >> Makefile
			echo "	xml3html $XML/$stem.xml > $WWW/$stem.html" >> Makefile
			echo "    $WWW/$stem.html" >>$LOG
		fi
	done
	echo >> Makefile
fi

if [ -d $HTM ] ; then
	echo "HTM Targets in $HTM:">>$LOG
	echo -n "tag/in3xml.$HTM: tag/in3xml.xml $HTM/header.htm" >> Makefile
	for infile in *.in ; do		# the *.in are the only guaranteed availables
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		elif [ "$infile" = "total.in" ] ; then
			:
		else
			echo -n " $HTM/$stem.htm" >> Makefile
		fi
	done
	echo ' |tag'>> Makefile
	echo "	touch tag/in3xml.$HTM" >> Makefile

	echo "$HTM/header.htm: complete.in" >> Makefile
	echo "	mkinheader > $HTM/header.htm" >> Makefile

	for infile in *.in ; do
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		elif [ "$infile" = "total.in" ] ; then
			:
		else
			echo "$HTM/$stem.htm: $XML/$stem.xml " >> Makefile
			echo "	xml3html --no-headers $XML/$stem.xml > $HTM/$stem.htm" >> Makefile
			echo "    $HTM/$stem.htm" >>$LOG
		fi
	done
	echo >> Makefile
fi

if [ ! -f stylesheet.css ] ; then
	echo "Created empty stylesheet">>$LOG
cat > stylesheet.css <<EOF
h1,h2,h3,h4 {
    font-family:"arial";
}
.toc {
    font-family:"Times";
}
p {
    font-family:"Times";
}
.lst {
    font-family:"Courier New";
}
.fixed {
    font-family:"Courier New";
}
table.table {
}
td.table {
}
.cell {
}
table.paragraph {
}
td.leftnote{
}
td.paragraph {
    font-family:"Times";
}
.list {
}
EOF
else 
	echo "stylesheet exists">>$LOG	
	
fi
#  ____  ____  _____   _                       _
# |  _ \|  _ \|  ___| | |_ __ _ _ __ __ _  ___| |_ ___
# | |_) | | | | |_    | __/ _` | '__/ _` |/ _ \ __/ __|
# |  __/| |_| |  _|   | || (_| | | | (_| |  __/ |_\__ \
# |_|   |____/|_|      \__\__,_|_|  \__, |\___|\__|___/
#                                   |___/

pwd >>$LOG

ls -ld |grep $PDF >>$LOG

if [ -d $PDF ] ; then
	echo "PDF Targets in $PDF:">>$LOG
	echo -n "tag/in3xml.$PDF: tag/in3xml.xml" >> Makefile
	for infile in *.in ; do		# the *.in are the only guaranteed availables
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		elif [ "$infile" = "total.in" ] ; then
			:
		else
			echo -n " $PDF/$stem.pdf" >> Makefile
		fi
	done
	echo ' |tag'>> Makefile
	echo "	touch tag/in3xml.$PDF" >> Makefile

	for infile in *.in ; do
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		elif [ "$infile" = "total.in" ] ; then
			:
		else
			echo "$PDF/$stem.pdf: $PDF/$stem.roff " >> Makefile
			echo "	cat $PDF/$stem.roff |preconv> $PDF/$stem.tbl" >> Makefile
			echo "	cat $PDF/$stem.tbl |tbl > $PDF/$stem.pic" >> Makefile
			echo "	cat $PDF/$stem.pic |pic > $PDF/$stem.eqn" >> Makefile
			echo "	cat $PDF/$stem.eqn |eqn > $PDF/$stem.rof" >> Makefile
			#echo "	cat $PDF/$stem.rof |groff -min -Kutf8 -Tpdf -pdfmark > $PDF/$stem.pdf" >> Makefile
			if [ -f stylesheet.mm ] ; then
				if grep -q '^\.NOHEAD' stylesheet.mm ; then
					dohead=' -rN4  '
				fi
			fi
			if [ "$stem" = "complete" ] ; then
				echo "	cat $PDF/$stem.rof |groff -min -rN=4 -Kutf8 -rN4 > $PDF/$stem.ps" >> Makefile
			elif [ "$stem" = "total" ] ; then
				echo "	cat $PDF/$stem.rof |groff -min -rN=4 -Kutf8  -rN4 > $PDF/$stem.ps" >> Makefile
			else
				echo "	cat $PDF/$stem.rof |groff -min -Kutf8 $dohead > $PDF/$stem.ps" >> Makefile
			fi
			echo "	cat $PDF/$stem.ps  | ps2pdf  -dPDFSETTINGS=/prepress - - > $PDF/$stem.pdf" >> Makefile
			if [ "$stem" = "complete" ] ; then
				echo "	pdfrm1stblank $PDF/$stem.pdf" >> Makefile
			fi
			echo "$PDF/$stem.roff: $XML/$stem.xml " >> Makefile
			if [ "$stem" = "complete" ] ; then
				echo "	xml3roff $XML/$stem.xml > $PDF/$stem.roff" >> Makefile
			else
				echo "	xml3roff $XML/$stem.xml > $PDF/$stem.roff" >> Makefile
			fi
			echo "    $PDF/$stem.roff" >>$LOG
		fi
	done
	echo >> Makefile
fi


rm -f complete.in

echo "Configyour.in3xml finnished" >> $LOG


