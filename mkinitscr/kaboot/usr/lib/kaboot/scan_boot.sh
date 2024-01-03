#!/bin/bash

get_scan () {
  #### Find bootable drives ####
  echo "Finding bootable drives ..."

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

mount_root () {
  mkdir -p /mnt
  mount -o ro,noexec "$target_root" /mnt
}

umount_root () {
  umount /mnt
}

find_grub_cfg () {
  cd /mnt
  FIND_PRIORITY=("./boot/grub/" "./boot/" "./grub/" "./efi/" "./BOOT/" "./GRUB")
  for dir in ${FIND_PRIORITY[@]};do
    CFG=$(find $dir | grep "grub.cfg")
    if [ -f $CFG ];then
      break
    fi
  done
  if [ -z $CFG ];then
    echo "Wasn't able to extract grub.cfg from current root"
    export grub_cfg=""
  else
    export grub_cfg=$CFG
  fi
}