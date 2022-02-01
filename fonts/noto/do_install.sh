#!/bin/bash

#DO_ME
#CLEAN_ME




remove(){
	sudo  sed -i '/# NOTO font start/,/# NOTO font end/d'  /usr/local/share/in3/in3charmap1
	sudo  sed -i '/# NOTO font start/,/# NOTO font end/d'  /usr/local/share/in3/in3charmap11
}

add(){
	cat in3charmap1.NOTO | sudo tee -a /usr/local/share/in3/in3charmap1
	cat in3charmap11.NOTO | sudo tee -a /usr/local/share/in3/in3charmap11
}

install(){
	echo "



"|	sudo install-font.sh -s -F NOTO -f +R NotoSerif-Regular.ttf
	echo "



"|	sudo install-font.sh -s -F NOTO -f +B NotoSerif-Bold.ttf
	echo "



"|	sudo install-font.sh -s -F NOTO -f +I NotoSerif-Italic.ttf
	echo "



"|	sudo install-font.sh -s -F NOTO -f +BI NotoSerif-BoldItalic.ttf
}

if [ "$1" = "DO_ME" ] ; then
	install
	remove
	add
elif [ "$1" = "CLEAN_ME" ] ; then
	remove
else
	echo "$0 { DO_ME | CLEAN_ME }"
fi
