;; SKILL Server Interface
;; Based on design by A.D.Beckett (Cadence Design Systems Ltd)

;; Debug flag - set to t for verbose output
abSkillServerDebug = t  ;; Enable debugging by default

;; Define the missing getDirName function
procedure(getDirName(path)
    let((idx)
        idx = strrchr(path "/")
        if(idx then
            substr(path 1 idx)
        else
            "./"
        )
    )
)

;; Process connection notifications
procedure(abSkillServerConnection(addr port)
    printf("Connection received from address %s, port %s\n" addr port)
)

;; Process commands from server
procedure(abSkillServerListener(ipcId data)
    let((channel command result)
        printf("Received data: %s\n" data)
        
        rexCompile("^\\([^ ]*\\) \\(.*\\)$")
        if(rexMatchp(data) then
            channel = rexReplace(data "\\1" 1)
            command = rexReplace(data "\\2" 1)
            
            when(abSkillServerDebug
                printf("COMMAND: [%s] %s\n" channel command)
            )
            
            ;; Execute the command safely
            unless(errset(result = evalstring(command))
                errMsg = errset.errset
                printf("ERROR: %L\n" errMsg)
                ipcWriteProcess(ipcId sprintf(nil "%s ERROR %L\n" channel errMsg))
                return(nil)
            )
            
            when(abSkillServerDebug
                printf("RESULT: %L\n" result)
            )
            
            ;; Send result back to client
            ipcWriteProcess(ipcId sprintf(nil "%s %L\n" channel result))
        else
            printf("ERROR: Invalid command format: %s\n" data)
            return(nil)
        )
    )
)

;; Start the server process
procedure(startSkillServer(@optional (port "8123"))
    let((cmd skillDir)
        ;; Set environment variable for port
        setShellEnvVar("SKILLSERVPORT" port)
        
        ;; Get location of skill directory
        skillDir = getShellEnvVar("CDS_SITE") || "."
        skillDir = strcat(skillDir "/skill")
        
        ;; Build command path - using absolute path
        cmd = strcat(skillDir "/skillServer")
        
        ;; Check if skillServer is executable
        if(isReadable(cmd) then
            ;; Check if executable
            system(sprintf(nil "test -x \"%s\" || chmod +x \"%s\"" cmd cmd))
            
            printf("Starting SKILL server on port %s\n" port)
            printf("Using server executable: %s\n" cmd)
            
            abSkillServer = ipcBeginProcess(cmd "" 'abSkillServerListener)
            
            if(abSkillServer != nil then
                printf("SKILL server started successfully (Process ID: %L)\n" 
                       abSkillServer)
                t
            else
                printf("Failed to start SKILL server\n")
                nil
            )
        else
            printf("Error: skillServer script not found at %s\n" cmd)
            printf("Current directory: %s\n" getCurrentDir())
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
