#!/bin/bash -ex
# Purpose: wipe pfdcm and CUBE pacsfiles

docker compose down pfdcm pfdcm-listener pfdcm-nonroot-user-volume-fix pfdcm-redis -v

docker compose exec chris pip install --user tqdm
docker compose exec chris python manage.py shell -c '
from pacsfiles.models import PACSFile
from tqdm import tqdm

with tqdm(PACSFile.objects.all()) as pbar:
    for pacs_file in pbar:
        pacs_file.delete()

'
docker compose up -d
