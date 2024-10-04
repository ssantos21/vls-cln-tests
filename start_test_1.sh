#!/bin/bash

docker compose --profile vls up -d --build

bash wait-for-services.sh

bash setup_nodes.sh

docker compose down -v
