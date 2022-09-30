#!/bin/sh

# wait for pfdcm
poll=0
until curl -fs 'http://pfdcm:4005/api/v1/hello/' > /dev/null; do
  sleep 1
  poll=$((poll+1))
  if [ "$poll" = "20" ]; then
    >&2 echo "error: timed out after 20 seconds waiting for pfdcm."
    exit 1
  fi
done

set -ex

# it is not necessary to start the listener, because storescp is running
# in another container.
#curl -if -X 'POST' \
#  'http://pfdcm:4005/api/v1/listener/initialize/' \
#  -H 'accept: application/json' \
#  -H 'Content-Type: application/json' \
#  -d '{
#  "value": "default"
#}'

curl -if -X 'PUT' \
  'http://pfdcm:4005/api/v1/PACSservice/orthanc/' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "info": {
    "aet": "CHRISLOCAL",
    "aet_listener": "ORTHANC",
    "aec": "ORTHANC",
    "serverIP": "orthanc",
    "serverPort": "4242"
  }
}'

curl -if -X 'POST'                                                            \
    'http://pfdcm:4005/api/v1/SMDB/swift/'                                    \
    -H 'accept: application/json'                                             \
    -H 'Content-Type: application/json'                                       \
    -d '{
    "swiftKeyName": {
      "value": "local"
    },
    "swiftInfo": {
      "ip":     "swift",
      "port":   "8080",
      "login":  "chris:chris1234"
    }
}'

curl -if -X 'POST'                                                            \
  "http://pfdcm:4005/api/v1/SMDB/CUBE/"                                       \
  -H 'accept: application/json'                                               \
  -H 'Content-Type: application/json'                                         \
  -d '{
  "cubeKeyName": {
    "value": "local"
  },
  "cubeInfo": {
    "url": "http://chris:8000/api/v1/",
    "username": "chris",
    "password": "chris1234"
  }
}'
