#!/bin/sh
# sets STOREBASE based on a docker volume's mountpoint

PMAN_DOCKER_VOLUME=${PMAN_DOCKER_VOLUME:-chris-remote}

get_volume_mountpoint_py="
import docker
d = docker.from_env()
v = d.volumes.get('$PMAN_DOCKER_VOLUME')
print(v.attrs['Mountpoint'])
"

if [ -z "$STOREBASE" ]; then
  if mountpoint=$(python -c "$get_volume_mountpoint_py"); then
    export STOREBASE=$mountpoint
  fi
fi

exec pman $@
