#!/bin/bash

BROOT=$1
BUILD_PATH=$2

SRC="$PWD"
INITRAMFS_PATH=$BUILD_PATH/initramfs
INIT_SCRIPT=$SRC/init
MODULES=$BUILD_PATH/modules.tar.xz
CPIO_ARCHIVE=$BUILD_PATH/initramfs.cpio.xz
#ALPINE vars as ALP
ALP_ARCHIVE=alpine-minirootfs-3.18.2-x86_64.tar.gz
ALP_ARCHIVE_PATH=$BUILD_PATH/$ALP_ARCHIVE
ALP_URL=https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/$ALP_ARCHIVE
ALP_UNUSED_APK="ca-certificates alpine-keys apk-tools"
ALP_USEFUL_APK="bash util-linux linux-firmware-amdgpu"
#ALP_EDGETE_APK=""
ALP_DEVELP_APK="vim nano tree"
ALP_COMDEV_APK="vboot-utils cgpt kexec-tools"
PATH="/bin:/sbin:/usr/bin:/usr/sbin"

CHROOT="chroot $INITRAMFS_PATH"

# Exit on errors
set -e

source $BROOT/functions.sh

clean () {

  infop "Make clean image"
  # make a clean image
  umount -Rl $INITRAMFS_PATH/* || /bin/true
  rm -rf $INITRAMFS_PATH
  mkdir $INITRAMFS_PATH
}

# Create basic root
basic_root () {
  cd $INITRAMFS_PATH
  
  mkdir --parents ./{usr,bin,dev,etc,lib,mnt,proc,root,sbin,sys,tmp}
  mknod -m 622 dev/console c 5 1
  mknod -m 622 dev/tty0 c 4 1
  mknod -m 622 dev/ttyS0 c 4 64
  cp $INIT_SCRIPT .
  chmod +x ./init
  
  # Make usr looks like root
  cd $INITRAMFS_PATH/usr
  mkdir --parents ./{local,state,share,src,bin,sbin,lib}
  cd ..
  
  if $ADDMOD;then
    # extract modules to /lib/modules
    mkdir ./lib/modules
    tar xpf $MODULES -C lib/modules
  fi
  
  
  if $DEVMODE;then
    # enable devmode in initramfs
    touch /etc/devmode
  fi
  
}

downtract_alpine () {
  cd $BUILD_PATH

  infop "Downloading alpine minimal rootfs"
  if [[ ! -d $ALP_ARCHIVE_PATH ]] ; then
    curl -L $ALP_URL -o $ALP_ARCHIVE_PATH || error "Failed to download using curl, check you own curl, check network connection." 1
  else
    warning "Alpine rootfs already downloaded"
  fi

  tar -xhf $ALP_ARCHIVE_PATH -C $INITRAMFS_PATH
}


alp_manage_apk () {
  cd $INITRAMFS_PATH
  
  infop "Set up internet access"
  cp /etc/resolv.conf ./etc/resolv.conf
  
  infop "Add apks"
  $CHROOT apk update
  $CHROOT apk add $ALP_USEFUL_APK
  #$CHROOT apk add $ALP_EDGETE_APK --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
  
  if $DEVAPK;then
    infop "Installing extra apks"
    $CHROOT apk add $ALP_DEVELP_APK
    $CHROOT apk add $ALP_COMDEV_APK --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/
  else
    infop "Cleaning unused apks"
    $CHROOT apk del $ALP_UNUSED_APK
  fi
}



# extract firmware blob needed
extract_blobs () {
  cd $INITRAMFS_PATH
  
  cp -r /lib/firmware/amdgpu ./lib/firmware
}

# add all scripts in scripts.d into /lib/scripts
install_scripts () {
  cd $INITRAMFS_PATH  
  
  if [ -d $SRC/initscr/ ];then
    mkdir ./lib/initscr
    cp $SRC/initscr/* ./lib/initscr
  fi
}

# compile cpio archive
compile_cpio () {
  cd $INITRAMFS_PATH

  rm -f $CPIO_ARCHIVE
  find .  | cpio -ov --format=newc | xz --check=crc32 --lzma2=dict=512KiB -ze -9 -T$(nproc) > $CPIO_ARCHIVE
}

ADDMOD=false
DEVAPK=false
DEVMODE=false

for opt in $@
do
  case $opt in
    --modules)
      ADDMOD=true
      ;;
    --devapk)
      DEVAPK=true
      ;;
    --devmode)
      DEVMODE=true
      ;;
  esac
done

clean
basic_root
downtract_alpine
alp_manage_apk
#extract_blobs
#install_scripts
compile_cpio
