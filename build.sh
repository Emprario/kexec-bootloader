#!/bin/bash

set -e

KVERSION="6.4.9"
AREV="arch1"
CREV="1"
BVERSION="$KVERSION-$AREV-$CREV"
KERNEL_VERSION="$KVERSION-$AREV"
CONFIG_VERSION="$KVERSION.$AREV-$CREV"

REMOTE_KERNEL="https://github.com/archlinux/linux/archive/refs/tags/v$KERNEL_VERSION.tar.gz"
REMOTE_CONFIG="https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/raw/$CONFIG_VERSION/config"

BUILDROOT_VERSION="2023.08.3"
REMOTE_BUILDROOT="https://buildroot.org/downloads/buildroot-$BUILDROOT_VERSION.tar.gz"
BUILDROOT_PATH=$BROOT/buildroot

BROOT="$PWD"
OUTPATH=$BROOT/output
SRC_LINUX=$BROOT/linux
MODULES_FOLDER=$SRC_LINUX/modules


#TMPDIR=$(mktemp -d) # Accessible var in $TMPDIR


TARGETs=("kaboot" "chgconfig" "clean") 

source functions.sh

usage () {
  echo "Usage: ./build.sh [-h|--help|-p|--print-var] TARGET"
  echo 
  echo "  -h | --help       Print help"
  echo "  -p | --print-var  Print input variables"
  echo "  --once            Build the kernel only once (not twice as default)"
  echo "  --dev-initramfs   Build the initramfs with dev apks"
  echo 
  #echo "    BVERSION is a variable that is overwritten the default ($BVERSION) if specifed."
  echo "    TARGET [required] is a keyword to specified what you want to build ;"
  echo "    List of TARGET: ${TARGETs[*]}"
  exit 0
}

print_var () {
  infop "TARGET=$TARGET"
  infop "BVERSION=$BVERSION"
  exit 0
}

main () {
  cd $BROOT
  
  infop "Building: $TARGET"
  
  download
  
  prepare_env
  
  if [[ $TARGET == "chgconfig" ]];then
    menuconfig
    exit 0
  fi
  
  if [[ $TARGET == "clean" ]];then
    clean
    exit 0
  fi
  
  if ! $ONCE;then
    build
    install_modules
  fi
  mkinit
  build
}

