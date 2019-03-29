#!/usr/bin/env bash

# Script to be run during build-time, to pre-initialise database(s) for faster startup time
sudo -u postgres pg_ctl -D /data/citus/master start
sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start
sudo -u postgres pg_ctl -D /data/citus/worker2 -o "-p 9702" start

for PORT in 5432 9701 9702; do
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

# Add all databases to master-node
for POSTGRES_DB in $POSTGRES_DBS; do    
    sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9701);" "$POSTGRES_DB"
    sudo -u postgres psql -c "SELECT * from master_add_node('localhost', 9702);" "$POSTGRES_DB"
done

echo Pre-init completed, shutting down database-nodes
sleep 5s

sudo -u postgres pg_ctl -D /data/citus/master -m fast -w stop
sudo -u postgres pg_ctl -D /data/citus/worker1 -m fast -w stop
sudo -u postgres pg_ctl -D /data/citus/worker2 -m fast -w stop

