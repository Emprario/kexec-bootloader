#!/bin/bash

[ -n "$(grep 'quiet' /proc/cmdline)" ] && QUIET=true || QUIET=false
LOGLEVEL=15

setup_verbosity () {
  for arg in $(cat /proc/cmdline)
  do
    if [[ $arg =~ "loglevel=" ]];then
      LOGLEVEL=${arg:9}
    fi
  done
}

infop () { # status update
  if [[ $LOGLEVEL -ge 15 ]] && ! $QUIET;then
    printf "\e[34m$1\e[0m \n"
  fi
}

sysout () {
  printf "\e[34m$1\e[0m \n"
}

ask () { # user question
  printf "\e[32m$1\e[0m" # Question answer should follow question
}

warning () { # non-critical error / warning
  if [[ $LOGLEVEL -ge 7 ]] && ! $QUIET;then
    printf "\e[33m$1\e[0m \n"
  fi
}

error () { # critical error -> script will exit
  if [[ $LOGLEVEL -ge 3 ]] && ! $QUIET;then
    printf "\e[31m$1\e[0m \n"
    if [[ $2 != "" ]];then
      exit $2
    fi
  fi
}

setup_verbosity
