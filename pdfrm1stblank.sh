#!/bin/sh
#INSTALL@ /usr/local/bin/pdfrm1stblank
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml
IN="$1"
TMP=/tmp/pdfrmblank.$$
PERCENT=$(gs -o -  -dFirstPage=1 -dLastPage=1 -sDEVICE=inkcov "$IN" | grep CMYK | nawk 'BEGIN { sum=0; } {sum += $1 + $2 + $3 + $4;} END { printf "%.5f\n", sum } ')
if [ $(echo "$PERCENT < 0.001" | bc) -eq 1 ] ; then
	if pdftk "$IN" cat 2-end output "$TMP" ; then
		mv "$TMP" "$IN"
	fi
fi
