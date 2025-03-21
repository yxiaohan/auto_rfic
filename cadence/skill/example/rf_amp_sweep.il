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
    
    ;; Find the last slash in the path
    index = rindex(strFilePath "/")
    
    ;; If no slash found or only at beginning, return appropriate directory
    cond(
      (index == nil
        result = "."
      )
      ((equal(index 1) && strlen(strFilePath) > 1)
        result = "/"
      )
      (t
        ;; Force integer conversion explicitly to ensure proper type
        let((charCount)
          charCount = fix(0) + index  ; Force numeric-to-integer conversion
          result = substring(strFilePath 1 charCount)
        )
      )
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

;; =================================================================
;; Schematic Manipulation Functions
;; =================================================================

;; Create a simple RF amplifier schematic
procedure(createRFAmplifier(libName cellName viewName @key (width 10u) (length 0.18u) (fingers 8))
  prog((cv schematicId transistorId result libId cellViewId)
    rfLog("INFO" sprintf(nil "Creating RF amplifier with W=%g L=%g fingers=%d" width length fingers))
    
    ;; Check if library exists and create it if needed
    libId = ddGetObj(libName)
    if(libId == nil then
      rfLog("INFO" sprintf(nil "Library %s does not exist, creating it..." libName))
      libId = ddCreateLib(libName)
      if(libId == nil then
        rfLog("ERROR" sprintf(nil "Failed to create library %s" libName))
        return(nil)
      )
    )
    
    ;; Create or open the cell view
    cv = ddGetObj(libName cellName viewName)
    if(cv == nil then
      cv = dbOpenCellViewByType(libName cellName viewName "schematic" "w")
      if(cv == nil then
        rfLog("ERROR" sprintf(nil "Failed to create cell view %s/%s/%s" libName cellName viewName))
        return(nil)
      )
    else
      cv = dbOpenCellViewByType(libName cellName viewName "schematic" "a")
      if(cv == nil then
        rfLog("ERROR" sprintf(nil "Failed to open existing cell view %s/%s/%s" libName cellName viewName))
        return(nil)
      )
    )
    
    ;; Check if analogLib exists and get transistor cell view template
    unless(ddGetObj("analogLib")
      rfLog("ERROR" "analogLib not found in library path. Check your Cadence setup.")
      dbClose(cv)
      return(nil)
    )
    
    ;; Get the cell view template for nmos4 from analogLib
    cellViewId = dbOpenCellViewByType("analogLib" "nmos4" "symbol" nil "r")
    unless(cellViewId
      rfLog("ERROR" "Failed to open analogLib/nmos4/symbol cell view.")
      dbClose(cv)
      return(nil)
    )
    
    ;; Create the NMOS transistor using the cell view template
    transistorId = dbCreateInst(cv cellViewId "I0" 0:0 "R0")
    if(transistorId == nil then
      rfLog("ERROR" "Failed to create NMOS transistor instance.")
      dbClose(cellViewId)
      dbClose(cv)
      return(nil)
    )
    
    ;; Close the cell view template
    dbClose(cellViewId)
    
    ;; Set the parameters using dbSetInstPropValue instead of dbAddProp
    dbSetInstPropValue(transistorId "w" width)
    dbSetInstPropValue(transistorId "l" length)
    dbSetInstPropValue(transistorId "fingers" fingers)
    
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
    return(t)  ;; Using return explicitly since we're in a prog block
  )
)

;; Helper function to create pins
procedure(createPin(cv name type orient location)
  prog((pin)
    unless(cv
      rfLog("ERROR" "Cannot create pin: invalid cell view")
      return(nil)
    )
    
    pin = dbCreatePin(cv name type orient location)
    unless(pin
      rfLog("ERROR" sprintf(nil "Failed to create pin %s" name))
    )
    
    return(pin)  ;; Return pin explicitly using return in prog block
  )
)

;; Helper function to wire components
procedure(wireComponents(cv netName pinName instanceId)
  prog((net term pin)
    unless(cv
      rfLog("ERROR" "Cannot wire components: invalid cell view")
      return(nil)
    )
    
    unless(instanceId
      rfLog("ERROR" sprintf(nil "Cannot wire components: invalid instance for net %s" netName))
      return(nil)
    )
    
    net = dbFindNetByName(cv netName)
    if(net == nil then
      net = dbCreateNet(cv netName)
      unless(net
        rfLog("ERROR" sprintf(nil "Failed to create net %s" netName))
        return(nil)
      )
    )
    
    term = dbGetTermByName(instanceId pinName)
    if(term != nil then
      pin = dbCreatePin(term "symbol" "rectangle" 0:0)
      if(pin != nil then
        dbAddNetToPin(pin net)
      else
        rfLog("ERROR" sprintf(nil "Failed to create pin for term %s" pinName))
        return(nil)
      )
    else
      rfLog("ERROR" sprintf(nil "Failed to find terminal %s on instance" pinName))
      return(nil)
    )
    
    return(t)  ;; Return t (true) explicitly using return in prog block
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
    
    ;; Verify analogLib exists (required for the NMOS transistor)
    if(ddGetObj("analogLib") == nil then
      rfLog("ERROR" "analogLib not found. Make sure Cadence libraries are properly loaded.")
      nil  ;; Return nil implicitly
    else
      ;; Create initial amplifier
      result = createRFAmplifier(libName cellName "schematic")
      if(result == nil then
        rfLog("ERROR" "Failed to create RF amplifier. Aborting example.")
        nil  ;; Return nil implicitly
      else
        rfLog("INFO" sprintf(nil "Successfully created RF amplifier in %s/%s" libName cellName))
        
        ;; Uncomment to run width sweep when simulation is properly configured
        ;; runParameterSweep(libName cellName "width" 5.0e-6 20.0e-6 2.5e-6)
        
        rfLog("INFO" "Example completed successfully")
        t  ;; Return t (true) implicitly
      )
    )
  )
)

;; Safe initialization function that catches errors
procedure(safeInitialize()
  let((result)
    ;; Auto-execute the RF sweep example
    rfLog("INFO" "Running RF sweep example automatically...")
    
    ;; Try to run the example, but catch errors
    result = errset(
      rfSweepExample()
      t
    )
    
    ;; Check for errors during execution
    if(car(result) == nil && cdr(result) != nil then
      rfLog("ERROR" "Error occurred during rfSweepExample execution")
    )
    
    rfLog("INFO" "SKILL script initialization complete.")
  )
)

;; Run the initialization when this script is loaded
safeInitialize()
