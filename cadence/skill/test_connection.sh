#!/bin/bash
# test_connection.sh - Test connection to skillServer
# Usage: ./test_connection.sh [host] [port]

HOST=${1:-"home.ling60.com"}
PORT=${2:-"8123"}

echo "$(date '+%Y-%m-%d %H:%M:%S') - Testing connection to skillServer at $HOST:$PORT"

# Create a temporary file with a simple diagnostic command
TMP_FILE=$(mktemp)
cat > "$TMP_FILE" << EOF
printf("Connection test from %s at %s\\n" getCurrentUser() getCurrentTime())
abSkillServerDebug = t  ;; Ensure debug is enabled
EOF

# Echo end of command marker
echo "__END_OF_COMMAND__" >> "$TMP_FILE"

# Show command being sent
echo "Sending test command:"
cat "$TMP_FILE"
echo "---"

# Attempt the connection with verbose output and extended timeout
echo "$(date '+%Y-%m-%d %H:%M:%S') - Connecting to $HOST:$PORT..."
cat "$TMP_FILE" | nc -v -w 10 "$HOST" "$PORT" 2>&1

# Store exit code
EXIT_CODE=$?
echo "$(date '+%Y-%m-%d %H:%M:%S') - Connection test exit code: $EXIT_CODE"

# Clean up
rm -f "$TMP_FILE"

# Check for server log file
LOG_FILE="/Volumes/990_2t/yuan/Nextcloud/projects/auto_rfic/cadence/logs/skillServer.log"
if [ -f "$LOG_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking recent server logs:"
    echo "Last 10 lines from $LOG_FILE:"
    tail -n 10 "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Warning: Log file not found at $LOG_FILE"
    
    # Try to find log file in current directory
    if [ -f "./skillServer.log" ]; then
        echo "Found log file in current directory:"
        tail -n 10 "./skillServer.log"
    fi
fi

# Display a reminder about the Cadence end
echo ""
echo "REMINDER: Make sure skillServer is properly loaded in Cadence with:"
echo "  - load(\"skillServer.il\")"
echo "  - startSkillServer(\"8123\")"
echo ""