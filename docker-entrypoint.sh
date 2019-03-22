#!/bin/sh

echo "*** Starting a citus-cluster with two workers ***"

export PATH=$PATH:/usr/lib/postgresql/11/bin

./init-databases.sh

exec "$@"