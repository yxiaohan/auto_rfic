;; remote_server.il - SKILL script server for remote execution
;; Uses file-based communication instead of sockets

;; =================================================================
;; Server Configuration
;; =================================================================
procedure(skillServerConfig()
  let((config)
    config = makeTable("SkillServerConfig")
    config["inboxDir"] = "/tmp/skill_inbox"
    config["outboxDir"] = "/tmp/skill_outbox"
    config["logFile"] = "skill_server.log"
    config["pollInterval"] = 1.0 ;; Seconds
    config  ;; Implicit return
  )
)

;; =================================================================
;; Server Functions
;; =================================================================

;; Start the SKILL server
procedure(startSkillServer(@optional (config nil))
  let((inboxDir outboxDir logFile)
    ;; Get configuration or use default
    if(config == nil then
      config = skillServerConfig()
    )
    
    inboxDir = config["inboxDir"]
    outboxDir = config["outboxDir"]
    logFile = config["logFile"]
    
    ;; Initialize logging
    serverLog("INFO" "Starting SKILL File-based Server" logFile)
    
    ;; Create directories if they don't exist
    system(sprintf(nil "mkdir -p %s" inboxDir))
    system(sprintf(nil "mkdir -p %s" outboxDir))
    
    serverLog("INFO" sprintf(nil "Server watching directory %s" inboxDir) logFile)
    printf("SKILL Server started. Watching directory: %s\n" inboxDir)
    printf("Results will be written to: %s\n" outboxDir)
    
    ;; Start the polling loop in a separate thread/process
    startPollingForScripts(config)
    
    t  ;; Implicit return
  )
)

;; Start watching for incoming script files
procedure(startPollingForScripts(config)
  let((inboxDir)
    inboxDir = config["inboxDir"]
    
    ;; Create a global variable to track if server is running
    _skillServerRunning = t
    
    ;; Register a scheduled callback to check for scripts
    when((_skillServerRunning)
      checkForScripts(config)
      ;; Reschedule after poll interval
      after(config["pollInterval"] startPollingForScripts(config))
    )
  )
)

;; Stop the server
procedure(stopSkillServer()
  _skillServerRunning = nil
  serverLog("INFO" "SKILL Server stopped")
  printf("SKILL Server stopped\n")
  t
)

;; Check for new scripts to process
procedure(checkForScripts(config)
  let((inboxDir outboxDir logFile files)
    inboxDir = config["inboxDir"]
    outboxDir = config["outboxDir"]
    logFile = config["logFile"]
    
    ;; Get list of .il files in inbox
    files = getDirFiles(inboxDir)
    files = setof(file files rexMatchp("\\.il$" file))
    
    foreach(file files
      scriptFile = strcat(inboxDir "/" file)
      
      ;; Check for a ".lock" file to avoid processing files being uploaded
      lockFile = strcat(scriptFile ".lock")
      if(!isFile(lockFile) then
        ;; Process the script
        serverLog("INFO" sprintf(nil "Processing script: %s" file) logFile)
        
        ;; Execute script and save output
        outputFile = strcat(outboxDir "/" file ".out")
        executeScriptToFile(scriptFile outputFile logFile)
        
        ;; Mark script as processed
        removeSkillFile(scriptFile)
      )
    )
  )
)

;; Execute script and save output to file
procedure(executeScriptToFile(scriptFile outputFile logFile)
  let((result output savedOutput fileId)
    serverLog("INFO" sprintf(nil "Executing script %s" scriptFile) logFile)
    
    ;; Open output file
    fileId = outfile(outputFile)
    fprintf(fileId "===== SCRIPT EXECUTION OUTPUT =====\n")
    
    ;; Redirect output during execution
    savedOutput = poport
    poport = fileId
    
    ;; Execute script in safe mode and capture result
    result = errset(
      load(scriptFile)
      (lambda (reason)
        sprintf(nil "ERROR: %L" reason)
      )
    )
    
    ;; Restore output
    poport = savedOutput
    
    ;; Write the result to the file
    fprintf(fileId "\n===== EXECUTION RESULT =====\n")
    fprintf(fileId "%L\n" result)
    fprintf(fileId "\n===== END OF EXECUTION =====\n")
    close(fileId)
    
    serverLog("INFO" "Script execution complete" logFile)
  )
)

;; Utility: Remove file
procedure(removeSkillFile(filename)
  system(sprintf(nil "rm -f %s" filename))
)

;; Utility: Get directory files
procedure(getDirFiles(dirPath)
  let((tmpFile files cmd)
    tmpFile = "/tmp/dir_listing.tmp"
    cmd = sprintf(nil "ls %s > %s" dirPath tmpFile)
    system(cmd)
    
    files = list()
    if(isFile(tmpFile) then
      inPort = infile(tmpFile)
      while(gets(line inPort)
        files = cons(line files)
      )
      close(inPort)
      removeSkillFile(tmpFile)
    )
    
    nreverse(files)
  )
)

;; Logging function
procedure(serverLog(level message @optional (logFile "skill_server.log"))
  let((fileId)
    if(equal(level "ERROR") then
      printf("SERVER ERROR: %s\n" message)
    else
      printf("SERVER INFO: %s\n" message)
    )
    
    ;; Also log to file
    fileId = outfile(logFile "a")
    fprintf(fileId "[%s] %s: %s\n" getCurrentTime() level message)
    close(fileId)
  )
)

;; Get current time as string
procedure(getCurrentTime()
  let((timeStr)
    timeStr = buildString(sprintf(nil "date +'%%Y-%%m-%%d %%H:%%M:%%S'"))
    while(rexMatchp("[\r\n]" timeStr)
      timeStr = substring(timeStr 1 strlen(timeStr)-1)
    )
    timeStr
  )
)

;; Execute system command and return output
procedure(buildString(cmd)
  let((tmpfile content)
    tmpfile = "/tmp/skill_cmd_output.tmp"
    system(sprintf(nil "%s > %s" cmd tmpfile))
    
    content = ""
    if(isFile(tmpfile) then
      inPort = infile(tmpfile)
      while(gets(line inPort)
        content = strcat(content line "\n")
      )
      close(inPort)
      removeSkillFile(tmpfile)
    )
    
    content
  )
)

;; Initialize the server when this file is loaded
printf("SKILL Remote Execution Server loaded\n")
printf("To start the server, call: startSkillServer()\n")
printf("To stop the server, call: stopSkillServer()\n")
