
# Docker Postgres, with Citus and Postgis extensions, for testing

[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)
[![Docker Stars](https://img.shields.io/docker/stars/gerbrand/citus-single-machine-cluster.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)
[![Docker Pulls](https://img.shields.io/docker/pulls/gerbrand/citus-single-machine-cluster.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)

This a docker image based on/inspired by the [Docker Postgres For Testing](https://github.com/labianchin/docker-postgres-for-testing), with Citus-extension and worker nodes preconfigured using manual on https://docs.citusdata.com/en/v8.1/installation/single_machine_debian.html as well as Postgis-extension installed.
The initialisation script, docker-entrypoint.sh based on the script of the [Postgres docker image](https://hub.docker.com/_/postgres).

The databases are prepared during build time, including postgis-extension. This way, the docker-image will start faster.

Two worker nodes are started within the docker-container, so you'll have a full citus cluster running with minimal start-up time. Great for integration-tests.

## Tweaks and tips for testing
See [labianchin's readme](https://github.com/labianchin/docker-postgres-for-testing#tips-for-writing-tests)

