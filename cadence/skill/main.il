;; main.il - Main entry point for auto_rfic framework

;; Create all namespace tables first
let(()
    ;; Core namespace
    unless(boundp('autoRfic)
        setq(autoRfic makeTable("autoRfic" nil))
    )
    ;; Module namespaces
    unless(boundp('autoRficConfig)
        setq(autoRficConfig makeTable("config" nil))
    )
    unless(boundp('autoRficUserConfig)
        setq(autoRficUserConfig makeTable("userConfig" nil))
    )
    unless(boundp('autoRficUtils)
        setq(autoRficUtils makeTable("utils" nil))
    )
    unless(boundp('autoRficLogging)
        setq(autoRficLogging makeTable("logging" nil))
    )
    unless(boundp('autoRficGui)
        setq(autoRficGui makeTable("gui" nil))
    )
    unless(boundp('autoRficDb)
        setq(autoRficDb makeTable("db" nil))
    )
    unless(boundp('autoRficTemplates)
        setq(autoRficTemplates makeTable("templates" nil))
    )
    unless(boundp('autoRficGenerator)
        setq(autoRficGenerator makeTable("generator" nil))
    )
    unless(boundp('autoRficOptimizer)
        setq(autoRficOptimizer makeTable("optimizer" nil))
    )
    unless(boundp('autoRficTestbench)
        setq(autoRficTestbench makeTable("testbench" nil))
    )
    unless(boundp('autoRficAnalyses)
        setq(autoRficAnalyses makeTable("analyses" nil))
    )
    unless(boundp('autoRficResults)
        setq(autoRficResults makeTable("results" nil))
    )
    unless(boundp('autoRficFloorplan)
        setq(autoRficFloorplan makeTable("floorplan" nil))
    )
    unless(boundp('autoRficPlacement)
        setq(autoRficPlacement makeTable("placement" nil))
    )
    unless(boundp('autoRficRouting)
        setq(autoRficRouting makeTable("routing" nil))
    )
    unless(boundp('autoRficRfStructures)
        setq(autoRficRfStructures makeTable("rfStructures" nil))
    )
    unless(boundp('autoRficDrc)
        setq(autoRficDrc makeTable("drc" nil))
    )
    unless(boundp('autoRficLvs)
        setq(autoRficLvs makeTable("lvs" nil))
    )
    unless(boundp('autoRficParasitic)
        setq(autoRficParasitic makeTable("parasitic" nil))
    )
)

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
        
        ;; First load core utilities and logging
        printf("Loading core modules...\n")
        autoRficLoadModule(sprintf(nil "%s/lib/utils.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/lib/logging.il" baseDir))
        
        ;; Then load configuration which may use logging
        printf("Loading configuration modules...\n")
        autoRficLoadModule(sprintf(nil "%s/config/default_config.il" baseDir))
        autoRficLoadModule(sprintf(nil "%s/config/user_config.il" baseDir))
        
        ;; Load remaining library modules
        printf("Loading library modules...\n")
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
        dbRegRefreshTrigger('autoRficGuiRefreshTrigger)
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
        autoRfic = append(autoRfic autoRficUserConfig)
        
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
