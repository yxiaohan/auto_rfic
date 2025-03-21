;; user_config.il - User-specific configuration overrides
;; This file contains user-specific configuration overrides for auto_rfic.
;; Values defined here will override those in default_config.il

;; Define the user configuration namespace
autoRficUserConfig = list(nil)

;; Override any default settings as needed
;; Example:
;; autoRficUserConfig = append(autoRficUserConfig list(
;;   'logLevel "debug"
;;   'backupInterval 30
;; ))

;; User-specific library paths
autoRficUserConfig = append(autoRficUserConfig list(
  'userWorkDir getShellEnvVar("HOME")
  'userLibraryPath strcat(getShellEnvVar("HOME") "/cadence/libraries")
))

;; Export the user configuration
autoRficUserConfig
