#!/bin/bash

#!/bin/bash

if [ "$(docker info -f '{{ .Swarm.LocalNodeState }}')" = "active" ] && ! docker inspect swarm-status > /dev/null 2>&1; then
  echo "WARNING: docker swarm is currently active. Proceed? [yN]"
  read -n 1 proceed
  if [ $proceed != 'y' ]; then
    exit
  fi
  echo "Reset swarm? Unsaved data will be lost! [yN]"
  read -n 1 reset_swarm
  if [ $reset_swarm = 'y' ]; then
    set -ex
    docker swarm leave --force
    { set +x; } 2> /dev/null
  else
    echo "WARNING: swarm state is stale, plugin instances might fail!"
  fi
fi

if [ "$CI" = "true" ]; then
  not='-T'
fi

# change to directory where this script lives
cd $(dirname "$0")

set -ex
docker compose up -d

# Wait for the Kafka Connect REST API to become available
until $(curl --output /dev/null --silent --head --fail http://localhost:8083); do
    printf '.'
    sleep 5
done

# setup elasticsearch sink
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:9200/plugins_plugin
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/es-chris-sink.json

# setup connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/postgres-chris-source.json

exec docker compose run --rm $not chrisomatic
