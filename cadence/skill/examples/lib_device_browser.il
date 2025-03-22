;; ================================================================
;; Library and Device Browser (Command Line Version)
;; 
;; This script provides a command-line interface to:
;; 1. List available libraries in the Cadence environment
;; 2. View the devices/cells in each library
;; 3. Display information about devices grouped by category
;; ================================================================

;; Helper function to list available libraries
procedure(listAvailableLibraries()
  let((libs)
    libs = ddGetLibList()
    printf("Available libraries:\n")
    foreach(lib libs
      printf("  - %s\n", lib->name)
    )
    libs
  )
)

;; Helper function to determine device category based on name
procedure(getDeviceCategory(cellName)
  cond(
    ((rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
      "NMOS"
    )
    ((rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName))
      "PMOS"
    )
    ((rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName) || 
      rexMatchp(".*_sym_.*" cellName) || rexMatchp(".*_std_.*" cellName))
      "Inductor"
    )
    ((rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName))
      "Capacitor"
    )
    ((rexMatchp("res" cellName) || rexMatchp("r[pnw].*" cellName) || rexMatchp("rpoly.*" cellName) || 
      rexMatchp("rpod.*" cellName) || rexMatchp("presistor" cellName))
      "Resistor"
    )
    (t
      "Other"
    )
  )
)

;; Helper function to list cells in a library with detailed information
procedure(listCellsInLibrary(libName)
  prog((libObj cells count category)
    libObj = ddGetObj(libName)
    unless(libObj
      printf("Library %s not found.\n", libName)
      return(nil)
    )
    
    cells = libObj->cells
    count = length(cells)
    
    printf("Cells in library %s (%d total):\n", libName count)
    
    ;; Display detailed information for each cell - show all cells
    for(i 1 count
      cell = nth((i - 1) cells)
      cellName = cell->name
      
      ;; Get device category
      category = getDeviceCategory(cellName)
      
      ;; Get the cell's available views as separate strings to avoid list printing
      cellViews = cell->views
      viewStr = ""
      
      ;; Show all views
      foreach(view cellViews
        viewName = view->name
        viewStr = strcat(viewStr " " viewName)
      )
      
      ;; Display cell name with category and available views
      printf("  - %s [%s] (Views:%s)\n", cellName category viewStr)
    )
    
    return(t) ;; Return true to indicate success
  )
)

;; Helper function to categorize devices by type
procedure(categorizeDevices(libName)
  let((libObj cells nmosDevices pmosDevices indDevices capDevices resDevices otherDevices)
    libObj = ddGetObj(libName)
    unless(libObj
      error("Library %s not found" libName)
      return(nil)
    )
    
    ;; Initialize device lists
    nmosDevices = '()
    pmosDevices = '()
    indDevices = '()
    capDevices = '()
    resDevices = '()
    otherDevices = '()
    
    ;; Populate device lists by examining cell names
    foreach(cell libObj->cells
      cellName = cell->name
      
      ;; Categorize by pattern matching - improved matching patterns
      cond(
        ((rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
          nmosDevices = append(nmosDevices list(cellName))
        )
        ((rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName))
          pmosDevices = append(pmosDevices list(cellName))
        )
        ((rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName) || 
          rexMatchp(".*_sym_.*" cellName) || rexMatchp(".*_std_.*" cellName))
          indDevices = append(indDevices list(cellName))
        )
        ((rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName))
          capDevices = append(capDevices list(cellName))
        )
        ((rexMatchp("res" cellName) || rexMatchp("r[pnw].*" cellName) || rexMatchp("rpoly.*" cellName) || 
          rexMatchp("rpod.*" cellName) || rexMatchp("presistor" cellName))
          resDevices = append(resDevices list(cellName))
        )
        (t
          otherDevices = append(otherDevices list(cellName))
        )
      )
    )
    
    ;; Return categorized lists
    list(nmosDevices pmosDevices indDevices capDevices resDevices otherDevices)
  )
)

