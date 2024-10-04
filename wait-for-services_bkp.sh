#!/bin/bash

set -e

SERVICES=(
  lightningd-regtest
  alice
  bob
)

# Start all services
# docker-compose up -d

echo "Waiting for services to become healthy..."

for SERVICE in "${SERVICES[@]}"; do
  echo "Checking $SERVICE..."
  until [ "$(docker inspect -f '{{.State.Health.Status}}' $SERVICE)" == "healthy" ]; do
    printf '.'
    sleep 5
  done
  echo "$SERVICE is healthy."
done

echo "All services are up and running!"
