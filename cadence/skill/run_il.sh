#!/bin/bash

# run_il.sh - Client script to send SKILL files to the remote server
# Usage: run_il.sh file_to_execute.il [server_host] [server_port]

# Default configuration
SERVER_HOST="localhost"
SERVER_PORT=8765
TIMEOUT=30

# Help function
show_help() {
    echo "Usage: $0 file_to_execute.il [server_host] [server_port]"
    echo ""
    echo "Arguments:"
    echo "  file_to_execute.il   Path to the SKILL script to execute"
    echo "  server_host          Server hostname or IP (default: localhost)"
    echo "  server_port          Server port (default: 8765)"
    echo ""
    echo "Example:"
    echo "  $0 my_script.il"
    echo "  $0 my_script.il remote-server.example.com"
    echo "  $0 my_script.il remote-server.example.com 9000"
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
[ ! -z "$3" ] && SERVER_PORT="$3"

# Function to send the script and receive response
send_script() {
    local script_file="$1"
    local server_host="$2"
    local server_port="$3"
    
    echo "Sending $script_file to $server_host:$server_port..."
    
    # Send script content with end marker
    {
        cat "$script_file"
        echo "__END_OF_SCRIPT__"
    } | nc -w "$TIMEOUT" "$server_host" "$server_port" > /tmp/skill_response.txt
    
    # Check if connection was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to connect to $server_host:$server_port"
        exit 2
    fi
    
    # Check if we got a response
    if [ ! -s /tmp/skill_response.txt ]; then
        echo "Error: No response received from server"
        exit 3
    fi
    
    # Display response (without end marker)
    sed 's/__END_OF_RESPONSE__//g' /tmp/skill_response.txt
    
    # Clean up
    rm -f /tmp/skill_response.txt
}

# Main execution
send_script "$SCRIPT_FILE" "$SERVER_HOST" "$SERVER_PORT"
