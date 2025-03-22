;; ================================================================
;; Script to import Class AB PA netlist into Virtuoso
;; ================================================================

procedure(importClassABPANetlist()
  let((lib cell view netlistFile importOptions spiceInPtr)
    ;; Set library and cell information
    lib = "RFIC_Designs"
    cell = "ClassAB_PA_65nm"
    view = "schematic"
    netlistFile = "./class_ab_pa_netlist.scs"
    
    ;; Create the library if it doesn't exist
    unless(ddGetObj(lib)
      printf("Creating library %s...\n" lib)
      createLib(lib)
    )
    
    ;; Set up import options
    importOptions = list(
      list("viewName" view)
      list("createUnknownCells" t)
      list("runChecks" nil)
      list("ignoreParamCase" t)
      list("verilogFormat" "mixedtext")
      list("checkLibCellView" nil)
      list("mergeUnknownNets" t)
      list("mapNetNames" t)
      list("propMapStrategy" "all")
      list("addPrefixToNewObjs" "inst0")
      list("preserveInst" t)
    )
    
    ;; Import the netlist using SpiceIn API
    printf("Importing netlist %s to %s %s %s...\n" netlistFile lib cell view)
    
    ;; Use ddsOpenCdsLibManager to ensure CIW is available
    ddsOpenCdsLibManager()
    
    ;; Use hiSpiceIn to import the netlist
    spiceInPtr = hiOpenSpiceIn(
      ?lib lib
      ?cell cell
      ?view view
      ?netlistFile netlistFile
    )
    
    ;; Set import options
    foreach(option importOptions
      spiceInSetOption(spiceInPtr car(option) cadr(option))
    )
    
    ;; Perform the import
    unless(spiceInReadNetlist(spiceInPtr)
      error("Failed to import netlist %s" netlistFile)
    )
    
    ;; Close the SpiceIn session
    hiCloseSpiceIn(spiceInPtr)
    
    printf("Netlist imported successfully to %s %s %s\n" lib cell view)
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

;; Function to run the netlist import
procedure(runImportClassABPANetlist()
  importClassABPANetlist()
)

;; To import the netlist, evaluate: runImportClassABPANetlist()
