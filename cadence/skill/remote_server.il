;; remote_server.il - SKILL script server for remote execution
;; Listens on a socket for incoming SKILL scripts to execute

;; =================================================================
;; Server Configuration
;; =================================================================
procedure(skillServerConfig()
  let((config)
    config = makeTable("SkillServerConfig")
    config["port"] = 8765
    config["logFile"] = "skill_server.log"
    config["allowedClients"] = list("localhost" "0.0.0.0") ;; Add other IPs as needed
    config["timeout"] = 300 ;; Seconds
    return(config)
  )
)

;; =================================================================
;; Server Functions
;; =================================================================

;; Start the SKILL server
procedure(startSkillServer(@optional (config nil))
  let((serverSocket port logFile)
    ;; Get configuration or use default
    if(config == nil then
      config = skillServerConfig()
    )
    
    port = config["port"]
    logFile = config["logFile"]
    
    ;; Initialize logging
    serverLog("INFO" "Starting SKILL server" logFile)
    
    ;; Create server socket
    serverSocket = ipcBeginServer(port "TCP")
    if(serverSocket == nil then
      serverLog("ERROR" sprintf(nil "Failed to start server on port %d" port) logFile)
      return(nil)
    )
    
    serverLog("INFO" sprintf(nil "Server started on port %d" port) logFile)
    printf("SKILL Server started on port %d. Waiting for connections...\n" port)
    
    ;; Start listening for connections
    skillServerListenLoop(serverSocket config)
    
    return(t)
  )
)

;; Server listening loop
procedure(skillServerListenLoop(serverSocket config)
  let((clientSocket logFile)
    logFile = config["logFile"]
    
    while(t
      ;; Wait for client connection
      clientSocket = ipcWaitForConnect(serverSocket)
      if(clientSocket != nil then
        serverLog("INFO" "Client connected" logFile)
        
        ;; Handle client in a safe manner
        errset(
          handleClientConnection(clientSocket config)
          (lambda (reason)
            serverLog("ERROR" sprintf(nil "Error handling client: %L" reason) logFile)
          )
        )
        
        ;; Close client connection
        ipcClose(clientSocket)
      else
        ;; Sleep briefly to prevent CPU hogging if accept fails
        sleep(1)
      )
    )
  )
)

;; Handle client connection
procedure(handleClientConnection(clientSocket config)
  let((request scriptContent scriptFile response logFile)
    logFile = config["logFile"]
    
    ;; Read request from client
    request = readClientRequest(clientSocket logFile)
    
    if(request != nil then
      ;; Extract script content
      scriptContent = request
      
      ;; Create temporary file for the script
      scriptFile = makeString(1024)
      sprintf(scriptFile "/tmp/remote_skill_%d.il" getpid())
      
      ;; Write script to temporary file
      writeScriptToFile(scriptFile scriptContent logFile)
      
      ;; Execute the script and capture output
      response = executeSkillScript(scriptFile logFile)
      
      ;; Send response back to client
      sendResponseToClient(clientSocket response logFile)
      
      ;; Clean up temporary file
      removeSkillFile(scriptFile)
    )
  )
)

;; Read request from client
procedure(readClientRequest(clientSocket logFile)
  let((request bytesRead)
    serverLog("INFO" "Reading client request" logFile)
    
    request = ""
    done = nil
    
    ;; Read until we get end marker or error
    while(!done
      data = ipcReadSocket(clientSocket 1024)
      if(data != nil && data != "" then
        request = strcat(request data)
        ;; Check for end marker
        if(rexMatchp("__END_OF_SCRIPT__" data) then
          done = t
        )
      else
        done = t
      )
    )
    
    ;; Remove end marker if present
    request = regsub("__END_OF_SCRIPT__" request "")
    
    serverLog("INFO" sprintf(nil "Received script of length %d" strlen(request)) logFile)
    return(request)
  )
)

;; Write script to temporary file
procedure(writeScriptToFile(scriptFile scriptContent logFile)
  let((fileId)
    serverLog("INFO" sprintf(nil "Writing script to %s" scriptFile) logFile)
    
    fileId = outfile(scriptFile)
    if(fileId != nil then
      fprintf(fileId "%s" scriptContent)
      close(fileId)
      return(t)
    else
      serverLog("ERROR" sprintf(nil "Failed to write script to %s" scriptFile) logFile)
      return(nil)
    )
  )
)

;; Execute SKILL script and capture output
procedure(executeSkillScript(scriptFile logFile)
  let((outputFile result output)
    serverLog("INFO" sprintf(nil "Executing script %s" scriptFile) logFile)
    
    ;; Create output capture file
    outputFile = strcat(scriptFile ".out")
    
    ;; Redirect output, load script, restore output
    savedOutput = poport
    fileId = outfile(outputFile)
    fprintf(fileId "===== SCRIPT EXECUTION OUTPUT =====\n")
    poport = fileId
    
    ;; Execute script in safe mode and capture result
    result = errset(
      load(scriptFile)
      (lambda (reason)
        sprintf(nil "ERROR: %L" reason)
      )
    )
    
    ;; Restore output
    fprintf(fileId "\n===== END OF EXECUTION =====\n")
    close(fileId)
    poport = savedOutput
    
    ;; Read execution output
    output = readOutputFile(outputFile)
    
    ;; Clean up output file
    removeSkillFile(outputFile)
    
    ;; Combine result and output
    response = sprintf(nil "Result: %L\n\nOutput:\n%s" result output)
    serverLog("INFO" "Script execution complete" logFile)
    
    return(response)
  )
)

;; Read output from file
procedure(readOutputFile(outputFile)
  let((fileId line output)
    output = ""
    fileId = infile(outputFile)
    
    if(fileId != nil then
      while(gets(line fileId)
        output = strcat(output line "\n")
      )
      close(fileId)
    )
    
    return(output)
  )
)

;; Send response to client
procedure(sendResponseToClient(clientSocket response logFile)
  let((result)
    serverLog("INFO" sprintf(nil "Sending response of length %d" strlen(response)) logFile)
    
    ;; Add end marker
    response = strcat(response "\n__END_OF_RESPONSE__")
    
    ;; Send response
    result = ipcWriteSocket(clientSocket response)
    
    if(result == nil then
      serverLog("ERROR" "Failed to send response to client" logFile)
    )
    
    return(result)
  )
)

;; Utility: Delete file - renamed from deleteFile to removeSkillFile
procedure(removeSkillFile(filename)
  system(sprintf(nil "rm -f %s" filename))
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

;; Initialize the server when this file is loaded
printf("SKILL Remote Execution Server loaded\n")
printf("To start the server, call: startSkillServer()\n")
