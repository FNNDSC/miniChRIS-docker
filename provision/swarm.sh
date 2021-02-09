#!/bin/sh
# initializes docker swarm and then waits for pman to exit.
# after pman exits, and SIGTERM is received, then we leave the swarm

printf "Detecting current docker swarm status... "

status=$(docker info --format '{{ .Swarm.LocalNodeState }}')
error=$?
if [ "$error" != "0" ]; then
  echo "error"
  exit $error
fi

echo $status

if [ "$status" = "inactive" ]; then
  docker swarm init --advertise-addr 127.0.0.1 || exit 1
  leave_command="docker swarm leave --force"
elif [ "$status" = "active" ]; then
  leave_command="true"
else
  echo "Unrecognized status"
  exit 1
fi

function end_swarm () {
  $@
  exit_status=$?
  STOP=y
  exit $exit_status
}

trap "end_swarm $leave_command" TERM INT

# Now, we just want to sleep and let the script end via the
# function end_swarm which is invoked asynchronously by
#
#     docker-compose down
#
# The specific solution below is pedantic.
#
# 1. `docker wait` blocks without polling, which is something bash cannot do.
# 2. poll until execution of `end_swarm` is finished
# 3. script should exit via `exit` command in `end_swarm`
# 4. the last lines `sleep 1 && exit 1` should never occur,
#    but are there in case a solar neutrino flips a bit in memory
#    (i.e. just to have complete coverage in our execution tree)
#
# Everything would work the same way if we just did
#
#     while true; do sleep 10000; done

docker wait pman

until [ "$STOP" = "y" ]; do
  sleep 1
done

sleep 1
exit 1
