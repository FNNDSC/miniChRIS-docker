#!/bin/sh
# Poll /api/v1/users/ on a given port every two seconds,
# unblocking after a successful request.
# Max 150 tries i.e. timeout after 5 minutes

host=${1:-localhost:8000}

for i in $(seq 150); do
  sleep 2
  curl -s http://$host/api/v1/users/ && exit 0
  printf .
done
exit 1
