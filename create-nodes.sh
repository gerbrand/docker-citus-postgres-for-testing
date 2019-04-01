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
        # Avoiding 'sorry, too many clients already': Citus requires quite a few connections
        echo "max_connections = 250" >> "$PGDATA"/postgresql.conf
        echo "max_prepared_transactions = 250" >> "$PGDATA"/postgresql.conf
        # Disabled 2pc, little use in test-set-up in single container
        echo "citus.multi_shard_commit_protocol = 1pc" >> "$PGDATA"/postgresql.conf

        fsync "$PGDATA"/postgresql.conf
        fsync "$PGDATA"/pg_hba.conf
    done

    touch /var/log/postgres-master.log
    chown postgres /var/log/postgres-master.log
fi



