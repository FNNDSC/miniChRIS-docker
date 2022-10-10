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
  echo Goodbye
  $leave_command
  exit_status=$?
  STOP=y
  exit $exit_status
}

trap end_swarm TERM INT

# Now, we just want to sleep and let the script end via the
# function end_swarm which is invoked asynchronously by
#
#     docker compose down

docker wait swarm-status &
wait
