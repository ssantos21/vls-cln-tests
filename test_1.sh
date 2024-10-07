source functions.sh

first_result=$(docker container exec lightningd-regtest lightning-cli --regtest listfunds)

docker container exec lightningd-regtest lightning-cli --regtest stop

docker compose stop core-lightning

primary_container="postgres_cln"
replica_container="postgres_replica_cln"

echo "Starting replication check..."
if check_replication_sync "$primary_container" "$replica_container"; then
    echo "Replication check completed successfully."
else
    echo "Replication check failed."
    exit 1
fi

docker compose stop restore_server

docker compose down -v restore_server

RESTORE_FROM_REPLICA=true docker compose up -d restore_server

# VLS node connects to new restored postgres server

DB_CONN_STRING=postgres://user:password@restore_server:5432/mydb docker compose up -d --build core-lightning

bash wait-for-services.sh

second_result=$(docker container exec lightningd-regtest lightning-cli --regtest listfunds)

echo "First result: $first_result"

echo "Second result: $second_result"
