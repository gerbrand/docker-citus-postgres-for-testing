#!/usr/bin/env bash
# Everything below is based on/copied from the docker-entrypoint.sh of the original postgresql-docker at https://hub.docker.com/_/postgres

set -e

if [ ! -s "$PGDATA" ]; then

    mkdir -p $PGDATA /data/citus/worker1 /data/citus/worker2
    cd /data
    chown -R postgres /data/citus

    set -o errexit
    set -o nounset
    PGDATA_MASTER=$PGDATA
    for PGDATA in $PGDATA_MASTER /data/citus/worker1 /data/citus/worker2; do
        sudo -u postgres initdb -D $PGDATA
        echo "shared_preload_libraries = 'citus'" >> $PGDATA/postgresql.conf
        # Big number to avoid running out of worker processes, probably not optimal
	echo "max_worker_processes = 32" >> $PGDATA/postgresql.conf
        # Disabled 2pc, little use in test-set-up in single container
        echo "citus.multi_shard_commit_protocol = 1pc" >> "$PGDATA"/postgresql.conf

        fsync "$PGDATA"/postgresql.conf
        fsync "$PGDATA"/pg_hba.conf
    done

    touch /var/log/postgres-master.log
    chown postgres /var/log/postgres-master.log
fi



