#!/usr/bin/env sh
# Purpose: upload a directory of DICOMs to Orthanc.

if ! [ -d "$1" ]; then
  echo "Must give a directory of DICOM files."
  exit 1
fi

url="http://localhost:8042/instances"

exec fd -L --no-ignore-vcs --ignore-case --type f -e '.dcm' \
  -j 4 \
  -x curl -sSfX POST -u orthanc:orthanc "$url" -H 'Expect:' -H 'Content-Type: application/dicom' -T '{}' -o /dev/null \; \
  . "$1"
