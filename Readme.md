
# Docker Postgres, with Citus and Postgis extensions, For Testing

[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)
[![Docker Stars](https://img.shields.io/docker/stars/gerbrand/citus-single-machine-cluster.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)
[![Docker Pulls](https://img.shields.io/docker/pulls/gerbrand/citus-single-machine-cluster.svg)](https://registry.hub.docker.com/u/gerbrand/citus-single-machine-cluster/)

This a docker image based on the [Postgres Citus docker image](https://hub.docker.com/r/citusdata/citus) with the worker nodes preconfigured using manual on https://docs.citusdata.com/en/v8.1/installation/single_machine_debian.html and tweaked for testing (see below).
The initialisation script, docker-entrypoint.sh based on the script of the [Postgres docker image](https://hub.docker.com/_/postgres).

Two worker nodes are started within the docker-container, so you'll have a full citus cluster running.

## Tweaks for testing
It basically configure things like turning off write ahead log (`fsync=off`) to make it faster. Notice that this can make the database more likely to be in an inconsistent state, if the case of a server crash. This is not a problem for database testing as we are more concerned with fast feedback and not about loosing data.

This is an alternative to [H2](http://www.h2database.com/html/main.html), [in memory SQLite](https://www.sqlite.org/inmemorydb.html) and [HyperSQL](http://hsqldb.org/). You should consider this as it runs a real PostgreSQL server, that would be very close on what you have in production.

Check the file `init_databases.sh` for all the configurations.

References:

- https://stackoverflow.com/questions/9407442/optimise-postgresql-for-fast-testing
- http://michael.robellard.com/2015/07/dont-test-with-sqllite-when-you-use.html

## Tips for writing tests

- Do all schema setup (DDL) once before running the tests
- Run the schema setup (DDL), as the DB migration that would run in production
- Avoid DDL in each test, as that tent to be very slow
- Before each test, truncate the tables and put some seed data (DML), that should be quick
- Remember fasts tests are important, slow tests make you avoid refactoring code!


## TODO

- Tweak `shared_buffers`
- Tweak `work_mem`
