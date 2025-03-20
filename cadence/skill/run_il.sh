#!/bin/bash

# run_il.sh - Script to send SKILL files to the remote server
# Usage: run_il.sh file_to_execute.il [server_host] [server_port]

# Default configuration
SERVER_HOST="localhost"
SERVER_PORT=8123
TIMEOUT=30

# Help function
show_help() {
    echo "Usage: $0 file_to_execute.il [server_host] [server_port]"
    echo ""
    echo "Arguments:"
    echo "  file_to_execute.il   Path to the SKILL script to execute"
    echo "  server_host          Server hostname or IP (default: localhost)"
    echo "  server_port          Server port (default: 8123)"
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

# Check if the client exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_SCRIPT="$SCRIPT_DIR/skillClient"

if [ ! -f "$CLIENT_SCRIPT" ]; then
    echo "Error: skillClient script not found at $CLIENT_SCRIPT"
    exit 1
fi

# Make sure the client script is executable
if [ ! -x "$CLIENT_SCRIPT" ]; then
    chmod +x "$CLIENT_SCRIPT"
fi

# Function to load and execute a script
echo "Executing SKILL file: $SCRIPT_FILE on server $SERVER_HOST:$SERVER_PORT"
$CLIENT_SCRIPT "$SERVER_HOST" "$SERVER_PORT" -file "$SCRIPT_FILE"
