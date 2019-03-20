#!/bin/sh

export PATH=$PATH:/usr/lib/postgresql/11/bin

mkdir -p /data/citus/master /data/citus/worker1 /data/citus/worker2
cd /data
chown -R postgres /data/citus

sudo -u postgres initdb -D citus/master
sudo -u postgres initdb -D citus/worker1
sudo -u postgres initdb -D citus/worker2

PGDATA=/data/citus/master /docker-entrypoint-initdb.d/init_for_testing.sh
PGDATA=/data/citus/worker1 /docker-entrypoint-initdb.d/init_for_testing.sh
PGDATA=/data/citus/worker2 /docker-entrypoint-initdb.d/init_for_testing.sh

echo "shared_preload_libraries = 'citus'" >> citus/master/postgresql.conf
echo "shared_preload_libraries = 'citus'" >> citus/worker1/postgresql.conf
echo "shared_preload_libraries = 'citus'" >> citus/worker2/postgresql.conf

sudo -u postgres pg_ctl -D citus/master start
sudo -u postgres pg_ctl -D citus/worker1 -o "-p 9701" start
sudo -u postgres pg_ctl -D citus/worker2 -o "-p 9702" start

sudo -u postgres psql --file=/docker-entrypoint-initdb.d/init.sql
sudo -u postgres psql --file=/docker-entrypoint-initdb.d/001-create-citus-extension.sql

sudo -u postgres psql -p 9701 --file=/docker-entrypoint-initdb.d/init.sql
sudo -u postgres psql -p 9701 --file=/docker-entrypoint-initdb.d/001-create-citus-extension.sql

sudo -u postgres psql -p 9702 --file=/docker-entrypoint-initdb.d/init.sql
sudo -u postgres psql -p 9702 --file=/docker-entrypoint-initdb.d/001-create-citus-extension.sql

sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9701);"
sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9702);"



