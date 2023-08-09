#!/bin/bash

set -e

VERSION="6.4.8"
AVERSION="arch1"
REV="1"
KVERSION="$VERSION-$AVERSION-$REV"
NO_REV_KVERSION="$VERSION-$AVERSION"
CONFIG_VERSION="$VERSION.$AVERSION-$REV"

REMOTE_KERNEL="https://github.com/archlinux/linux/archive/refs/tags/$NO_REV_KVERSION.tar.gz"
REMOTE_CONFIG="https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/raw/$CONFIG_VERSION/config"

BROOT="$PWD"
TMPDIR=$(mktemp -d) # Accessible var in $TMPDIR


TARGETs=("standard" "chgconfig" "rescue") 


source functions.sh

usage () {
  echo "Usage: ./build.sh [-h|--help|-p|--print-var] TARGET"
  echo 
  echo "  -h | --help       Print help"
  echo "  -p | --print-var  Print input variables"
  echo 
  #echo "    KVERSION is a variable that is overwritten the default ($KVERSION) if specifed."
  echo "    TARGET [required] is a keyword to specified what you want to build ;"
  echo "    List of TARGET: ${TARGETs[*]}"
  exit 0
}

print_var () {
  infop "TARGET=$TARGET"
  infop "KVERSION=$KVERSION"
  exit 0
}

main () {
  cd $BROOT
  
  infop "Building: $TARGET"
  
  download
}

download () {
  cd $BROOT
  
  infop "Dowloading using curl"
  
  curl -L $REMOTE_KERNEL -o kernel-$NO_REV_KVERSION.tar.gz || error "Cannot download kernel : $REMOTE_KERNEL" 1
  curl -L $REMOTE_CONFIG -o config-$KVERSION || error "Cannot download config : $REMOTE_CONFIG" 1
  
  tar xf kernel.tar.gz
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

main

exit 0
