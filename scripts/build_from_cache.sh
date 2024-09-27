#!/bin/sh

set -ex

SERVICE=$1

cd $SERVICE

docker build --load --builder $BUILDER --cache-from $CACHE/$SERVICE:$CACHE_TAG -t $SERVICE:$IMAGE_TAG $(grep -v '^#' ../.env | sed 's/^/--build-arg /' | tr '\n' ' ') .
