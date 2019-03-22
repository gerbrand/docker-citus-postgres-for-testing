#!/usr/bin/env bash
# Everyting below is based on/copied from the docker-entrypoint.sh of the original postgresql-docker at https://hub.docker.com/_/postgres

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

# check password first so we can output the warning before postgres
# messes it up
file_env 'POSTGRES_PASSWORD'
if [ "$POSTGRES_PASSWORD" ]; then
    pass="PASSWORD '$POSTGRES_PASSWORD'"
    authMethod=md5
else
    # The - option suppresses leading tabs but *not* spaces. :)
    echo "WARNING: No password has been set for the database."

    pass=
    authMethod=trust
fi

sudo -u postgres pg_ctl -D /data/citus/master -l /var/log/postgres-master.log start
sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start
sudo -u postgres pg_ctl -D /data/citus/worker2 -o "-p 9702" start


if [ "$POSTGRES_DB" != 'postgres' ]; then
    sudo -u postgres psql -U "$POSTGRES_USER" -h localhost -c "CREATE DATABASE $POSTGRES_DB;"
    sudo -u postgres psql -U "$POSTGRES_USER" -h localhost -c "CREATE USER "$POSTGRES_USER" WITH SUPERUSER $pass ;"
else
    sudo -u postgres psql -U "$POSTGRES_USER" -h localhost -c "ALTER USER "$POSTGRES_USER" WITH SUPERUSER $pass ;"
fi

if [ -f /docker-entrypoint-initdb.d/*.sql ]; then
    # database is already set-up, only run the entry-scripts
    for f in /docker-entrypoint-initdb.d/*.sql; do
        sudo -u postgres psql -h localhost -f "$f" "$POSTGRES_DB"
        echo "Executed $f on $POSTGRES_DB"
    done
fi

tail -f /var/log/postgres-master.log