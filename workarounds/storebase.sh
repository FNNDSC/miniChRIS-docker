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

def by_label(label):
    return d.containers.list(filters={'label': f'org.chrisproject.role={label}'})[0]

pfcon = by_label('pfcon')
storebase = [v['Source'] for v in pfcon.attrs['Mounts'] if v['Destination'] == '/var/local/storeBase'][0]
print(storebase)

pman = by_label('pman')
ep = pman.image.attrs['Config']['Entrypoint']
print(' '.join(ep) if ep else '')
print(' '.join(pman.image.attrs['Config']['Cmd']))
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
  echo "STOREBASE=$STOREBASE"
fi

exec $entrypoint $cmd
