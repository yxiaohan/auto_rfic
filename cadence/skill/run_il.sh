#!/bin/bash

# run_il.sh - Client script to send SKILL files to the remote server
# Usage: run_il.sh file_to_execute.il [server_host]

# Default configuration
SERVER_HOST="localhost"
REMOTE_INBOX="/tmp/skill_inbox"
REMOTE_OUTBOX="/tmp/skill_outbox"
TIMEOUT=30

# Help function
show_help() {
    echo "Usage: $0 file_to_execute.il [server_host]"
    echo ""
    echo "Arguments:"
    echo "  file_to_execute.il   Path to the SKILL script to execute"
    echo "  server_host          Server hostname or IP (default: localhost)"
    echo ""
    echo "Example:"
    echo "  $0 my_script.il"
    echo "  $0 my_script.il remote-server.example.com"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check for required arguments
if [ -z "$1" ]; then
    echo "Error: No script file specified"
    show_help
    exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
    echo "Error: Script file '$1' not found"
    exit 1
fi

# Assign arguments
SCRIPT_FILE="$1"
[ ! -z "$2" ] && SERVER_HOST="$2"

# Get the base filename
FILENAME=$(basename "$SCRIPT_FILE")
UNIQUE_ID=$(date +%s)_$(echo $RANDOM | md5sum | head -c 8)
REMOTE_FILENAME="${UNIQUE_ID}_${FILENAME}"

# Function to send the script and receive response
send_script() {
    local script_file="$1"
    local server_host="$2"
    local remote_filename="$3"
    
    echo "Sending $script_file to $server_host:$REMOTE_INBOX..."
    
    # Create lock file to prevent processing during upload
    ssh "$server_host" "touch $REMOTE_INBOX/$remote_filename.lock"
    
    # Copy script to remote inbox
    scp "$script_file" "$server_host:$REMOTE_INBOX/$remote_filename"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy script to server"
        ssh "$server_host" "rm -f $REMOTE_INBOX/$remote_filename.lock"
        exit 2
    fi
    
    # Remove lock file to allow processing
    ssh "$server_host" "rm -f $REMOTE_INBOX/$remote_filename.lock"
    
    # Wait for output file
    echo "Waiting for script execution to complete..."
    OUTPUT_FILE="$REMOTE_OUTBOX/$remote_filename.out"
    
    # Wait for the output file to appear with timeout
    for i in $(seq 1 $TIMEOUT); do
        if ssh "$server_host" "test -f $OUTPUT_FILE"; then
            break
        fi
        sleep 1
        if [ $i -eq $TIMEOUT ]; then
            echo "Error: Timeout waiting for script execution"
            exit 3
        fi
    done
    
    # Display output
    echo "Script execution completed. Output:"
    echo "----------------------------------------"
    ssh "$server_host" "cat $OUTPUT_FILE"
    echo "----------------------------------------"
    
    # Clean up
    ssh "$server_host" "rm -f $OUTPUT_FILE"
}

# Main execution
send_script "$SCRIPT_FILE" "$SERVER_HOST" "$REMOTE_FILENAME"
