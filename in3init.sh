#!/bin/bash
#INSTALLEDFROM verlaine:/home/ljm/src/in3xml
#INSTALL@ /usr/local/bin/in3init

#       _                                
#   ___| | ___  __ _ _ __    _   _ _ __  
#  / __| |/ _ \/ _` | '_ \  | | | | '_ \ 
# | (__| |  __/ (_| | | | | | |_| | |_) |
#  \___|_|\___|\__,_|_| |_|  \__,_| .__/ 
#                                 |_| 

if [ -f Makefile ] ; then
	if grep -q in3 Makefile ; then
		make clean
	fi
fi

rm -rf pdf html www

#                      _             _ _               _             _           
#   ___ _ __ ___  __ _| |_ ___    __| (_)_ __ ___  ___| |_ ___  _ __(_) ___  ___ 
#  / __| '__/ _ \/ _` | __/ _ \  / _` | | '__/ _ \/ __| __/ _ \| '__| |/ _ \/ __|
# | (__| | |  __/ (_| | ||  __/ | (_| | | | |  __/ (__| || (_) | |  | |  __/\__ \
#  \___|_|  \___|\__,_|\__\___|  \__,_|_|_|  \___|\___|\__\___/|_|  |_|\___||___/
#  

mkdir -p in3xml
mkdir -p roff
mkdir -p web
mkdir -p htm
mkdir -p block


