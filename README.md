# ![ChRIS logo](https://raw.githubusercontent.com/FNNDSC/ChRIS_ultron_backEnd/master/docs/assets/logo_chris.png) Minimake

[![CI](https://github.com/FNNDSC/minimake/workflows/CI/badge.svg)](https://github.com/FNNDSC/minimake/actions?query=workflow%3ACI)
[![GitHub license](https://img.shields.io/github/license/FNNDSC/minimake)](https://github.com/FNNDSC/minimake/blob/master/LICENSE)

A no-nonsense local ChRIS instance runner without the shenanigans of
[make.sh](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/master/make.sh).

If you've caught yourself muttering

> I don't care about all of this, just work

then this is the repo for you.

based on
https://github.com/FNNDSC/ChRIS_ultron_backEnd/tree/0ed91d7c3b3feaf9d68348623649a5d2e9918e34

## Start

```bash
./minimake.sh
```

## Stop

```bash
./unmake.sh
```

## Details

`./minimake.sh` wraps `docker-compose up -d` and it does a _few_ more things:

1. start swarm
2. pull images
3. start containers
4. wait for services
4. first-run setup

`./minimake.sh` takes around ~1 minute to run.

## Tips And Tricks

- http://localhost:8000/chris-admin/
- if `./minimake.sh` exits with a non-0 status, it is strongly recommended to run `./unmake.sh`
- default superusers `chris:chris1234` created in _CUBE_ and *ChRIS_store*
- containers are named `chris`, `chris_store`, `pfcon`, `pfioh`, and `pman` so you can directly run `docker exec chris ...`

### E2E Testing

`./minimake.sh` blocks until CUBE is ready to accept connections,
and it exits leaving the services up -- it should be easy to use for tests.

See https://github.com/FNNDSC/cni-store-proxy/blob/master/package.json
as an example.

### More Plugins

You can do a search on https://chrisstore.co for plugins to add,
then use a for-loop to register them all.

```bash
search=$(
  curl -s -H 'Accept:application/json' 'https://chrisstore.co/api/v1/plugins/' \
    | jq -r '.results[] | .url'
)
for $pu in $search; do
  docker exec chris python plugins/services/manager.py register host --pluginurl "$pu"
fi
```

## Vagrant

No docker? That's okay.

`Vagrantfile` provides a virtual machine (VM) with latest `docker-compose` installed.
VMs are inherently slow, and docker image pulls are not cached between lifecycles.
Setup using Vagrant is wasteful of time, memory, disk, and network bandwidth.
For me, `vagrant up` took 9 minutes.

### Start

```bash
vagrant up
```

### Stop

```bash
vagrant destroy -f
```
