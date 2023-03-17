# ![ChRIS logo](https://raw.githubusercontent.com/FNNDSC/ChRIS_ultron_backEnd/master/docs/assets/logo_chris.png) miniChRIS

[![CI badge](https://github.com/FNNDSC/miniChRIS-docker/workflows/CI/badge.svg)](https://github.com/FNNDSC/miniChRIS-docker/actions?query=workflow%3ACI)
[![MIT license](https://img.shields.io/github/license/FNNDSC/miniChRIS-docker)](LICENSE)

Run a demo of ChRIS. https://chrisproject.org/

## Abstract

_ChRIS_ is an open-source platform facilitating cloud-based medical compute.
This repository, _miniChRIS-docker_, provides a docker-compose based distribution
of the _ChRIS_ system including:

- _ChRIS_ backend ([ChRIS_ultron_backEnd](https://github.com/fnndsc/CHRIS_ultron_backEnd) a.k.a. CUBE)
- _ChRIS_ frontend ([ChRIS_ui](https://github.com/FNNDSC/ChRIS_ui))
- compute controller ([pfcon](https://github.com/FNNDSC/pfcon))
- process manager ([pman](https://github.com/FNNDSC/pman))
- _ChRIS_ store backend ([ChRIS_store](https://github.com/FNNDSC/ChRIS_store))
- _ChRIS_ store frontend ([ChRIS_store_ui](https://github.com/FNNDSC/ChRIS_store_ui))
- chrisomatic ([chrisomatic](https://github.com/FNNDSC/chrisomatic))
- Orthanc server https://www.orthanc-server.com/
- pfdcm ([pfdcm](https://github.com/FNNDSC/pfdcm))

Image tags are pinned to stable versions, so _miniChRIS_ might be
out-of-date with development versions of _ChRIS_ components.
Please visit the repositories linked above for instructions
on how to run development environments for the latest versions.

#### Which ChRIS???

- _miniChRIS-docker_ is the easiest, fastest, and most portable way to run _ChRIS_.
- [_miniChRIS-podman_](https://github.com/FNNDSC/miniChRIS-podman) uses rootless Podman to run _ChRIS_.
- [ChRIS_ultron_backEnd/make.sh](https://github.com/FNNDSC/ChRIS_ultron_backEnd) runs the _ChRIS_ backend in development mode and optionally runs integration tests.

### System Requirements

_miniChRIS_ requires docker-compose version v2.6 or above.

## Quick Start

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
Orthanc        | http://localhost:8042/

### Default Logins

website      | username | password
-------------|----------|----------
ChRIS        | chris    | chris1234
ChRIS Store  | chris    | chris1234
Orthanc      | orthanc  | orthanc

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

Try `docker compose down -v --remove-orphans`.

### Network Configuration

To run _miniChRIS_ remotely it is necessary to replace occurrences of `localhost` with your machine's hostname or IP address in `docker-compose.yml`.

```shell
sed -i -e 's/localhost/my_machines_hostname/' docker-compose.yml
docker compose up -d
```

### Add Plugins to CUBE

Plugins are added to _ChRIS_ via the Django admin dashboard.

https://github.com/FNNDSC/ChRIS_ultron_backEnd/wiki/%5BHOW-TO%5D-Register-a-plugin-via-Django-dashboard

Alternatively, plugins can be added declaratively.
A common use case would be to run locally built Python
[`chris_plugin`](https://github.com/FNNDSC/chris_plugin)-based
_ChRIS_ plugins. These can be added using `chrisomatic` by
listing their (docker) image tags. For example, if your local image
was built with the tag `localhost/myself/pl-workinprogress` by running

```shell
docker build -t localhost/myself/pl-workinprogress .
```

The bottom of your `chrisomatic.yml` file should look like

```yaml
  plugins:
    - name: pl-dircopy
      version: 2.1.1
    - name: pl-tsdircopy
      version: 1.2.1
    - name: pl-topologicalcopy
      version: 0.2
    - name: pl-simpledsapp
      version: 2.1.0
    - localhost/myself/pl-workinprogress
```

After modifying `chrisomatic.yml`, apply the changes by rerunning `./minichris.sh`

For details, see https://github.com/FNNDSC/chrisomatic#plugins-and-pipelines

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
      uses: FNNDSC/miniChRIS-docker@master
    - name: make a request
      run: curl -u chris:chris1234 http://localhost:8000/api/v1/
```

### Adding Plugins

`plugins` should be a whitespace-separated list of plugin identifiers.
Lines starting with `#` are treated as comments and ignored.
Plugin identifiers are interpreted by _chrisomatic_ as described here:
https://github.com/fnndsc/chrisomatic#plugins-and-pipelines

#### Example

```yaml
on: [push]

jobs:
  hello_world_job:
    runs-on: ubuntu-latest
    name: Do nothing useful
    steps:
    - name: setup CUBE
      id: cube
      uses: FNNDSC/miniChRIS-docker@master
      with:
        plugins: |
          https://chrisstore.co/api/v1/plugins/157/
          pl-lung_cnp
          ghcr.io/fnndsc/pl-re-sub:1.1.1
```

### Examples

- [FNNDSC/ChRIS_ui/.github/workflows/tests.yml](https://github.com/FNNDSC/ChRIS_ui/blob/0b7e4c5c5ae9dec9c44ea68db85373d2df403b64/.github/workflows/tests.yml#L21-L27) uses _miniChRIS_ for testing using [Cypress](https://cypress.io)
- [FNNDSC/cookicutter-chrisapp/.github/workflows/test.yml](https://github.com/FNNDSC/cookiecutter-chrisapp/blob/16db74860e8201f3d201183961eadc39116ce8a7/.github/workflows/test.yml#L31) uses _mihiChRIS_ for end-to-end testing.
- [FNNDSC/cni-store-proxy/package.json](https://github.com/FNNDSC/cni-store-proxy/blob/master/package.json) uses _miniChRIS_ as a git submodule for a local dev environment.


## About

_miniChRIS_ provides a no-nonsense collection of scripts which use
[Docker Compose](https://docs.docker.com/compose/)
to run a minimal and complete _ChRIS_ system.

### v.s. `make.sh`

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

#### Goals

- fast and minimal
- practical for E2E testing

##### Non-Goals

- production use
- back-end development environment

#### Performance

`./minichris.sh` takes 30-60 seconds on a decent laptop (quad-core, 16 GB, SSD)
and takes 2-3 minutes in [Github Actions' Ubuntu VMs](https://github.com/FNNDSC/miniChRIS/actions).
It is strongly recommended that you use an SSD!
