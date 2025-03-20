# Remote SKILL Script Testing Framework

This framework allows testing SKILL scripts remotely by sending them from a client terminal to a running Virtuoso instance on a server.

## Components

1. `skillServer` - Tcl script that acts as a server, listening for incoming connections
2. `skillServer.il` - SKILL script that launches the server process and handles commands
3. `skillClient` - Tcl script for sending commands to the Virtuoso session
4. `run_il.sh` - Shell script wrapper for executing SKILL files remotely

## How It Works

This solution uses a socket-based approach:

1. The server (running in Virtuoso) listens on a socket for incoming commands
2. The client sends SKILL commands or script files to the server
3. The server executes the commands and returns the results

## Setup Instructions

### Server Side (Virtuoso)

1. Make sure the scripts are executable:
   ```bash
   chmod +x skillServer skillClient
   ```

2. Start Virtuoso on the server

3. In the CIW (Command Interpreter Window), load the server script:
   ```
   load("/path/to/skillServer.il")
   ```

4. Start the server (optional port parameter):
   ```
   startSkillServer()  ; Uses default port 8123
   startSkillServer("9000")  ; Uses port 9000
   ```

5. To stop the server:
   ```
   stopSkillServer()
   ```

### Client Side

1. Make sure the `run_il.sh` script is executable:
   ```bash
   chmod +x run_il.sh
   ```

2. Use the script to send SKILL files for remote execution:
   ```bash
   ./run_il.sh path/to/your_script.il [server_host] [server_port]
   ```

3. You can also use the skillClient directly:
   ```bash
   ./skillClient server_host port "dbOpenCellView(\"library\" \"cell\" \"view\")"
   ./skillClient server_host port -file script.il
   ```

## Integration with Existing Scripts

You can add server initialization code to your SKILL scripts:

```skill
;; Load and start the server
procedure(initializeSkillServer(@optional (port "8123"))
  let((serverScript)
    serverScript = sprintf(nil "%s/skillServer.il" 
                         getDirName(getShellEnvVar("SCRIPT_FILE") || "_"))
    
    if(isFile(serverScript) then
      load(serverScript)
      if(fboundp('startSkillServer) then
        startSkillServer(port)
      )
    )
  )
)

;; Initialize the server
initializeSkillServer()
```

## Credits

This implementation is based on the design by A.D.Beckett (Cadence Design Systems Ltd)
as shared in the comp.cad.cadence newsgroup.
