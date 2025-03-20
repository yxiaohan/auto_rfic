#!/bin/bash
# Script to launch Cadence Virtuoso 64-bit with custom log location

LOG_FILE="/home/zhoulong/projects/auto_rfic/cadence/virtuoso.log"

# TSMC PDK environment setup
export TSMC_PDK="/home/zhoulong/projects/TSMC/TSMC65gp_1p9m"
export PATH="$TSMC_PDK:$PATH"

export CCASE_CDS_VERBOSITY=3 # Set verbosity level for Cadence tools

# Set Cadence PDK environment variables
export CDS_INST_DIR="/opt/cadence/IC617"
export PDK_DIR="$TSMC_PDK"
export CDS_Netlisting_Mode="Analog"
export CDS_LOAD_ENV="$TSMC_PDK/cds.lib"  # Point to the TSMC PDK cds.lib file

echo "TSMC PDK environment configured: $TSMC_PDK"

# Create empty log file
> "$LOG_FILE"

# Launch Virtuoso with the PDK configuration and direct output to log file
/opt/cadence/IC617/tools/dfII/bin/virtuoso -64 -cdslib "$TSMC_PDK/cds.lib" -tech "$TSMC_PDK/tech.lib" -log "$LOG_FILE" &

# Save the Virtuoso process ID for potential later use
VIRTUOSO_PID=$!

# Set up a background process to trim the log file
# (
#   while ps -p $VIRTUOSO_PID > /dev/null; do
#     if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 100 ]; then
#       tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
#     fi
#     sleep 5
#   done
# ) &

# Print confirmation message
echo "Virtuoso launched in background (PID: $VIRTUOSO_PID)"
echo "Log file: $LOG_FILE (limited to last 100 lines)"