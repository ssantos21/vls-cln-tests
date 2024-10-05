#!/bin/bash
set -e

echo "PGDATA is set to: $PGDATA"

# Remove the recovery.conf file if it exists (for PostgreSQL 11 and earlier)
rm -f "${PGDATA}/recovery.conf"

# Remove the standby.signal file (for PostgreSQL 12 and later)
rm -f "${PGDATA}/standby.signal"

# Modify postgresql.auto.conf to remove any standby settings
if [ -f "${PGDATA}/postgresql.auto.conf" ]; then
    sed -i '/primary_conninfo/d' "${PGDATA}/postgresql.auto.conf"
    sed -i '/recovery_target_timeline/d' "${PGDATA}/postgresql.auto.conf"
    echo "hot_standby = 'off'" >> "${PGDATA}/postgresql.auto.conf"
    echo "Modified postgresql.auto.conf"
else
    echo "postgresql.auto.conf not found. Creating it..."
    echo "hot_standby = 'off'" > "${PGDATA}/postgresql.auto.conf"
fi

echo "Post-restore configuration completed."
