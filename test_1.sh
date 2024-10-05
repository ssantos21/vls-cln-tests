docker container exec lightningd-regtest lightning-cli --regtest listfunds

docker compose stop core-lightning

# docker compose stop restore_server

# docker compose rm -v restore_server

docker compose rm -fsv restore_server

RESTORE_FROM_REPLICA=true docker compose up -d restore_server

# VLS node connects to new restored postgres server

DB_CONN_STRING=postgres://user:password@restore_server:5432/mydb docker compose up -d --build core-lightning

bash wait-for-services.sh

docker container exec lightningd-regtest lightning-cli --regtest listfunds

echo "Sleeping for 100 seconds"

sleep 100

docker container exec lightningd-regtest lightning-cli --regtest listfunds
