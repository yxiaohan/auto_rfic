#!/bin/bash

# Script to test network connectivity to the SKILL server
SERVER_HOST="home.ling60.com"
SERVER_PORT=8123

echo "==== SKILL Server Network Connectivity Test ===="

# 1. Basic ping test
echo "Testing basic connectivity with ping..."
ping -c 3 "$SERVER_HOST"
PING_RESULT=$?

if [ $PING_RESULT -eq 0 ]; then
  echo "✓ Ping test successful"
else
  echo "✗ Ping test failed - check if host is reachable"
fi

# 2. Port check
echo -e "\nTesting port connectivity..."
if command -v nc >/dev/null 2>&1; then
  # Use netcat for port testing with 5-second timeout
  nc -z -w5 "$SERVER_HOST" "$SERVER_PORT"
  NC_RESULT=$?
  
  if [ $NC_RESULT -eq 0 ]; then
    echo "✓ Port $SERVER_PORT is open on $SERVER_HOST"
  else
    echo "✗ Port $SERVER_PORT is not accessible on $SERVER_HOST"
    echo "  - Check if the server is running"
    echo "  - Check if any firewall is blocking the connection"
  fi
else
  echo "✗ netcat (nc) not found, skipping port test"
fi

# 3. Send a simple test command
echo -e "\nTesting command execution..."
echo "echo \"Hello from SKILL Server\"" | nc -w 5 "$SERVER_HOST" "$SERVER_PORT"
NC_CMD_RESULT=$?

if [ $NC_CMD_RESULT -eq 0 ]; then
  echo "✓ Command sent successfully (check response above)"
else
  echo "✗ Failed to send command"
fi

echo -e "\nTest completed. If issues persist:"
echo "1. Verify the server is running with 'ps aux | grep skillServer'"
echo "2. Check server logs for errors"
echo "3. Ensure the server is configured to listen on all interfaces"
echo "4. Check firewall settings on both client and server"
