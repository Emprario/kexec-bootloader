#!/bin/bash

HEADER="Kaboot grub selection ..."
TABLE=()

readkey () {
  # Read a single character from the keyboard
  read -s -n 1 key
  case "$key" in
    $'\x1b') # Check if the key is an escape sequence
      read -s -n 2 seq
      case "$seq" in
        '[A') OP="UP";;
        '[B') OP="DOWN" ;;
        '[C') OP="RIGHT" ;;
        '[D') OP="LEFT" ;;
      esac ;;        
    '') OP="ENTER" ;; # Handle Enter key
    #'c') echo "Cancel operation; " && exit ;; # Stop process
    *) OP="$key" ;; # Handle other keys
  esac
  echo "$OP"
}

menu () {
  sel=0
  OP=' '
  while [ "$OP" != "ENTER" ];do
    echo $HEADER
    cc=0
    for arg in ${TABLE[@]};do
    #echo "arg='$arg'"
      if [[ $arg =~ ^[0-9]+$ ]];then
        if [ $sel -eq $cc ];then
          printf "\n  * ${arg}."
        else
          printf "\n    ${arg}."
        fi
        cc=$((cc+1))
      else
        printf " ${arg}"
      fi
    done
    OP=$(readkey)
    if [ "$OP" = "DOWN" ];then
      sel=$((sel+1))
      if [ $sel -ge $cc ];then
        sel=$((cc-1))
      fi
    elif [ "$OP" = "UP" ];then
      sel=$((sel-1))
      if [ $sel -lt 0 ];then
        sel=0
      fi
    fi
    clear
  done
}