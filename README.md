# Minimake

A no-nonsense local ChRIS instance runner without the shenanigans of
[make.sh](https://github.com/FNNDSC/ChRIS_ultron_backEnd/blob/master/make.sh).

If you've caught yourself muttering

> I don't care about anything, just work

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
2. pull containers
3. start containers
4. setup

`./minimake.sh` takes around ~1 minute to run ~60 lines of code.

## Tips And Tricks

- default superusers `chris:chris1234` created in _CUBE_ and *ChRIS_store*
- containers are named `chris`, `chris_store`, `pfcon`, `pfioh`, and `pman` so you can directly run `docker exec chris ...`
- `./minimake.sh` blocks until CUBE is ready to accept connections, and it exits leaving the services up -- it should be easy to use for tests.
