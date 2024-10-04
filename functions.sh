# Function to get the 'id' and 'binding.port' from a lightning node container
get_id_and_port() {
    local container_name="$1"

    # Execute the command and capture the output
    local output
    output=$(docker container exec "$container_name" lightning-cli --regtest getinfo)

    # Check if the command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to execute lightning-cli command in container '$container_name'."
        return 1
    fi

    # Extract the 'id' value
    local id
    id=$(echo "$output" | grep '"id":' | head -n1 | awk -F'"' '{print $4}')

    # Verify that the 'id' was extracted
    if [ -z "$id" ]; then
        echo "Failed to parse 'id' from the output of container '$container_name'."
        return 1
    fi

    # Extract the 'binding.port' value
    local port
    port=$(echo "$output" | awk '/"binding": \[/{flag=1; next} /\]/{flag=0} flag' \
           | grep '"port":' | awk -F': ' '{print $2}' | tr -d ', ')

    # Verify that the 'port' was extracted
    if [ -z "$port" ]; then
        echo "Failed to parse 'binding.port' from the output of container '$container_name'."
        return 1
    fi

    # Return the values by setting global variables or echoing them
    CONTAINER_ID="$id"
    CONTAINER_PORT="$port"

    # Echo the values
    # echo "$id $port"
}
