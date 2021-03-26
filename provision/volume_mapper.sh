#!/bin/bash -e
#
# STOREBASE environment variable is a workaround in pman.
# It is supposed to be the mount point on the host of a
# network filesystem so that some data can be visible to
# all nodes in a docker swarm cluster.
#
# For a single machine ChRIS, we use a volume managed by
# docker-compose. Its name is hard-coded.

py="
import docker
import os

d = docker.from_env()

v = d.volumes.get('minichris-remote-data')
print(v.attrs['Mountpoint'])

image = d.containers.get('pman').image

print(' '.join(image.attrs['Config']['Entrypoint']))
print(' '.join(image.attrs['Config']['Cmd']))
"

data="$(python -c "$py")"
mountpoint=$(sed -n 1p <<< "$data")
entrypoint=$(sed -n 2p <<< "$data")
cmd=$(sed -n 3p <<< "$data")

if [ "$#" -gt 0 ]; then
  cmd=$@
fi

if [ -z "$STOREBASE" ]; then
  export STOREBASE=$mountpoint
fi

exec $entrypoint $cmd
