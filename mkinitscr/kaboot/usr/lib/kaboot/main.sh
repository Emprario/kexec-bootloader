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

ROOT=/mnt
GRUBROOT=/boot/grub

. $srcPATH/kexec-load-grub

main "$@"