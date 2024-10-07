#!/bin/bash

docker compose --profile vls up -d --build

bash wait-for-services.sh

bash setup_nodes.sh

# bash test_1.sh

# docker compose down -v