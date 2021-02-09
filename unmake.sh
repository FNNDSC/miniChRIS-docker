#!/bin/bash

# change to directory where this script lives
cd $(dirname "$(readlink -f "$0")")

docker-compose down -v
