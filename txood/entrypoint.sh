#!/bin/sh

set -ex

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for txood"

  set -- txood "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "txood" ]; then
  echo "$0: setting network to $BITCOIN_NETWORK"
  echo "$0: setting RPC URL to $BITCOIND_RPC_URL"

  set -- "$@" --network $BITCOIN_NETWORK -r $BITCOIND_RPC_URL
fi

echo
exec "$@"
