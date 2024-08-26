#!/usr/bin/env sh

set -ex
exec chrs login --username chris --password chris1234 --cube http://localhost:8000/api/v1/ --ui http://localhost:8020/api/v1/ --no-keyring
