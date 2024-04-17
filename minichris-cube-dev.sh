#!/bin/bash

# change to directory where this script lives
cd "$(dirname "$(readlink -f "$0")")"

set -ex
docker compose --env-file docker-compose-cube-dev.env -f docker-compose-cube-dev.yml up -d
exec docker compose --env-file docker-compose-cube-dev.env -f docker-compose-cube-dev.yml run --rm $notty chrisomatic
