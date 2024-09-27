#!/bin/sh

set -ex

# Get the latest file with extension .sa from /root/.txoo/$BITCOIN_NETWORK/public directory and get the block number from the file name
TXOO_LOCATION=/root/.txoo/$BITCOIN_NETWORK/public
latest_block=$(ls -r1 $TXOO_LOCATION | grep '.sa' | head -n1 | cut -d'-' -f1)

# Check if no file was found
if [ -z "$latest_block" ]; then
  echo "No file found" >&2
  exit 1
fi

# Convert latest_block to a number
latest_block=$(expr $latest_block + 0)

# Get the block count from bitcoind
bitcoind_block_count=$(curl --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockcount", "params": [] }' -H 'content-type: text/plain;' $BITCOIND_RPC_URL | jq .result)

blocks_behind=$((bitcoind_block_count - latest_block))

# Check if the latest attestation is more than 1 block behind
if [[ $blocks_behind -gt 1 ]]; then
  echo "The latest attestation is more than 1 block behind" >&2
  exit 1
fi
