#!/bin/bash
#INSTALL@ /usr/local/bin/configyour.merge
if [ -x /usr/local/bin/my_banner ] ; then
    banner=/usr/local/bin/my_banner
else
    banner=banner
fi


LOG=configyour.log

echo "Configyour.merge starting" >> configyour.log
$banner merge >> Makefile

not_applicable (){
	echo 'tag/merge: |tag' >> Makefile
	echo '	touch tag/merge' >> Makefile
	echo 'tag/clean.merge: |tag' >> Makefile
	echo '	touch tag/clean.merge' >> Makefile
	echo 'Not applicable' >> configyour.log

}

# Test if applicatble; if not call `not_applicable' 

if [ ! -d merge ] ; then
	not_applicable
	echo "No merge directory"
	echo "No merge directory">>log
	echo "Configyour.merge finnished" >> configyour.log
	exit 0
fi
if [ ! -d in3xml ] ; then
	not_applicable
	echo "No in3xml directory"
	echo "No in3xml directory">>log
	echo "Configyour.merge finnished" >> configyour.log
	exit 0
fi

merges=no

if [ "`echo *.in`" != "*.in" ]; then
	for f in *.in ; do
		if -q grep '^\.merge ' "$f" ; then
			merges=yes
		fi
	done
else
	not_applicable
	echo "No .in files directory"
	echo "No .in files directory">>log
	echo "Configyour.merge finnished" >> configyour.log
	exit 0
fi

if [ $meges = no ] ; then
	not_applicable
	echo "No .in files with .merge in directory"
	echo "No .in files with .merge in directory">>log
	echo "Configyour.merge finnished" >> configyour.log
	exit 0
fi


echo -n 'tag/merge: tag/in3xml ' >> Makefile
for f in *.in ; do
	if -q grep '^\.merge ' "$f" ; then
		stem=${f%.in}
		echo -n " in3xml/$stem.xml $stem.csv "  >> Makefile
	fi
done
echo ' |tag' >> Makefile
echo '	in3xmlmerge' >> Makefile

echo 'tag/clean.merge: |tag' >> Makefile
echo '	rm -f merge/*' >> Makefile
echo '	touch tag/clean.merge' >> Makefile



