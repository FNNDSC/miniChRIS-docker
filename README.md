# ![ChRIS logo](https://raw.githubusercontent.com/FNNDSC/ChRIS_ultron_backEnd/master/docs/assets/logo_chris.png) _ChRIS_ Minimake

[![CI](https://github.com/FNNDSC/minimake/workflows/CI/badge.svg)](https://github.com/FNNDSC/minimake/actions?query=workflow%3ACI)
[![GitHub license](https://img.shields.io/github/license/FNNDSC/minimake)](https://github.com/FNNDSC/minimake/blob/master/LICENSE)

Run a demo of ChRIS. https://chrisproject.org/

```bash
git clone https://github.com/FNNDSC/minimake.git chris_minimake
cd chris_minimake
./minimake.sh
```

## Usage

A default superuser `chris:chris1234` is created.

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

### Wait

Block until CUBE is ready for use.

```bash
docker wait cube-setup
```

### Fancy Start

Beautiful output and some runtime assertions.

```bash
./minimake.sh
```

# Github Actions

*Minimake* can be used as a step in Github Actions workflows to spin up
an ephermeral instance of the ChRIS backend and its ancillary services
for the purpose of end-to-end testing.

```yaml
on: [push]

jobs:
  hello_world_job:
    runs-on: ubuntu-latest
    name: Do nothing useful
    steps:
    - name: setup CUBE
      id: cube
      uses: fnndsc/minimake@v3
    - name: make a request
      run: curl -u "${{ steps.cube.outputs.cube-user }}" "${{ steps.cube.outputs.cube-url }}"
```

### Examples

- [FNNDSC/cookicutter-chrisapp/.github/workflows/test.yml](https://github.com/FNNDSC/cookiecutter-chrisapp/blob/16db74860e8201f3d201183961eadc39116ce8a7/.github/workflows/test.yml#L31) uses *ChRIS Minimake* for end-to-end testing.
- [FNNDSC/cni-store-proxy/package.json](https://github.com/FNNDSC/cni-store-proxy/blob/master/package.json) uses *ChRIS Minimake* as a git submodule for a local dev environment.


# About

`./minimake.sh` is a no-nonsense collection of scripts to start ChRIS without the shenanigans of
[make.sh](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/master/make.sh).
It is fully managed by `docker-compose`.

Traditionally, to bring up CUBE+pfcon+pfioh+pman on a single-machine on-the-metal requires a few extra steps on the host.

CUBE setup involves:

1. waiting for web server to come online
2. creating a superuser
3. adding `host` as a compute environment
4. registering some plugins

`pman` setup involves:

1. joining a docker swarm
2. figuring out the [`STOREBASE` environment variable](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/78670f6abf0b6ebac7aeef75989893b4502d4823/docker-compose_dev.yml#L208-L222)

`pman` is special because it itself is a container which spawns other containers on its host.

It needs `/var/run/docker.sock` to be mounted inside the container.
We can resolve the two setup requirements by connecting to the host's dockerd.

The workaround for `STOREBASE` was merged upstream.
https://github.com/FNNDSC/pman/pull/142

`./minimake.sh` takes 50 seconds on an okay laptop (quad-core, 16 GB, SSD)
and takes 2-3 minutes in [Github Actions' Ubuntu VMs](https://github.com/FNNDSC/minimake/actions).

### Goals

- fast
- simple use
  - no arguments
  - do one thing, and one thing well (a UNIX philosophy)
- legible code
- practical for E2E testing

#### Non-Goals

- configurable
- production use
- back-end development environment

### More Plugins

You can do a search on https://chrisstore.co for plugins to add,
then use a for-loop to register them all.

```bash
# add one thing
name=pl-brainmgz
url=$(
  curl -s -H 'Accept:application/json' \
    "https://chrisstore.co/api/v1/plugins/search/?name=$url" \
      | jq -r '.results[].url'
)
docker exec chris python plugins/services/manager.py register host --pluginurl "$url"

# add everything
search=$(
  curl -s -H 'Accept:application/json' \
    'https://chrisstore.co/api/v1/plugins/' \
      | jq -r '.results[].url'
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
