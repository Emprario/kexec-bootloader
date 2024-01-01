#!/bin/bash

set -e


BROOT=$1
OUTPATH=$2
TARGET=$3
BUILDROOT_PATH=$4

echo Building with 
echo $BROOT
echo $OUTPATH
echo $TARGET
echo $BUILDROOT_PATH

rm -rf $OUTPATH/rootfs
mkdir $OUTPATH/rootfs
cd $OUTPATH/rootfs
echo Extracting BR rootfs
cpio -id < $BUILDROOT_PATH/output/images/rootfs.cpio

ls -l dev -a $BROOT/mkinitscr/$TARGET/* $OUTPATH/rootfs
cp -a $BROOT/mkinitscr/$TARGET/* $OUTPATH/rootfs

rm -f $OUTPATH/initramfs.cpio.xz
find .  | cpio -ov --format=newc | xz --check=crc32 --lzma2=dict=512KiB -ze -9 -T$(nproc) > $OUTPATH/initramfs.cpio.xz