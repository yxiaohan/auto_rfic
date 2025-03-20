#!/bin/bash
# check_server.sh - Check and monitor the skillServer status
# Usage: ./check_server.sh [host] [port]

HOST=${1:-"home.ling60.com"}
PORT=${2:-"8123"}
DEBUG=true

echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking skillServer at $HOST:$PORT"

# Function to check if port is open
check_port() {
    local host=$1
    local port=$2
    local timeout=${3:-5}
    
    if nc -z -w"$timeout" "$host" "$port" 2>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: Port $port is open on $host"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILURE: Port $port is closed on $host"
        return 1
    fi
}

# Function to check route to host
check_route() {
    local host=$1
    local count=${2:-5}
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking network route to $host..."
    traceroute -m 15 "$host" 2>&1
}

# Function to check DNS resolution
check_dns() {
    local host=$1
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Resolving DNS for $host..."
    dig +short "$host" || nslookup "$host" || host "$host"
}

# Check local network interfaces
echo "$(date '+%Y-%m-%d %H:%M:%S') - Local network interfaces:"
ifconfig || ip addr

# Check DNS resolution
check_dns "$HOST"

# Check route to host
check_route "$HOST"

# Check if port is open
if check_port "$HOST" "$PORT"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Testing basic communication with server..."
    
    # Create a test command
    TEST_FILE=$(mktemp)
    cat > "$TEST_FILE" << EOT
printf("SKILL server test connection successful at %s\\n" getCurrentTime())
EOT
    
    # Send test command to server
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Sending test command to server..."
    (cat "$TEST_FILE"; echo "__END_OF_COMMAND__") | nc -v -w 10 "$HOST" "$PORT" 2>&1
    
    # Clean up
    rm -f "$TEST_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cannot test communication with server because port is closed."
    
    # Check if server process might be running locally
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking for local skillServer process:"
    ps aux | grep skillServer | grep -v grep
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking for processes listening on port $PORT:"
    lsof -i :"$PORT" || netstat -tuln | grep :"$PORT" || ss -tuln | grep :"$PORT"
fi

# Check the log file
LOG_PATHS=(
    "/Volumes/990_2t/yuan/Nextcloud/projects/auto_rfic/cadence/logs/skillServer.log"
    "./skillServer.log"
)

for LOG_PATH in "${LOG_PATHS[@]}"; do
    if [ -f "$LOG_PATH" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Found log file at $LOG_PATH"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Last 20 lines of log:"
        tail -n 20 "$LOG_PATH"
        break
    fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S') - Server check completed"