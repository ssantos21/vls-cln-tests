#!/bin/sh

set -ex

lightning-cli --network $VLS_NETWORK getinfo
