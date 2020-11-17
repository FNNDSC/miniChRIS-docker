#!/bin/bash

cd $(dirname "$(readlink -f "$0")")
set -x

docker-compose down -v
docker swarm leave --force

if [ -e "FS" ]; then
  # a hack to do rm -rf on the host, regardless of who the user is
  docker run --rm -v $PWD:/hostFS -w /hostFS --entrypoint /bin/rm fnndsc/ubuntu-python3 -rf FS
fi

{ set +x; } 2> /dev/null

# check cleanup is successful
test "$(docker container inspect chris 2>&1 > /dev/null)" \
  '=' 'Error: No such container: chris' \
  && ! test -e FS

