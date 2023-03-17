#!/bin/bash

# change to directory where this script lives
cd "$(dirname "$(readlink -f "$0")")"

set -ex

# remove all plugin instance jobs
pls=$(docker ps -q -f 'label=org.chrisproject.miniChRIS=plugininstance')
[ -z "$pls" ] || docker rm -fv $pls

# stop and remove everything
docker compose down -v
