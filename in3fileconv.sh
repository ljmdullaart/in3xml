#!/bin/bash
#INSTALL@ /usr/local/bin/in3fileconv
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml

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
| xcf  |  y  |  y  |  .  |     |
| png  |  y  |  .  |  -  |     |
| dia  |  y  |  y  |  y  |     |
| eqn  |  y  |  y  |  y  |     |


note:
   y  Conversion is available
   .  No conversion needed
   -  No conversion available
         



EOF
}

DEBUG=1
debug(){
	if [ "$DEBUG" = "1" ] ; then
		echo "$*" >>/tmp/in3fileconv.log 
	fi
}

if [ "$2" = "" ] ; then
	helpme
	exit 0
fi

if [ "$3" = "" ] ; then
	caption=''
else
	caption="$3"
fi
	

touch /tmp/in3fileconv.log

logsize=$(ls -s /tmp/in3fileconv.log | sed 's/ .*//')
if [ $logsize -ge 500 ] ; then
	mv /tmp/in3fileconv.log /tmp/in3fileconv.log.1
	touch /tmp/in3fileconv.log
fi



fromfile="$1"
tofile="$2"
frombase=$(basename "$fromfile")
tobase=$(basename "$tofile")
fromext=${frombase##*.}
toext=${tobase##*.}
fromstem=${frombase%.*}
tostem=${tobase%.*}

gimpcnvt(){
{
cat <<EOF
(define (convert-xcf-png filename outpath)
    (let* (
            (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename )))
            (drawable (car (gimp-image-merge-visible-layers image CLIP-TO-IMAGE)))
            )
        (begin (display "Exporting ")(display filename)(display " -> ")(display outpath)(newline))
	(plug-in-semiflatten RUN-NONINTERACTIVE image drawable)
        (gimp-file-save RUN-NONINTERACTIVE image drawable outpath outpath )
        (gimp-image-delete image)
    )
)

(gimp-message-set-handler 1) ; Messages to standard output
EOF

echo "(convert-xcf-png \"$1\" \"$2\")"

echo "(gimp-quit 0)"

} | gimp -i -b - > /dev/null 2>/dev/null
}

cat >> /tmp/in3fileconv.log <<EOF
------------------------
EOF

if [ ! -f "$fromfile" ] ; then
	>&2 echo "File $fromfile does not exist; trying to correct..."
	echo "File $fromfile does not exist; trying to correct..." >> /tmp/in3fileconv.log
	if    [ -f "$fromstem.xcf" ] ; then fromfile="$fromstem.xcf"; fromext='xcf'
	elif  [ -f "$fromstem.XCF" ] ; then fromfile="$fromstem.XCF"; fromext='XCF'
	elif  [ -f "$fromstem.png" ] ; then fromfile="$fromstem.png"; fromext='png'
	elif  [ -f "$fromstem.PNG" ] ; then fromfile="$fromstem.PNG"; fromext='PNG'
	elif  [ -f "$fromstem.jpg" ] ; then fromfile="$fromstem.jpg"; fromext='jpg'
	elif  [ -f "$fromstem.JPG" ] ; then fromfile="$fromstem.JPG"; fromext='JPG'
	else 
		>&2 echo "Giving it up"
		echo "Giving it up">> /tmp/in3fileconv.log
	fi
fi

cat >> /tmp/in3fileconv.log <<EOF

fromfile=$fromfile
tofile=$tofile
frombase=$frombase
tobase=$tobase
fromext=$fromext
toext=$toext
fromstem=$fromstem
tostem=$tostem

EOF



if [ ! -d block ] ; then
	mkdir block
fi

if [ "$fromfile" = "block/$tobase" ] ; then
	debug "Fromfile $fromfile is block/$tobase; no converion done."
	if [ "$tofile" = "block/$tobase" ] ; then
	   debug "To-file $tofile is block/$tobase; no copy made."
   else
	   if cp "block/$tobase" "$tofile" ; then 
		   :
	   else
		   >&2 echo "cp block/$tobase $tofile failed misserably"
	   fi

	fi
	exit 0
fi
TMP=$(mktemp /tmp/in3fileconv.XXXXXXXXX)

