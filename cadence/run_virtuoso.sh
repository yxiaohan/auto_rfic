#!/bin/bash
# Script to launch Cadence Virtuoso 64-bit
# Configure log and path settings
PROJECT_DIR="/home/zhoulong/projects/auto_rfic"
CADENCE_DIR="$PROJECT_DIR/cadence"
LOG_FILE="$CADENCE_DIR/virtuoso.log"
# SKILL_PORT=9191  # Remote server disabled

# TSMC PDK environment setup
export TSMC_PDK="/home/zhoulong/projects/TSMC/TSMC65gp_1p9m"
export PATH="$TSMC_PDK:$PATH"
export CCASE_CDS_VERBOSITY=3 # Set verbosity level for Cadence tools

# Set Cadence PDK environment variables
export CDS_INST_DIR="/opt/cadence/IC617"
export PDK_DIR="$TSMC_PDK"
export CDS_Netlisting_Mode="Analog"
export CDS_LOAD_ENV="$TSMC_PDK/cds.lib"  # Point to the TSMC PDK cds.lib file

# Set the environment variables for Virtuoso
export CDS_SITE="$CADENCE_DIR"

# Remote SKILL server disabled
export SKILL_SERVER_PATH="$CADENCE_DIR/skill/example/rf_amp_sweep.il"
export SKILL_SERVER_PORT="$SKILL_PORT"

# Create empty log file
> "$LOG_FILE"

# Print startup information
echo "========================================================"
echo "Launching Cadence Virtuoso (Remote SKILL Access Disabled)"
echo "========================================================"
echo "TSMC PDK environment: $TSMC_PDK"
echo "CDS_SITE: $CDS_SITE" 
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

echo "Virtuoso launched successfully (PID: $VIRTUOSO_PID)"
echo "Remote SKILL access has been disabled in this session"

# # Monitor the log file
# echo -e "\nShowing log file content (Ctrl+C to exit):\n"
# tail -f "$LOG_FILE"