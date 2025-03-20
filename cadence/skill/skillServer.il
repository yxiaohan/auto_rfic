;; SKILL Server Interface
;; Based on design by A.D.Beckett (Cadence Design Systems Ltd)

;; Debug flag - set to t for verbose output
abSkillServerDebug = nil

;; Function to extract directory path from a filename
procedure(getDirectoryPath(fileName)
  let((path)
    ;; Use parseString to get directory components
    path = parseString(simplifyFilename(fileName) "/")
    
    ;; Remove the last component (the filename itself)
    path = reverse(cdr(reverse(path)))
    
    ;; Join the path components back with "/"
    path = buildString(mapcar(lambda(p) strcat(p "/")) path)
    
    ;; Remove trailing slash if present
    if(rexMatchp("/$" path) then
      path = substring(path 1 strlen(path)-1)
    )
    
    path
  )
)

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
procedure(startSkillServer(@optional (port "8123") (serverPath nil))
    let((cmd)
        ;; Set environment variable for port
        setShellEnvVar("SKILLSERVPORT" port)
        
        ;; Determine the path to the skillServer script
        if(serverPath == nil then
            if(boundp('SKILL_SERVER_PATH) then
                cmd = SKILL_SERVER_PATH
            else
                ;; Try to guess based on this file's path if SCRIPT_FILE is available
                scriptFile = getShellEnvVar("SCRIPT_FILE")
                if(scriptFile != nil then
                    cmd = strcat(getDirectoryPath(scriptFile) "/skillServer")
                else
                    ;; Default location
                    cmd = "/Volumes/990_2t/yuan/Nextcloud/projects/auto_rfic/cadence/skill/skillServer"
                )
            )
        else
            cmd = serverPath
        )
        
        ;; Check if skillServer is executable
        if(isFile(cmd) then
            printf("Starting SKILL server on port %s using server at %s\n" port cmd)
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
            printf("Please set the SKILL_SERVER_PATH variable to point to the skillServer executable\n")
            printf("Example: SKILL_SERVER_PATH = \"/path/to/skillServer\"\n")
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

;; Helper to build a string from a list
procedure(buildString(strList)
  let((result)
    result = ""
    foreach(str strList
      result = strcat(result str)
    )
    result
  )
)

;; Print information about usage
printf("SKILL Server Interface loaded\n")
printf("To start server: startSkillServer([\"port\"] [\"serverPath\"])\n")
printf("To stop server: stopSkillServer()\n")
printf("Before starting, set the path to the skillServer script:\n")
printf("SKILL_SERVER_PATH = \"/full/path/to/skillServer\"\n")
