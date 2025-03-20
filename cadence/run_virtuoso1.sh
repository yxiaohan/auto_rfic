#!/bin/bash
# Script to launch Cadence Virtuoso 64-bit with remote access to Command Interface Window (CIW)

# Configure paths and files
BASE_DIR="/home/zhoulong/projects/auto_rfic/cadence"
LOG_FILE="$BASE_DIR/virtuoso.log"
FIFO_FILE="$BASE_DIR/virtuoso_ciw_fifo"
SOCKET_PORT=9876
SSH_PORT=22

# TSMC PDK environment setup
export TSMC_PDK="/home/zhoulong/projects/TSMC/TSMC65gp_1p9m"
export PATH="$TSMC_PDK:$PATH"

export CCASE_CDS_VERBOSITY=3 # Set verbosity level for Cadence tools

# Set Cadence PDK environment variables
export CDS_INST_DIR="/opt/cadence/IC617"
export PDK_DIR="$TSMC_PDK"
export CDS_Netlisting_Mode="Analog"
export CDS_LOAD_ENV="$TSMC_PDK/cds.lib"  # Point to the TSMC PDK cds.lib file

# Check if netcat is installed
if ! command -v nc &> /dev/null; then
    echo "Error: netcat (nc) is not installed. Please install it first."
    exit 1
fi

# Ensure the base directory exists
mkdir -p "$BASE_DIR"

# Create empty log file
> "$LOG_FILE"

# Create named pipe for CIW output if it doesn't exist
if [ ! -p "$FIFO_FILE" ]; then
    rm -f "$FIFO_FILE"  # Remove if it exists but is not a pipe
    mkfifo "$FIFO_FILE"
fi

echo "TSMC PDK environment configured: $TSMC_PDK"
echo "Starting Virtuoso with remote CIW access..."

# Launch Virtuoso with customized environment and redirect output to the FIFO
{
    /opt/cadence/IC617/tools/dfII/bin/virtuoso -64 \
        -cdslib "$TSMC_PDK/cds.lib" \
        -tech "$TSMC_PDK/tech.lib" \
        -replay "$BASE_DIR/skill/init.il" 2>&1 | tee "$LOG_FILE"
} > "$FIFO_FILE" &

# Save the Virtuoso process ID for later use
VIRTUOSO_PID=$!

# Set up netcat to serve the CIW output over the network
{
    # Start netcat in listen mode, serving content from the FIFO
    while true; do
        nc -l "$SOCKET_PORT" < "$FIFO_FILE"
        echo "Client disconnected. Waiting for new connection..."
        sleep 1
    done
} &

NC_PID=$!

# Get the host IP address (choose the appropriate network interface)
HOST_IP=$(hostname -I | awk '{print $1}')

# Create a readable file with connection instructions
cat > "$BASE_DIR/remote_access_info.txt" << EOL
# Virtuoso Remote CIW Access

Virtuoso is running with remote Command Interface Window (CIW) access.

## Connection Information
- Host: ${HOST_IP}
- Port: ${SOCKET_PORT}
- PID: ${VIRTUOSO_PID}

## Access Methods

1. Using netcat (nc):
   $ nc ${HOST_IP} ${SOCKET_PORT}

2. Using SSH tunnel (more secure):
   $ ssh -L ${SOCKET_PORT}:localhost:${SOCKET_PORT} username@${HOST_IP}
   Then in a new terminal:
   $ nc localhost ${SOCKET_PORT}

3. Using telnet:
   $ telnet ${HOST_IP} ${SOCKET_PORT}

## Sending SKILL Commands
You can pipe SKILL commands to the connection:
   $ echo '(println "Hello from remote SKILL")' | nc ${HOST_IP} ${SOCKET_PORT}

## Stopping the Remote Access
To stop the remote access server without terminating Virtuoso:
   $ kill ${NC_PID}
EOL

# Set up a cleanup function that runs on script termination
cleanup() {
    echo "Cleaning up resources..."
    # Kill the netcat server if it's still running
    kill $NC_PID 2>/dev/null || true
    # Remove the FIFO
    rm -f "$FIFO_FILE"
    echo "Cleanup complete."
}

# Register the cleanup function to run on exit
trap cleanup EXIT

# Print confirmation message
echo "Virtuoso launched in background (PID: $VIRTUOSO_PID)"
echo "Log file: $LOG_FILE"
echo "Remote CIW access available at: $HOST_IP:$SOCKET_PORT"
echo "Connection instructions saved to: $BASE_DIR/remote_access_info.txt"
echo ""
echo "To connect from a remote machine:"
echo "  $ nc $HOST_IP $SOCKET_PORT"
echo ""
echo "Press Ctrl+C to terminate this script and clean up resources."

# Keep the script running to maintain the netcat server
# (the trap will handle cleanup when the script is terminated)
while ps -p $VIRTUOSO_PID > /dev/null; do
    sleep 5
done

echo "Virtuoso process has terminated."