#!/bin/sh

# verify SHA256SUMS
gpg --batch --verify SHA256SUMS.asc SHA256SUMS
ret_val=$?

# allow 2 as well in case of untrusted keys
if [ $ret_val -eq 0 ] || [ $ret_val -eq 2 ]; then
  exit 0
else
  exit $ret_val
fi