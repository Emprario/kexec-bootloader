#!/bin/sh

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

underscores() {
  # Convert underscores to spaces
  echo $1 | tr '_' ' '
}