
# Docker Postgres, with Citus and Postgis extensions, for Testing

[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)
[![Docker Stars](https://img.shields.io/docker/stars/gerbrand/citus-single-machine-cluster.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)
[![Docker Pulls](https://img.shields.io/docker/pulls/gerbrand/citus-single-machine-cluster.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)

This a docker image based on/inspired by the [Docker Postgres For Testing](https://github.com/labianchin/docker-postgres-for-testing), with Citus-extension and worker nodes preconfigured using manual on https://docs.citusdata.com/en/v8.1/installation/single_machine_debian.html as well as Postgis-extension installed.
The initialisation script, docker-entrypoint.sh based on the script of the [Postgres docker image](https://hub.docker.com/_/postgres).

The database(s) are prepared during *build-time*, including postgis-extension. This way, the docker-image will start faster.

* By default, the default database *postgres* is available. Other database(s) can be configured using build-arguments, for example:
  `docker build . --tag myapp/citus-single-machine-cluster:latest --build-arg "POSTGRES_DBS=myappa myappb"`

* If you want you can run initialisation scripts at build time, in case they take a long time to run
  `docker build . --tag myapp/citus-single-machine-cluster:latest --build-arg "SQL_BUILD_INIT_FILES=mytestdata.sql"`<br/>
  Above commands asumes mytestdata.sql is present in the current directory

Username and password can be set during *run-time*, for example
`POSTGRES_USER=myapp POSTGRES_PASSWORD=myapppassword docker run -p5432:5432 gerbrand/citus-single-machine-cluster:latest`

Two worker nodes are started within the docker-container, so you'll have a full citus cluster running with minimal start-up time. Great for integration-tests.

## Tweaks and tips for testing
See [labianchin's readme](https://github.com/labianchin/docker-postgres-for-testing#tips-for-writing-tests)

