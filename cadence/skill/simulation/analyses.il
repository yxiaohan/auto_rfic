;; analyses.il - Analysis configuration for auto_rfic
;; This file contains functions for configuring and running different types of analyses

;; Define the analyses namespace
autoRficAnalyses = list(nil)

;; Function to configure AC analysis
procedure(autoRficConfigureAcAnalysis(startFreq stopFreq @optional (pointsPerDec 20))
  let(()
    autoRficLogInfo(sprintf(nil "Configuring AC analysis from %g to %g Hz" startFreq stopFreq))
    
    adeAddAnalysis(
      "ac"
      ?start startFreq
      ?stop stopFreq
      ?dec pointsPerDec
    )
    
    t
  )
)

;; Function to configure S-parameter analysis
procedure(autoRficConfigureSParameterAnalysis(startFreq stopFreq numPorts @optional (pointsPerDec 20))
  let(()
    autoRficLogInfo(sprintf(nil "Configuring S-parameter analysis from %g to %g Hz with %d ports" 
                           startFreq stopFreq numPorts))
    
    adeAddAnalysis(
      "sp"
      ?start startFreq
      ?stop stopFreq
      ?dec pointsPerDec
      ?port numPorts
    )
    
    t
  )
)

;; Function to configure transient analysis
procedure(autoRficConfigureTransientAnalysis(stopTime @optional (stepTime nil))
  let((step)
    step = if(stepTime stepTime stopTime/100.0)
    
    autoRficLogInfo(sprintf(nil "Configuring transient analysis from 0 to %g s with step %g s" 
                           stopTime step))
    
    adeAddAnalysis(
      "tran"
      ?stop stopTime
      ?step step
    )
    
    t
  )
)

;; Function to configure noise analysis
procedure(autoRficConfigureNoiseAnalysis(startFreq stopFreq outputNode inputNode @optional (pointsPerDec 20))
  let(()
    autoRficLogInfo(sprintf(nil "Configuring noise analysis from %g to %g Hz" startFreq stopFreq))
    
    adeAddAnalysis(
      "noise"
      ?start startFreq
      ?stop stopFreq
      ?dec pointsPerDec
      ?outport outputNode
      ?inport inputNode
    )
    
    t
  )
)

;; Function to configure DC analysis
procedure(autoRficConfigureDcAnalysis(parameter startValue stopValue stepValue)
  let(()
    autoRficLogInfo(sprintf(nil "Configuring DC analysis of %s from %g to %g with step %g" 
                           parameter startValue stopValue stepValue))
    
    adeAddAnalysis(
      "dc"
      ?param parameter
      ?start startValue
      ?stop stopValue
      ?step stepValue
    )
    
    t
  )
)

;; Function to configure harmonic balance analysis
procedure(autoRficConfigureHbAnalysis(fundamentalFreq @optional (numHarmonics 10))
  let(()
    autoRficLogInfo(sprintf(nil "Configuring harmonic balance analysis at %g Hz with %d harmonics" 
                           fundamentalFreq numHarmonics))
    
    adeAddAnalysis(
      "hb"
      ?fund fundamentalFreq
      ?nharm numHarmonics
    )
    
    t
  )
)

;; Function to configure PSS analysis
procedure(autoRficConfigurePssAnalysis(fundamentalFreq @optional (numHarmonics 10))
  let(()
    autoRficLogInfo(sprintf(nil "Configuring PSS analysis at %g Hz with %d harmonics" 
                           fundamentalFreq numHarmonics))
    
    adeAddAnalysis(
      "pss"
      ?fund fundamentalFreq
      ?harmNum numHarmonics
    )
    
    t
  )
)

;; Function to configure PSP analysis
procedure(autoRficConfigurePspAnalysis(startFreq stopFreq @optional (pointsPerDec 20))
  let(()
    autoRficLogInfo(sprintf(nil "Configuring PSP analysis from %g to %g Hz" startFreq stopFreq))
    
    adeAddAnalysis(
      "psp"
      ?start startFreq
      ?stop stopFreq
      ?dec pointsPerDec
    )
    
    t
  )
)

;; Function to configure Monte Carlo analysis
procedure(autoRficConfigureMonteCarloAnalysis(numRuns)
  let(()
    autoRficLogInfo(sprintf(nil "Configuring Monte Carlo analysis with %d runs" numRuns))
    
    adeAddAnalysis(
      "montecarlo"
      ?numruns numRuns
    )
    
    t
  )
)

;; Function to configure corner analysis
procedure(autoRficConfigureCornerAnalysis(corners)
  let(()
    autoRficLogInfo("Configuring corner analysis")
    
    adeAddCorners(corners)
    
    t
  )
)

;; Function to configure temperature sweep
procedure(autoRficConfigureTemperatureSweep(temperatures)
  let(()
    autoRficLogInfo(sprintf(nil "Configuring temperature sweep: %L" temperatures))
    
    adeAddTemperatures(temperatures)
    
    t
  )
)

;; Function to configure standard RF analyses
procedure(autoRficConfigureStandardRfAnalyses(startFreq stopFreq)
  let(()
    autoRficLogInfo(sprintf(nil "Configuring standard RF analyses from %g to %g Hz" startFreq stopFreq))
    
    ;; AC analysis
    autoRficConfigureAcAnalysis(startFreq stopFreq)
    
    ;; S-parameter analysis
    autoRficConfigureSParameterAnalysis(startFreq stopFreq 2)
    
    ;; Noise analysis
    autoRficConfigureNoiseAnalysis(startFreq stopFreq "OUT" "IN")
    
    ;; PSS/PSP for nonlinear RF analysis
    autoRficConfigurePssAnalysis(startFreq)
    autoRficConfigurePspAnalysis(startFreq stopFreq)
    
    t
  )
)

;; Add all analyses functions to the namespace
autoRficAnalyses = append(autoRficAnalyses list(
  'configureAc autoRficConfigureAcAnalysis
  'configureSParameter autoRficConfigureSParameterAnalysis
  'configureTransient autoRficConfigureTransientAnalysis
  'configureNoise autoRficConfigureNoiseAnalysis
  'configureDc autoRficConfigureDcAnalysis
  'configureHb autoRficConfigureHbAnalysis
  'configurePss autoRficConfigurePssAnalysis
  'configurePsp autoRficConfigurePspAnalysis
  'configureMonteCarlo autoRficConfigureMonteCarloAnalysis
  'configureCorner autoRficConfigureCornerAnalysis
  'configureTemperature autoRficConfigureTemperatureSweep
  'configureStandardRf autoRficConfigureStandardRfAnalyses
))

;; Export the analyses namespace
autoRficAnalyses
