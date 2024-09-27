#!/bin/sh

set -ex

SERVICE=$1

docker buildx create --name=$SERVICE --use
cd $SERVICE

docker build --load --builder=$SERVICE --cache-to type=registry,ref=$CACHE/$SERVICE:$CACHE_TAG --cache-from $CACHE/$SERVICE:$CACHE_TAG -t $SERVICE:$IMAGE_TAG $(grep -v '^#' ../.env | sed 's/^/--build-arg /' | tr '\n' ' ') .
