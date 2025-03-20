#!/bin/bash
# check_server_logs.sh - Comprehensive diagnostic tool for skillServer
# Usage: ./check_server_logs.sh [host] [port]

# Configuration
HOST=${1:-"home.ling60.com"}
PORT=${2:-"8123"}
LOGS_DIR="/home/zhoulong/projects/auto_rfic/cadence/logs"
CADENCE_LOGS_DIR="."  # Current directory where Cadence might be running

echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking skillServer logs and communication"
echo "=================================================================="

# Check connection to server
echo "1. Testing network connectivity to $HOST:$PORT"
if nc -z -w3 "$HOST" "$PORT"; then
    echo "✅ Connection successful to $HOST:$PORT"
else
    echo "❌ Cannot connect to $HOST:$PORT"
    echo "   Please check if skillServer is running on the target machine."
fi
echo ""

# Check skillServer logs
echo "2. Checking skillServer logs"
SERVER_LOG="$LOGS_DIR/skillServer.log"
if [ -f "$SERVER_LOG" ]; then
    echo "✅ Found log file: $SERVER_LOG"
    echo "   Last 5 log entries:"
    tail -n 5 "$SERVER_LOG"
else
    echo "❌ skillServer log file not found at $SERVER_LOG"
    echo "   Searching for logs in current directory..."
    
    if [ -f "./skillServer.log" ]; then
        echo "✅ Found log in current directory"
        echo "   Last 5 log entries:"
        tail -n 5 "./skillServer.log"
    else
        echo "❌ No skillServer logs found"
    fi
fi
echo ""

# Check Cadence SKILL-side logs
echo "3. Checking for Cadence-side SKILL server logs"
echo "   Looking for logs in SKILL environment..."
SKILL_LOGS=(
    "skillServer_connections.log"
    "skillServer_commands.log"
    "skillServer_startup.log"
    "skillServer_results.log"
    "skillServer_errors.log"
)

FOUND_LOGS=0
for LOG in "${SKILL_LOGS[@]}"; do
    if [ -f "$CADENCE_LOGS_DIR/$LOG" ]; then
        echo "✅ Found SKILL log: $CADENCE_LOGS_DIR/$LOG"
        echo "   Last 5 entries:"
        tail -n 5 "$CADENCE_LOGS_DIR/$LOG"
        echo ""
        FOUND_LOGS=1
    fi
done

if [ $FOUND_LOGS -eq 0 ]; then
    echo "❌ No Cadence SKILL logs found. This suggests:"
    echo "   1. skillServer.il is not loaded in Cadence"
    echo "   2. startSkillServer() was not called"
    echo "   3. Log files are being written to a different directory"
fi
echo ""

# Socket diagnostic
echo "4. Full connection diagnostic"
echo "   Creating test command for advanced diagnosis..."

# Create a test command with special markers
TEST_FILE=$(mktemp)
cat > "$TEST_FILE" << EOF
;; ==== TEST COMMAND START ====
printf("TEST_COMMAND_MARKER: Connection test at %s\\n" getCurrentTime())
;; Command ID: $(date +%s%N | md5sum | head -c 10)
;; Insert special character sequence for tracking: ###TRACK_ME_$(date +%s)###
abSkillServerDebug = t
printf("TEST_COMMAND_MARKER: End of test command\\n")
;; ==== TEST COMMAND END ====
EOF

echo "__END_OF_COMMAND__" >> "$TEST_FILE"

# Show test command
echo "   Sending test command with unique markers for tracking:"
cat "$TEST_FILE" | grep -v "__END_OF_COMMAND__"
echo "   (End marker added)"
echo ""

# Send the test command
echo "   Attempting connection with verbose output..."
(cat "$TEST_FILE"; echo "__END_OF_COMMAND__") | nc -v -w 5 "$HOST" "$PORT" 2>&1
RESULT=$?

echo "   Connection test exit code: $RESULT"
echo ""

# Check if the test command appears in logs
echo "5. Checking for test command in logs (may require a few seconds)"
sleep 2  # Give time for logs to be written

# Search for the marker in all possible log files
echo "   Searching for test command marker in logs..."
MARKER_FOUND=0

# Search in skillServer.log
if [ -f "$SERVER_LOG" ]; then
    if grep -q "TEST_COMMAND_MARKER" "$SERVER_LOG"; then
        echo "✅ Test command found in skillServer.log"
        grep -A 2 "TEST_COMMAND_MARKER" "$SERVER_LOG" | tail -n 3
        MARKER_FOUND=1
    fi
fi

# Search in Cadence SKILL logs
for LOG in "${SKILL_LOGS[@]}"; do
    if [ -f "$CADENCE_LOGS_DIR/$LOG" ]; then
        if grep -q "TEST_COMMAND_MARKER" "$CADENCE_LOGS_DIR/$LOG"; then
            echo "✅ Test command found in $LOG"
            grep -A 2 "TEST_COMMAND_MARKER" "$CADENCE_LOGS_DIR/$LOG" | tail -n 3
            MARKER_FOUND=1
        fi
    fi
done

if [ $MARKER_FOUND -eq 0 ]; then
    echo "❌ Test command not found in any logs. This indicates:"
    echo "   1. Command never reached Cadence SKILL environment"
    echo "   2. Logs are being written to a location we didn't check"
    echo "   3. There may be a problem with the skillServer.il code"
fi
echo ""

# Process details
echo "6. Checking for skillServer process"
echo "   Local skillServer processes:"
ps aux | grep skillServer | grep -v grep

echo ""
echo "   Remote skillServer processes (if possible):"
if command -v ssh &> /dev/null && [ "$HOST" != "localhost" ] && [ "$HOST" != "127.0.0.1" ]; then
    if ssh -o ConnectTimeout=5 "$HOST" "ps aux | grep skillServer | grep -v grep" 2>/dev/null; then
        echo "✅ Found skillServer process on remote host"
    else
        echo "❌ Could not find or check skillServer process on remote host"
    fi
else
    echo "   (Cannot check remote processes - SSH not available or localhost)"
fi
echo ""

# Summary
echo "=================================================================="
echo "DIAGNOSTIC SUMMARY:"

if [ $RESULT -eq 0 ]; then
    echo "✅ Network connection: Connection to $HOST:$PORT SUCCESSFUL"
else
    echo "❌ Network connection: FAILED to connect to $HOST:$PORT"
fi

if [ -f "$SERVER_LOG" ] || [ -f "./skillServer.log" ]; then
    echo "✅ Server logs: FOUND"
else
    echo "❌ Server logs: NOT FOUND"
fi

if [ $FOUND_LOGS -eq 1 ]; then
    echo "✅ SKILL-side logs: FOUND"
else
    echo "❌ SKILL-side logs: NOT FOUND"
fi

if [ $MARKER_FOUND -eq 1 ]; then
    echo "✅ Test command tracing: SUCCESSFUL"
else
    echo "❌ Test command tracing: FAILED"
fi

echo ""
echo "TROUBLESHOOTING RECOMMENDATIONS:"
echo "1. Ensure skillServer.il is loaded in Cadence SKILL environment"
echo "2. Run the following commands in Cadence SKILL console:"
echo "   load(\"skillServer.il\")"
echo "   restartSkillServer(\"$PORT\")"
echo "   checkSkillServerStatus()"
echo "3. Look for any error messages in the Cadence console"
echo "4. Verify that the skillServer tcl script is running with:"
echo "   ps aux | grep skillServer"
echo "=================================================================="

# Clean up
rm -f "$TEST_FILE"
