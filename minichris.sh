#!/usr/bin/env bash 

if [ "$CI" = "true" ]; then
  notty='-T'
fi

# change to directory where this script lives
cd "$(dirname "$(readlink -f "$0")")"

set -x  # print commands before running them

# (optional) set HOSTNAME environment variable
hn="$(hostname)" && echo "HOSTNAME=$hn" > .env

set -e  # fail on error

docker compose up -d "$@"

# if chris is running, run chrisomatic
if [ -n "$(docker compose ps chris -q)" ]; then
  docker compose run --rm $notty chrisomatic
fi
