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

debug(){
	if [ "$DEBUG" = "1" ] ; then
		echo "$*"
	fi
}

if [ "$2" = "" ] ; then
	helpme
	exit 0
fi

fromfile="$1"
tofile="$2"
frombase=$(basename "$fromfile")
tobase=$(basename "$tofile")
fromext=${frombase##*.}
toext=${tobase##*.}
fromstem=${frombase%.*}
tostem=${tobase%.*}

cat >> /tmp/in3fileconv.log <<EOF
------------------------
fromfile=$fromfile
tofile=$tofile
frombase=$frombase
tobase=$tobase
fromext=$fromext
toext=$toext
fromstem=$fromstem
tostem=$tostem
------------------------
EOF


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
				debug cairosvg  -f ps "$fromfile" -o "block/$tobase"
				cairosvg  -f ps "$fromfile" -o "block/$tobase"
				;;
			(png)
				debug convert -density 1000 -scale 15% -trim "$fromfile" "block/$tobase"
				convert -density 1000 -scale 15% -trim "$fromfile" "block/$tobase"
				;;
			(svg)
				debug cp "$fromfile" "block/$tobase"
				cp "$fromfile" "block/$tobase"
				;;
			(pdf)
				debug cairosvg  -f ps "$fromfile" -o $TMP.ps
				cairosvg  -f ps "$fromfile" -o $TMP.ps
				debug ps2pdf $TMP.ps $TMP.pdf
				ps2pdf $TMP.ps $TMP.pdf
				debug pdfcrop $TMP "block/$tostem.pdf"
				pdfcrop $TMP "block/$tostem.pdf"
				debug rm -f $TMP.ps $TMP.pdf
				rm -f $TMP.ps $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(JPG)
		case $toext in
			(eps)
				debug convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				;;
			(png)
				debug convert "$fromfile" "block/$tobase"
				convert "$fromfile" "block/$tobase"
				;;
			(pdf)
				debug convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
			 	debug pdfcrop $TMP.pdf "block/$tobase"
			 	pdfcrop $TMP.pdf "block/$tobase"
				rm -f $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(jpg)
		case $toext in
			(eps)
				debug convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				;;
			(png)
				debug convert "$fromfile" "block/$tobase"
				convert "$fromfile" "block/$tobase"
				;;
			(pdf)
				debug convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
			 	debug pdfcrop $TMP.pdf "block/$tobase"
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
				debug convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				;;
			(png)
				debug cp "$fromfile" "block/$tobase"
				cp "$fromfile" "block/$tobase"
				;;
			(pdf)
				debug convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
			 	debug pdfcrop $TMP.pdf "block/$tobase"
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
				debug dia -t eps "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				dia -t eps "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				;;
			(png)
				debug dia -t png "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				dia -t png "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				;;
			(svg)
				debug dia -t svg "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				dia -t svg "$fromfile"  -e "block/$tobase" > /dev/null 2>/dev/null
				;;
			(pdf)
				debug dia -t eps "$fromfile"  -e $TMP.ps > /dev/null 2>/dev/null
				dia -t eps "$fromfile"  -e $TMP.ps > /dev/null 2>/dev/null
				debug ps2pdf $TMP.ps $TMP.pdf > /dev/null 2>/dev/null
				ps2pdf $TMP.ps $TMP.pdf > /dev/null 2>/dev/null
				debug pdfcrop $TMP "block/$tostem.pdf" > /dev/null 2>/dev/null
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
				debug dvips -E "$fromfile" -o "block/$tobase"
				dvips -E "$fromfile" -o "block/$tobase"
				;;
			(png)
				echo "convert -trim -density 500 $fromfile block/$tobase"
				convert -trim -density 750 "$fromfile" "block/$tobase" > /dev/null 2>/dev/null
				;;
			(svg)
				debug dvipdf "$fromfile"  "block/$tostem.pdf"
				dvipdf "$fromfile"  "block/$tostem.pdf"
				debug pdfcrop "block/$tostem.pdf" "block/$tostem.c.pdf"
				pdfcrop "block/$tostem.pdf" "block/$tostem.c.pdf"
				debug pdf2svg "block/$tostem.c.pdf" "block/$tostem.svg"
				pdf2svg "block/$tostem.c.pdf" "block/$tostem.svg"
				#dvifontpath=$(find /usr/share -name 'ps2pk.map' -exec dirname {} \;  2>&1 | grep -v 'Permission denied' | tail -1)
				#dvisvgm -n -c1.5 -m $dvifontpath "$fromfile" -o block/$tostem.svg
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(eqn)
		case $toext in
			(eps) 
				debug eqn $fromfile > block/$tostem.groff
				eqn $fromfile > block/$tostem.groff
				debug groff block/$tostem.groff > block/$tostem.ps
				groff block/$tostem.groff > block/$tostem.ps
				debug gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps"
				gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps"
				;;
			(png)
				debug eqn $fromfile > block/$tostem.groff
				eqn $fromfile > block/$tostem.groff > /dev/null 2>/dev/null
				debug groff block/$tostem.groff > block/$tostem.ps
				groff block/$tostem.groff > block/$tostem.ps > /dev/null 2>/dev/null
				debug gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps"
				gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps" > /dev/null 2>/dev/null
				debug convert -density 1000 "block/$tostem.eps" "block/$tostem.png"
				convert -density 1000 -trim "block/$tostem.eps" "block/$tostem.png" > /dev/null 2>/dev/null
				;;
			(svg)
				debug dvifontpath=$(find /usr/share -name 'ps2pk.map' -exec dirname {} \; 2>&1 | grep -v 'Permission denied' | tail -1)
				dvifontpath=$(find /usr/share -name 'ps2pk.map' -exec dirname {} \; 2>&1 | grep -v 'Permission denied' | tail -1)
				debug eqn $fromfile > block/$tostem.groff
				eqn $fromfile > block/$tostem.groff
				debug groff block/$tostem.groff -Tdvi > block/$tostem.dvi
				groff block/$tostem.groff -Tdvi > block/$tostem.dvi
				debug dvisvgm -n -c1.5 -m $dvifontpath block/$tostem.dvi -o block/$tostem.svg
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
				debug sed -i '1i set terminal postscript eps' block/$tostem.plt
				sed -i '1i set terminal postscript eps' block/$tostem.plt
				debug sed -i "1i set output 'block/$tostem.eps'" block/$tostem.plt
				sed -i "1i set output 'block/$tostem.eps'" block/$tostem.plt
				debug gnuplot block/$tostem.plt
				gnuplot block/$tostem.plt
				;;
			(png)
				debug sed -i '1i set terminal png size 800,800 enhanced font "Helvetica,8"' block/$tostem.plt
				sed -i '1i set terminal png size 800,800 enhanced font "Helvetica,8"' block/$tostem.plt
				debug sed -i "1i set output 'block/$tostem.png'" block/$tostem.plt
				sed -i "1i set output 'block/$tostem.png'" block/$tostem.plt
				debug gnuplot block/$tostem.plt
				gnuplot block/$tostem.plt
				;;
			(svg)
				debug sed -i '1i set terminal svg' block/$tostem.plt
				sed -i '1i set terminal svg' block/$tostem.plt
				debug sed -i "1i set output 'block/$tostem.svg'" block/$tostem.plt
				sed -i "1i set output 'block/$tostem.svg'" block/$tostem.plt
				debug gnuplot block/$tostem.plt
				gnuplot block/$tostem.plt
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(*)
		>&2 echo "Sorry, no conversion from $fromext"
		;;


esac

rm -f $TMP*
