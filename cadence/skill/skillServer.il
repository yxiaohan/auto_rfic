;; SKILL Server Interface
;; Based on design by A.D.Beckett (Cadence Design Systems Ltd)

;; Debug flag - set to t for verbose output
abSkillServerDebug = nil

;; Process connection notifications
procedure(abSkillServerConnection(addr port)
    printf("Connection received from address %s, port %s\n" addr port)
)

;; Process commands from server
procedure(abSkillServerListener(ipcId data)
    let((channel command result)
        rexCompile("^\\([^ ]*\\) \\(.*\\)$")
        channel = rexReplace(data "\\1" 1)
        command = rexReplace(data "\\2" 1)
        
        when(abSkillServerDebug
            printf("COMMAND: %L\n" command)
        )
        
        ;; Execute the command safely
        unless(errset(result = evalstring(command))
            when(abSkillServerDebug
                printf("ERROR: %L\n" errset.errset)
            )
            ipcWriteProcess(ipcId sprintf(nil "%s ERROR %L\n" 
                channel errset.errset))
        )
        
        when(abSkillServerDebug
            printf("RESULT: %L\n" result)
        )
        
        ;; Send result back to client
        ipcWriteProcess(ipcId sprintf(nil "%s %L\n" channel result))
    )
)

;; Start the server process
procedure(startSkillServer(@optional (port "8123"))
    let((cmd)
        ;; Set environment variable for port
        setShellEnvVar("SKILLSERVPORT" port)
        
        ;; Build command path - assuming skillServer is in the same directory
        cmd = strcat(getDirName(getShellEnvVar("SCRIPT_FILE") || "_") "/skillServer")
        
        ;; Check if skillServer is executable
        if(isFile(cmd) then
            printf("Starting SKILL server on port %s\n" port)
            abSkillServer = ipcBeginProcess(cmd "" 'abSkillServerListener)
            
            if(abSkillServer != nil then
                printf("SKILL server started successfully\n")
                t
            else
                printf("Failed to start SKILL server\n")
                nil
            )
        else
            printf("Error: skillServer script not found at %s\n" cmd)
            nil
        )
    )
)

;; Stop the server
procedure(stopSkillServer()
    if(boundp('abSkillServer) && abSkillServer != nil then
        ipcKillProcess(abSkillServer)
        printf("SKILL server stopped\n")
        t
    else
        printf("SKILL server is not running\n")
        nil
    )
)

;; Load script from file and run it
procedure(runScriptFile(filename)
    let((fileId script)
        script = ""
        fileId = infile(filename)
        
        if(fileId != nil then
            while(gets(line fileId)
                script = strcat(script line "\n")
            )
            close(fileId)
            
            ;; Execute the script
            printf("Executing script: %s\n" filename)
            result = evalstring(script)
            printf("Script execution completed\n")
            result
        else
            printf("Error: Cannot open file %s\n" filename)
            nil
        )
    )
)

;; Print information about usage
printf("SKILL Server Interface loaded\n")
printf("To start server: startSkillServer([\"port\"])\n")
printf("To stop server: stopSkillServer()\n")
