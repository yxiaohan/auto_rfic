#!/bin/bash

# Script to check and analyze SKILL server logs

LOG_FILE="/home/zhoulong/projects/auto_rfic/cadence/logs/skillServer.log"

# Function to show help
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help       Show this help message"
  echo "  -l, --last N     Show last N lines (default: 20)"
  echo "  -f, --follow     Follow the log file in real time"
  echo "  -e, --errors     Show only errors"
  echo "  -c, --connections Show only connection events"
  echo "  -s, --status     Show server status"
  echo ""
  echo "Examples:"
  echo "  $0 -l 50         Show last 50 lines of the log"
  echo "  $0 -f            Follow log in real time"
  echo "  $0 -e            Show only error messages"
}

# Default values
LINES=20
FOLLOW=0
FILTER=""
STATUS=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -l|--last)
      LINES="$2"
      shift 2
      ;;
    -f|--follow)
      FOLLOW=1
      shift
      ;;
    -e|--errors)
      FILTER="ERROR\\|Error\\|Failed"
      shift
      ;;
    -c|--connections)
      FILTER="connection\\|Connection"
      shift
      ;;
    -s|--status)
      STATUS=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
  echo "Error: Log file not found at $LOG_FILE"
  echo "The server may not have been started or logs are in a different location."
  exit 1
fi

# Check server status
if [ $STATUS -eq 1 ]; then
  echo "=== SKILL Server Status ==="
  
  # Check if server process is running
  SERVER_PROCESS=$(ps aux | grep skillServer | grep -v grep)
  
  if [ -z "$SERVER_PROCESS" ]; then
    echo "Status: NOT RUNNING"
  else
    echo "Status: RUNNING"
    echo "Process info:"
    echo "$SERVER_PROCESS"
  fi
  
  # Show last start time from logs
  LAST_START=$(grep "SKILL Server started at" "$LOG_FILE" | tail -1)
  if [ ! -z "$LAST_START" ]; then
    echo "Last start time: $LAST_START"
  fi
  
  # Show socket status
  SOCKET_STATUS=$(grep "listening on port" "$LOG_FILE" | tail -1)
  if [ ! -z "$SOCKET_STATUS" ]; then
    echo "Socket: $SOCKET_STATUS"
  fi
  
  exit 0
fi

# Display logs based on options
if [ $FOLLOW -eq 1 ]; then
  if [ -z "$FILTER" ]; then
    tail -f "$LOG_FILE"
  else
    tail -f "$LOG_FILE" | grep --color=auto "$FILTER"
  fi
else
  if [ -z "$FILTER" ]; then
    tail -n "$LINES" "$LOG_FILE"
  else
    grep --color=auto "$FILTER" "$LOG_FILE" | tail -n "$LINES"
  fi
fi
