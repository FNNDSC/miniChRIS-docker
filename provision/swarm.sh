#!/bin/sh
# creates a docker swarm and then waits for pman to exit.
# after pman exits, and SIGTERM is received, then we leave the swarm

docker swarm init --advertise-addr 127.0.0.1 || exit 1

trap 'STOP=y' TERM INT

docker wait pman

until [ "$STOP" = "y" ]; do
  sleep 1
done

docker swarm leave --force
