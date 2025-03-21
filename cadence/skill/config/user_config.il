;; user_config.il - User-specific configuration overrides for auto_rfic framework

;; Initialize user configuration table
unless(boundp('autoRficUserConfig)
    setq(autoRficUserConfig makeTable("userConfig" nil))
)

;; Example of how to override default settings:
;;
;; let((result)
;;     ;; Override system settings
;;     autoRficConfig["logLevel"] = "DEBUG"
;;     
;;     ;; Override design settings
;;     autoRficConfig["designLibrary"] = "myRficLib"
;;     
;;     ;; Override RF settings
;;     autoRficConfig["rfBandStart"] = 2.4  ; GHz
;;     autoRficConfig["rfBandStop"] = 2.5   ; GHz
;;     
;;     result = t
;;     result
;; )

;; Your configuration overrides go here:
let((result)
    ;; Set user-specific paths and configurations
    autoRficUserConfig["userWorkDir"] = getShellEnvVar("HOME")
    autoRficUserConfig["userLibraryPath"] = strcat(getShellEnvVar("HOME") "/cadence/libraries")
    
    ;; Add any user-specific overrides to main config
    autoRficConfig["userSettings"] = autoRficUserConfig
    
    result = t
    result
)
