;; rf_amp_sweep.il - Simple SKILL script for RF amplifier parameter sweeping
;; This example demonstrates basic automation concepts for RFIC design

;; =================================================================
;; Utility Functions
;; =================================================================

;; Get directory name from a file path
procedure(getDirName(filePath)
  let((index result strFilePath)
    ;; Handle nil case
    if(filePath == nil then
      return(".")
    )
    
    ;; Ensure filePath is a string
    strFilePath = sprintf(nil "%s" filePath)
    
    ;; Special case for root files like "/rf_amp_sweep.il"
    if(substring(strFilePath 1 1) == "/" && rindex(strFilePath "/") == 0 then
      return("/")
    )
    
    ;; Find the last slash in the path
    index = rindex(strFilePath "/")
    
    ;; If no slash found, return current directory "." 
    if(index == nil then
      result = "."
    else
      ;; Otherwise, return everything up to the last slash
      ;; Make sure index is an integer
      index = fix(index)
      result = substring(strFilePath 1 index)
    )
    
    result  ; Return result
  )
)

;; Error handling and logging
procedure(rfLog(level message @optional (logFile "rf_automation.log"))
  let((fileId)
    if(equal(level "ERROR") then
      printf("ERROR: %s\n" message)
    else
      printf("INFO: %s\n" message)
    )
    
    ;; Also log to file
    fileId = outfile(logFile "a")
    fprintf(fileId "[%s] %s: %s\n" rfGetCurrentTime() level message)
    close(fileId)
  )
)

procedure(rfGetCurrentTime()
  let((timeStr)
    timeStr = getCurrentTime()
    timeStr  ; Return value implicitly (no explicit 'return' needed)
  )
)

;; Parameter manipulation
procedure(getParameterValue(paramName defaultValue)
  let((value)
    ;; Try to get from environment first
    value = getShellEnvVar(paramName)
    
    ;; If not found, use default
    if(value == nil then
      rfLog("INFO" sprintf(nil "Using default value %s for parameter %s" defaultValue paramName))
      value = defaultValue
    )
    
    value  ; Return value implicitly
  )
)

