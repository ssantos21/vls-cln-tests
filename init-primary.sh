#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER SYSTEM SET wal_level = replica;
    ALTER SYSTEM SET max_wal_senders = 2;
    ALTER SYSTEM SET max_replication_slots = 2;
    ALTER SYSTEM SET hot_standby = on;
EOSQL

echo "host replication $POSTGRES_USER all md5" >> "$PGDATA/pg_hba.conf"