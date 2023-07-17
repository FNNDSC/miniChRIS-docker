#!/bin/bash -e
# Purpose: monitor Redis for pypx-re-mode data

refresh_rate="${1-0.25}"

script="$(cat << EOF
import os
import time
import redis

r = redis.from_url(os.getenv('PYPX_REDIS_URL'), decode_responses=True)

while True:
    os.system('clear')
    all_series = r.keys('series:*')

    if all_series:
        for series in all_series:
            data = r.hgetall(series)
            print(f'{data["fileCounter"]}/{data["NumberOfSeriesRelatedInstances"]} [{data["lastUpdate"]}] {series}')
    else:
        print('Redis is empty')
    
    time.sleep($refresh_rate)
EOF
)"

exec docker compose exec pfdcm python -c "$script"
