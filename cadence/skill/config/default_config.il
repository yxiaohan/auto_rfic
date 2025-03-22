;; default_config.il - Default configuration settings for auto_rfic framework

;; Set framework configuration parameters
let((result)
    ;; System settings - ensure logging is set up first
    when(boundp('autoRficLogging)
        autoRficConfig["logLevel"] = "INFO"
    )
    
    ;; Base directory settings
    autoRficConfig["baseDir"] = getShellEnvVar("AUTO_RFIC_DIR")
    when(autoRficConfig["baseDir"]
        autoRficConfig["logFile"] = strcat(autoRficConfig["baseDir"] "/logs/auto_rfic.log")
    )
    
    ;; Design settings
    autoRficConfig["technology"] = getShellEnvVar("TSMC_PDK")
    autoRficConfig["designLibrary"] = "autoRfic"
    autoRficConfig["defaultView"] = "schematic"
    
    ;; RF settings
    autoRficConfig["defaultFreqUnit"] = "GHz"
    autoRficConfig["rfBandStart"] = 1.0  ; GHz
    autoRficConfig["rfBandStop"] = 5.0   ; GHz
    
    ;; Analysis settings
    autoRficConfig["defaultTemp"] = 27.0  ; Celsius
    autoRficConfig["defaultAnalysisPoints"] = 101
    autoRficConfig["defaultCornersEnabled"] = t
    
    ;; Layout settings
    autoRficConfig["minMetalWidth"] = 0.1  ; um
    autoRficConfig["metalLayers"] = list("M1" "M2" "M3" "M4" "M5" "M6" "M7" "M8" "M9")
    autoRficConfig["topMetalLayer"] = "M9"
    
    result = t
    result
)
