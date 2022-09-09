#!/bin/bash

if [ "$(docker info -f '{{ .Swarm.LocalNodeState }}')" = "active" ] && ! docker inspect swarm-status > /dev/null 2>&1; then
  echo "WARNING: docker swarm is currently active. Proceed? [yN]"
  read -n 1 proceed
  if [ $proceed != 'y' ]; then
    exit
  fi
fi

if [ "$CI" = "true" ]; then
  not='-T'
fi

# change to directory where this script lives
cd $(dirname "$0")

set -ex
docker-compose up -d
docker-compose run --rm $not init-pfdcm
exec docker-compose run --rm $not chrisomatic

