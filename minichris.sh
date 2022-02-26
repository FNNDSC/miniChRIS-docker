#!/bin/bash

if [ "$(docker info -f '{{ .Swarm.LocalNodeState }}')" = "active" ] && docker inspect swarm-status > /dev/null 2>&1; then
  echo "WARNING: docker swarm is currently active. Proceed? [yN]"
  read -n 1 proceed
  if [ $proceed != 'y' ]; then
    exit
  fi
fi

if [ "$CI" = "true" ]; then
  not='-T'
fi

set -ex
docker compose up -d
exec docker compose exec $not chrisomatic chrisomatic apply
