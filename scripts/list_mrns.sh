#!/bin/bash -e
# Purpose: list all Patient MRNs inside Orthanc

set -o pipefail

curl -sfu orthanc:orthanc http://localhost:8042/patients \
  | jq -r ".[]" \
  | xargs -I _ curl -sfu orthanc:orthanc 'http://localhost:8042/patients/_' \
  | jq -r ".MainDicomTags.PatientID"
