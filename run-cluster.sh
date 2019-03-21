#!/bin/sh

#sudo -u postgres pg_ctl -D /data/citus/master start
sudo -u postgres pg_ctl -D /data/citus/worker1 -o "-p 9701" start
sudo -u postgres pg_ctl -D /data/citus/worker2 -o "-p 9702" start


sudo -u postgres postgres -D /data/citus/master