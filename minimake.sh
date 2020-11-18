#!/bin/bash
# pull containers and start 'em, that's it.

# PRECONDITIONS
###############

if docker ps | grep -q chris; then
  echo "cannot proceed: CUBE is already running on this machine"
  exit 1
fi

if ! docker swarm init --advertise-addr 127.0.0.1 > /dev/null; then
  echo "cannot proceed: please leave the docker swarm"
  echo
  echo "    docker swarm leave --force"
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

# PULL LATEST IMAGES
####################

# change to directory where this script lives
cd $(dirname "$(readlink -f "$0")")

print_status run pull
set -e  # stop if user does CTRL-C
docker pull -q fnndsc/pfdcm > /dev/null
docker pull -q fnndsc/swarm > /dev/null
docker-compose pull -q
set +e
print_status done pull

# START CONTAINERS
##################

print_status run start
docker-compose up -d 2>&1 | grep -i error
if [ "$?" = "0" ]; then
  exit 1
fi
print_status done start

# WAIT FOR SERVICES TO BE READY
###############################

print_status run wait
# Poll /api/v1/users/ on a given port every two seconds,
# unblocking after a successful request.
# Max 150 tries i.e. timeout after 5 minutes
function block_until_ready () {
  for i in {0..150}; do
    sleep 2
    curl -s http://localhost:$1/api/v1/users/ > /dev/null && return 0
  done
  print_status error wait
  exit 1
}

block_until_ready 8000 # CUBE
block_until_ready 8010 # ChRIS_store

print_status done wait

# FIRST-RUN SETUP
#################
# - create superusers
# - add host pfcon
# - add pl-dircopy

print_status run setup
superuser_script='
from django.contrib.auth.models import User
User.objects.create_superuser(username="chris", password="chris1234", email="dev@babymri.org")'

docker exec chris       python manage.py shell -c "$superuser_script"
docker exec chris_store python manage.py shell -c "$superuser_script"

docker exec chris        python plugins/services/manager.py \
  add host "http://pfcon.local:5005" --description "Local compute"
docker exec chris_store  python plugins/services/manager.py \
  add pl-dircopy chris https://github.com/FNNDSC/pl-dircopy fnndsc/pl-dircopy \
  --descriptorstring "$(docker run --rm fnndsc/pl-dircopy dircopy.py --json   \
  2> /dev/null)" > /dev/null 2>&1
docker exec chris python plugins/services/manager.py register host --pluginname pl-dircopy

# ASSERTION
###########
# - can log in as the user "chris"
# - "pl-dircopy" plugin found in CUBE

if curl -su 'chris:chris1234' http://localhost:8000/api/v1/plugins/ | grep -q pl-dircopy; then
  print_status done setup
else
  print_status error setup
  exit 1
fi

