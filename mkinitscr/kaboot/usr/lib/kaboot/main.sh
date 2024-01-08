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

parse_cmdline

mount_root
find_grub_cfg

ROOT=/mnt
GRUBROOT=${grub_cfg%/*}

. $srcPATH/kexec-load-grub

main "$@"
umount_root
kexec -e