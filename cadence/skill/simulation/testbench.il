;; testbench.il - Test bench setup for auto_rfic
;; This file contains functions for creating and configuring simulation test benches

;; Initialize the testbench namespace
unless(boundp('autoRficTestbench)
    autoRficTestbench = makeTable("testbench" nil)
)

;; Function to create a simulation testbench from a schematic
procedure(autoRficCreateTestbench(schematic)
    let((cv testbenchName sourceCv sourceLib sourceCell result)
        ;; Handle both string and dbObject inputs
        sourceCv = if(stringp(schematic) then
            dbOpenCellViewByType(
                autoRficGetParameter('designLibrary "autoRfic")
                schematic
                "schematic"
                nil
                "r"
            )
            schematic
        )
        
        unless(sourceCv
            autoRficLogError("Invalid schematic")
            return(nil)
        )
        
        ;; Get source details
        sourceLib = sourceCv->libName
        sourceCell = sourceCv->cellName
        testbenchName = strcat(sourceCell "_tb")
        
        ;; Create testbench cellview
        cv = dbOpenCellViewByType(
            sourceLib
            testbenchName
            "schematic"
            "schematic"
            "w"
        )
        
        when(cv
            ;; Add the design under test
            let((dutInst)
                dutInst = dbCreateInst(
                    cv
                    sourceLib
                    sourceCell
                    "schematic"
                    list(0:0)
                    "R0"
                    1
                )
                
                ;; Add pins for each terminal
                foreach(term sourceCv->terminals
                    let((pinName pinDir net)
                        pinName = term->name
                        pinDir = term->direction
                        
                        ;; Create net and pin
                        net = dbCreateNet(cv pinName)
                        dbCreatePin(
                            cv
                            net
                            pinName
                            pinDir
                            list(list(-100:0 -90:0))  ; Default pin location
                        )
                        
                        ;; Connect pin to DUT
                        schCreateWire(
                            cv
                            "route"
                            "full"
                            list(
                                dbGetInstTermPoint(dutInst pinName)
                                dbGetPinLoc(net->pins)
                            )
                            0.1
                        )
                    )
                )
                
                ;; Add standard testbench components
                let((yo 0)  ; Vertical offset for components
                    foreach(term sourceCv->terminals
                        case(term->purpose
                            ("input"
                                ;; Add voltage source
                                dbCreateParamInst(
                                    cv
                                    "analogLib"
                                    "vsin"
                                    "symbol"
                                    strcat("V_" term->name)
                                    list(-200:(yo = yo + 100))
                                    "R0"
                                    1
                                    list(
                                        list("vdc" "0")
                                        list("va" "1")
                                        list("freq" "1G")
                                    )
                                )
                            )
                            ("output"
                                ;; Add load resistor
                                dbCreateParamInst(
                                    cv
                                    "analogLib"
                                    "res"
                                    "symbol"
                                    strcat("R_" term->name)
                                    list(200:(yo = yo + 100))
                                    "R0"
                                    1
                                    list(list("r" "50"))
                                )
                            )
                        )
                    )
                )
                
                ;; Add ground connections
                dbCreateInst(
                    cv
                    "analogLib"
                    "gnd"
                    "symbol"
                    list(0:-100)
                    "R0"
                    1
                )
                
                ;; Save testbench
                dbSave(cv)
                when(sourceLib != sourceLib
                    dbClose(sourceCv)
                )
                dbClose(cv)
                
                ;; Create ADE state
                unless(createADEState(cv)
                    autoRficLogError("Failed to create ADE state")
                    return(nil)
                )
                
                autoRficLogInfo(sprintf(nil "Created testbench: %s" testbenchName))
                result = cv
            )
            result
        )
    )
)

;; Function to create an ADE state for a testbench
procedure(createADEState(testbench)
    let((state result)
        ;; Create ADE state
        state = adeCreateState(
            testbench->libName
            testbench->cellName
            "schematic"
        )
        
        when(state
            ;; Set up default analyses
            adePutParameter(state 'temp autoRficGetParameter('defaultTemp 27.0))
            
            ;; Enable corners if configured
            when(autoRficGetParameter('defaultCornersEnabled t)
                adeEnableCorners(state)
            )
            
            ;; Save state
            adeSaveState(state)
            result = t
        )
        result
    )
)

;; Function to configure a specific analysis in ADE
procedure(autoRficConfigureAnalysis(state analysisType analysisParams)
    case(analysisType
        ("ac"
            adeAddAnalysis(state "ac"
                ?start analysisParams->start
                ?stop analysisParams->stop
                ?dec analysisParams->dec
            )
        )
        ("tran"
            adeAddAnalysis(state "tran"
                ?stop analysisParams->stop
                ?step analysisParams->step
            )
        )
        ("dc"
            adeAddAnalysis(state "dc"
                ?param analysisParams->param
                ?start analysisParams->start
                ?stop analysisParams->stop
                ?step analysisParams->step
            )
        )
        ("sp"
            adeAddAnalysis(state "sp"
                ?start analysisParams->start
                ?stop analysisParams->stop
                ?dec analysisParams->dec
                ?port analysisParams->port
            )
        )
        ("noise"
            adeAddAnalysis(state "noise"
                ?start analysisParams->start
                ?stop analysisParams->stop
                ?dec analysisParams->dec
                ?outport analysisParams->outport
                ?inport analysisParams->inport
            )
        )
        ("hb"
            adeAddAnalysis(state "hb"
                ?fund analysisParams->fund
                ?nharm analysisParams->nharm
            )
        )
        (t
            autoRficLogError(sprintf(nil "Unknown analysis type: %s" analysisType))
            nil
        )
    )
)

;; Function to create a complete RF testbench with common analyses
procedure(autoRficCreateRfTestbench(schematic)
    let((cv state params)
        ;; Create base testbench
        cv = autoRficCreateTestbench(schematic)
        unless(cv return(nil))
        
        ;; Get ADE state
        state = adeGetState(cv->libName cv->cellName)
        unless(state return(nil))
        
        ;; Configure standard RF analyses
        params = list(
            'start 100e6  ; 100MHz
            'stop 10e9    ; 10GHz
            'dec 20       ; Points per decade
            'port 2       ; Two-port analysis
        )
        
        ;; Add S-parameter analysis
        autoRficConfigureAnalysis(state "sp" params)
        
        ;; Add noise analysis
        autoRficConfigureAnalysis(state "noise" params)
        
        ;; Save state
        adeSaveState(state)
        cv
    )
)

;; Add testbench functions to namespace
when(boundp('autoRficTestbench)
    autoRficTestbench['create] = 'autoRficCreateTestbench
    autoRficTestbench['createRf] = 'autoRficCreateRfTestbench
    autoRficTestbench['configureAnalysis] = 'autoRficConfigureAnalysis
)

;; Export the testbench namespace
autoRficTestbench
