#!/bin/bash

if [ "$1" = "" ] ; then
	echo "$0 FONT"
	exit 1
fi

ft=$1



for c in $(seq 32 4095); do
	hex=$(printf '%04X' $c)
	chr="\\[u$hex]"
	echo '.br'
	echo  "$c $hex $chr"
	echo ".ft $ft"
	echo "$chr"
	echo ".ft"
done
	
