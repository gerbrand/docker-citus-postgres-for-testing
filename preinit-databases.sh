#!/usr/bin/env bash

# Script to be run during build-time, to pre-initialise database(s) for faster startup time
sudo -u postgres pg_ctl -D $PGDATA start
sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start

for PORT in 5432 9701; do
        echo Initializing databases $POSTGRES_DBS at port $PORT
        sudo -u postgres createdb -h localhost -p $PORT "template-postgis" 2> /dev/null || echo template-postgis database is present
        for POSTGRES_DB in $POSTGRES_DBS; do
            if [ "$POSTGRES_DB" != 'postgres' ]; then
                sudo -u postgres createdb -h localhost -p $PORT "$POSTGRES_DB"
            fi
            for f in /docker-build-initdb.d/*.sql; do                
                sudo -u postgres psql -h localhost -p $PORT -f "$f" "$POSTGRES_DB"
            done
        done
done

# Add all worker-nodes to coordinator-node
for POSTGRES_DB in $POSTGRES_DBS; do    
    sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9701);" "$POSTGRES_DB"
done

echo Pre-init completed, shutting down database-nodes
sleep 15s

sudo -u postgres pg_ctl -D $PGDATA -w stop
sudo -u postgres pg_ctl -D /data/citus/worker1 -w stop

sleep 15s
