;; test_harness.il - Test harness for RF amplifier parameter sweep script
;; This emulates Cadence Virtuoso functions for testing without the actual tool

;; =================================================================
;; MOCK FUNCTIONS FOR TESTING
;; =================================================================

;; Mock time function
procedure(piGetCurrentTime()
  return("Thu Mar 20 14:30:00 2025")
)

;; Mock environment functions
procedure(getShellEnvVar(varName)
  let((mockEnv)
    mockEnv = makeTable("MockEnv" nil)
    mockEnv["RF_LIB"] = "TestRFLib"
    mockEnv["CELL_NAME"] = "test_amplifier"
    
    return(mockEnv[varName])
  )
)

;; Mock database functions
procedure(ddGetObj(libName cellName viewName)
  printf("MOCK: ddGetObj(\"%s\" \"%s\" \"%s\")\n" libName cellName viewName)
  return(nil)  ;; Always return nil to force creation
)

procedure(dbOpenCellViewByType(libName cellName viewName type mode)
  printf("MOCK: dbOpenCellViewByType(\"%s\" \"%s\" \"%s\" \"%s\" \"%s\")\n" 
          libName cellName viewName type mode)
  return(makeTable("MockCellView" nil))
)

procedure(dbCreateInst(cv libName cellName viewName location orient)
  printf("MOCK: Creating instance of %s/%s/%s\n" libName cellName viewName)
  return(makeTable("MockInstance" nil))
)

procedure(dbAddProp(obj propName type value)
  printf("MOCK: Setting property %s = %s\n" propName value)
  return(t)
)

procedure(dbCreatePin(cv_or_term name type orient location)
  printf("MOCK: Creating pin %s\n" name)
  return(makeTable("MockPin" nil))
)

procedure(dbFindNetByName(cv netName)
  printf("MOCK: Finding net %s\n" netName)
  return(nil)  ;; Force net creation
)

procedure(dbCreateNet(cv netName)
  printf("MOCK: Creating net %s\n" netName)
  return(makeTable("MockNet" nil))
)

procedure(dbGetTermByName(instId termName)
  printf("MOCK: Getting terminal %s\n" termName)
  return(makeTable("MockTerm" nil))
)

procedure(dbAddNetToPin(pin net)
  printf("MOCK: Connecting pin to net\n")
  return(t)
)

procedure(dbSave(obj)
  printf("MOCK: Saving object\n")
  return(t)
)

procedure(dbClose(obj)
  printf("MOCK: Closing object\n")
  return(t)
)

;; Mock ADE functions
procedure(asiCreateSession(libName cellName)
  printf("MOCK: Creating ADE session for %s/%s\n" libName cellName)
  return(makeTable("MockSession" nil))
)

procedure(asiAddAnalysis(session analysisType @key param)
  printf("MOCK: Adding %s analysis\n" analysisType)
  return(t)
)

procedure(asiSetSaveOption(session option value)
  printf("MOCK: Setting save option %s = %L\n" option value)
  return(t)
)

procedure(asiRun(session)
  printf("MOCK: Running simulation\n")
  return(t)
)

procedure(asiCloseSession(session)
  printf("MOCK: Closing ADE session\n")
  return(t)
)

;; Mock file operations (simplified)
procedure(outfile(filename @optional mode)
  printf("MOCK: Opening file %s for writing\n" filename)
  return("MockFileID")
)

procedure(fprintf(fileId format @rest args)
  printf("MOCK FILE WRITE: %L\n" args)
  return(t)
)

procedure(close(fileId)
  printf("MOCK: Closing file\n")
  return(t)
)

;; =================================================================
;; TEST FUNCTION
;; =================================================================

procedure(testRFSweepExample()
  printf("\n\n========== TESTING RF SWEEP EXAMPLE ==========\n\n")
  
  ;; Load the main script (assumes it's in the same directory)
  printf("Loading rf_amp_sweep.il...\n")
  loadi("rf_amp_sweep.il")
  
  ;; Run the example
  printf("\nRunning example...\n\n")
  rfSweepExample()
  
  printf("\n\n========== TEST COMPLETE ==========\n\n")
  return(t)
)

;; Automatically run the test when this file is loaded
testRFSweepExample()
