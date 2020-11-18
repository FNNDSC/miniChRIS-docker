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

# SETUP
#######

cd $(dirname "$(readlink -f "$0")")

docker pull fnndsc/pfdcm
docker pull fnndsc/swarm
docker-compose pull

docker-compose up -d

if [ "$?" != "0" ]; then
  exit 1
fi

echo "Waiting for services to come online..."

# poll /api/v1/users/ on a given port once every two seconds,
# unblocking after a successful request. Max 30 tries i.e. timeout 60 secs
function block_until_ready () {
  for i in {0..10}; do
    sleep 2
    curl -s http://localhost:$1/api/v1/users/ > /dev/null && return 0
  done
  echo "Timed out, giving up."
  exit 1
}

block_until_ready 8000 # CUBE
block_until_ready 8010 # ChRIS_store

printf "Performing setup... "

superuser_script='
from django.contrib.auth.models import User
User.objects.create_superuser(username="chris", password="chris1234", email="dev@babymri.org")
'
function create_user () {
  docker exec $1 python manage.py shell -c "$superuser_script"
}

create_user chris
create_user chris_store
docker exec chris        python plugins/services/manager.py \
  add host "http://pfcon.local:5005" --description "Local compute"
docker exec chris_store  python plugins/services/manager.py \
  add pl-dircopy chris https://github.com/FNNDSC/pl-dircopy fnndsc/pl-dircopy \
  --descriptorstring "$(docker run --rm fnndsc/pl-dircopy dircopy.py --json   \
  2> /dev/null)" > /dev/null 2>&1
docker exec chris python plugins/services/manager.py register host --pluginname pl-dircopy

# assert setup was successful:
# - can log in as the user "chris"
# - "pl-dircopy" plugin found in CUBE
if curl -su 'chris:chris1234' http://localhost:8000/api/v1/plugins/ | grep -q pl-dircopy; then
  echo "Done!"
else
  echo "Setup failed."
  exit 1
fi

