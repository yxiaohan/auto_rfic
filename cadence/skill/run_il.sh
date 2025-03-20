#!/bin/bash

# run_il.sh - Script to send SKILL files to the remote server
# Usage: run_il.sh file_to_execute.il [server_host] [server_port]

# Default configuration
SERVER_HOST="home.ling60.com"
SERVER_PORT=8123
TIMEOUT=30
DEBUG=true  # Set to true for verbose output

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

# Get absolute path of the script file
SCRIPT_FILE=$(readlink -f "$1")
[ ! -z "$2" ] && SERVER_HOST="$2"
[ ! -z "$3" ] && SERVER_PORT="$3"

# Get current directory for reference
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_SCRIPT="$SCRIPT_DIR/skillClient"

if [ ! -f "$CLIENT_SCRIPT" ]; then
    echo "Warning: skillClient script not found at $CLIENT_SCRIPT"
    echo "Creating a simple client implementation..."
    
    # Create a simple client using netcat
    cat > "$CLIENT_SCRIPT" << 'EOF'
#!/bin/bash
# Simple SKILL client implementation using netcat
HOST="$1"
PORT="$2"
OPTION="$3"
FILE="$4"

if [ "$OPTION" != "-file" ]; then
    echo "Error: Only -file option is supported"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "Connecting to $HOST:$PORT..."
echo "Sending file: $FILE"

# Print the file content for debugging
if [ "$DEBUG" = true ]; then
    echo "File content:"
    cat "$FILE"
    echo "---"
fi

# Send the file content to the server and capture response
cat "$FILE" | nc -w 10 "$HOST" "$PORT"

# Check the exit status of netcat
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to SKILL server at $HOST:$PORT"
    exit 1
fi

echo "Command sent successfully."
EOF
    
    chmod +x "$CLIENT_SCRIPT"
    echo "Simple client created."
fi

# Make sure the client script is executable
if [ ! -x "$CLIENT_SCRIPT" ]; then
    chmod +x "$CLIENT_SCRIPT"
fi

# Check if netcat is available
if ! command -v nc &> /dev/null; then
    echo "Error: netcat (nc) is required but not installed."
    echo "Please install netcat: sudo apt-get install netcat"
    exit 1
fi

# Function to check if the server is responsive
check_server() {
    # Using netcat to check if the port is open, with a 2-second timeout
    if nc -z -w2 "$SERVER_HOST" "$SERVER_PORT"; then
        echo "Server is responsive at $SERVER_HOST:$SERVER_PORT"
        return 0
    else
        echo "Warning: Server does not appear to be responding at $SERVER_HOST:$SERVER_PORT"
        return 1
    fi
}

# Check server before attempting to send commands
check_server

# Execute the script
echo "Executing SKILL file: $SCRIPT_FILE on server $SERVER_HOST:$SERVER_PORT"

# Create a temporary file with the script content using absolute path
TMP_FILE=$(mktemp)
cat > "$TMP_FILE" << EOF
;; Begin execution wrapper
printf("===== Beginning execution of $(basename "$SCRIPT_FILE") =====\\n");

;; Set current directory to match the script location
setShellEnvVar("SKILLDIR" "$(dirname "$SCRIPT_FILE")");
printf("Setting working directory: %s\\n" getShellEnvVar("SKILLDIR"));

;; Try different methods to load the script (absolute path + relative)
if(isFile("$SCRIPT_FILE") then
    printf("Loading script from absolute path: $SCRIPT_FILE\\n");
    load("$SCRIPT_FILE");
else
    relPath = "$(basename "$SCRIPT_FILE")";
    printf("Trying relative path: %s\\n" relPath);
    load(relPath);
);

printf("===== Completed execution of $(basename "$SCRIPT_FILE") =====\\n");
EOF

if [ "$DEBUG" = true ]; then
    echo "Debug: Sending the following SKILL commands:"
    cat "$TMP_FILE"
    echo "---"
fi

# Use longer timeout to wait for response
$CLIENT_SCRIPT "$SERVER_HOST" "$SERVER_PORT" -file "$TMP_FILE"
EXIT_CODE=$?

# Clean up temp file
rm -f "$TMP_FILE"

exit $EXIT_CODE
