#!/bin/bash

docker compose --profile vls up -d --build

source wait-for-services.sh

source setup_nodes.sh

docker compose down -v