;; testbench.il - Test bench setup for auto_rfic
;; This file contains functions for creating and configuring simulation test benches

;; Define the testbench namespace
autoRficTestbench = list(nil)

;; Function to create a new test bench for a design
procedure(autoRficCreateTestbench(designLib designCell @optional (testbenchName nil))
  let((tbName tbLib tbCell cv)
    ;; Generate test bench name if not provided
    tbName = if(testbenchName 
               testbenchName 
               strcat(designCell "_tb"))
    
    ;; Use the same library as the design
    tbLib = designLib
    tbCell = tbName
    
    autoRficLogInfo(sprintf(nil "Creating test bench %s for design %s" tbCell designCell))
    
    ;; Create test bench schematic
    cv = dbOpenCellViewByType(
      tbLib
      tbCell
      "schematic"
      "schematic"
      "w"
    )
    
    when(cv
      ;; Create instance of design under test
      dbCreateInst(
        cv
        dbOpenCellViewByType(designLib designCell "symbol")
        "I0"
        list(0:0)
        "R0"
        1
      )
      
      ;; Add power supplies
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "vdc" "symbol")
        "VDD"
        list(-100:100)
        "R0"
        1
        list(list("vdc" "1.8"))
      )
      
      ;; Add ground
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "gnd" "symbol")
        "GND"
        list(0:-100)
        "R0"
        1
      )
      
      ;; Add input stimulus
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "vsin" "symbol")
        "VIN"
        list(-100:0)
        "R0"
        1
        list(
          list("freq" "1G")
          list("amplitude" "0.1")
        )
      )
      
      ;; Add output load
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "res" "symbol")
        "RLOAD"
        list(100:0)
        "R0"
        1
        list(list("r" "50"))
      )
      
      ;; Save and close
      dbSave(cv)
      dbClose(cv)
      
      autoRficLogInfo(sprintf(nil "Created test bench: %s" tbCell))
      tbCell
    )
  )
)

;; Function to create an ADE state for a test bench
procedure(autoRficCreateAdeState(testbenchLib testbenchCell @optional (stateName nil))
  let((adeName)
    ;; Generate ADE state name if not provided
    adeName = if(stateName 
                stateName 
                strcat(testbenchCell "_state"))
    
    autoRficLogInfo(sprintf(nil "Creating ADE state %s for test bench %s" adeName testbenchCell))
    
    ;; Create ADE state
    adeCreateADEState(
      testbenchLib
      testbenchCell
      "schematic"
      adeName
    )
    
    ;; Open ADE
    adeOpenADEState(
      testbenchLib
      testbenchCell
      "schematic"
      adeName
    )
    
    adeName
  )
)

;; Function to configure a specific analysis in ADE
procedure(autoRficConfigureAnalysis(analysisType analysisParams)
  let(()
    autoRficLogInfo(sprintf(nil "Configuring %s analysis" analysisType))
    
    case(analysisType
      ("ac"
        adeAddAnalysis(
          "ac"
          ?start analysisParams->start
          ?stop analysisParams->stop
          ?dec analysisParams->dec
        )
      )
      ("tran"
        adeAddAnalysis(
          "tran"
          ?stop analysisParams->stop
          ?step analysisParams->step
        )
      )
      ("dc"
        adeAddAnalysis(
          "dc"
          ?param analysisParams->param
          ?start analysisParams->start
          ?stop analysisParams->stop
          ?step analysisParams->step
        )
      )
      ("sp"
        adeAddAnalysis(
          "sp"
          ?start analysisParams->start
          ?stop analysisParams->stop
          ?dec analysisParams->dec
          ?port analysisParams->port
        )
      )
      ("noise"
        adeAddAnalysis(
          "noise"
          ?start analysisParams->start
          ?stop analysisParams->stop
          ?dec analysisParams->dec
          ?outport analysisParams->outport
          ?inport analysisParams->inport
        )
      )
      ("hb"
        adeAddAnalysis(
          "hb"
          ?fund analysisParams->fund
          ?nharm analysisParams->nharm
        )
      )
      (t
        autoRficLogError(sprintf(nil "Unknown analysis type: %s" analysisType))
      )
    )
    
    t
  )
)

;; Function to add output signals to ADE
procedure(autoRficAddOutputs(outputs)
  let(()
    foreach(output outputs
      adeAddOutput(output)
    )
    t
  )
)

;; Function to run a simulation
procedure(autoRficRunSimulation()
  let((results)
    autoRficLogInfo("Running simulation")
    
    ;; Run the simulation
    adeRun()
    
    ;; Wait for simulation to complete
    while(adeIsRunning()
      sleep(1)
    )
    
    autoRficLogInfo("Simulation completed")
    t
  )
)

;; Function to create a complete test bench with common RF analyses
procedure(autoRficCreateRfTestbench(designLib designCell freqStart freqStop)
  let((tbCell adeName)
    ;; Create test bench
    tbCell = autoRficCreateTestbench(designLib designCell)
    
    ;; Create ADE state
    adeName = autoRficCreateAdeState(designLib tbCell)
    
    ;; Configure analyses
    
    ;; AC analysis
    autoRficConfigureAnalysis(
      "ac"
      list(
        'start freqStart
        'stop freqStop
        'dec 20
      )
    )
    
    ;; S-parameter analysis
    autoRficConfigureAnalysis(
      "sp"
      list(
        'start freqStart
        'stop freqStop
        'dec 20
        'port 2
      )
    )
    
    ;; Noise analysis
    autoRficConfigureAnalysis(
      "noise"
      list(
        'start freqStart
        'stop freqStop
        'dec 20
        'outport "OUT"
        'inport "IN"
      )
    )
    
    ;; Add outputs
    autoRficAddOutputs(
      list(
        "OUT"
        "IN"
        "VDD:p"
      )
    )
    
    ;; Save ADE state
    adeSave()
    
    list(
      'testbench tbCell
      'adeState adeName
    )
  )
)

;; Add all testbench functions to the namespace
autoRficTestbench = append(autoRficTestbench list(
  'create autoRficCreateTestbench
  'createAdeState autoRficCreateAdeState
  'configureAnalysis autoRficConfigureAnalysis
  'addOutputs autoRficAddOutputs
  'runSimulation autoRficRunSimulation
  'createRfTestbench autoRficCreateRfTestbench
))

;; Export the testbench namespace
autoRficTestbench
