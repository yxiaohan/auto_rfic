# Remote SKILL Script Testing Framework

This framework allows testing SKILL scripts remotely by sending them from a client terminal to a running Virtuoso instance on a server.

## Components

1. `remote_server.il` - SKILL server that runs inside Virtuoso and executes scripts from a specified directory
2. `run_il.sh` - Client script for sending SKILL files to the server
3. Example integration with existing SKILL files

## How It Works

This solution uses a file-based approach:

1. The server monitors a directory (`/tmp/skill_inbox`) for new SKILL scripts
2. When a script is found, it's executed and the results are saved to an output directory (`/tmp/skill_outbox`)
3. The client sends scripts to the inbox directory and waits for results in the outbox directory

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

4. To stop the server:

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
   ./run_il.sh path/to/your_script.il [server_host]
   ```

3. The script will be transferred to the server, executed, and the results displayed on your terminal.

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
        t
      else
        nil
      )
    else
      nil
    )
  )
)
```

Then add a call to this function in your main script:

```skill
;; Initialize remote server capability
initializeRemoteServer()
```

## Requirements

- SSH access between client and server
- Proper permissions on the inbox and outbox directories
- The client must have SSH key-based authentication set up with the server for passwordless login
