#!/bin/bash
# Purpose: upload a directory of DICOMs to Orthanc.

if ! [ -d "$1" ]; then
  echo "Must give a directory of DICOM files."
  exit 1
fi

url="http://localhost:8042/instances"

find -L "$1" -type f -name '*.dcm' \
  | parallel --bar -j 4 "curl -sfX POST -u orthanc:orthanc http://localhost:8042/instances -H Expect: -H 'Content-Type: application/dicom' --data-binary @'{}' -o /dev/null"
