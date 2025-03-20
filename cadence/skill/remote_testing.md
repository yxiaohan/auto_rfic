# Remote SKILL Script Testing Framework

This framework allows testing SKILL scripts remotely by sending them from a client terminal to a running Virtuoso instance on a server.

## Components

1. `remote_server.il` - SKILL server that runs inside Virtuoso and executes received scripts
2. `run_il.sh` - Client script for sending SKILL files to the server
3. Example integration with existing SKILL files

## Setup Instructions

### Server Side (Virtuoso)

1. Start Virtuoso on the server
2. In the CIW (Command Interpreter Window), load the server script:

   ```
   load("/path/to/remote_server.il")
   ```

3. Start the server:

   ```
   startSkillServer()
   ```

   This will start the server on the default port (8765)

### Client Side

1. Make sure the `run_il.sh` script is executable:

   ```bash
   chmod +x run_il.sh
   ```

2. Use the script to send SKILL files for remote execution:

   ```bash
   ./run_il.sh path/to/your_script.il [server_host] [server_port]
   ```

## Integration with Existing Scripts

You can integrate the remote server initialization with existing scripts by adding the following to your main SKILL file:

```skill
;; Load and start the remote server
procedure(initializeRemoteServer()
  let((serverScript)
    serverScript = sprintf(nil "%s/../remote_server.il" 
                         getDirName(getShellEnvVar("SCRIPT_FILE") || "_"))
    
    if(isFile(serverScript) then
      load(serverScript)
      if(fboundp('startSkillServer) then
        startSkillServer()
        return(t)
      else
        return(nil)
      )
    else
      return(nil)
    )
  )
)
```

Then add a call to this function in your main script:

```skill
;; Initialize remote server capability
initializeRemoteServer()
```

## Security Considerations

- The current implementation accepts connections from localhost only by default
- Update the `allowedClients` list in `skillServerConfig()` to allow connections from specific IPs
- This should be used in trusted networks only
- There is no authentication mechanism in this basic implementation