;; Remote server initialization function - add this function
procedure(initializeRemoteServer()
  let((serverScript result)
    rfLog("INFO" "Setting up remote SKILL execution server...")
    
    ;; Get the current script's directory
    ;; First try using environment variable, fall back to CIW working directory
    scriptDir = getDirName(getShellEnvVar("SKILL_SERVER_PATH") || getWorkingDir())
    
    ;; Define path to the server script
    serverScript = sprintf(nil "%s/../remote_server.il" scriptDir)
    
    ;; Try to load the server script
    if(isFile(serverScript) then
      load(serverScript)
      rfLog("INFO" sprintf(nil "Remote server script loaded from %s" serverScript))
      
      ;; Start the server
      if(fboundp('startSkillServer) then
        startSkillServer()
        rfLog("INFO" "Remote SKILL server started successfully")
        result = t
      else
        rfLog("ERROR" "startSkillServer function not found after loading server script")
        result = nil
      )
    else
      rfLog("WARN" sprintf(nil "Server script not found at %s - skipping remote server initialization" serverScript))
      result = nil
    )
    
    result  ; Return result implicitly
  )
)

;; =================================================================
;; Schematic Manipulation Functions
;; =================================================================

;; Create a simple RF amplifier schematic
procedure(createRFAmplifier(libName cellName viewName @key (width 10u) (length 0.18u) (fingers 8))
  let((cv schematicId transistorId result)
    rfLog("INFO" sprintf(nil "Creating RF amplifier with W=%s L=%s fingers=%d" width length fingers))
    
    ;; Create or open the cell view
    cv = ddGetObj(libName cellName viewName)
    if(cv == nil then
      cv = dbOpenCellViewByType(libName cellName viewName "schematic" "w")
    else
      schematicId = dbOpenCellViewByType(libName cellName viewName "schematic" "a")
    )
    
    ;; Create the NMOS transistor
    transistorId = dbCreateInst(cv "analogLib" "nmos4" "symbol" 0:0 "R0")
    
    ;; Set the parameters
    dbAddProp(transistorId "w" "float" width)
    dbAddProp(transistorId "l" "float" length)
    dbAddProp(transistorId "fingers" "int" fingers)
    
    ;; Add nets and pins
    createPin(cv "IN" "inputOutput" "R0" -100:0)
    createPin(cv "OUT" "inputOutput" "R0" 100:0)
    createPin(cv "VDD" "inputOutput" "R0" 0:100)
    createPin(cv "VSS" "inputOutput" "R0" 0:-100)
    
    ;; Connect pins to transistor
    wireComponents(cv "IN" "G" transistorId)
    wireComponents(cv "OUT" "D" transistorId)
    wireComponents(cv "VSS" "S" transistorId)
    wireComponents(cv "VDD" "B" transistorId)
    
    ;; Save and close
    dbSave(cv)
    dbClose(cv)
    
    rfLog("INFO" sprintf(nil "RF amplifier %s/%s/%s created successfully" libName cellName viewName))
    t  ; Return t (true) implicitly
  )
)

;; Helper function to create pins
procedure(createPin(cv name type orient location)
  let((pin)
    pin = dbCreatePin(cv name type orient location)
    pin  ; Return pin implicitly
  )
)

;; Helper function to wire components
procedure(wireComponents(cv netName pinName instanceId)
  let((net term pin)
    net = dbFindNetByName(cv netName)
    if(net == nil then
      net = dbCreateNet(cv netName)
    )
    
    term = dbGetTermByName(instanceId pinName)
    if(term != nil then
      pin = dbCreatePin(term "symbol" "rectangle" 0:0)
      dbAddNetToPin(pin net)
    )
    
    t  ; Return t (true) implicitly
  )
)

;; =================================================================
;; Simulation Functions
;; =================================================================

;; Setup simulation testbench
procedure(setupSimulation(libName cellName)
  let((session)
    rfLog("INFO" sprintf(nil "Setting up simulation for %s/%s" libName cellName))
    
    ;; Create ADE session
    session = asiCreateSession(libName cellName)
    
    ;; Setup basic analyses
    asiAddAnalysis(session "dc" ?param nil)
    asiAddAnalysis(session "ac" ?param list("start" 1.0e6 "stop" 10.0e9 "dec" 20))
    
    ;; Setup outputs to save
    asiSetSaveOption(session "all" t)
    asiSetSaveOption(session "allpub" t)
    asiSetSaveOption(session "nestlvl" "all")
    
    rfLog("INFO" "Simulation setup complete")
    session  ; Return session implicitly
  )
)

;; Run parameter sweep
procedure(runParameterSweep(libName cellName paramName startVal endVal stepSize)
  let((session results i curVal numSteps)
    rfLog("INFO" sprintf(nil "Running parameter sweep for %s from %s to %s with step %s" 
                          paramName startVal endVal stepSize))
    
    ;; Calculate number of steps
    numSteps = ceiling((endVal - startVal) / stepSize) + 1
    
    ;; Initialize results storage
    results = makeTable("ResultTable" nil)
    
    ;; Create simulation session
    session = setupSimulation(libName cellName)
    
    ;; Run sweep
    for(i 0 numSteps-1
      curVal = startVal + (i * stepSize)
      
      ;; Update parameter value
      if(paramName == "width" then
        createRFAmplifier(libName cellName "schematic" ?width curVal)
      else
        if(paramName == "length" then
          createRFAmplifier(libName cellName "schematic" ?length curVal)
        else
          createRFAmplifier(libName cellName "schematic" ?fingers curVal)
        )
      )
      
      ;; Run simulation
      rfLog("INFO" sprintf(nil "Simulating with %s = %s" paramName curVal))
      asiRun(session)
      
      ;; Extract results
      gain = extractGain(session)
      bandwidth = extractBandwidth(session)
      
      ;; Store results
      results[curVal] = list(gain bandwidth)
      
      rfLog("INFO" sprintf(nil "Results for %s = %s: Gain = %f, BW = %e" 
                            paramName curVal gain bandwidth))
    )
    
    ;; Close session
    asiCloseSession(session)
    
    ;; Report results
    reportResults(libName cellName paramName results)
    
    rfLog("INFO" "Parameter sweep complete")
    results  ; Return results implicitly
  )
)

;; Placeholder for result extraction functions
procedure(extractGain(session)
  let((result)
    ;; In a real implementation, this would extract the gain from simulation results
    ;; For this example, we'll return a dummy value
    20.0  ; Return value implicitly
  )
)

procedure(extractBandwidth(session)
  let((result)
    ;; In a real implementation, this would extract the bandwidth from simulation results
    ;; For this example, we'll return a dummy value
    5.0e9  ; Return value implicitly
  )
)

;; Report results
procedure(reportResults(libName cellName paramName results)
  let((fileId keys i)
    fileId = outfile(sprintf(nil "%s_%s_sweep_results.csv" cellName paramName))
    fprintf(fileId "%s,Gain(dB),Bandwidth(Hz)\n" paramName)
    
    keys = sort(tableKeys(results))
    foreach(key keys
      fprintf(fileId "%s,%f,%e\n" key nth(0 results[key]) nth(1 results[key]))
    )
    
    close(fileId)
    rfLog("INFO" sprintf(nil "Results saved to %s_%s_sweep_results.csv" cellName paramName))
  )
)

;; =================================================================
;; Main Function
;; =================================================================

procedure(rfSweepExample()
  let((libName cellName result)
    rfLog("INFO" "Starting RF amplifier parameter sweep example")
    
    ;; Get configuration parameters
    libName = getParameterValue("RF_LIB" "RFDesign")
    cellName = getParameterValue("CELL_NAME" "rf_amplifier")
    
    ;; Initialize remote server
    initializeRemoteServer()
    
    ;; Create initial amplifier
    createRFAmplifier(libName cellName "schematic")
    
    ;; Run width sweep from 5um to 20um in steps of 2.5um
    runParameterSweep(libName cellName "width" 5.0e-6 20.0e-6 2.5e-6)
    
    rfLog("INFO" "Example completed successfully")
    t  ; Return t (true) implicitly
  )
)

;; Safe initialization function that catches errors
procedure(safeInitialize()
  let((result)
    rfLog("INFO" "Starting SKILL script initialization...")
    
    ;; Try to initialize the remote server, but catch errors
    errset(
      result = initializeRemoteServer()
      t
    )
    
    ;; Run the example if everything is configured
    if(getShellEnvVar("RF_RUN_EXAMPLE") == "1" then
      rfLog("INFO" "Running RF sweep example automatically...")
      
      ;; Try to run the example, but catch errors
      errset(
        rfSweepExample()
        t
      )
    else
      rfLog("INFO" "RF sweep example available. Run rfSweepExample() to execute.")
    )
    
    rfLog("INFO" "SKILL script initialization complete.")
  )
)

;; Run the initialization when this script is loaded
safeInitialize()
