#!/bin/sh

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
  HEADER=$1
  OPTS="$*"

  tmp=''
  sel=1
  OP=' '
  while [ "$OP" != "ENTER" ];do
    echo $(underscores $HEADER)
    cc=0
    for arg in $OPTS;do
      if [ $cc -ne 0 ];then
        if [ $sel -eq $cc ];then
          echo "  * $(underscores $arg)"
        else
          echo "    $(underscores $arg)"
        fi
      fi
      cc=$((cc+1))
    done
    OP=$(readkey)
    if [ "$OP" = "DOWN" ];then
      sel=$((sel+1))
      if [ $sel -ge $cc ];then
        sel=$((cc-1))
      fi
    elif [ "$OP" = "UP" ];then
      sel=$((sel-1))
      if [ $sel -lt 1 ];then
        sel=1
      fi
    fi
    clear
    #echo "cc=$cc sel=$sel OP=$OP"
  done
}

#. ./functions.sh
#menu Welcome_to_my_custom_menu opta opt_b opt__c