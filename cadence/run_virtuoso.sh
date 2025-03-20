#!/bin/bash
# Script to launch Cadence Virtuoso 64-bit with custom log location

LOG_FILE="/home/zhoulong/projects//auto_rfic/cadence/virtouso.log"

# Add TSMC PDK to PATH
export PATH="/home/zhoulong/projects/TSMC/TSMC65gp_1p9m:$PATH"
echo "Added TSMC PDK to PATH: /home/zhoulong/projects/TSMC/TSMC65gp_1p9m"

# Create empty log file or truncate existing one
> "$LOG_FILE"

# Launch Virtuoso with output piped through a log size limiter
/opt/cadence/IC617/tools/dfII/bin/virtuoso -64 2>&1 | tee >(tail -n 100 > "$LOG_FILE") &

# Save the Virtuoso process ID for potential later use
VIRTUOSO_PID=$!

# Print confirmation message
echo "Virtuoso launched in background (PID: $VIRTUOSO_PID)"
echo "Log will maintain last 100 lines at: $LOG_FILE"