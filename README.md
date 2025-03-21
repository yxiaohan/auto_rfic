# Auto RFIC

A comprehensive framework for automating RFIC design using Cadence SKILL scripts.

## Overview

Auto RFIC provides a set of SKILL scripts for automating various aspects of RFIC design, including:

- Schematic generation and optimization
- Simulation setup and analysis
- Layout generation and optimization
- Design verification (DRC, LVS)
- Parasitic extraction and analysis

## Directory Structure

```
auto_rfic/
├── cadence/
│   └── skill/
│       ├── config/
│       │   ├── default_config.il - Default configuration settings
│       │   └── user_config.il - User-specific configuration overrides
│       ├── lib/
│       │   ├── utils.il - Utility functions
│       │   ├── logging.il - Logging system
│       │   ├── gui.il - GUI components
│       │   └── db.il - Database functions
│       ├── schematic/
│       │   ├── templates.il - Schematic templates
│       │   ├── generator.il - Schematic generation
│       │   └── optimizer.il - Parameter optimization
│       ├── simulation/
│       │   ├── testbench.il - Testbench creation
│       │   ├── analyses.il - Analysis configuration
│       │   └── results.il - Results processing
│       ├── layout/
│       │   ├── floorplan.il - Layout floorplanning
│       │   ├── placement.il - Component placement
│       │   ├── routing.il - Signal routing
│       │   └── rf_structures.il - RF-specific structures
│       ├── verification/
│       │   ├── drc.il - Design Rule Check
│       │   ├── lvs.il - Layout vs. Schematic
│       │   └── parasitic.il - Parasitic extraction and analysis
│       └── main.il - Main entry point
└── README.md - This file
```

## Installation

1. Clone or download this repository to your local machine.
2. Set the environment variable `AUTO_RFIC_DIR` to point to the `cadence/skill` directory:
   ```
   export AUTO_RFIC_DIR=/path/to/auto_rfic/cadence/skill
   ```
3. In Cadence Virtuoso, load the main script:
   ```
   load("/path/to/auto_rfic/cadence/skill/main.il")
   ```

## Usage

After loading the main script, you can access all functions through the `autoRfic` namespace:

```skill
;; Get help
autoRfic->help()

;; Create a schematic from a template
template = autoRfic->createTemplate("lna" list('gain 20.0 'nf 2.0))
schematic = autoRfic->generateSchematic(template)

;; Create a testbench and run simulation
testbench = autoRfic->createTestbench(schematic)
autoRfic->setupAnalysis(testbench "sp" list('start 1.0e9 'stop 5.0e9 'points 101))
results = autoRfic->runSimulation(testbench)

;; Create layout
layout = autoRfic->createFloorplan(schematic)
autoRfic->placeComponents(layout)
autoRfic->routeNets(layout)

;; Run verification
drcResults = autoRfic->runDrc(layout)
lvsResults = autoRfic->runLvs(layout schematic)
parasitics = autoRfic->extractParasitics(layout)
```

## Configuration

You can customize the behavior of Auto RFIC by modifying the configuration parameters:

```skill
;; Get a configuration parameter
logLevel = autoRfic->getParameter("logLevel")

;; Set a configuration parameter
autoRfic->setParameter("logLevel" "DEBUG")

;; Save configuration to a file
autoRfic->saveConfig("my_config.il")

;; Load configuration from a file
autoRfic->loadConfig("my_config.il")
```

## Features

### Schematic Generation

- Parameterized templates for common RFIC blocks (LNA, mixer, VCO, etc.)
- Automatic component sizing based on specifications
- Parameter optimization for performance targets

### Simulation

- Automated testbench creation
- Support for various analysis types (DC, AC, SP, PSS, etc.)
- Results extraction and post-processing

### Layout

- Automatic floorplanning
- Intelligent component placement
- Signal routing with RF considerations
- RF-specific structures (inductors, transmission lines, etc.)

### Verification

- DRC and LVS automation
- Parasitic extraction and analysis
- Performance verification against specifications

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Cadence Design Systems for the Virtuoso platform
- The RFIC design community for inspiration and best practices
