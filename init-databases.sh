#!/usr/bin/env bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'POSTGRES_USER' 'postgres'
file_env 'POSTGRES_DB' "$POSTGRES_USER"

mkdir -p /data/citus/master /data/citus/worker1 /data/citus/worker2
cd /data
chown -R postgres /data/citus

set -o errexit
set -o nounset
for PGDATA in /data/citus/master /data/citus/worker1 /data/citus/worker2; do
    sudo -u postgres initdb -D $PGDATA
    echo "shared_preload_libraries = 'citus'" >> $PGDATA/postgresql.conf
    echo "host  all  all 0.0.0.0/0 trust" >> $PGDATA/pg_hba.conf

    # Some settings for improved performance
    sed -ri "s/^#*(fsync\s*=\s*)\S+/\1 off/" "$PGDATA"/postgresql.conf
    sed -ri "s/^#*(full_page_writes\s*=\s*)\S+/\1 off/" "$PGDATA"/postgresql.conf
    sed -ri "s/^#*(random_page_cost\s*=\s*)\S+/\1 2.0/" "$PGDATA"/postgresql.conf
    sed -ri "s/^#*(checkpoint_segments\s*=\s*)\S+/\1 64/" "$PGDATA"/postgresql.conf
    sed -ri "s/^#*(checkpoint_completion_target\s*=\s*)\S+/\1 0.9/" "$PGDATA"/postgresql.conf

    fsync "$PGDATA"/postgresql.conf
    fsync "$PGDATA"/pg_hba.conf
done


sudo -u postgres pg_ctl -D /data/citus/master start
sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start
sudo -u postgres pg_ctl -D /data/citus/worker2 -o "-p 9702" start

for PORT in 5432 9701 9702; do
        echo Initializing database at port $PORT
        for f in /docker-entrypoint-initdb.d/*.sql; do
            if [ "$POSTGRES_DB" != 'postgres' ]; then
                sudo -u postgres psql -U "$POSTGRES_USER" -h localhost -p $PORT -c "CREATE DATABASE $POSTGRES_DB;"
                sudo -u postgres psql -U "$POSTGRES_USER" -h localhost -p $PORT -c "CREATE USER "$POSTGRES_USER" WITH SUPERUSER ;"
            else
                sudo -u postgres psql -U "$POSTGRES_USER" -h localhost -p $PORT -c "ALTER USER "$POSTGRES_USER" WITH SUPERUSER ;"
            fi
            sudo -u postgres psql -h localhost -p $PORT -f "$f" "$POSTGRES_DB"
        done
done

sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9701);" "$POSTGRES_DB"
sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9702);" "$POSTGRES_DB"

sudo -u postgres pg_ctl -D /data/citus/master -m fast -w stop
sudo -u postgres pg_ctl -D /data/citus/worker1 -m fast -w stop
sudo -u postgres pg_ctl -D /data/citus/worker2 -m fast -w stop
