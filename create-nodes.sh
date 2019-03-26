#!/usr/bin/env bash
# Everything below is based on/copied from the docker-entrypoint.sh of the original postgresql-docker at https://hub.docker.com/_/postgres

set -e

if [ ! -s "/data/citus/master" ]; then

    mkdir -p /data/citus/master /data/citus/worker1 /data/citus/worker2
    cd /data
    chown -R postgres /data/citus

    set -o errexit
    set -o nounset
    for PGDATA in /data/citus/master /data/citus/worker1 /data/citus/worker2; do
        sudo -u postgres initdb -D $PGDATA
        echo "shared_preload_libraries = 'citus'" >> $PGDATA/postgresql.conf

        fsync "$PGDATA"/postgresql.conf
        fsync "$PGDATA"/pg_hba.conf
    done

    touch /var/log/postgres-master.log
    chown postgres /var/log/postgres-master.log
fi



