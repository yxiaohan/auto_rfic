;; optimizer.il - Parameter optimization for auto_rfic
;; This file contains functions for optimizing schematic parameters

;; Initialize the optimizer namespace
unless(boundp('autoRficOptimizer)
    autoRficOptimizer = makeTable("optimizer" nil)
)

;; Function to perform a parameter sweep
procedure(autoRficSweepParameter(schematic paramName start stop step)
    let((cv paramType result results currentValue)
        ;; Get cellview and validate parameter type
        cv = if(stringp(schematic) then
            dbOpenCellViewByType(
                autoRficGetParameter('designLibrary "autoRfic")
                schematic
                "schematic"
                nil
                "r"
            )
            schematic
        )
        
        unless(cv
            autoRficLogError("Invalid schematic")
            return(nil)
        )
        
        ;; Initialize results table
        results = makeTable("sweep_results" nil)
        currentValue = start
        
        ;; Store sweep configuration
        results['paramName] = paramName
        results['start] = start
        results['stop] = stop
        results['step] = step
        results['values] = list()
        results['metrics] = list()
        
        ;; Perform sweep
        while(currentValue <= stop
            ;; Update parameter
            autoRficLogInfo(sprintf(nil "Sweeping %s = %g" paramName currentValue))
            
            ;; Create analysis for current value
            when(tbCreateTestbench(cv)
                ;; Set parameter value in testbench
                let((testbench)
                    testbench = tbGetTestbench(cv)
                    tbSetParameter(testbench paramName currentValue)
                    
                    ;; Run simulation and collect results
                    result = tbRunSimulation(testbench)
                    when(result
                        ;; Store value and results
                        results['values] = append(results['values] list(currentValue))
                        results['metrics] = append(results['metrics] list(result))
                    )
                )
            )
            
            ;; Increment value
            currentValue = currentValue + step
        )
        
        ;; Generate sweep report
        autoRficLogInfo(sprintf(nil "Parameter sweep complete for %s" paramName))
        results
    )
)

;; Function to perform gradient descent optimization
procedure(autoRficGradientOptimize(paramNames initialValues stepSizes evaluationFunc 
                                  @optional (maxIterations 20) (convergenceThreshold 0.001))
  let((currentValues bestValues bestResult iteration converged results gradients)
    autoRficLogInfo("Starting gradient descent optimization")
    
    ;; Initialize values
    currentValues = initialValues
    bestValues = initialValues
    bestResult = evaluationFunc(initialValues)
    iteration = 0
    converged = nil
    results = list(list(iteration bestValues bestResult))
    
    ;; Create progress bar
    progressBar = autoRficCreateProgressBar(
      "Gradient Optimization"
      maxIterations
    )
    
    ;; Perform optimization iterations
    while(and !converged iteration < maxIterations
      let((improved)
        ;; Update progress bar
        autoRficUpdateProgressBar(
          progressBar
          iteration
          sprintf(nil "Iteration %d, current result: %g" iteration bestResult)
        )
        
        ;; Compute gradients for each parameter
        gradients = foreach(mapcar paramName paramNames
          let((idx currentValue stepSize plusValue minusValue plusResult minusResult gradient)
            idx = position(paramName paramNames)
            currentValue = nth(idx currentValues)
            stepSize = nth(idx stepSizes)
            
            ;; Evaluate at plus step
            plusValue = currentValue + stepSize
            currentValues = replaceItem(plusValue idx currentValues)
            plusResult = evaluationFunc(currentValues)
            
            ;; Evaluate at minus step
            minusValue = currentValue - stepSize
            currentValues = replaceItem(minusValue idx currentValues)
            minusResult = evaluationFunc(currentValues)
            
            ;; Restore current value
            currentValues = replaceItem(currentValue idx currentValues)
            
            ;; Compute gradient
            gradient = (plusResult - minusResult) / (2 * stepSize)
            
            list(paramName gradient)
          )
        )
        
        ;; Update parameters based on gradients
        improved = nil
        foreach(gradient gradients
          let((paramName gradValue idx currentValue newValue)
            paramName = car(gradient)
            gradValue = cadr(gradient)
            idx = position(paramName paramNames)
            currentValue = nth(idx currentValues)
            stepSize = nth(idx stepSizes)
            
            ;; Update in the direction of the gradient
            newValue = currentValue + stepSize * gradValue
            currentValues = replaceItem(newValue idx currentValues)
          )
        )
        
        ;; Evaluate new parameter set
        currentResult = evaluationFunc(currentValues)
        
        ;; Check if improved
        if(currentResult > bestResult
          prog(()
            bestResult = currentResult
            bestValues = currentValues
            improved = t
          )
          ;; If not improved, reduce step sizes
          prog(()
            stepSizes = foreach(mapcar step stepSizes
              step * 0.5
            )
          )
        )
        
        ;; Store results
        iteration = iteration + 1
        results = append(results list(iteration bestValues bestResult))
        
        ;; Check convergence
        converged = foreach(mapcar step stepSizes
          step < convergenceThreshold
        )
        converged = and(converged)
      )
    )
    
    ;; Close progress bar
    autoRficCloseProgressBar(progressBar)
    
    ;; Log results
    autoRficLogInfo(sprintf(nil "Optimization complete after %d iterations. Final result: %g" 
                           iteration bestResult))
    
    ;; Return results
    list(
      'bestValues bestValues
      'bestResult bestResult
      'iterations iteration
      'converged converged
      'allResults results
    )
  )
)

;; Function to perform random/Monte Carlo optimization
procedure(autoRficMonteCarloOptimize(paramNames minValues maxValues evaluationFunc 
                                    @optional (numSamples 100))
  let((currentValues bestValues bestResult results)
    autoRficLogInfo("Starting Monte Carlo optimization")
    
    ;; Initialize results
    bestResult = -1e9  ; Assuming higher is better
    bestValues = foreach(mapcar min minValues
      min  ; Default to min values
    )
    results = list()
    
    ;; Create progress bar
    progressBar = autoRficCreateProgressBar(
      "Monte Carlo Optimization"
      numSamples
    )
    
    ;; Perform random sampling
    for(i 1 numSamples
      let((currentValues result)
        ;; Update progress bar
        autoRficUpdateProgressBar(
          progressBar
          i
          sprintf(nil "Sample %d of %d" i numSamples)
        )
        
        ;; Generate random values for each parameter
        currentValues = foreach(mapcar min maxValues minValues
          let((minVal maxVal)
            minVal = car(min)
            maxVal = car(maxValues)
            minVal + random(1.0) * (maxVal - minVal)
          )
        )
        
        ;; Evaluate the design
        result = evaluationFunc(currentValues)
        
        ;; Store the result
        results = append(results list(currentValues result))
        
        ;; Check if this is the best result so far
        when(result > bestResult
          bestResult = result
          bestValues = currentValues
        )
      )
    )
    
    ;; Close progress bar
    autoRficCloseProgressBar(progressBar)
    
    ;; Log the results
    autoRficLogInfo(sprintf(nil "Monte Carlo optimization complete. Best result: %g" bestResult))
    
    ;; Return the results
    list(
      'bestValues bestValues
      'bestResult bestResult
      'allResults results
    )
  )
)

;; Add optimizer functions to namespace
when(boundp('autoRficOptimizer)
    autoRficOptimizer['sweepParameter] = 'autoRficSweepParameter
    autoRficOptimizer['gradientOptimize] = 'autoRficGradientOptimize
    autoRficOptimizer['monteCarloOptimize] = 'autoRficMonteCarloOptimize
)

;; Export the optimizer namespace
autoRficOptimizer
