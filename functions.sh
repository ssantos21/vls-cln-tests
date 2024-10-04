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

# Function to check if the 'outputs' array from 'listfunds' is not empty
check_funds() {
    local container_name="$1"
    local max_time=120    # Maximum time to wait in seconds (2 minutes)
    local delay=5         # Delay between checks in seconds
    local start_time
    start_time=$(date +%s)

    while true; do
        # Run the command and capture the output
        local output
        output=$(docker container exec "$container_name" lightning-cli --regtest listfunds 2>/dev/null)

        # Check if the command was successful
        if [ $? -ne 0 ]; then
            echo "Failed to execute lightning-cli command in container '$container_name'."
            return 1
        fi

        # Check if 'outputs' array is not empty by searching for '"txid":'
        echo "$output" | grep '"txid":' >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            # Found a 'txid', so 'outputs' array is not empty
            echo "Funds are available in container '$container_name'."
            return 0
        else
            # No 'txid' found, 'outputs' array is still empty
            local current_time
            current_time=$(date +%s)
            local elapsed_time=$((current_time - start_time))

            if [ $elapsed_time -ge $max_time ]; then
                echo "No funds available in container '$container_name' after $max_time seconds."
                return 1
            else
                echo "Waiting for funds in container '$container_name'... ($elapsed_time/$max_time seconds elapsed)"
                sleep $delay
            fi
        fi
    done
}

# Function to check if all channels are in 'CHANNELD_NORMAL' state and have 'status' property
check_channels() {
    local container_name="$1"
    local max_time=120    # Maximum time to wait in seconds (2 minutes)
    local delay=5         # Delay between checks in seconds
    local start_time
    start_time=$(date +%s)

    while true; do
        # Run the command and capture the output
        local output
        output=$(docker container exec "$container_name" lightning-cli --regtest listpeerchannels 2>/dev/null)

        # Check if the command was successful
        if [ $? -ne 0 ]; then
            echo "Failed to execute lightning-cli command in container '$container_name'."
            return 1
        fi

        # Extract all 'state' values
        local states
        states=$(echo "$output" | grep '"state":' | awk -F'"' '{print $4}')

        # Extract all 'status' occurrences
        local status_count
        status_count=$(echo "$output" | grep -c '"status":')

        # Count the number of channels
        local channel_count
        channel_count=$(echo "$output" | grep -c '"state":')

        # Initialize a flag to check if all channels are in 'CHANNELD_NORMAL' state
        local all_normal=true

        # Check if 'states' is empty (no channels)
        if [ -z "$states" ]; then
            all_normal=false
        else
            for state in $states; do
                if [ "$state" != "CHANNELD_NORMAL" ]; then
                    all_normal=false
                    break
                fi
            done
        fi

        # Check if 'status' exists for each channel
        if [ "$status_count" -ne "$channel_count" ]; then
            all_normal=false
        fi

        if $all_normal; then
            echo "All channels are in 'CHANNELD_NORMAL' state and have 'status' property in container '$container_name'."
            return 0
        else
            local current_time
            current_time=$(date +%s)
            local elapsed_time=$((current_time - start_time))

            if [ $elapsed_time -ge $max_time ]; then
                echo "Channels did not reach 'CHANNELD_NORMAL' state in container '$container_name' after $max_time seconds."
                return 1
            else
                echo "Waiting for channels to reach 'CHANNELD_NORMAL' in container '$container_name'... ($elapsed_time/$max_time seconds elapsed)"
                sleep $delay
            fi
        fi
    done
}
