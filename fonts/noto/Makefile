# Makefile Thu Jan 20 16:40:11 CET 2022
ALL: tag tag/feature tag/fotoblader tag/htmlindex tag/in tag/in3xml tag/merge tag/pgm tag/photo tag/photoswipe tag/photozip tag/src
clean: tag/clean.feature tag/clean.fotoblader tag/clean.htmlindex tag/clean.in tag/clean.in3xml tag/clean.merge tag/clean.pgm tag/clean.photo tag/clean.photoswipe tag/clean.photozip tag/clean.src
	rm -rf tag
upload: tag/upload.feature tag/upload.fotoblader tag/upload.htmlindex tag/upload.in tag/upload.in3xml tag/upload.merge tag/upload.pgm tag/upload.photo tag/upload.photoswipe tag/upload.photozip tag/upload.src
tag:
	test -d tag || mkdir tag
# feature
#   __            _                  
#  / _| ___  __ _| |_ _   _ _ __ ___ 
# | |_ / _ \/ _` | __| | | | '__/ _ \
# |  _|  __/ (_| | |_| |_| | | |  __/
# |_|  \___|\__,_|\__|\__,_|_|  \___|
#                                    
tag/feature: |tag
	touch tag/feature
tag/clean.feature: |tag
	touch tag/clean.feature
# fotoblader
#   __       _        _     _           _                      __    
#  / _| ___ | |_ ___ | |__ | | __ _  __| | ___ _ __   _ __    / /_ _ 
# | |_ / _ \| __/ _ \| '_ \| |/ _` |/ _` |/ _ \ '__| | '_ \  / / _` |
# |  _| (_) | || (_) | |_) | | (_| | (_| |  __/ |    | | | |/ / (_| |
# |_|  \___/ \__\___/|_.__/|_|\__,_|\__,_|\___|_|    |_| |_/_/ \__,_|
#                                                                    
tag/upload.fotoblader: |tag
	touch tag/upload.fotoblader
tag/fotoblader: |tag
	touch tag/fotoblader
tag/clean.fotoblader: |tag
	touch tag/clean.fotoblader
# htmlindex
#  _     _             _ _           _                      __    
# | |__ | |_ _ __ ___ | (_)_ __   __| | _____  __  _ __    / /_ _ 
# | '_ \| __| '_ ` _ \| | | '_ \ / _` |/ _ \ \/ / | '_ \  / / _` |
# | | | | |_| | | | | | | | | | | (_| |  __/>  <  | | | |/ / (_| |
# |_| |_|\__|_| |_| |_|_|_|_| |_|\__,_|\___/_/\_\ |_| |_/_/ \__,_|
#                                                                 
tag/upload.htmlindex: |tag
	touch tag/upload.htmlindex
tag/htmlindex: |tag
	touch tag/htmlindex
tag/clean.htmlindex: |tag
	touch tag/clean.htmlindex
# in
#  _       _____ 
# (_)_ __ |___ / 
# | | '_ \  |_ \ 
# | | | | |___) |
# |_|_| |_|____/ 
#                
tag/in: |tag
	touch tag/in
tag/clean.in: |tag
	touch tag/clean.in
tag/upload.in: |tag
	touch tag/upload.in
# in3xml
#  _       _____               _ 
# (_)_ __ |___ /_  ___ __ ___ | |
# | | '_ \  |_ \ \/ / '_ ` _ \| |
# | | | | |___) >  <| | | | | | |
# |_|_| |_|____/_/\_\_| |_| |_|_|
#                                
tag/in3xml: |tag
	touch tag/in3xml
tag/clean.in3xml: |tag
	touch tag/clean.in3xml
# merge
#                                
#  _ __ ___   ___ _ __ __ _  ___ 
# | '_ ` _ \ / _ \ '__/ _` |/ _ \
# | | | | | |  __/ | | (_| |  __/
# |_| |_| |_|\___|_|  \__, |\___|
#                     |___/      
tag/merge: |tag
	touch tag/merge
tag/clean.merge: |tag
	touch tag/clean.merge
# pgm
#                        
#  _ __   __ _ _ __ ___  
# | '_ \ / _` | '_ ` _ \ 
# | |_) | (_| | | | | | |
# | .__/ \__, |_| |_| |_|
# |_|    |___/           
tag/upload.pgm: |tag
	touch tag/upload.pgm
tag/pgm: tag/pgm.cron tag/pgm.bin tag/pgm.do_me |tag
.PHONY: pgm
pgm: tag/pgm
tag/pgm.bin: Makefile |tag
	touch tag/pgm.bin
tag/pgm.do_me:  tag/do_me_do_install.sh  Makefile |tag
	touch tag/pgm.do_me
tag/do_me_do_install.sh: do_install.sh Makefile |tag
	chmod +x do_install.sh
	./do_install.sh DO_ME
	touch tag/do_me_do_install.sh
tag/pgm.cron: Makefile |tag
	touch tag/pgm.cron
tag/clean.pgm:
	chmod +x do_install.sh
	./do_install.sh CLEAN_ME
	touch tag/clean.pgm
# photo
#        _           _        
#  _ __ | |__   ___ | |_ ___  
# | '_ \| '_ \ / _ \| __/ _ \ 
# | |_) | | | | (_) | || (_) |
# | .__/|_| |_|\___/ \__\___/ 
# |_|                         
tag/photo: |tag
	touch tag/photo
tag/clean.photo: |tag
	touch tag/clean.photo
# photoswipe
tag/upload.photoswipe: |tag
	touch tag/upload.photoswipe
tag/photoswipe: |tag
	touch tag/photoswipe
tag/clean.photoswipe:
	touch tag/clean.photoswipe
# photozip
tag/photozip: |tag
	touch tag/photozip
tag/clean.photozip:
	touch tag/clean.photozip
# src
#               
#  ___ _ __ ___ 
# / __| '__/ __|
# \__ \ | | (__ 
# |___/_|  \___|
#               
tag/src: |tag
	touch tag/src
tag/clean.src: |tag
	touch tag/clean.src
