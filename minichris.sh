#!/bin/bash

if [ "$CI" = "true" ]; then
  notty='-T'
fi

# change to directory where this script lives
cd "$(dirname "$(readlink -f "$0")")"

set -ex
docker compose up -d
exec docker compose run --rm $notty chrisomatic
