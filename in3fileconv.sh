#!/bin/bash
#INSTALL@ /usr/local/bin/in3fileconv

helpme(){
realpath $0
cat << EOF
NAME: in3fileconv -- file conversions all sorts of images
SYNOPSYS: in3fileconv source.ext destination.ext
DESCRIPTION:
in3fileconv converts source files as best as possible into
destination files. The extension is used to determine the 
type of the file.

Always, the destination is placed in the subdir block.

+------------------------------+
|      |           to          |
|      |-----------------------|
| from | eps | png | svg | pdf |
|------+-----+-----+-----+-----+
| svg  |  y  |  y  |  .  |     |
| png  |  y  |  .  |  -  |     |
| dia  |  y  |  y  |  y  |     |
| eqn  |  y  |  y  |  y  |     |


note:
   y  Conversion is available
   .  No conversion needed
   -  No conversion available
         
EOF
}

if [ "$2" = "" ] ; then
	helpme
	exit 0
fi

fromfile="$1"
tofile="$2"
frombase=$(basename "$fromfile")
tobase=$(basename "$tofile")
fromext=${frombase#*.}
toext=${tobase#*.}
fromstem=${frombase%.*}
tostem=${tobase%.*}


if [ ! -d block ] ; then
	mkdir block
fi

if [ "$fromfile" = "block/$tobase" ] ; then
	>&2 echo "Fromfile $fromfile is block/$tobase; no converion done."
	if [ "$tofile" = "block/$tobase" ] ; then
	   >&2 echo "To-file $tofile is block/$tobase; no copy made."
   else
	   cp "block/$tobase" "$tofile"
	fi
	exit 0
fi
TMP=$(mktemp /tmp/in3fileconv.XXXXXXXXX)

case $fromext in
	(svg)
		case $toext in
			(eps)
				cairosvg  -f ps "$fromfile" -o "block/$tobase"
				;;
			(png)
				convert -density 1000 -scale 15% -trim "$fromfile" "block/$tobase"
				;;
			(svg)
				cp "$fromfile" "block/$tobase"
				;;
			(pdf)
				cairosvg  -f ps "$fromfile" -o $TMP.ps
				ps2pdf $TMP.ps $TMP.pdf
				pdfcrop $TMP "block/$tostem.pdf"
				rm -f $TMP.ps $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(jpg)
		case $toext in
			(eps)
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				;;
			(png)
				convert "$fromfile" "block/$tobase"
				;;
			(pdf)
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
			 	pdfcrop $TMP.pdf "block/$tobase"
				rm -f $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(png)
		case $toext in
			(eps)
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				;;
			(png)
				cp "$fromfile" "block/$tobase"
				;;
			(pdf)
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
			 	pdfcrop $TMP.pdf "block/$tobase"
				rm -f $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(dia)
		case $toext in
			(eps)
				dia -t eps "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				;;
			(png)
				dia -t png "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				;;
			(svg)
				dia -t svg "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				;;
			(pdf)
				dia -t eps "$fromfile"  -e $TMP.ps > /dev/null 2>/dev/null
				ps2pdf $TMP.ps $TMP.pdf > /dev/null 2>/dev/null
				pdfcrop $TMP "block/$tostem.pdf" > /dev/null 2>/dev/null
				rm -f $TMP.ps $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(dvi)
		case $toext in
			(eps) 
				dvips -E "$fromfile" -o "block/$tobase"
				;;
			(png)
				dvipng  --bdpi 1000 -Q 15 "$fromfile" -o "block/$tostem.untr.png"
				convert -trim "block/$tostem.untr.png" "block/$tobase"
				;;
			(svg)
				dvifontpath=$(find /usr/share -name 'ps2pk.map' -exec dirname {} \;  2>&1 | grep -v 'Permission denied' | tail -1)
				dvisvgm -n -c1.5 -m $dvifontpath "$fromfile" -o block/$tostem.svg
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(eqn)
		case $toext in
			(eps) 
				eqn $fromfile > block/$tostem.groff
				groff block/$tostem.groff > block/$tostem.ps
				gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps"
				;;
			(png)
				eqn $fromfile > block/$tostem.groff
				groff block/$tostem.groff > block/$tostem.ps
				gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps"
				convert -density 300 "block/$tostem.eps" "block/$tostem.png"
				;;
			(svg)
				dvifontpath=$(find /usr/share -name 'ps2pk.map' -exec dirname {} \; 2>&1 | grep -v 'Permission denied' | tail -1)
				eqn $fromfile > block/$tostem.groff
				groff block/$tostem.groff -Tdvi > block/$tostem.dvi
				dvisvgm -n -c1.5 -m $dvifontpath block/$tostem.dvi -o block/$tostem.svg
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(gpi)
		egrep -v 'set terminal|set output' $fromfile > block/$tostem.plt
		case $toext in
			(eps) 
				sed -i '1i set terminal postscript eps' block/$tostem.plt
				sed -i "1i set output 'block/$tostem.eps'" block/$tostem.plt
				gnuplot block/$tostem.plt
				;;
			(png)
				sed -i '1i set terminal png size 800,800 enhanced font "Helvetica,8"' block/$tostem.plt
				sed -i "1i set output 'block/$tostem.png'" block/$tostem.plt
				gnuplot block/$tostem.plt
				;;
			(svg)
				sed -i '1i set terminal svg' block/$tostem.plt
				sed -i "1i set output 'block/$tostem.svg'" block/$tostem.plt
				gnuplot block/$tostem.plt
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;


esac

rm -f $TMP*
