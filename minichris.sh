#!/bin/bash
# pull containers and start 'em, that's it.

# PRECONDITIONS
###############

if [ "$(docker info -f '{{ .Swarm.LocalNodeState }}')" = "active" ]; then
  echo "WARNING: docker swarm is currently active. Proceed? [yN]"
  read -n 1 proceed
  if [ $proceed != 'y' ]; then
    exit
  fi
fi

if docker ps | grep -q chris; then
  echo "cannot proceed: CUBE is already running on this machine"
  exit 1
fi

# print a symbol and message, e.g.:
#  ✓  pull
#  ✓  start
#  •  wait
#  ✕  setup
function print_status () {
  local symbol=$1
  local prefix='\r'
  local suffix='\n'
  shift

  # simplify output for boring terminals
  if ! tput sgr0 2> /dev/null; then
    if [ "$symbol" = "run" ]; then
      printf "$@..."
    else
      echo "$symbol"
    fi
    return 0
  fi

  case $symbol in
    run )   symbol="$(tput setaf 6)●" suffix= ;;
    done )  symbol="$(tput setaf 2)✓";;
    error ) symbol="$(tput setaf 1)✕";;
  esac

  tput sgr0
  printf "$prefix %1s $(tput sgr0) %-20s$suffix" "$symbol" "$@"
}

# print success or failure based on exit code.
# if failure, then exit script.
function finish_task () {
  if [ "$?" = "0" ]; then
    print_status done "$1"
  else
    print_status error "$1"
    exit 1
  fi
}

# PULL LATEST IMAGES
####################

# change to directory where this script lives
cd $(dirname "$(readlink -f "$0")")

print_status run pull
docker-compose pull -q
finish_task pull

# START CONTAINERS
##################

print_status run start
! docker-compose up -d --build 2>&1 | grep -i error
finish_task start

# WAIT FOR SERVICES TO BE READY
###############################

print_status run wait
( exit "$(docker wait cube-starting)" )
finish_task wait
  
# FIRST-RUN SETUP
#################
# - create superusers
# - add host pfcon
# - add pl-dircopy

print_status run setup
docker wait cube-setup > /dev/null

# ASSERTION
###########
# - can log in as the user "chris"
# - "pl-dircopy" plugin found in CUBE

if curl -su 'chris:chris1234' http://localhost:8000/api/v1/users/ | grep -q password; then
  print_status done setup
else
  print_status error setup
  exit 1
fi
