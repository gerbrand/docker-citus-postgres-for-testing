#!/usr/bin/env bash
# Everything below is based on/copied from the docker-entrypoint.sh of the original postgresql-docker at https://hub.docker.com/_/postgres

set -e

if [ ! -s "$PGDATA" ]; then

    mkdir -p $PGDATA /data/citus/worker1
    cd /data
    chown -R postgres /data/citus

    set -o errexit
    set -o nounset
    PGDATA_MASTER=$PGDATA
    for PGDATA in $PGDATA_MASTER /data/citus/worker1; do
        sudo -u postgres initdb -D $PGDATA
        echo "shared_preload_libraries = 'citus'" >> $PGDATA/postgresql.conf
        # Big number to avoid running out of worker processes, probably not optimal
	    echo "max_worker_processes = 8" >> $PGDATA/postgresql.conf
        # Citus needs a lot of connections, set max to some high number
        echo "max_connections = 150" >> $PGDATA/postgresql.conf

        # Disabled 2pc, little use in test-set-up in single container
        echo "citus.multi_shard_commit_protocol = 1pc" >> "$PGDATA"/postgresql.conf

        # Some configuration options for improved performance, taken from:
        # https://github.com/labianchin/docker-postgres-for-testing/blob/master/config.sh
        echo "Configuring psql with improved performance..."

        sed -ri "s/^#*(fsync\s*=\s*)\S+/\1 off/" "$PGDATA"/postgresql.conf
        sed -ri "s/^#*(full_page_writes\s*=\s*)\S+/\1 off/" "$PGDATA"/postgresql.conf
        sed -ri "s/^#*(random_page_cost\s*=\s*)\S+/\1 2.0/" "$PGDATA"/postgresql.conf
        sed -ri "s/^#*(checkpoint_segments\s*=\s*)\S+/\1 64/" "$PGDATA"/postgresql.conf
        sed -ri "s/^#*(checkpoint_completion_target\s*=\s*)\S+/\1 0.9/" "$PGDATA"/postgresql.conf

        fsync "$PGDATA"/postgresql.conf
        fsync "$PGDATA"/pg_hba.conf
    done

    touch /var/log/postgres-master.log
    chown postgres /var/log/postgres-master.log
fi



