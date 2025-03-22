;; ================================================================
;; Script to generate Class AB PA netlist from schematic
;; ================================================================

procedure(generateClassABPANetlist()
  let((lib cell view netlistFile)
    ;; Set library and cell information
    lib = "RFIC_Designs"
    cell = "ClassAB_PA_65nm"
    view = "schematic"
    netlistFile = "./class_ab_pa_netlist.scs"
    
    ;; Check if schematic exists, if not create it
    unless(ddGetObj(lib cell view)
      printf("Schematic does not exist. Creating it first...\n")
      createClassABPA()
    )
    
    ;; Generate netlist
    printf("Generating Spectre netlist for %s %s %s\n", lib, cell, view)
    
    ;; Use si command to generate netlist
    sim_settings = make_sevSession(
      ?simulator "spectre" 
      ?netlistFile netlistFile
    )
    sevSetViewList(sim_settings list("spectre" "cmos_sch" "schematic"))
    sevSetStopList(sim_settings list("spectre"))
    
    ;; Add simulation setup
    simulator(sim_settings)
    design(sim_settings lib cell view)
    resultsDir(sim_settings "./simResults")
    sevAnalysis(sim_settings "ac" ?start "3G" ?stop "4G" ?step "10M")
    sevAnalysis(sim_settings "sp" ?start "3G" ?stop "4G" ?step "10M")
    sevAnalysis(sim_settings "pss" ?fund "3.5G" ?maxharms 10)
    
    ;; Generate the netlist
    sevNetlist(sim_settings)
    
    printf("Netlist generated at %s\n", netlistFile)
    printf("PA specifications:\n")
    printf("  * Frequency: 3.3-3.8 GHz\n")
    printf("  * Output Power: 23 dBm\n")
    printf("  * Gain: 25 dB\n")
    printf("  * PAE: 45%%\n")
    printf("  * Supply: 3.3 V\n")
    printf("  * ACLR: -35 dBc\n")
    printf("  * EVM: 5%%\n")
    
    return(t)
  )
)

;; Function to run the netlist generation
procedure(runGenerateClassABPANetlist()
  generateClassABPANetlist()
)

;; To run the netlist generation, evaluate: runGenerateClassABPANetlist()
