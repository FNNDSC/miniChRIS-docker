#!/bin/bash

# change to directory where this script lives
cd $(dirname "$0")

# stop and remove everything
docker compose down -v
