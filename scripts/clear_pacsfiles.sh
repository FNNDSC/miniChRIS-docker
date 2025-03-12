#!/usr/bin/env bash
# Purpose: wipe pfdcm and CUBE pacsfiles

# change to directory where this script lives
cd "$(dirname "$(readlink -f "$0")")"

set -ex

docker compose exec pfdcm sh -c 'rm -rf /home/dicom/log/seriesData/*'

docker compose exec chris pip install tqdm
docker compose exec chris python manage.py shell -c '
from django.conf import settings
from core.storage import connect_storage
from pacsfiles.models import PACSSeries
from tqdm import tqdm

with tqdm(PACSSeries.objects.all()) as pbar:
    for pacs_file in pbar:
        _ = pacs_file.delete()

storage = connect_storage(settings)
with tqdm(storage.ls("SERVICES/PACS")) as pbar:
    for f in pbar:
        _ = storage.delete_obj(f)

'
