#!/bin/sh

echo "*** Starting a citus-cluster with two workers ***"

export PATH=$PATH:/usr/lib/postgresql/11/bin

if [ ! -s "/data/citus/master/PG_VERSION" ]; then

	./init-databases.sh

fi

exec "$@"