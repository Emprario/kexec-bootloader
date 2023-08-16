#!/bin/bash

parse_cmdline () {
  CMDLINE=$(cat /proc/cmdline)
  
  ROOT=""
  INIT="/sbin/init"
  MOUNT_OPT=()
  
  for arg in ${CMDLINE[@]}
  do
    case $arg in
      "root="*)
        case $arg in
          "root=UUID="*)
            ROOT=$(realpath /dev/disk/by-uuid/${arg:10})
            ;;
          "root=PARTUUID="*)
            ROOT=$(realpath /dev/disk/by-partuuid/${arg:14})
            ;;
          "root="*)
            ROOT=${arg:5}
            ;;
        esac
        ;;
      rw)
        IFS=":"
        if ! [[ ":${MOUNT_OPT[*]}:" =~ ":ro:" ]] && ! [[ ":${MOUNT_OPT[*]}:" =~ ":rw:" ]];then
          MOUNT_OPT+=(rw)
        elif ! [[ ":${MOUNT_OPT[*]}:" =~ ":rw:" ]];then
          error "A partition cannot be mount as rw and ro !"
          error "Choosing first arg : ro"
        else
          warning "The root partition is already set to be mount as rw"
        fi
        IFS=" "
        ;;
      ro)
        IFS=":"
        if ! [[ ":${MOUNT_OPT[*]}:" =~ ":ro:" ]] && ! [[ ":${MOUNT_OPT[*]}:" =~ ":rw:" ]];then
          MOUNT_OPT+=(ro)
        elif ! [[ ":${MOUNT_OPT[*]}:" =~ ":ro:" ]];then
          error "A partition cannot be mount as rw and ro !"
          error "Choosing first arg : rw"
        else
          warning "The root partition is already set to be mount as ro"
        fi
        IFS=" "
        ;;
      "init="*)
        INIT="${arg:5}"
        ;;
      esac
  done
  
  # MOUNT_OPT shouldn't be empty
  if [[ ${MOUNT_OPT[*]} == "" ]];then
    MOUNT_OPT=("rw")
  fi
  
}

mount_root () {
  #1. Check Filesystem ...
  FSTYPE=""
  cc=0
  while [ -z $FSTYPE ] && [ $cc -le 15 ]
  do
    FSTYPE=($(lsblk -r -o NAME,FSTYPE | grep ${ROOT:5}))
    FSTYPE=${FSTYPE[1]}
    cc=$(($cc + 1))
    if [ -z $FSTYPE ] && [ $cc -le 15 ];then
     sleep 1
    fi
  done
  
  #2. Resolve encryption
  
  #3. Mount actual root
  IPS=','
  mount -t $FSTYPE -o ${MOUNT_OPT[*]} $ROOT /mnt/root
  
}

#parse_cmdline 
#ROOT=/dev/sda2
#echo $CMDLINE
#echo ${MOUNT_OPT[*]}
#echo $INIT
#mount_root
