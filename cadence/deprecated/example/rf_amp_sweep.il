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
  prog((cv schematicId transistorId result libId cellViewId instanceName existingCv uniqueID)
    rfLog("INFO" sprintf(nil "Creating RF amplifier with W=%g L=%g fingers=%d" width length fingers))
    
    ;; Check if library exists and create it if needed
    libId = ddGetObj(libName)
    if(libId == nil then
      rfLog("INFO" sprintf(nil "Library %s does not exist, creating it..." libName))
      
      ;; Determine a safe path for the new library
      ;; First try to get the path from cdsenv
      libPath = getShellEnvVar("CDS_LIB_DIR")
      
      ;; If not set, use the current directory as fallback
      if(libPath == nil || !isDir(libPath) then
        libPath = getWorkingDir()
        rfLog("INFO" sprintf(nil "Using current working directory for library path: %s" libPath))
      )
      
      ;; Make sure the path exists
      unless(isDir(libPath)
        rfLog("ERROR" sprintf(nil "Library path %s does not exist. Cannot create library." libPath))
        return(nil)
      )
      
      ;; Create the library directory
      libDirPath = strcat(libPath "/" libName)
      unless(isDir(libDirPath)
        system(sprintf(nil "mkdir -p %s" libDirPath))
      )
      
      ;; Create the library
      libId = ddCreateLib(libName ?dir libDirPath)
      if(libId == nil then
        rfLog("ERROR" sprintf(nil "Failed to create library %s at path %s" libName libDirPath))
        return(nil)
      )
    )
    
    ;; Create or open the cell view
    existingCv = ddGetObj(libName cellName viewName)
    if(existingCv == nil then
      cv = dbOpenCellViewByType(libName cellName viewName "schematic" "w")
      if(cv == nil then
        rfLog("ERROR" sprintf(nil "Failed to create cell view %s/%s/%s" libName cellName viewName))
        return(nil)
      )
    else
      ;; If cell view exists, reopen it
      rfLog("INFO" sprintf(nil "Cell view %s/%s/%s exists, reopening it" libName cellName viewName))
      
      ;; Try to open existing cell view for editing
      cv = dbOpenCellViewByType(libName cellName viewName "schematic" "a")
      if(cv == nil then
        ;; If can't append, try to create a new one
        rfLog("INFO" sprintf(nil "Cannot open existing cell view for editing, creating a new one"))
        cv = dbOpenCellViewByType(libName cellName viewName "schematic" "w")
        if(cv == nil then
          rfLog("ERROR" sprintf(nil "Failed to recreate cell view %s/%s/%s" libName cellName viewName))
          return(nil)
        )
      )
      
      ;; Delete all existing instances to start fresh
      foreach(inst dbGetInstByName(cv "*")
        dbDeleteObject(inst)
      )
    )
    
    ;; Check if analogLib exists and get transistor cell view template
    unless(ddGetObj("analogLib")
      rfLog("ERROR" "analogLib not found in library path. Check your Cadence setup.")
      when(cv
        dbClose(cv)
      )
      return(nil)
    )
    
    ;; Get the cell view template for nmos4 from analogLib
    cellViewId = dbOpenCellViewByType("analogLib" "nmos4" "symbol" nil "r")
    unless(cellViewId
      rfLog("ERROR" "Failed to open analogLib/nmos4/symbol cell view.")
      when(cv
        dbClose(cv)
      )
      return(nil)
    )
    
    ;; Generate a unique instance name
    ;; Using a timestamp-based ID without format conversion issues
    uniqueID = getCurrentTime()
    uniqueID = lsprintf(nil "M_%s" uniqueID)
    ;; Replace spaces and special characters with underscores
    uniqueID = lsSubst("_" " " uniqueID)
    uniqueID = lsSubst("_" ":" uniqueID)
    instanceName = uniqueID
    
    ;; Create the NMOS transistor using the cell view template with unique name
    transistorId = dbCreateInst(cv cellViewId instanceName 0:0 "R0")
    if(transistorId == nil then
      rfLog("ERROR" "Failed to create NMOS transistor instance.")
      when(cellViewId
        dbClose(cellViewId)
      )
      when(cv
        dbClose(cv)
      )
      return(nil)
    )
    
    ;; Close the cell view template
    when(cellViewId
      dbClose(cellViewId)
    )
    
    ;; Set the parameters using dbSetInstPropValue 
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
    when(cv
      dbClose(cv)
    )
    
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
;; Library Management Functions
;; =================================================================

;; Check if a library exists and prompt user to create it if missing
procedure(rfCheckLibrary(libName)
  let((libId libPath libDir form buttonId)
    ;; Try to find the library
    libId = ddGetObj(libName)
    
    ;; If library doesn't exist, prompt the user
    if(libId == nil then
      rfLog("INFO" sprintf(nil "Library %s not found. Prompting user to create it." libName))
      
      ;; Create a form to let user create the library
      form = hiCreateAppForm(
        ?name             "createLibForm"
        ?formTitle        sprintf(nil "Create Library: %s" libName)
        ?callback         nil
        ?buttonLayout     'OKCancelApply
      )

      ;; Add library name field
      hiCreateStringField(
        ?parent           form
        ?name             "libNameField"
        ?prompt           "Library Name:"
        ?value            libName
        ?editable         nil
      )
      
      ;; Add library path field - default to CDS_LIB_DIR or current dir
      libDir = getShellEnvVar("CDS_LIB_DIR")
      if(libDir == nil || !isDir(libDir) then
        libDir = getWorkingDir()
      )
      libPath = strcat(libDir "/" libName)
      
      hiCreateStringField(
        ?parent           form
        ?name             "libPathField"
        ?prompt           "Library Path:"
        ?value            libPath
        ?editable         t
      )
      
      ;; Display form and get user action
      buttonId = hiDisplayForm(form)
      
      ;; Process result based on button pressed
      if(buttonId == 1 then  ;; OK button
        ;; Get the path from the form
        libPath = hiGetStringValue(hiGetFormField(form "libPathField"))
        
        ;; Create directory if it doesn't exist
        unless(isDir(libPath)
          rfLog("INFO" sprintf(nil "Creating directory: %s" libPath))
          system(sprintf(nil "mkdir -p %s" libPath))
        )
        
        ;; Create the library
        rfLog("INFO" sprintf(nil "Creating library %s at path %s" libName libPath))
        libId = ddCreateLib(libName ?dir libPath)
        
        ;; Check if library was created successfully
        if(libId != nil then
          rfLog("INFO" sprintf(nil "Library %s created successfully" libName))
          hiDeleteForm(form)
          libId  ;; Return libId
        else
          rfLog("ERROR" sprintf(nil "Failed to create library %s" libName))
          hiDisplayModalMessage(sprintf(nil "Failed to create library %s at path %s.\nCheck permissions and path validity." libName libPath))
          hiDeleteForm(form)
          nil  ;; Return nil to indicate failure
        )
      else
        ;; User canceled
        rfLog("INFO" sprintf(nil "User canceled creation of library %s" libName))
        hiDeleteForm(form)
        nil  ;; Return nil to indicate cancelation
      )
    else
      ;; Library exists, return the ID
      libId  ;; Return libId implicitly
    )
  )
)

;; Check for missing library directories in cds.lib and offer to create them
procedure(rfCheckMissingLibraries()
  let((warnings libName libPath result)
    rfLog("INFO" "Checking for missing library directories...")
    
    ;; Get list of defined libraries using safer approach
    let((libList libPath libName)
      foreach(lib ddGetLibList()
        when(listp(lib) && length(lib) >= 2
          libName = car(lib)
          libPath = cadr(lib)
          
          ;; Skip built-in libraries
          unless(member(libName '("basic" "analogLib" "functional" "cdsDefTechLib"))
            ;; Check if directory exists
            when(stringp(libPath) && !isDir(libPath)
              rfLog("WARNING" sprintf(nil "Directory for library '%s' does not exist: %s" libName libPath))
              
              ;; Ask user if they want to create the missing directory
              result = hiDisplayYesNoDialog(
                sprintf(nil "The directory for library '%s' does not exist:\n%s\n\nDo you want to create it?" 
                        libName libPath)
              )
              
              when(result
                rfLog("INFO" sprintf(nil "Creating directory for library '%s': %s" libName libPath))
                system(sprintf(nil "mkdir -p %s" libPath))
                
                ;; Check if created successfully
                if(isDir(libPath) then
                  rfLog("INFO" sprintf(nil "Directory for library '%s' created successfully" libName))
                else
                  rfLog("ERROR" sprintf(nil "Failed to create directory for library '%s'" libName))
                )
              )
            )
          )
        )
      )
    )
    
    t  ;; Return t implicitly
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
    ;; Check for missing libraries first
    rfLog("INFO" "Checking for missing library directories in cds.lib...")
    rfCheckMissingLibraries()
    
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
