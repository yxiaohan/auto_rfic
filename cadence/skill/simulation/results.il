;; results.il - Results processing for auto_rfic
;; This file contains functions for processing and analyzing simulation results

;; Define the results namespace
autoRficResults = list(nil)

;; Function to get the current simulation results
procedure(autoRficGetSimResults()
  let((results)
    results = adeGetResults()
    if(results
      prog(()
        autoRficLogInfo("Retrieved simulation results")
        results
      )
      prog(()
        autoRficLogError("No simulation results available")
        nil
      )
    )
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

;; Add all results functions to the namespace
autoRficResults = append(autoRficResults list(
  'getResults autoRficGetSimResults
  'extractSignal autoRficExtractSignal
  'calculateGain autoRficCalculateGain
  'calculateNoiseFigure autoRficCalculateNoiseFigure
  'calculateInputImpedance autoRficCalculateInputImpedance
  'calculatePowerConsumption autoRficCalculatePowerConsumption
  'calculate1dBCompressionPoint autoRficCalculate1dBCompressionPoint
  'calculateIIP3 autoRficCalculateIIP3
  'exportToCsv autoRficExportResultsToCsv
  'generateReport autoRficGeneratePerformanceReport
))

;; Export the results namespace
autoRficResults
