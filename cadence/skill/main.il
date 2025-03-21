;; main.il - Main entry point for auto_rfic
;; This file loads all modules and initializes the auto_rfic framework

;; Define the auto_rfic namespace
autoRfic = list(nil)

;; Function to load a module
procedure(autoRficLoadModule(modulePath)
  let((fullPath)
    fullPath = simplifyFilename(modulePath)
    printf("Loading module: %s\n" fullPath)
    load(fullPath)
  )
)

;; Function to initialize the auto_rfic framework
procedure(autoRficInit()
  let((baseDir)
    printf("Initializing auto_rfic framework\n")
    
    ;; Get the base directory
    baseDir = getShellEnvVar("AUTO_RFIC_DIR")
    unless(baseDir
      baseDir = "/Volumes/970-1t/yuan/projects/auto_rfic/cadence/skill"
      printf("AUTO_RFIC_DIR environment variable not set, using default: %s\n" baseDir)
    )
    
    ;; Load configuration modules
    autoRficLoadModule(sprintf(nil "%s/config/default_config.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/config/user_config.il" baseDir))
    
    ;; Load library modules
    autoRficLoadModule(sprintf(nil "%s/lib/utils.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/lib/logging.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/lib/gui.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/lib/db.il" baseDir))
    
    ;; Load schematic modules
    autoRficLoadModule(sprintf(nil "%s/schematic/templates.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/schematic/generator.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/schematic/optimizer.il" baseDir))
    
    ;; Load simulation modules
    autoRficLoadModule(sprintf(nil "%s/simulation/testbench.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/simulation/analyses.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/simulation/results.il" baseDir))
    
    ;; Load layout modules
    autoRficLoadModule(sprintf(nil "%s/layout/floorplan.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/layout/placement.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/layout/routing.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/layout/rf_structures.il" baseDir))
    
    ;; Load verification modules
    autoRficLoadModule(sprintf(nil "%s/verification/drc.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/verification/lvs.il" baseDir))
    autoRficLoadModule(sprintf(nil "%s/verification/parasitic.il" baseDir))
    
    ;; Initialize logging
    autoRficInitLogging()
    
    ;; Initialize configuration
    autoRficInitConfig()
    
    ;; Initialize database
    autoRficInitDb()
    
    ;; Initialize GUI
    autoRficInitGui()
    
    printf("auto_rfic framework initialized\n")
  )
)

;; Function to create the auto_rfic namespace
procedure(autoRficCreateNamespace()
  let()
    printf("Creating auto_rfic namespace\n")
    
    ;; Add configuration functions
    autoRfic = append(autoRfic autoRficConfig)
    
    ;; Add utility functions
    autoRfic = append(autoRfic autoRficUtils)
    
    ;; Add logging functions
    autoRfic = append(autoRfic autoRficLogging)
    
    ;; Add GUI functions
    autoRfic = append(autoRfic autoRficGui)
    
    ;; Add database functions
    autoRfic = append(autoRfic autoRficDb)
    
    ;; Add schematic functions
    autoRfic = append(autoRfic autoRficTemplates)
    autoRfic = append(autoRfic autoRficGenerator)
    autoRfic = append(autoRfic autoRficOptimizer)
    
    ;; Add simulation functions
    autoRfic = append(autoRfic autoRficTestbench)
    autoRfic = append(autoRfic autoRficAnalyses)
    autoRfic = append(autoRfic autoRficResults)
    
    ;; Add layout functions
    autoRfic = append(autoRfic autoRficFloorplan)
    autoRfic = append(autoRfic autoRficPlacement)
    autoRfic = append(autoRfic autoRficRouting)
    autoRfic = append(autoRfic autoRficRfStructures)
    
    ;; Add verification functions
    autoRfic = append(autoRfic autoRficDrc)
    autoRfic = append(autoRfic autoRficLvs)
    autoRfic = append(autoRfic autoRficParasitic)
    
    printf("auto_rfic namespace created\n")
  )


;; Function to display help information
procedure(autoRficHelp()
  let()
    printf("\nauto_rfic Help\n")
    printf("=============\n\n")
    
    printf("Configuration Functions:\n")
    printf("  autoRfic->getParameter(name [default]) - Get configuration parameter\n")
    printf("  autoRfic->setParameter(name value) - Set configuration parameter\n")
    printf("  autoRfic->saveConfig(filename) - Save configuration to file\n")
    printf("  autoRfic->loadConfig(filename) - Load configuration from file\n\n")
    
    printf("Schematic Functions:\n")
    printf("  autoRfic->createTemplate(name params) - Create schematic template\n")
    printf("  autoRfic->generateSchematic(template params) - Generate schematic from template\n")
    printf("  autoRfic->optimizeParameters(schematic params constraints) - Optimize parameters\n\n")
    
    printf("Simulation Functions:\n")
    printf("  autoRfic->createTestbench(schematic) - Create simulation testbench\n")
    printf("  autoRfic->setupAnalysis(testbench type params) - Setup simulation analysis\n")
    printf("  autoRfic->runSimulation(testbench) - Run simulation\n")
    printf("  autoRfic->getResults(testbench) - Get simulation results\n\n")
    
    printf("Layout Functions:\n")
    printf("  autoRfic->createFloorplan(schematic) - Create layout floorplan\n")
    printf("  autoRfic->placeComponents(layout) - Place components in layout\n")
    printf("  autoRfic->routeNets(layout) - Route nets in layout\n")
    printf("  autoRfic->createRfStructure(layout type params) - Create RF structure\n\n")
    
    printf("Verification Functions:\n")
    printf("  autoRfic->runDrc(layout) - Run DRC\n")
    printf("  autoRfic->runLvs(layout schematic) - Run LVS\n")
    printf("  autoRfic->extractParasitics(layout) - Extract parasitics\n\n")
    
    printf("For more detailed help on specific functions, use:\n")
    printf("  autoRfic->help(\"function_name\")\n\n")
  )
)

;; Function to display detailed help on a specific function
procedure(autoRficHelpFunction(functionName)
  let((helpText)
    printf("\nHelp for function: %s\n" functionName)
    printf("=======================%s\n\n" make_string(length(functionName) "="))
    
    helpText = case(functionName
      ("getParameter"
        "autoRfic->getParameter(name [default])\n\n" +
        "Gets a configuration parameter value.\n\n" +
        "Parameters:\n" +
        "  name - Name of the parameter\n" +
        "  default - Optional default value if parameter is not found\n\n" +
        "Returns:\n" +
        "  The parameter value, or the default value if not found\n\n" +
        "Example:\n" +
        "  autoRfic->getParameter(\"logLevel\" \"INFO\")"
      )
      ;; Add more function help texts here
      (t
        if(functionName then
          sprintf(nil "No detailed help available for function: %s\n" functionName)
        else
          "No function name specified\n"
        )
      )
    )
    
    printf("%s\n" helpText)
  )


;; Add main functions to the namespace
autoRfic = append(autoRfic list(
  'init autoRficInit
  'help autoRficHelp
  'helpFunction autoRficHelpFunction
))

;; Initialize the auto_rfic framework
autoRficInit()

;; Create the auto_rfic namespace
autoRficCreateNamespace()

;; Export the auto_rfic namespace
autoRfic
