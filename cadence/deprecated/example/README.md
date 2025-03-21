# RF Amplifier Parameter Sweep Example

This is a simple working example of a Cadence SKILL script that demonstrates RFIC design automation concepts. The example shows how to automate parameter sweeping for an RF amplifier design.

## Overview

The script `rf_amp_sweep.il` demonstrates:

1. **Basic infrastructure**:
   - Error handling and logging
   - Parameter management
   - File I/O operations

2. **Schematic manipulation**:
   - Creating RF amplifier schematics
   - Setting component parameters
   - Adding pins and connections

3. **Simulation control**:
   - Setting up ADE simulations
   - Running parameter sweeps
   - Extracting and reporting results

## How to Use

### Loading the Script in Virtuoso

1. Launch Cadence Virtuoso
2. In the CIW (Command Interpreter Window), load the script:
   ```
   load("/path/to/rf_amp_sweep.il")
   ```

3. Run the example:
   ```
   rfSweepExample()
   ```

### Customizing Parameters

You can customize the example by setting environment variables before running:

- `RF_LIB`: Library name (default: "RFDesign")
- `CELL_NAME`: Cell name (default: "rf_amplifier")

Example:
```
envSetVal("RF_LIB" "string" "MyRFLib")
envSetVal("CELL_NAME" "string" "my_amplifier")
rfSweepExample()
```

### Understanding the Results

The script:
1. Creates an RF amplifier schematic with a configurable NMOS transistor
2. Performs a width parameter sweep from 5μm to 20μm in steps of 2.5μm
3. Simulates each configuration (dummy simulation in this example)
4. Extracts gain and bandwidth metrics (dummy values in this example)
5. Generates a CSV report with the results

## Extending the Example

This example can be extended by:

1. Adding real simulation result extraction
2. Including more sophisticated parameter sweeps
3. Implementing layout generation
4. Adding optimization algorithms
5. Creating a GUI for parameter control

## Notes for RFIC Automation

This example demonstrates the core concepts needed for the larger RFIC automation project:

1. **Modular design**: Separating functions by purpose
2. **Error handling**: Robust logging and error management
3. **Parameter management**: Flexible configuration
4. **Design automation**: Schematic creation and modification
5. **Simulation control**: Setting up and running simulations
6. **Results analysis**: Extracting and reporting simulation data

When using in production, replace the dummy functions with real implementations that interact with your specific RFIC designs and verification flows.

## Limitations

This is a simplified example with the following limitations:

1. Dummy simulation results (no actual circuit simulation)
2. Limited error handling
3. No layout automation
4. No advanced optimization algorithms
5. No GUI components

These limitations will be addressed in the full implementation described in the project plan.
