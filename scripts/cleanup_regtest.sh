#!/bin/sh

set -ex

docker compose --profile vls down
docker volume rm vls-container_bitcoin_regtest
docker volume rm vls-container_lightning_regtest
docker volume rm vls-container_vls_regtest
docker volume rm vls-container_txoo_regtest
docker volume ls | grep -q "vls-container_lss_regtest" && docker volume rm vls-container_lss_regtest
