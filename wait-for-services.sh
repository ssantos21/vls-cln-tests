#!/bin/bash

# List of services to check
services=(
  "core-lightning"
  "alice"
  "bob"
)

# Maximum time to wait in seconds (5 minutes)
max_time=300
# Delay between attempts in seconds
delay=10

start_time=$(date +%s)

while true; do
  echo "Checking services..."
  all_healthy=true

  for service in "${services[@]}"; do
    # Get the container ID
    container_id=$(docker compose ps -q $service)

    if [ -z "$container_id" ]; then
      echo "Service $service not found."
      all_healthy=false
      continue
    fi

    # Get the health status
    health_status=$(docker inspect --format='{{.State.Health.Status}}' $container_id 2>/dev/null)

    if [ "$health_status" == "healthy" ]; then
      echo "Service $service is healthy."
    else
      echo "Service $service health status is '$health_status'."
      all_healthy=false
    fi
  done

  if $all_healthy; then
    echo "All services are healthy. Ready to start tests."
    exit 0
  else
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $max_time ]; then
      echo "Services did not become healthy within 5 minutes."
      exit 1
    else
      echo "Not all services are healthy yet. Waiting for $delay seconds..."
      sleep $delay
    fi
  fi
done
