#!/bin/sh -ex
# 0. wait for CUBE to be online
# 1. create user chris:chris1234 in CUBE
# 2. add local compute environment
# 3. register pl-dircopy

docker wait cube-starting
res=$(docker inspect --format '{{ .State.ExitCode }}'  cube-starting)
if [ "$res" != "0" ]; then
  echo "Timed out waiting for ChRIS backend."
  exit 1
fi

if [ -f /miniChRIS_state/.setup ]; then
  echo "Already set up"
  exit 1
fi


docker exec chris python manage.py shell -c '
from core.models import ChrisInstance
inst = ChrisInstance.load()
inst.job_id_prefix = "minichris-jid-"
inst.save()'


superuser_script='
from django.contrib.auth.models import User
User.objects.create_superuser(username="chris", password="chris1234", email="dev@babymri.org")'

docker exec chris       python manage.py shell -c "$superuser_script"
docker exec chris_store python manage.py shell -c "$superuser_script"

docker exec chris python plugins/services/manager.py \
  add host "http://pfcon.host:5005/api/v1/" --description "Local compute"

touch /miniChRIS_state/.setup

# install plugins
docker restart minichris_plugins_installer
