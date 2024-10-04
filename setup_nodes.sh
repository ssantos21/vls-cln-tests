#!/bin/bash

# Source the functions file
source functions.sh

# Execute the command and store the output in a variable
bitcoind_address=$(docker container exec bitcoind-regtest bitcoin-cli getnewaddress)

docker container exec bitcoind-regtest bitcoin-cli generatetoaddress 1850 $bitcoind_address

# Execute the command and store the output
output=$(docker container exec lightningd-regtest lightning-cli --regtest newaddr)

echo $output

# Extract the bech32 address from the output using sed
cln_address=$(echo "$output" | sed -n 's/.*"bech32": "\(.*\)".*/\1/p')

echo "cln_address: $cln_address"

# Display the address
# echo "The new bech32 address is: $address"

docker container exec bitcoind-regtest bitcoin-cli -named sendtoaddress address=$cln_address amount=150.0 fee_rate=1

output=$(docker container exec alice lightning-cli --regtest newaddr)

alice_address=$(echo "$output" | sed -n 's/.*"bech32": "\(.*\)".*/\1/p')

docker container exec bitcoind-regtest bitcoin-cli -named sendtoaddress address=$alice_address amount=150.0 fee_rate=1

docker container exec bitcoind-regtest bitcoin-cli listtransactions

# echo "The new alice address is: $alice_address"

output=$(docker container exec bob lightning-cli --regtest newaddr)

bob_address=$(echo "$output" | sed -n 's/.*"bech32": "\(.*\)".*/\1/p')

docker container exec bitcoind-regtest bitcoin-cli -named sendtoaddress address=$bob_address amount=150.0 fee_rate=1

# echo "The new bob address is: $bob_address"

### Confirm blocks

docker container exec bitcoind-regtest bitcoin-cli generatetoaddress 10 $bitcoind_address

# Containers to check
containers=("lightningd-regtest" "alice" "bob")

for container in "${containers[@]}"; do
    echo "Checking funds for container '$container'..."
    
    # Call the check_funds function
    check_funds "$container"
    
    # Check if the function succeeded
    if [ $? -eq 0 ]; then
        echo "Funds are available in container '$container'."
    else
        echo "Failed to detect funds in container '$container'. Aborting."
        exit 1
    fi
done

### Get all IP addresses, IDs and ports

alice_ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' alice)

bob_ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' bob)

cln_ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lightningd-regtest)

# echo "The alice address IP is: $alice_ip_address"

# echo "The bob address IP is: $bob_ip_address"

# echo "The CLN address IP is: $cln_ip_address"

get_id_and_port alice

alice_id=$CONTAINER_ID

alice_port=$CONTAINER_PORT

get_id_and_port bob

bob_id=$CONTAINER_ID

bob_port=$CONTAINER_PORT

get_id_and_port lightningd-regtest

cln_id=$CONTAINER_ID

cln_port=$CONTAINER_PORT

# echo "The alice id is: $alice_id and the port is: $alice_port"

# echo "The bob id is: $bob_id and the port is: $bob_port"

# echo "The CLN id is: $cln_id and the port is: $cln_port"

### CLN node connects to Alice

docker container exec lightningd-regtest lightning-cli --regtest connect $alice_id $alice_ip_address:$alice_port

### Alice connects to Bob

docker container exec alice lightning-cli --regtest connect $bob_id $bob_ip_address:$bob_port

### Bob connects to VLS CLN node

docker container exec bob lightning-cli --regtest connect $cln_id $cln_ip_address:$cln_port

docker container exec lightningd-regtest lightning-cli --regtest listfunds

### CLN funds a channel with Alice

docker container exec lightningd-regtest lightning-cli --regtest fundchannel -k "id"="$alice_id" "amount"=500016530

### Alice funds a channel with Bob

docker container exec alice lightning-cli --regtest fundchannel -k "id"="$bob_id" "amount"=500016530

### Bob funds a channel with CLN node

docker container exec bob lightning-cli --regtest fundchannel -k "id"="$cln_id" "amount"=500016530

### Confirm blocks
docker container exec bitcoind-regtest bitcoin-cli generatetoaddress 12 $bitcoind_address

# VLS node checks channels

echo "VLS node checks channels"

# Containers to check
containers=("lightningd-regtest" "alice" "bob")

for container in "${containers[@]}"; do
    echo "Checking channels for container '$container'..."
    
    # Call the check_funds function
    check_channels "$container"
    
    # Check if the function succeeded
    if [ $? -eq 0 ]; then
        echo "All channels are ready in container '$container'. Proceeding with tests..."
    else
        echo "Channels are not ready in container '$container'. Aborting."
        exit 1
    fi
done

### Bob creates invoice and VLS node pays it

# Execute the command and capture the output
output=$(docker container exec bob lightning-cli --regtest invoice 1000000 "first" "VLS node pays bob")

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Failed to execute lightning-cli command."
    exit 1
fi

# Extract the 'bolt11' value using sed
bob_invoice=$(echo "$output" | sed -n 's/.*"bolt11": "\(.*\)",*/\1/p')

container_name="lightningd-regtest"

# Call the pay_invoice_and_wait function
pay_invoice_and_wait "$container_name" "$bob_invoice"

# Check if the function succeeded
if [ $? -eq 0 ]; then
    echo "Payment is complete in container '$container_name'. Proceeding with tests..."
else
    echo "Payment did not complete in container '$container_name'. Aborting."
    exit 1
fi

### Alice creates invoice and Bob pays it

# Execute the command and capture the output
output=$(docker container exec alice lightning-cli --regtest invoice 1000000 "first" "Bob pays alice")

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Failed to execute lightning-cli command."
    exit 1
fi

# Extract the 'bolt11' value using sed
alice_invoice=$(echo "$output" | sed -n 's/.*"bolt11": "\(.*\)",*/\1/p')

container_name="bob"

# Call the pay_invoice_and_wait function
pay_invoice_and_wait "$container_name" "$alice_invoice"

# Check if the function succeeded
if [ $? -eq 0 ]; then
    echo "Payment is complete in container '$container_name'. Proceeding with tests..."
else
    echo "Payment did not complete in container '$container_name'. Aborting."
    exit 1
fi
