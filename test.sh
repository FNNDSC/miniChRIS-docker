#!/bin/bash -ex
# run pl-dircopy on the file "LICENSE", that's it

cd $(dirname "$(readlink -f "$0")")

# log in
token=$(
  curl -s 'http://localhost:8000/api/v1/auth-token/' \
    -H 'Content-Type:application/json' \
    --data '{"username":"chris","password":"chris1234"}' \
    | jq -r '.token'
)

# upload a file
curl -s 'http://localhost:8000/api/v1/uploadedfiles/' \
  -H 'Accept: application/vnd.collection+json' \
  -H "Authorization: Token $token" \
  -F 'upload_path=chris/uploads/wow-upload-01/LICENSE' \
  -F "fname=@LICENSE"

# find the plugin ID for pl-dircopy
inst_url=$(
  curl -s 'http://localhost:8000/api/v1/plugins/search/?name=pl-dircopy' \
    -H "Authorization: Token $token" \
    -H 'Accept: application/json' | jq -r '.results[0].instances'
)

# run pl-dircopy
feed=$(
  curl -s "$inst_url" \
    -H "Authorization: Token $token" \
    -H 'Content-Type: application/vnd.collection+json' \
    -H 'Accept: application/json' \
    --data '{"template":{"data":[{"name":"dir","value":"chris/uploads/wow-upload-01"}]}}'
)

job_url=$(echo $feed | jq -r .url)

# wait for job to finish, timeout after 5 minutes
{ set +x; } 2> /dev/null
for i in {0..60}; do
  sleep 5
  job=$(
    curl -s "$job_url" \
      -H "Authorization: Token $token" \
      -H 'Accept: application/json'
  )
  run_status=$(echo $job | jq -r .status)
  if [[ "$run_status" == "finished"* ]]; then
    break
  fi
  printf .
done
echo

set -x
if [ "$run_status" != "finishedSuccessfully" ]; then
  exit 1
fi

# download output file
output_files=$(
  curl -s "$(echo $job | jq -r .files)" \
    -H "Authorization: Token $token" \
    -H 'Accept: application/json'
)
copied_file_url=$(
  echo $output_files \
    | jq -r '.results | map(select(.fname|endswith("LICENSE")))[0].file_resource'
)

copied_file_download=$(mktemp)

curl -s -o "$copied_file_download" "$copied_file_url" \
  -H "Authorization: Token $token"

# asser that it's the same as the original
if ! diff -q $copied_file_download LICENSE; then
  exit 1
fi