download () {
  mkdir -p $OUTPATH
  mkdir -p $BUILDROOT_PATH

  cd $BROOT
  
  if ! [ -d v$BVERSION  ];  then
    mkdir -p v$BVERSION
    cd v$BVERSION
    infop "Use archive directory: $BROOT/v$BVERSION"

    infop "Dowloading using curl ..."

    curl -L $REMOTE_KERNEL -o kernel-$KERNEL_VERSION.tar.gz || error "Cannot download kernel : $REMOTE_KERNEL" 1
    curl -L $REMOTE_CONFIG -o config-$CONFIG_VERSION || error "Cannot download config : $REMOTE_CONFIG" 1
    
    infop "Setting up enviroment ..."

    tar xf kernel-$KERNEL_VERSION.tar.gz
    cd ..
    rm -f linux config
    ln -s v$BVERSION/linux-$KERNEL_VERSION linux
    ln -s v$BVERSION/config-$CONFIG_VERSION config

    infop "Build kernel env sucessfully setup !"
  else
    infop "Version already created, pass"
  fi

  if ! [ -d $BUILDROOT_PATH ]; then
    mkdir -p $BUILDROOT_PATH
    cd $BUILDROOT_PATH
    infop "Use buildroot directory: $BUILDROOT_PATH"

    infop "Downloading using curl ..."

    curl -L $REMOTE_BUILDROOT -o buildroot-$BUILDROOT_VERSION.tar.gz || error "Cannot download buildroot : $REMOTE_BUILDROOT" 1

    infop "Setting up environement ..."

    tar xf buildroot-$BUILDROOT_VERSION.tar.gz
    mv buildroot-$BUILDROOT_VERSION/* buildroot-$BUILDROOT_VERSION/.* .
    rmdir buildroot-$BUILDROOT_VERSION

    infop "Buildroot env sucessfully setup !"
  else
    infop "Buildroot is already downloaded, pass"
  fi
}

prepare_env () {
  cd $OUTPATH
  
  infop "Prepare build environement"
  
  cp $BROOT/config config.appended
  
  if ! [ -f $BROOT/overlays/$TARGET/no_overlay.conf ]; then
    cat $BROOT/overlays/$TARGET/*.conf >> config.appended
  fi
  
  cp config.appended $SRC_LINUX/.config
}

menuconfig () {
  cd $SRC_LINUX
  
  infop "Change configuration"
  
  make menuconfig
  
  diff -y --suppress-common-lines $BROOT/config .config > $OUTPATH/config.diff || /bin/true
  
  infop "You can find the diff in $OUTPATH/config.diff"
}

build () {
  cd $SRC_LINUX
  
  infop "Building Kernel ..."

  make -j"$(nproc)"

  #Version of kernel
  KERNEL_STRING=$(file -bL arch/x86/boot/bzImage | grep -o 'version [^ ]*' | cut -d ' ' -f 2)
  
  infop "Kernel $KERNEL_STRING sucessfully built !"
}

mkinit () {
  cd $BROOT/mkinitscr/$TARGET
  
  MKINIT=$BROOT/mkinitscr/$TARGET/mkinitramfs.sh
  
  infop "Building initramfs using : $MKINIT"

  if $DEV_INITRAMFS; then
    CMDLINE="sudo bash $MKINIT $BROOT $OUTPATH --devapk"
  else
    CMDLINE="sudo bash $MKINIT $BROOT $OUTPATH"
  fi
  
  if ! $CMDLINE; then
    error "Something went wrong with MKINIT script !" 1
  fi
  
  cp $OUTPATH/initramfs.cpio.xz $SRC_LINUX
}

mkroot () {

}

clean () {
  cd $SRC_LINUX
  
  make clean
}

install_modules() {
  mkdir -p $MODULES_FOLDER
  
  cd $SRC_LINUX

  # Create empty modules folder
  sudo rm -rf $OUTPATH/modules.tar.xz

  make -j"$(nproc)" modules_install INSTALL_MOD_PATH=$MODULES_FOLDER INSTALL_MOD_STRIP=1

  cd $MODULES_FOLDER/lib/modules
  # Remove broken symlinks
  rm -rf */build
  rm -rf */source

  # Create an archive for the modules
  tar -cv --use-compress-program="xz -9 -T0" -f $OUTPATH/modules.tar.xz *
  infop "Modules archive created."

}

post () {
  cp $SRC_LINUX/arch/x86/boot/bzImage $OUTPATH
  export -n BROOT
  export -n OUTPATH
}

TARGET=""
PRINT_VAR=false
ONCE=false
DEV_INITRAMFS=false

for arg in $@
do
  case $arg in 
    -h | --help)
      usage
      ;;
    -p | --print-var)
      PRINT_VAR=true
      ;;
    --once)
      ONCE=true
      ;;
    --dev-initramfs)
      DEV_INITRAMFS=true
      ;;
    *)
      for pretend in ${TARGETs[@]}
      do
        IFS=":"
        if [[ $arg == $pretend ]] && [[ $TARGET == "" ]];then
          TARGET=$arg
          IFS=" "
          break
        elif [[ $arg == $pretend ]] && [[ $TARGET != "" ]];then
          error "You can't pretend to more than 1 TARGET" 1
        elif ! [[ ":${TARGETs[*]}:" =~ ":$arg:" ]];then
          error "Unknown statement: '$arg'" 1
        fi
      done
  esac
done

if [[ $TARGET == "" ]];then
  TARGET=${TARGETs[0]}
fi

if $PRINT_VAR; then
  print_var
fi 

if ! main; then
  post
  exit 1
fi

post

exit 0
