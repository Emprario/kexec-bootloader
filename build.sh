#!/bin/bash

set -e

BROOT="$PWD"
OUTPATH=$BROOT/output

KVERSION="6.4.9"
AREV="arch1"
CREV="1"
BVERSION="$KVERSION-$AREV-$CREV"
KERNEL_VERSION="$KVERSION-$AREV"
CONFIG_VERSION="$KVERSION.$AREV-$CREV"

REMOTE_KERNEL="https://github.com/archlinux/linux/archive/refs/tags/v$KERNEL_VERSION.tar.gz"
REMOTE_CONFIG="https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/raw/$CONFIG_VERSION/config"

SRC_LINUX=$BROOT/linux
MODULES_FOLDER=$SRC_LINUX/modules

REMOTE_BUILDROOT="https://gitlab.com/buildroot.org/buildroot.git"
BUILDROOT_PATH=$BROOT/buildroot


#TMPDIR=$(mktemp -d) # Accessible var in $TMPDIR


TARGETs=("kaboot" "empty") 

source functions.sh

usage () {
  echo "Usage: ./build.sh [-h|--help|-p|--print-var] TARGET"
  echo 
  echo "  -h | --help       Print help"
  echo "  -p | --print-var  Print input variables"
  echo "  --once            Build the kernel only once (not twice as default)"
  echo "  --config          Config the kernel and buildroot with the specified target"
  echo "  --clean           Clean build environement"
  #echo "  --dev-initramfs   Build the initramfs with dev apks"
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
  
  if $CONFIG;then
    menuconfig
    exit 0
  fi
  
  if $CLEAN;then
    clean
    exit 0
  fi
  
  if ! $ONCE;then
    build
    install_modules
  fi

  #mkinit
  mkroot

  build
}

download () {
  mkdir -p $OUTPATH

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

    infop "Downloading using git ..."

    git clone $REMOTE_BUILDROOT . || error "Cannot download buildroot : $REMOTE_BUILDROOT" 1

  else
    infop "Buildroot is already downloaded, doing a git pull"
    cd $BUILDROOT_PATH
    git pull
  fi

  infop "Buildroot env sucessfully setup !"
}

prepare_env () {
  cd $OUTPATH
  
  infop "Prepare build environement"
  
  cp $BROOT/config config-linux.appended
  
  if ! [ -f $BROOT/overlays/linux/$TARGET/no_overlay.conf ]; then
    cat $BROOT/overlays/linux/$TARGET/*.conf >> config-linux.appended
  fi
  
  cp config-linux.appended $SRC_LINUX/.config

  # Preparing buildroot

  cd $BUILDROOT_PATH
  make defconfig
  cd $OUTPATH

  cp $BUILDROOT_PATH/.config config-buildroot.appended
  
  if ! [ -f $BROOT/overlays/buildroot/$TARGET/no_overlay.conf ]; then
    cat $BROOT/overlays/buildroot/$TARGET/*.conf >> config-buildroot.appended
  fi
  
  cp config-buildroot.appended $BUILDROOT_PATH/.config

  infop "All configs generated !"
}

menuconfig () {
  cd $SRC_LINUX
  
  infop "Change configuration of linux ..."
  
  make menuconfig
  
  diff -y --suppress-common-lines $BROOT/config .config > $OUTPATH/config-linux.diff || /bin/true
  
  infop "You can find the linux diff in $OUTPATH/config-linux.diff"

  cd $BUILDROOT_PATH
  
  infop "Change configuration of buildroot ..."
  
  make menuconfig

  cp .config config_br_tmp

  make defconfig
  
  diff -y --suppress-common-lines .config config_br_tmp > $OUTPATH/config-buildroot.diff || /bin/true

  rm config_br_tmp
  
  infop "You can find the buildroot diff in $OUTPATH/config-buildroot.diff"
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
  cd $BUILDROOT_PATH
  
  infop "Building a rootfs"

  if ! make -j8; then
    error "Error while compiling buildroot" 1
  fi

  #mkdir output/images/rootfs
  #cd output/images/rootfs
  #tar xf ../rootfs.tar -C .
  
  #rm -f ../initramfs.cpio.xz
  #find .  | cpio -ov --format=newc | xz --check=crc32 --lzma2=dict=512KiB -ze -9 -T$(nproc) > ../initramfs.cpio.xz
  
  cp output/images/rootfs.cpio.xz $SRC_LINUX/initramfs.cpio.xz
  rm -rf $OUTPATH/rootfs
  mkdir $OUTPATH/rootfs
  cd $OUTPATH/rootfs
  cpio -idv < $BUILDROOT_PATH/output/images/rootfs.cpio
}

clean () {
  cd $SRC_LINUX
  
  make clean

  cd $BUILDROOT_PATH

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
CONFIG=false
CLEAN=false

space=false
for path in $PATH; do
  if ! $space; then
    space=true
  else
    error "Spaces find in PATH !" 1
  fi
done


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
    --config)
      CONFIG=true
      ;;
    --clean)
      CLEAN=true
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
