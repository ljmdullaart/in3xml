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
	not_applicable
fi

if ls *.in >/dev/null 2>/dev/null ; then
	echo '# in3xml --- main targets' >> Makefile
else
	not_applicable
fi

if [ -f meta.in ] ; then 
	META=yes
else
	META=no
fi

if [ ! -d block ] ; then
	mkdir block
fi
if [ -d $WWW ] ; then
	if [ ! -L $WWW/block ] ; then
		ln -s $(realpath block) $WWW
	fi
fi


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
	echo "No $WWW"
fi
if [ -d $PDF ] ; then
	echo -n " tag/in3xml.$PDF" >> Makefile
else
	echo "No $PDF"
fi
if [ -d $HTM ] ; then
	echo -n " tag/in3xml.$HTM" >> Makefile
else
	echo "No $HTM"
fi
if [ -d $EPUB ] ; then
	echo -n " tag/in3xml.$EPUB" >> Makefile
else
	echo "No $EPUB"
fi
echo " |tag" >> Makefile
echo "	touch tag/in3xml" >> Makefile
echo "tag/clean.in3xml: |tag" >> Makefile
echo "	rm -f tag/in3xml.*"  >> Makefile
echo "	rm -f $WWW/*"  >> Makefile
echo "	rm -f $PDF/*"  >> Makefile
echo "	rm -f $HTM/*"  >> Makefile
echo "	rm -f $EPUB/*"  >> Makefile
echo "	rm -f $WWW/*"  >> Makefile
echo "	touch tag/clean.in3xml" >> Makefile

#                            _      _         _
#   ___ ___  _ __ ___  _ __ | | ___| |_ ___  (_)_ __
#  / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __/ _ \ | | '_ \
# | (_| (_) | | | | | | |_) | |  __/ ||  __/_| | | | |
#  \___\___/|_| |_| |_| .__/|_|\___|\__\___(_)_|_| |_|
#                     |_|

echo '# in3xml --- xml targets' >> Makefile
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
echo -n "	grep -vh '^\.header' ">> Makefile
for infile in $(ls *.in| sort -n) ; do
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
		cat $infile > complete.in
		
	fi
done
echo ' > complete.in' >> Makefile


#                 _   _                       _
# __  ___ __ ___ | | | |_ __ _ _ __ __ _  ___| |_ ___
# \ \/ / '_ ` _ \| | | __/ _` | '__/ _` |/ _ \ __/ __|
#  >  <| | | | | | | | || (_| | | | (_| |  __/ |_\__ \
# /_/\_\_| |_| |_|_|  \__\__,_|_|  \__, |\___|\__|___/
#                                  |___/

echo -n "tag/in3xml.xml:" >> Makefile
for infile in *.in ; do
	stem=${infile%.in}
	if [ "$infile" = "meta.in" ] ; then
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
	else
		echo -n "$XML/$stem.xml: $infile " >> Makefile
		if [ $META = yes ] ; then
			echo " meta.in" >> Makefile
		else
			echo >> Makefile
		fi
		echo "	in3multipass $infile > $XML/$stem.xml" >> Makefile
		echo "	xmllint --postvalid $XML/$stem.xml > /dev/null" >> Makefile
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
	echo -n "tag/in3xml.$WWW: tag/in3xml.xml" >> Makefile
	for infile in *.in ; do		# the *.in are the only guaranteed availables
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
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
		else
			echo "$WWW/$stem.html: $XML/$stem.xml " >> Makefile
			echo "	xml3html $XML/$stem.xml > $WWW/$stem.html" >> Makefile
		fi
	done
	echo >> Makefile
fi

if [ -d $HTM ] ; then
	echo -n "tag/in3xml.$HTM: tag/in3xml.xml" >> Makefile
	for infile in *.in ; do		# the *.in are the only guaranteed availables
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		else
			echo -n " $HTM/$stem.htm" >> Makefile
		fi
	done
	echo ' |tag'>> Makefile
	echo "	touch tag/in3xml.$HTM" >> Makefile

	for infile in *.in ; do
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
			:
		else
			echo "$HTM/$stem.htm: $XML/$stem.xml " >> Makefile
			echo "	xml3html --no-headers $XML/$stem.xml > $HTM/$stem.htm" >> Makefile
		fi
	done
	echo >> Makefile
fi
	

#  ____  ____  _____   _                       _
# |  _ \|  _ \|  ___| | |_ __ _ _ __ __ _  ___| |_ ___
# | |_) | | | | |_    | __/ _` | '__/ _` |/ _ \ __/ __|
# |  __/| |_| |  _|   | || (_| | | | (_| |  __/ |_\__ \
# |_|   |____/|_|      \__\__,_|_|  \__, |\___|\__|___/
#                                   |___/


if [ -d $PDF ] ; then
	echo -n "tag/in3xml.$PDF: tag/in3xml.xml" >> Makefile
	for infile in *.in ; do		# the *.in are the only guaranteed availables
		stem=${infile%.in}
		if [ "$infile" = "meta.in" ] ; then
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
		else
			echo "$PDF/$stem.pdf: $PDF/$stem.ps " >> Makefile
			echo "	cat $PDF/$stem.ps | ps2pdf - - > $PDF/$stem.pdf" >> Makefile
			echo "$PDF/$stem.ps: $PDF/$stem.roff " >> Makefile
			echo "	cat $PDF/$stem.roff |preconv|pic|eqn|tbl|groff -min -Kutf8 > $PDF/$stem.ps" >> Makefile
			echo "$PDF/$stem.roff: $XML/$stem.xml " >> Makefile
			echo "	xml3roff $XML/$stem.xml > $PDF/$stem.roff" >> Makefile
		fi
	done
	echo >> Makefile
fi



echo "Configyour.feature finnished" >> $LOG


