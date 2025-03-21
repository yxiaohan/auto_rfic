;; main.il - Main entry point for auto_rfic framework

;; Define the namespace variable first
autoRfic = makeTable("autoRfic" nil)

;; Function to load a module
procedure(autoRficLoadModule(modulePath)
    let((fullPath result moduleName)
        fullPath = simplifyFilename(modulePath)
        moduleName = car(reverse(parseString(fullPath "/")))
        result = load(fullPath)
        result
    )
)

;; Function to initialize the framework
procedure(autoRficInit()
    let((baseDir result)
        ;; Get the base directory
        baseDir = getShellEnvVar("AUTO_RFIC_DIR")
        unless(baseDir
            baseDir = "/Volumes/970-1t/yuan/projects/auto_rfic/cadence/skill"
        )
        
        ;; Initialize module namespace tables first
        unless(autoRficConfig
            autoRficConfig = makeTable("config" nil)
        )
        unless(autoRficUtils
            autoRficUtils = makeTable("utils" nil)
        )
        unless(autoRficLogging
            autoRficLogging = makeTable("logging" nil)
        )
        unless(autoRficGui
            autoRficGui = makeTable("gui" nil)
        )
        unless(autoRficDb
            autoRficDb = makeTable("db" nil)
        )
        unless(autoRficTemplates
            autoRficTemplates = makeTable("templates" nil)
        )
        unless(autoRficGenerator
            autoRficGenerator = makeTable("generator" nil)
        )
        unless(autoRficOptimizer
            autoRficOptimizer = makeTable("optimizer" nil)
        )
        unless(autoRficTestbench
            autoRficTestbench = makeTable("testbench" nil)
        )
        unless(autoRficAnalyses
            autoRficAnalyses = makeTable("analyses" nil)
        )
        unless(autoRficResults
            autoRficResults = makeTable("results" nil)
        )
        unless(autoRficFloorplan
            autoRficFloorplan = makeTable("floorplan" nil)
        )
        unless(autoRficPlacement
            autoRficPlacement = makeTable("placement" nil)
        )
        unless(autoRficRouting
            autoRficRouting = makeTable("routing" nil)
        )
        unless(autoRficRfStructures
            autoRficRfStructures = makeTable("rfStructures" nil)
        )
        unless(autoRficDrc
            autoRficDrc = makeTable("drc" nil)
        )
        unless(autoRficLvs
            autoRficLvs = makeTable("lvs" nil)
        )
        unless(autoRficParasitic
            autoRficParasitic = makeTable("parasitic" nil)
        )
        
        ;; Load modules by type
        printf("Loading configuration modules...\n")
        autoRficLoadModule(sprintf(nil "%s/config/default_config.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/config/user_config.il" baseDir))
        
        printf("Loading library modules...\n")
        autoRficLoadModule(sprintf(nil "%s/lib/utils.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/lib/logging.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/lib/gui.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/lib/db.il" baseDir))
        
        printf("Loading schematic modules...\n")
        autoRficLoadModule(sprintf(nil "%s/schematic/templates.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/schematic/generator.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/schematic/optimizer.il" baseDir))
        
        printf("Loading simulation modules...\n")
        autoRficLoadModule(sprintf(nil "%s/simulation/testbench.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/simulation/analyses.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/simulation/results.il" baseDir))
        
        printf("Loading layout modules...\n")
        autoRficLoadModule(sprintf(nil "%s/layout/floorplan.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/layout/placement.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/layout/routing.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/layout/rf_structures.il" baseDir))
        
        printf("Loading verification modules...\n")
        autoRficLoadModule(sprintf(nil "%s/verification/drc.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/verification/lvs.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/verification/parasitic.il" baseDir))
        
        ;; Setup core systems
        dbRegSaveTrigger('autoRficDbSaveTrigger)
        geRegRefreshTrigger('autoRficGuiRefreshTrigger)
        CCSCreateAlias("testRemote" 'autoRficTestRemote)
        
        result = t
        result
    )
)

;; Function to create the namespace
procedure(autoRficCreateNamespace()
    let((result)
        
        ;; First add core functions to namespace
        autoRfic["loadModule"] = 'autoRficLoadModule
        autoRfic["init"] = 'autoRficInit
        autoRfic["createNamespace"] = 'autoRficCreateNamespace
        autoRfic["help"] = 'autoRficHelp
        autoRfic["helpFunction"] = 'autoRficHelpFunction
        
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
        
        result = t
        result
    )
)

;; Function to display help information
procedure(autoRficHelp()
    let((result)
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
        
        result = t
        result
    )
)

;; Function to display detailed help for a specific function
procedure(autoRficHelpFunction(functionName)
    let((helpText result)
        printf("\nHelp for function: %s\n" functionName)
        printf("=======================%s\n\n" make_string(length(functionName) "="))
        
        helpText = case(functionName
            ("getParameter"
                strcat(
                    "autoRfic->getParameter(name [default])\n\n"
                    "Gets a configuration parameter value.\n\n"
                    "Parameters:\n"
                    "  name - Name of the parameter\n"
                    "  default - Optional default value if parameter is not found\n\n"
                    "Returns:\n"
                    "  The parameter value, or the default value if not found\n\n"
                    "Example:\n"
                    "  autoRfic->getParameter(\"logLevel\" \"INFO\")"
                )
            )
            (t
                if(functionName && stringp(functionName)
                    sprintf(nil "No detailed help available for function: %s\n" functionName)
                    "No function name specified\n"
                )
            )
        )
        
        printf("%s\n" helpText)
        result = t
        result
    )
)

;; Initialize the framework
printf("Loading Auto RFIC framework v1.0...\n")

;; Initialize first, then create namespace
let((result)
    autoRficInit()
    autoRficCreateNamespace()
    printf("Auto RFIC framework initialization complete\n")
    result = t
    result
)
