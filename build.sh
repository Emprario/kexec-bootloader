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

BROOT="$PWD"
BUILD_PATH=$BROOT/output
SRC_LINUX=$BROOT/linux
MODULES_FOLDER=$SRC_LINUX/modules


#TMPDIR=$(mktemp -d) # Accessible var in $TMPDIR


TARGETs=("standard" "chgconfig" "rescue" "clean") 

source functions.sh

usage () {
  echo "Usage: ./build.sh [-h|--help|-p|--print-var] TARGET"
  echo 
  echo "  -h | --help       Print help"
  echo "  -p | --print-var  Print input variables"
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
  
  build
  install_modules
  mkinit
  build
}

download () {
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

    infop "Build env sucessfully setup !"
  else
    infop "Version already created, pass"
  fi
}

prepare_env () {
  cd $BUILD_PATH
  
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
  
  diff -y --suppress-common-lines $BROOT/config .config > $BUILD_PATH/config.diff || /bin/true
  
  infop "You can find the diff in $BUILD_PATH/config.diff"
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
  
  if ! sudo bash $MKINIT $BROOT $BUILD_PATH; then
    error "Something went wrong with MKINIT script !" 1
  fi
  
  cp $BUILD_PATH/initramfs.cpio.xz $SRC_LINUX
}

clean () {
  cd $SRC_LINUX
  
  make clean
}

install_modules() {
  cd $SRC_LINUX

  # Create empty modules folder
  sudo rm -rf $BUILD_PATH/modules.tar.xz

  make -j"$(nproc)" modules_install INSTALL_MOD_PATH=$MODULES_FOLDER INSTALL_MOD_STRIP=1

  cd $MODULES_FOLDER/lib/modules
  # Remove broken symlinks
  rm -rf */build
  rm -rf */source

  # Create an archive for the modules
  tar -cv --use-compress-program="xz -9 -T0" -f $BUILD_PATH/modules.tar.xz *
  infop "Modules archive created."

}

post () {
  cp $SRC_LINUX/arch/x86/boot/bzImage $BUILD_PATH
  export -n BROOT
  export -n BUILD_PATH
}

TARGET=""
PRINT_VAR=false

for arg in $@
do
  case $arg in 
    -h | --help)
      usage
      ;;
    -p | --print-var)
      PRINT_VAR=true
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
