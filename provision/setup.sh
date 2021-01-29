#!/bin/sh -ex
# 0. wait for CUBE to be online
# 1. create user chris:chris1234 in CUBE
# 2. add local compute environment
# 3. register pl-dircopy

docker wait cube-starting

superuser_script='
from django.contrib.auth.models import User
User.objects.create_superuser(username="chris", password="chris1234", email="dev@babymri.org")'

docker exec chris python manage.py shell -c "$superuser_script"

docker exec chris python plugins/services/manager.py \
  add host "http://pfcon.local:5005" --description "Local compute"

# pl-dircopy
docker exec chris python plugins/services/manager.py register host --pluginurl https://chrisstore.co/api/v1/plugins/7/
