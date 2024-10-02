#!/bin/bash
set -e

if [ "${RESTORE_FROM_REPLICA}" = "true" ]; then
  echo "Restoring data from replica..."
  until PGPASSWORD=${POSTGRES_PASSWORD} psql -h postgres_replica_cln -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for postgres_replica_cln..."
    sleep 1
  done
  echo "Replica PostgreSQL is ready. Starting base backup..."
  export PGPASSWORD=${POSTGRES_PASSWORD}
  pg_basebackup -h postgres_replica_cln -D "${PGDATA}" -U ${POSTGRES_USER} -v -P -X stream
  rm -f "${PGDATA}/standby.signal"
  echo "Base backup completed."
fi
