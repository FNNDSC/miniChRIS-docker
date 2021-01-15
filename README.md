# ![ChRIS logo](https://raw.githubusercontent.com/FNNDSC/ChRIS_ultron_backEnd/master/docs/assets/logo_chris.png) Minimake

[![CI](https://github.com/FNNDSC/minimake/workflows/CI/badge.svg)](https://github.com/FNNDSC/minimake/actions?query=workflow%3ACI)
[![GitHub license](https://img.shields.io/github/license/FNNDSC/minimake)](https://github.com/FNNDSC/minimake/blob/master/LICENSE)

A no-nonsense local ChRIS instance runner without the shenanigans of
[make.sh](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/master/make.sh).
Uses various hacks so that CUBE setup is managed completely by `docker-compose`.

## Usage

Default superuser `chris:chris1234` is created in _CUBE_.

website        | URL
---------------|-----
ChRIS_ui       | http://localhost:3000/
ChRIS admin    | http://localhost:8000/chris-admin/
ChRIS_store_ui | http://localhost:3001/

### Start

```bash
docker-compose up -d
```

### Stop

```bash
docker-compose down -v
```

### Update

```bash
docker-compose pull
```

### Fancy Start

Beautiful output and some runtime assertions.

```bash
./minimake.sh
```

# Github Actions

```yaml
on: [push]

jobs:
  hello_world_job:
    runs-on: ubuntu-latest
    name: Do nothing useful
    steps:
    - name: setup CUBE
      id: cube
      uses: fnndsc/minimake@v1
    - name: make a request
      run: curl -u "${{ steps.cube.outputs.cube-user }}" "${{ steps.cube.outputs.cube-url }}"
```

# About

`./minimake.sh` shoves everything inside of shell scripts and `docker-compose.yml`.
Traditionally, to bring up a single-machine on-the-metal requires
a few extra steps on the host.

CUBE setup involves:

1. waiting for web server to come online
2. creating a superuser
3. adding `host` as a compute environment
4. registering some plugins

`pman` setup involves:

1. joining a docker swarm
2. figuring out the [`STOREBASE` environment variable](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/78670f6abf0b6ebac7aeef75989893b4502d4823/docker-compose_dev.yml#L208-L222)

`pman` is messy because it is a container which spawns other containers on its host.

It needs `/var/run/docker.sock` to be mounted inside the container.
We can resolve the two setup requirements by connecting to the host's dockerd.

There is no clean way to `STOREBASE`.
The upstream workaround is to mount `$PWD/FS/remote`
and then tell `pman` the path on the host to this volume.
This leads to difficult cleanup: `$PWD/FS/remote`
is polluted by files with mixed permissions,
neither can it be automatically cleaned up by `docker-compose down -v`
hence an `./unmake.sh <<< y` is necessary.

Here, our workaround is completely managed by `docker-compose`.
A named volume `chris-remote` is defined, and its path on the host
(a.k.a. "Mountpoint") is discovered dynamically and automatically
in `entrypoints/pman.sh`.
Teardown of this CUBE setup does not require any further steps after  `docker-compose down -v`.

`./minimake.sh` takes 50 seconds on an okay laptop (quad-core, 16 GB, SSD)
and takes 2-3 minutes in [Github Actions' Ubuntu VMs](https://github.com/FNNDSC/minimake/actions).

### Goals

- fast
- simple use (one purpose, no arguments)
- legible code
- practical for E2E testing

#### Non-Goals

- configurable
- production use
- back-end development environment

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

### Vagrant

No docker? That's okay.

`Vagrantfile` provides a virtual machine (VM) with latest `docker-compose` installed.
VMs are inherently slow, and docker image pulls are not cached between lifecycles.
Setup using Vagrant is wasteful of time, memory, disk, and network bandwidth.
For me, `vagrant up` took 9 minutes.

#### Start

```bash
vagrant up
```

#### Stop

```bash
vagrant destroy -f
```
