;; default_config.il - Default configuration settings for auto_rfic
;; This file contains the default configuration parameters for the auto_rfic system.
;; Users should not modify this file directly, but instead create or modify user_config.il

;; Define the default configuration namespace
autoRficDefaultConfig = list(nil)

;; General settings
autoRficDefaultConfig = append(autoRficDefaultConfig list(
  'projectName "auto_rfic"
  'projectVersion "1.0.0"
  'logLevel "info"  ; Possible values: debug, info, warning, error
  'logFile "auto_rfic.log"
  'backupEnabled t
  'backupInterval 15  ; minutes
))

;; Library settings
autoRficDefaultConfig = append(autoRficDefaultConfig list(
  'designLibrary "auto_rfic_designs"
  'templateLibrary "auto_rfic_templates"
  'technologyLibrary "auto_rfic_tech"
  'simulationLibrary "auto_rfic_sim"
))

;; Simulation settings
autoRficDefaultConfig = append(autoRficDefaultConfig list(
  'defaultSimulator "spectre"
  'defaultAnalysisType "ac"
  'defaultTemperature 27.0
  'cornerAnalysisEnabled t
  'monteCarloCycles 100
  'parallelSimulations 4
))

;; Layout settings
autoRficDefaultConfig = append(autoRficDefaultConfig list(
  'defaultFloorplanStrategy "compact"
  'symmetryEnforcement t
  'shieldingEnabled t
  'routingStrategy "performance"  ; Possible values: performance, density, balanced
  'emAwareLayout t
))

;; Optimization settings
autoRficDefaultConfig = append(autoRficDefaultConfig list(
  'optimizationAlgorithm "gradient"  ; Possible values: gradient, genetic, montecarlo
  'maxIterations 50
  'convergenceThreshold 0.001
  'multiObjectiveMethod "pareto"  ; Possible values: pareto, weighted
))

;; Export the default configuration
autoRficDefaultConfig
