#!/bin/bash


if [ -d "/lib/kaboot/" ];then
  srcPATH="/lib/kaboot"
else
  srcPATH="."
fi

# '.' is equivalent to the good old 'source' in bash
. $srcPATH/functions.sh
. $srcPATH/print_menu.sh
. $srcPATH/scan_boot.sh

#get_scan # return $OPTIONS

#OPTIONS_useNAME=""
#for option in $OPTIONS
#do
#  OPTIONS_useNAME="$(echo $option | cut -f4 -d"/")_on_/dev/$(echo $option | cut -f3 -d"/") $OPTIONS_useNAME"
#done
#selection "Selection:" "$OPTIONS_useNAME"

$srcPATH/kexec-load-grub --grub /mnt/boot/grub --mnt /mnt