#!/usr/bin/env bash

set -e

echo "*** Starting a citus-cluster with two workers ***"

export PATH=$PATH:/usr/lib/postgresql/11/bin

# Everyting below is based on/copied from the docker-entrypoint.sh of the original postgresql-docker at https://hub.docker.com/_/postgres

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

# check password first so we can output the warning before postgres
# messes it up
file_env 'POSTGRES_PASSWORD'
if [ "$POSTGRES_PASSWORD" ]; then
    pass="PASSWORD '$POSTGRES_PASSWORD'"
    authMethod=md5
else
    echo "WARNING: No password has been set for the database."

    pass=
    authMethod=trust
fi

PGDATA_MASTER=$PGDATA
for PGDATA in $PGDATA_MASTER /data/citus/worker1; do
    echo "" >> "$PGDATA/pg_hba.conf"
    echo "host all all all $authMethod" >> "$PGDATA/pg_hba.conf"
    fsync "$PGDATA"/pg_hba.conf
done

sudo -u postgres pg_ctl -D $PGDATA_MASTER -l /var/log/postgres-master.log start
sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start

for POSTGRES_DB in $POSTGRES_DBS; do
    echo Running initialization scripts for database $POSTGRES_DB
    # database is already set-up, only run the entry-scripts
    psql=( sudo -u postgres psql --dbname "$POSTGRES_DB" )
    
    for f in /docker-entrypoint-initdb.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; "${psql[@]}" -f "$f"; echo ;;
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done
done

# Finally set password
if [ "$POSTGRES_USER" != 'postgres' ]; then
    sudo -u postgres psql -h localhost -c "CREATE USER "$POSTGRES_USER" WITH SUPERUSER $pass ;"
else
    sudo -u postgres psql -h localhost -c "ALTER USER "$POSTGRES_USER" WITH SUPERUSER $pass ;"
fi

tail -f /var/log/postgres-master.log
