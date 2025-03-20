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
    printf("Connection time: %s\n" getCurrentTime())
    
    ;; Optional: write to a log file for debugging
    logentry = sprintf(nil "New connection from %s:%s at %s" addr port getCurrentTime())
    appendStringToFile(logentry "skillServer_connections.log")
    
    t ;; Return true to acknowledge the connection
)

;; Append string to a log file
procedure(appendStringToFile(str filename)
    let((port)
        port = outfile(filename "a")
        when(port
            fprintf(port "%s\n" str)
            close(port)
        )
    )
)

;; Process commands from server
procedure(abSkillServerListener(ipcId data)
    let((channel command result errMsg logEntry)
        printf("Received data: %s\n" data)
        
        ;; Log the raw data received
        logEntry = sprintf(nil "Raw data received at %s: %s" getCurrentTime() data)
        appendStringToFile(logEntry "skillServer_commands.log")
        
        ;; Special handling for end-of-command marker
        if(data == "__END_OF_COMMAND__" || rexMatchp("__END_OF_COMMAND__$" data) then
            printf("End of command marker received\n")
            return(t)
        )
        
        rexCompile("^\\([^ ]*\\) \\(.*\\)$")
        if(rexMatchp(data) then
            channel = rexReplace(data "\\1" 1)
            command = rexReplace(data "\\2" 1)
            
            when(abSkillServerDebug
                printf("COMMAND: [%s] %s\n" channel command)
                logEntry = sprintf(nil "Channel %s command: %s" channel command)
                appendStringToFile(logEntry "skillServer_commands.log")
            )
            
            ;; Execute the command safely
            unless(errset(result = evalstring(command))
                errMsg = errset.errset
                printf("ERROR: %L\n" errMsg)
                ipcWriteProcess(ipcId sprintf(nil "%s ERROR %L\n" channel errMsg))
                appendStringToFile(sprintf(nil "ERROR: %L" errMsg) "skillServer_errors.log")
                return(nil)
            )
            
            when(abSkillServerDebug
                printf("RESULT: %L\n" result)
                logEntry = sprintf(nil "Result for channel %s: %L" channel result)
                appendStringToFile(logEntry "skillServer_results.log")
            )
            
            ;; Send result back to client
            ipcWriteProcess(ipcId sprintf(nil "%s %L\n" channel result))
        else
            printf("ERROR: Invalid command format: %s\n" data)
            appendStringToFile(sprintf(nil "Invalid command format: %s" data) "skillServer_errors.log")
            return(nil)
        )
    )
)

;; Get current date and time as string
procedure(getCurrentTime()
    sprintf(nil "%d/%02d/%02d %02d:%02d:%02d"
        getdate().year
        getdate().month 
        getdate().day
        getdate().hour
        getdate().minute
        getdate().second
    )
)

;; Start the server process
procedure(startSkillServer(@optional (port "8123"))
    let((cmd skillDir)
        ;; Set environment variable for port
        setShellEnvVar("SKILLSERVPORT" port)
        
        ;; Get location of skill directory
        skillDir = getShellEnvVar("CDS_SITE") || "."
        
        ;; Try to get better skill directory from current file
        if(!isDir(skillDir) then
            skillDir = getDirName(get_filename() || ".") || "."
            if(isDir(strcat(skillDir "/skill")) then
                skillDir = strcat(skillDir "/skill")
            )
        else
            skillDir = strcat(skillDir "/skill")
        )
        
        ;; Build command path - using absolute path
        cmd = strcat(skillDir "/skillServer")
        
        ;; Check if skillServer is executable
        if(isReadable(cmd) then
            ;; Check if executable
            system(sprintf(nil "test -x \"%s\" || chmod +x \"%s\"" cmd cmd))
            
            printf("Starting SKILL server on port %s\n" port)
            printf("Using server executable: %s\n" cmd)
            printf("Current time: %s\n" getCurrentTime())
            
            ;; Create a startup log entry
            startupLog = sprintf(nil "Starting skillServer at %s with port %s from path %s"
                            getCurrentTime() port cmd)
            appendStringToFile(startupLog "skillServer_startup.log")
            
            ;; Start the server process
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

;; Restart the server (for troubleshooting)
procedure(restartSkillServer(@optional (port "8123"))
    stopSkillServer()
    startSkillServer(port)
)

;; Check server status
procedure(checkSkillServerStatus()
    if(boundp('abSkillServer) && abSkillServer != nil then
        printf("SKILL server is running (Process ID: %L)\n" abSkillServer)
        portValue = getShellEnvVar("SKILLSERVPORT") || "8123"
        printf("Listening on port: %s\n" portValue)
        t
    else
        printf("SKILL server is not running\n")
        nil
    )
)

;; Print information about usage
printf("SKILL Server Interface loaded at %s\n" getCurrentTime())
printf("To start server: startSkillServer([\"port\"])\n")
printf("To restart server: restartSkillServer([\"port\"])\n")
printf("To check status: checkSkillServerStatus()\n")
printf("To stop server: stopSkillServer()\n")
