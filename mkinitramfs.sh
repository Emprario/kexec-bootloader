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
tar xpf $BUILDROOT_PATH/output/images/rootfs.tar

ls -l dev -a $BROOT/mkinitscr/$TARGET/* $OUTPATH/rootfs
cp -a $BROOT/mkinitscr/$TARGET/* $OUTPATH/rootfs

mknod -m 622 dev/console c 5 1
mknod -m 622 dev/tty0 c 4 1
mknod -m 622 dev/ttyS0 c 4 64

rm -f $OUTPATH/initramfs.cpio.xz
find .  | cpio -ov --format=newc | xz --check=crc32 --lzma2=dict=512KiB -ze -9 -T$(nproc) > $OUTPATH/initramfs.cpio.xz