;; Function to display device details
procedure(getDeviceDetails(libName cellName)
  let((views viewNames deviceInfo parameters)
    printf("Getting details for %s in library %s\n" cellName libName)
    
    ;; Get views for the cell
    cellObj = ddGetObj(libName cellName)
    unless(cellObj
      printf("Cell %s not found in library %s\n" cellName libName)
      return(nil)
    )
    
    views = cellObj->views
    viewNames = '()
    foreach(view views
      viewNames = append(viewNames list(view->name))
    )
    
    printf("Library: %s\nCell: %s\nAvailable Views: %L\n" 
           libName cellName viewNames)
    
    deviceInfo = ""
    
    ;; Determine likely device type based on name
    cond(
      ((rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
        printf("Device Type: NMOS Transistor\n")
        parameters = '("w" "l" "fingers" "m" "nf")
      )
      ((rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName))
        printf("Device Type: PMOS Transistor\n")
        parameters = '("w" "l" "fingers" "m" "nf")
      )
      ((rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName))
        printf("Device Type: Inductor\n")
        parameters = '("inductance" "q" "dcr")
      )
      ((rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName))
        printf("Device Type: Capacitor\n")
        parameters = '("capacitance" "tc")
      )
      ((rexMatchp("res" cellName) || rexMatchp("poly" cellName) || rexMatchp("r[0-9]+" cellName))
        printf("Device Type: Resistor\n")
        parameters = '("resistance" "tc")
      )
      (t
        printf("Device Type: Other/Unknown\n")
        parameters = '()
      )
    )
    
    ;; Try to get parameters from master
    foreach(viewName '("symbol" "schematic" "spectre"))
      when(ddGetObj(libName cellName viewName)
        viewObj = dbOpenCellViewByType(libName cellName viewName "r")
        when(viewObj
          printf("Default Values:\n")
          foreach(param parameters
            paramValue = dbGetPropByName(viewObj param)
            when(paramValue
              printf("  %s: %L\n" param paramValue)
            )
          )
          dbClose(viewObj)
        )
        break()
      )
    )
  )
)

;; Helper function to categorize and display results with better formatting
procedure(categorizeDevicesAndDisplay(libName)
  let((deviceCategories)
    printf("\n=== Device Categories in %s ===\n" libName)
    deviceCategories = categorizeDevices(libName)
    
    when(deviceCategories
      printf("Device summary for library %s:\n" libName)
      printf("  NMOS transistors: %d\n" length(nth(0 deviceCategories)))
      printf("  PMOS transistors: %d\n" length(nth(1 deviceCategories)))
      printf("  Inductors: %d\n" length(nth(2 deviceCategories)))
      printf("  Capacitors: %d\n" length(nth(3 deviceCategories)))
      printf("  Resistors: %d\n" length(nth(4 deviceCategories)))
      printf("  Other devices: %d\n" length(nth(5 deviceCategories)))
      
      ;; Display specific device names by category if available with improved formatting
      when(length(nth(0 deviceCategories)) > 0
        printf("\nNMOS devices:\n")
        foreach(device nth(0 deviceCategories)
          printf("  \"%s\"" device)
        )
        printf("\n")
      )
      when(length(nth(1 deviceCategories)) > 0
        printf("\nPMOS devices:\n")
        foreach(device nth(1 deviceCategories)
          printf("  \"%s\"" device)
        )
        printf("\n")
      )
      when(length(nth(2 deviceCategories)) > 0
        printf("\nInductors:\n")
        foreach(device nth(2 deviceCategories)
          printf("  \"%s\"" device)
        )
        printf("\n")
      )
      when(length(nth(3 deviceCategories)) > 0
        printf("\nCapacitors:\n")
        foreach(device nth(3 deviceCategories)
          printf("  \"%s\"" device)
        )
        printf("\n")
      )
      when(length(nth(4 deviceCategories)) > 0
        printf("\nResistors:\n")
        foreach(device nth(4 deviceCategories)
          printf("  \"%s\"" device)
        )
        printf("\n")
      )
      when(length(nth(5 deviceCategories)) > 0
        printf("\nOther devices:\n")
        foreach(device nth(5 deviceCategories)
          printf("  \"%s\"" device)
        )
        printf("\n")
      )
    )
  )
)

;; Print usage instructions when the script is loaded
procedure(showLibBrowserHelp()
  printf("\n====================================\n")
  printf("Library and Device Browser (CLI Version)\n")
  printf("====================================\n")
  printf("Available commands:\n")
  printf("  listAvailableLibraries()              - List all available libraries\n")
  printf("  listCellsInLibrary(\"libName\")         - List all cells in a library\n")
  printf("  categorizeDevicesAndDisplay(\"libName\") - Show devices by category\n")
  printf("  getDeviceDetails(\"libName\" \"cellName\") - Show details of a specific device\n")
  printf("====================================\n\n")
)

;; Initialize the browser with usage instructions
showLibBrowserHelp()
