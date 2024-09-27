#!/bin/sh

set -ex

if [[ "$BITCOIN_CHAIN" = "regtest" ]]; then
  # Check if default wallet isn't loaded
  if ! bitcoin-cli listwallets | grep -q "default"; then
    # Check if default wallet is present and needs to be loaded
    if bitcoin-cli listwalletdir | grep -q "default"; then
      bitcoin-cli loadwallet default
    else
      # create default wallet since no file was found
      bitcoin-cli createwallet default
    fi
  fi

  block_count=$(bitcoin-cli -chain=$BITCOIN_CHAIN getblockcount)
  if [[ "$block_count" = "0" ]]; then
    bitcoin-cli generatetoaddress 101 $(bitcoin-cli -chain=$BITCOIN_CHAIN getnewaddress)
  fi
fi

bitcoin-cli -chain=$BITCOIN_CHAIN getblockchaininfo
