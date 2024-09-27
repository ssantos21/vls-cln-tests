#!/bin/sh
set -e

cp /bitcoin.conf $BITCOIN_DATA/
sed -i "1s/^/chain=$BITCOIN_CHAIN\n/" $BITCOIN_DATA/bitcoin.conf

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for bitcoind"

  set -- bitcoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "bitcoind" ]; then
  echo "$0: setting chain to $BITCOIN_CHAIN"

  set -- "$@" -chain=$BITCOIN_CHAIN
fi

echo
exec "$@"
