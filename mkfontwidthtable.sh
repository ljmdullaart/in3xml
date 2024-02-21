#!/bin/bash
#INSTALL@ /usr/local/bin/mkfontwidthtable
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml
tmpfont=tmpfont

font=$(basename $1)
if [ ! -f "/usr/share/groff/current/font/devps/$font" ] ; then
	echo "No suchfont $font"
	exit 
fi

cp "/usr/share/groff/current/font/devps/$font" $tmpfont
sed -i '1,/charset/d' $tmpfont
sed -i 's/,.*//' $tmpfont
sed -i 's/^\(..\)\t/\\(\1  /'  $tmpfont
sed -i 's/^\(...\)\t/\\[\1]  /'  $tmpfont
sed -i '/^\(.....*\)\t/d'  $tmpfont
sed -i '/"/d'  $tmpfont
sed -i 'a .br'  $tmpfont
groff $tmpfont > $tmpfont.ps

echo "#INSTALL@ /usr/local/share/in3/$font.measure" > $font.measure
ps2ascii $tmpfont.ps  | sed 's/ //g;s/^\(.\)/\1	/'>>$font.measure
sudo cp $font.measure /usr/local/share/in3/
rm $tmpfont
