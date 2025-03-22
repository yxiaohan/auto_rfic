;; results.il - Results processing for auto_rfic
;; This file contains functions for processing and analyzing simulation results

;; Initialize the results namespace
unless(boundp('autoRficResults)
    autoRficResults = makeTable("results" nil)
)

;; Function to get a list of plot names from a result directory
procedure(autoRficGetPlotNames(resultsDir)
    let((plotList)
        plotList = ddGetFamilies(resultsDir)
        plotList
    )
)

;; Function to get signals from a plot
procedure(autoRficGetSignalNames(resultsDir plotName)
    let((signalList)
        signalList = ddGetWaveNames(resultsDir plotName)
        signalList
    )
)

;; Function to extract value from a result signal
procedure(autoRficGetSignalValue(resultsDir plotName signalName @optional (index 0))
    let((value waveform)
        waveform = ddGetWave(resultsDir plotName signalName)
        value = nth(index waveform->value)
        value
    )
)

;; Function to get a complete signal data as X-Y pairs
procedure(autoRficGetSignalData(resultsDir plotName signalName)
    let((wave data)
        wave = ddGetWave(resultsDir plotName signalName)
        data = list(wave->x wave->value)
        data
    )
)

;; Function to get S-parameters from simulation results
procedure(autoRficGetSParameters(resultsDir)
    let((sParams freq)
        ;; Get frequency points
        freq = ddGetWave(resultsDir "sp" "freq")
        
        ;; Extract S-parameters
        sParams = makeTable("sparams" nil)
        sParams['freq] = freq->value
        sParams['s11] = ddGetWave(resultsDir "sp" "S11")
        sParams['s12] = ddGetWave(resultsDir "sp" "S12")
        sParams['s21] = ddGetWave(resultsDir "sp" "S21")
        sParams['s22] = ddGetWave(resultsDir "sp" "S22")
        
        sParams
    )
)

;; Function to get noise analysis results
procedure(autoRficGetNoiseResults(resultsDir)
    let((noiseData freq)
        ;; Get frequency points
        freq = ddGetWave(resultsDir "noise" "freq")
        
        ;; Extract noise data
        noiseData = makeTable("noise" nil)
        noiseData['freq] = freq->value
        noiseData['nf] = ddGetWave(resultsDir "noise" "nf")
        noiseData['sourceNoise] = ddGetWave(resultsDir "noise" "inoise")
        noiseData['outputNoise] = ddGetWave(resultsDir "noise" "onoise")
        
        noiseData
    )
)

;; Function to get PSS/HB results
procedure(autoRficGetPeriodic(resultsDir analysisType)
    let((periodicData)
        periodicData = makeTable("periodic" nil)
        
        ;; Get time/frequency domain data based on analysis type
        case(analysisType
            ("pss"
                ;; Time domain waveforms
                periodicData['time] = ddGetWave(resultsDir "pss" "time")->value
                periodicData['v] = ddGetWave(resultsDir "pss" "v")->value
                periodicData['i] = ddGetWave(resultsDir "pss" "i")->value
            )
            ("hb"
                ;; Frequency components
                periodicData['freq] = ddGetWave(resultsDir "hb" "freq")->value
                periodicData['vFreq] = ddGetWave(resultsDir "hb" "vf")->value
                periodicData['iFreq] = ddGetWave(resultsDir "hb" "if")->value
            )
        )
        
        periodicData
    )
)

;; Main function to get simulation results
procedure(autoRficGetSimResults(testbench @optional (analysisType nil))
    let((state results resultsDir plotNames)
        ;; Get ADE state for testbench
        state = adeGetState(testbench->libName testbench->cellName)
        unless(state
            autoRficLogError("Failed to get ADE state")
            return(nil)
        )
        
        ;; Get results directory
        resultsDir = adeGetResultsDir(state)
        unless(resultsDir
            autoRficLogError("No simulation results found")
            return(nil)
        )
        
        ;; Initialize results table
        results = makeTable("sim_results" nil)
        results['plotNames] = autoRficGetPlotNames(resultsDir)
        
        ;; Extract results based on analysis type
        if(analysisType then
            case(analysisType
                ("sp"
                    results['sparam] = autoRficGetSParameters(resultsDir)
                )
                ("noise"
                    results['noise] = autoRficGetNoiseResults(resultsDir)
                )
                ("pss"
                    results['pss] = autoRficGetPeriodic(resultsDir "pss")
                )
                ("hb"
                    results['hb] = autoRficGetPeriodic(resultsDir "hb")
                )
                (t
                    autoRficLogError(sprintf(nil "Unknown analysis type: %s" analysisType))
                )
            )
        else
            ;; Get all available results
            foreach(plotName results['plotNames]
                results[plotName] = list()
                foreach(signal autoRficGetSignalNames(resultsDir plotName)
                    results[plotName] = append(
                        results[plotName]
                        list(signal autoRficGetSignalData(resultsDir plotName signal))
                    )
                )
            )
        )
        
        results
    )
)

;; Function to extract a specific output signal from results
procedure(autoRficExtractSignal(results signalName)
  let((signal)
    signal = adeGetSignalFromResults(results signalName)
    if(signal
      prog(()
        autoRficLogInfo(sprintf(nil "Extracted signal: %s" signalName))
        signal
      )
      prog(()
        autoRficLogError(sprintf(nil "Signal not found in results: %s" signalName))
        nil
      )
    )
  )
)

;; Function to calculate gain from S-parameters
procedure(autoRficCalculateGain(results)
  let((s21)
    s21 = adeGetSignalFromResults(results "S21")
    if(s21
      prog(()
        ;; Convert S21 to dB
        s21dB = 20 * log10(abs(s21))
        autoRficLogInfo("Calculated gain from S21")
        s21dB
      )
      prog(()
        autoRficLogError("S21 not found in results")
        nil
      )
    )
  )
)

;; Function to calculate noise figure
procedure(autoRficCalculateNoiseFigure(results)
  let((nf)
    nf = adeGetSignalFromResults(results "NF")
    if(nf
      prog(()
        autoRficLogInfo("Retrieved noise figure")
        nf
      )
      prog(()
        autoRficLogError("Noise figure not found in results")
        nil
      )
    )
  )
)

;; Function to calculate input impedance
procedure(autoRficCalculateInputImpedance(results)
  let((s11 z0 zin)
    s11 = adeGetSignalFromResults(results "S11")
    if(s11
      prog(()
        ;; Assume 50 ohm reference impedance
        z0 = 50.0
        
        ;; Calculate input impedance from S11
        zin = z0 * (1 + s11) / (1 - s11)
        
        autoRficLogInfo("Calculated input impedance")
        zin
      )
      prog(()
        autoRficLogError("S11 not found in results")
        nil
      )
    )
  )
)

;; Function to calculate power consumption
procedure(autoRficCalculatePowerConsumption(results)
  let((vddNode vddCurrent power)
    vddCurrent = adeGetSignalFromResults(results "VDD:p")
    if(vddCurrent
      prog(()
        ;; Get VDD voltage from parameters
        vdd = autoRficGetParameter('vddVoltage 1.8)
        
        ;; Calculate power
        power = vdd * abs(vddCurrent)
        
        autoRficLogInfo(sprintf(nil "Calculated power consumption: %g W" power))
        power
      )
      prog(()
        autoRficLogError("VDD current not found in results")
        nil
      )
    )
  )
)

;; Function to calculate 1dB compression point
procedure(autoRficCalculate1dBCompressionPoint(results)
  let((pout pin p1dB)
    pout = adeGetSignalFromResults(results "Pout")
    pin = adeGetSignalFromResults(results "Pin")
    
    if(and pout pin
      prog(()
        ;; Convert to dB
        poutdB = 10 * log10(pout)
        pindB = 10 * log10(pin)
        
        ;; Find small-signal gain
        smallSignalGain = car(poutdB) - car(pindB)
        
        ;; Find where gain drops by 1dB
        for(i 1 length(poutdB)
          when((car(poutdB) - car(pindB)) < (smallSignalGain - 1.0)
            p1dB = nth(i pindB)
            return()
          )
        )
        
        autoRficLogInfo(sprintf(nil "Calculated 1dB compression point: %g dBm" p1dB))
        p1dB
      )
      prog(()
        autoRficLogError("Output or input power not found in results")
        nil
      )
    )
  )
)

;; Function to calculate IIP3 (Third-order Input Intercept Point)
procedure(autoRficCalculateIIP3(results)
  let((fund im3 iip3)
    fund = adeGetSignalFromResults(results "fund_pwr")
    im3 = adeGetSignalFromResults(results "im3_pwr")
    
    if(and fund im3
      prog(()
        ;; Convert to dB
        funddB = 10 * log10(fund)
        im3dB = 10 * log10(im3)
        
        ;; Calculate IIP3
        iip3 = funddB + (funddB - im3dB) / 2
        
        autoRficLogInfo(sprintf(nil "Calculated IIP3: %g dBm" iip3))
        iip3
      )
      prog(()
        autoRficLogError("Fundamental or IM3 power not found in results")
        nil
      )
    )
  )
)

;; Function to export results to a CSV file
procedure(autoRficExportResultsToCsv(results fileName)
  let((fileId signals)
    fileId = outfile(fileName)
    if(fileId
      prog(()
        ;; Get all signal names
        signals = adeGetSignalNamesFromResults(results)
        
        ;; Write header
        fprintf(fileId "Frequency")
        foreach(signal signals
          fprintf(fileId ",%s" signal)
        )
        fprintf(fileId "\n")
        
        ;; Write data
        freq = adeGetSignalFromResults(results "freq")
        for(i 1 length(freq)
          fprintf(fileId "%g" nth(i freq))
          foreach(signal signals
            data = adeGetSignalFromResults(results signal)
            fprintf(fileId ",%g" nth(i data))
          )
          fprintf(fileId "\n")
        )
        
        close(fileId)
        autoRficLogInfo(sprintf(nil "Exported results to CSV: %s" fileName))
        t
      )
      prog(()
        autoRficLogError(sprintf(nil "Failed to open file for writing: %s" fileName))
        nil
      )
    )
  )
)

;; Function to generate a performance report
procedure(autoRficGeneratePerformanceReport(results specs)
  let((report)
    autoRficLogInfo("Generating performance report")
    
    report = list(nil)
    
    ;; Calculate gain
    gain = autoRficCalculateGain(results)
    when(gain
      report = append(report list(
        'gain gain
        'gainPass if(gain > specs->minGain t nil)
      ))
    )
    
    ;; Calculate noise figure
    nf = autoRficCalculateNoiseFigure(results)
    when(nf
      report = append(report list(
        'noiseFigure nf
        'nfPass if(nf < specs->maxNF t nil)
      ))
    )
    
    ;; Calculate power consumption
    power = autoRficCalculatePowerConsumption(results)
    when(power
      report = append(report list(
        'power power
        'powerPass if(power < specs->maxPower t nil)
      ))
    )
    
    ;; Calculate input impedance
    zin = autoRficCalculateInputImpedance(results)
    when(zin
      zinMag = abs(zin)
      report = append(report list(
        'inputImpedance zinMag
        'zinPass if(and (zinMag > specs->minZin) (zinMag < specs->maxZin) t nil)
      ))
    )
    
    ;; Overall pass/fail
    allTests = list(
      report->gainPass
      report->nfPass
      report->powerPass
      report->zinPass
    )
    
    report = append(report list(
      'overallPass if(forall(x allTests x) t nil)
    ))
    
    autoRficLogInfo(sprintf(nil "Performance report generated, overall pass: %L" report->overallPass))
    
    report
  )
)

;; Add core functions to namespace first
when(boundp('autoRficResults)
    autoRficResults['getPlotNames] = 'autoRficGetPlotNames
    autoRficResults['getSignalNames] = 'autoRficGetSignalNames
    autoRficResults['getSignalValue] = 'autoRficGetSignalValue
    autoRficResults['getSignalData] = 'autoRficGetSignalData
    autoRficResults['getSParameters] = 'autoRficGetSParameters
    autoRficResults['getNoiseResults] = 'autoRficGetNoiseResults
    autoRficResults['getPeriodic] = 'autoRficGetPeriodic
    autoRficResults['get] = 'autoRficGetSimResults
    autoRficResults['getResults] = 'autoRficGetSimResults  ; Alias for backward compatibility
    
    ;; Add analysis functions to namespace using pairlis to create alist
    autoRficResults = append(autoRficResults 
        pairlis(
            '(extractSignal calculateGain calculateNoiseFigure calculateInputImpedance
              calculatePowerConsumption calculate1dBCompressionPoint calculateIIP3
              exportToCsv generateReport)
            '(autoRficExtractSignal autoRficCalculateGain autoRficCalculateNoiseFigure
              autoRficCalculateInputImpedance autoRficCalculatePowerConsumption
              autoRficCalculate1dBCompressionPoint autoRficCalculateIIP3
              autoRficExportResultsToCsv autoRficGeneratePerformanceReport)
        )
    )
)

;; Export the results namespace
autoRficResults
