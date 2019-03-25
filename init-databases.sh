#!/usr/bin/env bash
# Everyting below is based on/copied from the docker-entrypoint.sh of the original postgresql-docker at https://hub.docker.com/_/postgres

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

    sudo -u postgres pg_ctl -D /data/citus/master start
    sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start
    sudo -u postgres pg_ctl -D /data/citus/worker2 -o "-p 9702" start

    for PORT in 5432 9701 9702; do
            echo Initializing databases $POSTGRES_DBS at port $PORT
            for POSTGRES_DB in $POSTGRES_DBS; do
                if [ "$POSTGRES_DB" != 'postgres' ]; then
                    sudo -u postgres psql -h localhost -p $PORT -c "CREATE DATABASE \"$POSTGRES_DB\";"
                fi
                for f in /docker-entrypoint-initdb.d/*.sql; do
                    sudo -u postgres psql -h localhost -p $PORT -f "$f" "$POSTGRES_DB"
                done
            done
    done
    # Delete files present at build-time, no need to run them again
    rm /docker-entrypoint-initdb.d/*.sql

    # Add all databases to master-node
    for POSTGRES_DB in $POSTGRES_DB; do    
        sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9701);" "$POSTGRES_DB"
        sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9702);" "$POSTGRES_DB"
    done
    
    sudo -u postgres pg_ctl -D /data/citus/master -m fast -w stop
    sudo -u postgres pg_ctl -D /data/citus/worker1 -m fast -w stop
    sudo -u postgres pg_ctl -D /data/citus/worker2 -m fast -w stop

    touch /var/log/postgres-master.log
    chown postgres /var/log/postgres-master.log
fi



