# Auto RFIC - Cadence Virtuoso Automation

This directory contains scripts and tools for automating Cadence Virtuoso RFIC design processes.

## Remote Virtuoso CIW Access

The `run_virtuoso.sh` script provides a mechanism to access the Cadence Command Interface Window (CIW) remotely in real-time. This allows:

- Monitoring Virtuoso output from a remote machine
- Sending SKILL commands to Virtuoso remotely
- Integrating with other tools and scripts

### Usage

1. Run the Virtuoso launcher script:
   ```
   cd /path/to/auto_rfic/cadence
   ./run_virtuoso.sh
   ```

2. The script will:
   - Launch Virtuoso with the appropriate PDK configuration
   - Set up a network socket for remote CIW access
   - Create a named pipe for streaming CIW output
   - Save connection details to `remote_access_info.txt`

3. Connect to the CIW remotely using one of these methods:
   - Directly with netcat: `nc <host-ip> <port>`
   - Via SSH tunnel (more secure): 
     ```
     ssh -L <port>:localhost:<port> username@<host-ip>
     nc localhost <port>
     ```
   - Using telnet: `telnet <host-ip> <port>`

4. Test the connection by sending a SKILL command:
   ```
   echo 'testRemote()' | nc <host-ip> <port>
   ```

### Troubleshooting

- If the connection is refused, check that:
  - The script is still running on the host machine
  - No firewall is blocking the port
  - You're using the correct IP address and port

- If you see no output, try:
  - Checking if Virtuoso is still running
  - Restarting the script
  - Checking the log file for errors

### Advanced Usage

You can also create scripts that interact with Virtuoso remotely:

```bash
#!/bin/bash
# Example: Send multiple SKILL commands to Virtuoso

HOST="192.168.1.100"
PORT=9876

# Send a sequence of SKILL commands
{
    echo '(println "Running remote SKILL sequence")'
    echo '(setq myVar 42)'
    echo '(println (strcat "The value is: " (sprintf nil "%d" myVar)))'
    echo 'testRemote()'
} | nc $HOST $PORT
```

## Security Considerations

The remote CIW access uses plain text communication. For secure usage:

1. Only run on trusted networks
2. Use SSH tunneling for connections over untrusted networks
3. Consider setting up firewall rules to restrict access to the socket port
