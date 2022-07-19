# ![ChRIS logo](https://raw.githubusercontent.com/FNNDSC/ChRIS_ultron_backEnd/master/docs/assets/logo_chris.png) miniChRIS

[![CI](https://github.com/FNNDSC/miniChRIS/workflows/CI/badge.svg)](https://github.com/FNNDSC/miniChRIS/actions?query=workflow%3ACI)
[![GitHub license](https://img.shields.io/github/license/FNNDSC/miniChRIS)](LICENSE)

Run a demo of ChRIS. https://chrisproject.org/

```bash
git clone https://github.com/FNNDSC/miniChRIS-docker.git
cd miniChRIS-docker
./minichris.sh
```

## Usage

A default superuser `chris:chris1234` is created.

website        | URL
---------------|-----
ChRIS_ui       | http://localhost:8020/
ChRIS admin    | http://localhost:8000/chris-admin/
ChRIS_store_ui | http://localhost:8021/

### Start

```bash
./minichris.sh
```

### Stop

```bash
./unmake.sh
```

### Not Working?

1. Make sure you have `docker` and `docker-compose` both installed and working properly.
2. Stop all running containers.
3. No process should be bound to ports 5005, 5010, 5055, 8000, 8010, 8020, 8021

#### Still Not Working?

Try `docker-compose down -v --remove-orphans`.

### Add Plugins

Add them to `chrisomatic.yml` and then rerun `./minichris.sh`.
For more information, see https://github.com/FNNDSC/chrisomatic#plugins-and-pipelines

# Github Actions

*miniChRIS* can be used as a step in Github Actions workflows to spin up
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
      uses: FNNDSC/miniChRIS-docker@20220718
    - name: make a request
      run: curl -u "${{ steps.cube.outputs.cube-user }}" "${{ steps.cube.outputs.cube-url }}"
```

### Examples

- [FNNDSC/cookicutter-chrisapp/.github/workflows/test.yml](https://github.com/FNNDSC/cookiecutter-chrisapp/blob/16db74860e8201f3d201183961eadc39116ce8a7/.github/workflows/test.yml#L31) uses *ChRIS miniChRIS* for end-to-end testing.
- [FNNDSC/cni-store-proxy/package.json](https://github.com/FNNDSC/cni-store-proxy/blob/master/package.json) uses *ChRIS miniChRIS* as a git submodule for a local dev environment.


# About

_miniChRIS_ provides a no-nonsense collection of scripts which use
[Docker Compose](https://docs.docker.com/compose/)
to run a minimal and complete _ChRIS_ system.

## v.s. `make.sh`

The conventional way to run a _ChRIS_ system is
[ChRIS_ultron_backEnd/make.sh](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/master/make.sh).

_miniChRIS_ does not replace `make.sh`. However, for most users
looking for how to run _ChRIS_ and have it "just work," _miniChRIS_
is right for you.

- _miniChRIS_ has 109 lines of shell code --- *ChRIS_ultron_backEnd* has 3,200
- _miniChRIS_ does not create files on host outside of named docker volumes
- `make.sh` runs arbitrary `chmod 755` and `chmod -R 777` on the host filesystem.
- _miniChRIS_ is fully containerized.
- `make.sh` has unlisted dependencies, does not work cross-platform (e.g. default `bash` on Mac not supported, no support for Windows)
- `minichris.sh` does not have any command-line arguments. Usage: `./minichris.sh`
- The recommended way to run `./make.sh` is: `docker swarm leave --force && docker swarm init --advertise-addr 127.0.0.1 && ./unmake.sh && sudo rm -fr CHRIS_REMOTE_FS && rm -fr CHRIS_REMOTE_FS && ./make.sh -U -I -i`
- `make.sh` runs backend automatic tests.
- `minichris.sh` provides a complete `docker-compose.yml`
- `make.sh` uses `docker stack deploy`; `docker-compose_dev.yml` depends on `.env` and other variables set by `make.sh`

### Goals

- fast and minimal
- practical for E2E testing

#### Non-Goals

- production use
- back-end development environment

### Performance

`./minichris.sh` takes 30-60 seconds on a decent laptop (quad-core, 16 GB, SSD)
and takes 2-3 minutes in [Github Actions' Ubuntu VMs](https://github.com/FNNDSC/miniChRIS/actions).
It is strongly recommended that you use an SSD!

## How It Works

Traditionally, to bring up CUBE+pfcon+pman on a single-machine on-the-metal requires a few extra steps on the host.

CUBE setup typically involves:

1. waiting for web server to come online
2. creating a superuser
3. adding `host` as a compute environment
4. registering some plugins: `pl-dircopy` and `pl-topologicalcopy` are required

### pman

`pman` setup involves:

1. joining a docker swarm
2. figuring out the [`STOREBASE` environment variable](h)

`pman` is special because it itself is a container which spawns other containers on its host.

It needs `/var/run/docker.sock` to be mounted inside the container.
We can resolve the two setup requirements by connecting to the host's dockerd.

#### docker swarm

`workarounds/swarm.sh` manages single-machine swarm cluster state.
When the service `swarm-status` is brought up, it tells the local
docker daemon to create and join a swarm.

#### `STOREBASE`

`STOREBASE` is a space for files created by plugin instances.
`./workarounds/storebase.sh` derives the path of a docker volume
and provides it to `pman`.

About: https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/78670f6abf0b6ebac7aeef75989893b4502d4823/docker-compose_dev.yml#L208-L222
