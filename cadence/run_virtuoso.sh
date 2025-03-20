#!/bin/bash
# Script to launch Cadence Virtuoso 64-bit with remote SKILL access

# Configure log and path settings
PROJECT_DIR="/home/zhoulong/projects/auto_rfic"
CADENCE_DIR="$PROJECT_DIR/cadence"
LOG_FILE="$CADENCE_DIR/virtuoso.log"
SKILL_PORT=9191

# TSMC PDK environment setup
export TSMC_PDK="/home/zhoulong/projects/TSMC/TSMC65gp_1p9m"
export PATH="$TSMC_PDK:$PATH"

export CCASE_CDS_VERBOSITY=3 # Set verbosity level for Cadence tools

# Set Cadence PDK environment variables
export CDS_INST_DIR="/opt/cadence/IC617"
export PDK_DIR="$TSMC_PDK"
export CDS_Netlisting_Mode="Analog"
export CDS_LOAD_ENV="$TSMC_PDK/cds.lib"  # Point to the TSMC PDK cds.lib file

# Set the environment variables for Virtuoso and SKILL server
export CDS_SITE="$CADENCE_DIR"
export SKILL_SERVER_PATH="$CADENCE_DIR/skill/example/rf_amp_sweep.il"
export SKILL_SERVER_PORT="$SKILL_PORT"

# Check if netcat is installed for checking the socket
if command -v nc >/dev/null 2>&1; then
  HAVE_NETCAT=true
else
  HAVE_NETCAT=false
  echo "Note: 'nc' (netcat) not found - socket testing will be limited"
fi

# Get the host IP address
HOST_IP=$(hostname -I | awk '{print $1}')

# Create empty log file
> "$LOG_FILE"

# Print startup information
echo "========================================================"
echo "Launching Cadence Virtuoso with Remote SKILL Access"
echo "========================================================"
echo "TSMC PDK environment: $TSMC_PDK"
echo "CDS_SITE: $CDS_SITE"
echo "SKILL server port: $SKILL_SERVER_PORT"
echo "Host IP: $HOST_IP"
echo "Log file: $LOG_FILE"
echo "========================================================"

# Launch Virtuoso with the PDK configuration
/opt/cadence/IC617/tools/dfII/bin/virtuoso -64 \
  -cdslib "$TSMC_PDK/cds.lib" \
  -tech "$TSMC_PDK/tech.lib" \
  -log "$LOG_FILE" &

# Save the Virtuoso process ID for potential later use
VIRTUOSO_PID=$!

# Wait a moment for Virtuoso to initialize
sleep 3

# Generate remote connection instructions
cat > "$CADENCE_DIR/remote_access.txt" << EOL
# Virtuoso Remote SKILL Access

Virtuoso is running with remote SKILL command access via socket server.

## Connection Information
- Host: ${HOST_IP}
- Port: ${SKILL_PORT}
- Virtuoso PID: ${VIRTUOSO_PID}

## Access Methods

1. Using netcat (nc):
   $ nc ${HOST_IP} ${SKILL_PORT}

2. Using SSH tunnel (more secure):
   $ ssh -L ${SKILL_PORT}:localhost:${SKILL_PORT} username@${HOST_IP}
   Then in a new terminal:
   $ nc localhost ${SKILL_PORT}

3. Using telnet:
   $ telnet ${HOST_IP} ${SKILL_PORT}

## Example SKILL Commands
- (testRemote) - Test remote connectivity
- (help) - Show available commands
- (getCurrentTime) - Get current time
- (rfSweepExample) - Run the RF amplifier parameter sweep example

## Monitoring Output
Tail the log file to see output:
$ tail -f ${LOG_FILE}
EOL

echo "Virtuoso launched successfully (PID: $VIRTUOSO_PID)"
echo "Remote SKILL access should be available at $HOST_IP:$SKILL_PORT"
echo "  (after Virtuoso fully initializes)"
echo "Connection instructions saved to: $CADENCE_DIR/remote_access.txt"

# Monitor the log file
echo "\nShowing log file content (Ctrl+C to exit):\n"
tail -f "$LOG_FILE"