case $fromext in
	(svg)
		case $toext in
			(eps)
				debug "cairosvg  -f ps $fromfile -o block/$tobase"
				cairosvg  -f ps "$fromfile" -o "block/$tobase"
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
					

					
			
				;;
			(png)
				debug "convert -density 1000 -scale 15% -trim $fromfile block/$tobase"
				convert -density 1000 -scale 15% -trim "$fromfile" "block/$tobase" 2>>/tmp/in3fileconv.log
				;;
			(svg)
				debug "cp $fromfile block/$tobase"
				if cp "$fromfile" "block/$tobase" ; then
					:
				else
					>&2 echo "cp $fromfile block/$tobase failed miserably"
				fi
				;;
			(pdf)
				debug "cairosvg  -f ps $fromfile -o $TMP.ps"
				cairosvg  -f ps "$fromfile" -o $TMP.ps
				debug ps2pdf $TMP.ps $TMP.pdf 
				ps2pdf $TMP.ps $TMP.pdf > /dev/null 2> /dev/null
				debug pdfcrop $TMP "block/$tostem.pdf"
				pdfcrop $TMP "block/$tostem.pdf"
				debug rm -f $TMP.ps $TMP.pdf
				rm -f $TMP.ps $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(XCF|xcf)
		case $toext in
			(eps)
				gimpcnvt "$fromfile" block/tmp.$$.png
				convert  "block/tmp.$$.png"  pnm:- | convert -density 300 -trim - "block/$tobase"
				rm -f block/tmp.$$.png
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
				;;
			(jpg|png)
				gimpcnvt "$fromfile" "block/$tobase"
				;;
			(pdf)
				gimpcnvt "$fromfile" block/tmp.$$.png
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
				rm -f block/tmp.$$.png
			 	debug pdfcrop $TMP.pdf "block/$tobase.pdf"
			 	pdfcrop $TMP.pdf "block/$tobase.pdf"
				rm -f $TMP.pdf
				;;
				
			esac
		;;	

	(JPG|jpg)
		case $toext in
			(eps)
				debug "convert  $fromfile  pnm:- | convert -density 300 -trim - block/$tobase"
				convert -resize '1000x1000>'  "$fromfile"  pnm:- | convert -density 300 -gamma 1.5  -trim - "block/$tobase" 2>> /tmp/in3fileconv.log
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
				;;
			(jpg)
				debug convert "$fromfile" "block/$tobase"
				convert -resize '1000x1000>' "$fromfile" "block/$tobase"
				;;
			(png)
				debug convert "$fromfile" "block/$tobase"
				convert -resize '1000x1000>' "$fromfile" "block/$tobase"
				;;
			(pdf)
				debug "convert  -resize '1000x1000>' $fromfile  pnm:- | convert -density 300 -trim - $TMP.pdf"
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - $TMP.pdf
			 	debug pdfcrop $TMP.pdf "block/$tobase"
			 	pdfcrop $TMP.pdf "block/$tobase"
				rm -f $TMP.pdf
				;;
			(*)
				>&2 echo "Sorry, no conversion from $fromext to $toext known."
				;;
		esac ;;
	(PNG|png)
		case $toext in
			(eps)
				debug "convert  $fromfile  pnm:- | convert -density 300 -trim - block/$tobase"
				convert  "$fromfile"  pnm:- | convert -density 300 -trim - "block/$tobase"
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
				;;
			(png)
				debug " cp $fromfile block/$tobase"
				if cp "$fromfile" "block/$tobase" ; then
					:
				else 
					>&2 echo " cp $fromfile block/$tobase failed miserably"
				fi
				;;
			(pdf)
				debug "convert  $fromfile  pnm:- | convert -density 300 -trim - $TMP.pdf"
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
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
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
				ps2pdf $TMP.ps $TMP.pdf > /dev/null 2>/dev/null > /dev/null 2> /dev/null
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
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
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
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
				;;
			(png)
				debug eqn $fromfile > block/$tostem.groff
				eqn $fromfile > block/$tostem.groff > /dev/null 2>/dev/null
				debug groff block/$tostem.groff > block/$tostem.ps
				groff block/$tostem.groff > block/$tostem.ps > /dev/null 2>/dev/null
				debug gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps"
				gs -o "block/$tostem.eps" -sDEVICE=eps2write "block/$tostem.ps" > /dev/null 2>/dev/null
				debug "convert -density 1000 block/$tostem.eps block/$tostem.png"
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
				if [ "$caption" = "" ] ; then
					:
				else
					cd block
					mv "$tobase" "$tobase".nocap
					echo ".PSPIC $tobase.nocap" > "$tobase".caproff
					echo ".ce" >> "$tobase".caproff
					echo "$caption" >> "$tobase".caproff
					groff "$tobase".caproff > "$tobase".cap.ps
					rm -f "$tobase".cap.eps
					ps2eps -B -C "$tobase".cap.ps > /dev/null 2> /dev/null
					mv "$tobase".cap.eps "$tobase"
				fi
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

cat >> /tmp/in3fileconv.log <<EOF
------------------------
EOF
