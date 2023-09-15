#!/bin/bash -ex
# Purpose: wipe pfdcm and CUBE pacsfiles

docker compose down --timeout 1 pfdcm pfdcm-listener pfdcm-nonroot-user-volume-fix -v

docker compose exec chris pip install tqdm
docker compose exec chris python manage.py shell -c '
from django.conf import settings
from core.storage import connect_storage
from pacsfiles.models import PACSFile
from tqdm import tqdm

with tqdm(PACSFile.objects.all()) as pbar:
    for pacs_file in pbar:
        pacs_file.delete()

storage = connect_storage(settings)
with tqdm(storage.ls("SERVICES/PACS")) as pbar:
    for f in pbar:
        storage.delete_obj(f)

'
docker compose up -d
