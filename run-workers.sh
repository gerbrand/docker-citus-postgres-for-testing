#!/bin/sh

pg_ctl -D citus/worker1 -o "-p 9701" -l worker1_logfile start
pg_ctl -D citus/worker2 -o "-p 9702" -l worker2_logfile start

psql -p 9701 --file=/init.sql
psql -p 9702 --file=/init.sql

psql -c "SELECT * from master_add_node('localhost', 9701);"
psql -c "SELECT * from master_add_node('localhost', 9702);"