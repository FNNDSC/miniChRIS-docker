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
  ./unmake.sh
  exit 1
fi

echo "Waiting for services to come online..."

docker-compose exec chris_store sh -c \
  'while ! curl -sSf http://localhost:8010/api/v1/users/; do sleep 1; done;' > /dev/null 2>&1
docker-compose exec chris sh -c \
  'while ! curl -sSf http://localhost:8000/api/v1/users/; do sleep 1; done;' > /dev/null 2>&1

printf "Performing setup..."

function create_user () {
docker-compose exec -T $1 sh -c 'python manage.py shell' << EOF
from django.contrib.auth.models import User
User.objects.create_superuser(username='chris', password='chris1234', email='dev@babymri.org')
EOF
}

create_user chris
create_user chris_store
docker-compose exec chris python plugins/services/manager.py \
  add host "http://pfcon.local:5005" --description "Local compute"
docker-compose exec chris_store python plugins/services/manager.py \
  add pl-dircopy chris https://github.com/FNNDSC/pl-dircopy fnndsc/pl-dircopy \
  --descriptorstring "$(docker run --rm fnndsc/pl-dircopy dircopy.py --json 2> /dev/null)" > /dev/null
docker-compose exec chris python plugins/services/manager.py register host --pluginname pl-dircopy

if curl -su 'chris:chris1234' http://localhost:8000/api/v1/plugins/ | grep -q pl-dircopy; then
  echo "Done!"
else
  echo "Setup failed."
  exit 1
fi
