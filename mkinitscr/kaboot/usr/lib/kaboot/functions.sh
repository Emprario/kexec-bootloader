#!/bin/bash

infop () { # status update
  printf "\e[34m$1\e[0m \n"
}

ask () { # user question
  printf "\e[32m$1\e[0m" # Question answer should follow question
}

warning () { # non-critical error / warning
  printf "\e[33m$1\e[0m \n"
}

error () { # critical error -> script will exit
  printf "\e[31m$1\e[0m \n"
  if [ -n $2 ];then
    exit $2
  fi
}

parse_cmdline () {
  CMDLINE=$(cat /proc/cmdline)
  for arg in $CMDLINE;do
    if [ ${arg:0:5} = "root=" ] ;then
      if [ ${arg:5:11} = "LABEL=" ];then
        target_root=/dev/disk/by-label/${arg:11}
      elif [ ${arg:5:10} = "UUID=" ];then
        target_root=/dev/disk/by-uuid/${arg:10}
      elif [ ${arg:5:8} = "ID=" ];then
        target_root=/dev/disk/by-id/${arg:8}
      elif [ ${arg:5:15} = "PARTLABEL=" ];then
        target_root=/dev/disk/by-partlabel/${arg:15}
      elif [ ${arg:5:14} = "PARTUUID=" ];then
        target_root=/dev/disk/by-partuuid/${arg:14}
      elif [ ${arg:5:10} = "PATH=" ];then
        target_root=/dev/disk/by-path/${arg:10}
      else
        target_root=${arg:5}
      fi
    fi
  done
  export TARGET=$target_root
}