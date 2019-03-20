#!/bin/sh

export PATH=$PATH:/usr/lib/postgresql/11/bin

cd /var/lib/postgresql
# The preconfigured postgresql will act as coordinator, so no need to configure that
mkdir -p citus/worker1 citus/worker2

PGDATA=/var/lib/postgresql/citus/worker1 /init_for_testing.sh
PGDATA=/var/lib/postgresql/citus/worker2 /init_for_testing.sh

echo "shared_preload_libraries = 'citus'" >> citus/worker1/postgresql.conf
echo "shared_preload_libraries = 'citus'" >> citus/worker2/postgresql.conf