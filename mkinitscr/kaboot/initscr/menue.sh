#!/usr/bin/bash

show_menue () {
  #HEADER=$2   # Is a string
  #SEL=$1      # Is an int
  #OPTS=$@     # Is a bash array
  #OPTS=${OPTS[@]:$((${#HEADER}+2))} # Keep only the real menu options
  cc=0
  
  clear
  echo "$HEADER"
  for opt in ${OPTS[@]}
  do
    if [ $cc -eq $SEL ];then
      echo " * $opt"
    else
      echo "   $opt"
    fi
    cc=$(($cc+1))
  done
}

chg_sel () {
  OP=0
  read -s -n 1 key
  case "$key" in
    $'\x1b') # Check if the key is an escape sequence
      read -s -n 2 -t 1 seq # read in busybox only accept entire values (time)
      case "$seq" in
        '[A') OP=$((-1));;
        '[B') OP=$(( 1));;
        #'[C') OP="RIGHT" ;;
        #'[D') OP="LEFT" ;;
      esac ;;        
    '') OP="ENTER" ;; # Handle Enter key
    #'c') echo "Cancel operation; " && exit ;; # Stop process
    #*) OP="$key" ;; # Handle other keys
  esac
  echo "$OP"
}


loop_menue () {
  # cd doc above
  MAX=${#OPTS[@]}
  while true
  do
    if [[ $SEL == 'ENTER' ]];then
      REPLY=${OPTS[$SEL]}
      break
    else
      show_menue $SEL "$HEADER" ${OPTS[@]}
      chg_sel
      if [[ $OP == "ENTER" ]];then
        SEL=$OP
      else
        SEL=$(($SEL+$OP))
        if  [ $SEL -lt 0 ];then
          SEL=0
        elif [ $SEL -ge $MAX ];then
          SEL=$(($MAX-1))
        fi
      fi
    fi
  done
}


#HEADER="This is the menue header :"
#OPTS=("AAA" "BBB" "CCC" "DDD" "EEE" "FFF" "GGG")
#SEL=4
# Define variables as external variables
#loop_menue

