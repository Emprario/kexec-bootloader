#!/bin/sh

get_scan () {
  #### Find bootable drives ####
  echo "Finding bootable drives ..."

  #DRIVES=$(ls /dev/disks/by-uuid)
  #
  ## Separate Drives lines to only keep drive name
  #tmp=""
  #for disk in $DRIVES; do
  #  tmp="$tmp $(realpath $disk | cut -c6-)" # cut /dev
  #done
  #DRIVES="$tmp"

  echo "Boot partitions found: $DRIVES"

  #### Mount and search for kernels ####
  echo "Mounting and looking for kernels ..."

  # Use of systemd-boot like 
  mkdir -p /mnt/$drive
  mount /dev/$drive /mnt/$drive
  cd /mnt/$drive 
  
  scan_loader
  ENTRIES=$(scan_entries)
  
  cd /mnt
  umount /dev/$drive
  echo "Options detected: $ENTRIES"
}

scan_loader () {
  for key in TIMEOUT DEFAULT EDITOR;do
    if [ -n "$(export | grep $key)" ];then
      export -n $key
    fi
  done

  LOADER=$(cat ./loader/loader.conf)
  iskey=true
  next=undefined
  for word in $LOADER;do
    echo "LINE='$word' ISKEY='$iskey' NEXT='$next'"
    if $iskey;then
      iskey=false
      if [ "$word" = "default" ];then
        next=DEFAULT
      elif [ "$word" = "timeout" ];then
        next=TIMEOUT
      elif [ "$word" = "editor" ];then
        next=EDITOR
      else
        next=undefined
        iskey=true
      fi
    elif ! $iskey && [ "$next" != "undefined" ];then
      echo "exporting ..."
      export $next=$word
      next=undefined
      iskey=true
    fi
  done
  echo "DEFAULT=$DEFAULT TIMEOUT=$TIMEOUT EDITOR=$EDITOR"
}

scan_entries () {
  echo "$(ls ./loader/entries/*.conf)"
}

scan_loader