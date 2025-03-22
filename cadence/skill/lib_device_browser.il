;; ================================================================
;; Library and Device Browser
;; 
;; This script provides a simple GUI to:
;; 1. Browse available libraries in the Cadence environment
;; 2. View the devices/cells in each library
;; 3. Display basic information about selected devices
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

;; Helper function to list cells in a library
procedure(listCellsInLibrary(libName)
  let((libObj cells)
    libObj = ddGetObj(libName)
    unless(libObj
      printf("Library %s not found.\n", libName)
      nil
    )
    
    cells = libObj->cells
    printf("Cells in library %s:\n", libName)
    foreach(cell cells
      printf("  - %s\n", cell->name)
    )
    cells
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
      
      ;; Categorize by pattern matching
      cond(
        ((rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
          nmosDevices = append(nmosDevices list(cellName))
        )
        ((rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName))
          pmosDevices = append(pmosDevices list(cellName))
        )
        ((rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName))
          indDevices = append(indDevices list(cellName))
        )
        ((rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName))
          capDevices = append(capDevices list(cellName))
        )
        ((rexMatchp("res" cellName) || rexMatchp("poly" cellName) || rexMatchp("r[0-9]+" cellName))
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

;; Function to display device details when selected
procedure(viewDeviceDetails(libName)
  let((cellName views viewNames deviceInfo parameters)
    cellName = hiGetSelectedItem()
    printf("Viewing details for %s in library %s\n" cellName libName)
    
    ;; Get views for the cell
    views = ddGetObj(libName cellName)->views
    viewNames = '()
    foreach(view views
      viewNames = append(viewNames list(view->name))
    )
    
    deviceInfo = ""
    
    ;; Determine likely device type based on name
    cond(
      ((rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
        deviceInfo = strcat(deviceInfo "Device Type: NMOS Transistor\n")
        parameters = '("w" "l" "fingers" "m" "nf")
      )
      ((rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName))
        deviceInfo = strcat(deviceInfo "Device Type: PMOS Transistor\n")
        parameters = '("w" "l" "fingers" "m" "nf")
      )
      ((rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName))
        deviceInfo = strcat(deviceInfo "Device Type: Inductor\n")
        parameters = '("inductance" "q" "dcr")
      )
      ((rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName))
        deviceInfo = strcat(deviceInfo "Device Type: Capacitor\n")
        parameters = '("capacitance" "tc")
      )
      ((rexMatchp("res" cellName) || rexMatchp("poly" cellName) || rexMatchp("r[0-9]+" cellName))
        deviceInfo = strcat(deviceInfo "Device Type: Resistor\n")
        parameters = '("resistance" "tc")
      )
      (t
        deviceInfo = strcat(deviceInfo "Device Type: Other/Unknown\n")
        parameters = '()
      )
    )
    
    ;; Try to get parameters from master
    foreach(viewName '("symbol" "schematic" "spectre"))
      when(ddGetObj(libName cellName viewName)
        viewObj = dbOpenCellViewByType(libName cellName viewName "r")
        when(viewObj
          deviceInfo = strcat(deviceInfo "Default Values:\n")
          foreach(param parameters
            paramValue = dbGetPropByName(viewObj param)
            when(paramValue
              deviceInfo = strcat(deviceInfo sprintf(nil "  %s: %L\n" param paramValue))
            )
          )
          dbClose(viewObj)
        )
        break()
      )
    )
    
    ;; Display device details in a dialog box
    hiDisplayAppDBox(
      ?name           'deviceDetailsDialog
      ?dboxBanner     sprintf(nil "Device Details: %s" cellName)
      ?dboxText       sprintf(nil "Library: %s\nCell: %s\nAvailable Views: %L\n%s" 
                              libName cellName viewNames deviceInfo)
      ?buttonLayout   'OK
    )
  )
)

;; Browse contents of selected library
procedure(browseLibraryContents()
  let((libName cells cellNames)
    ;; Get the selected library name
    libName = hiGetSelectedItem()
    printf("Selected library: %L\n" libName)
    
    ;; Get cells from the library
    printf("Fetching cells from library %L...\n" libName)
    cells = listCellsInLibrary(libName)
    
    ;; Try to categorize devices in this library
    deviceCategories = categorizeDevices(libName)
    
    ;; Display in a new dialog
    if(cells != nil then
      cellNames = '()
      foreach(cell cells
        cellNames = append(cellNames list(cell->name))
      )
      printf("Found %d cells in library\n" length(cellNames))
      
      ;; Sort cell names alphabetically
      cellNames = sort(cellNames 'lexLess)
      
      ;; Print summary of device types
      printf("Device summary for library %s:\n" libName)
      printf("  NMOS transistors: %d\n" length(nth(0 deviceCategories)))
      printf("  PMOS transistors: %d\n" length(nth(1 deviceCategories)))
      printf("  Inductors: %d\n" length(nth(2 deviceCategories)))
      printf("  Capacitors: %d\n" length(nth(3 deviceCategories)))
      printf("  Resistors: %d\n" length(nth(4 deviceCategories)))
      printf("  Other devices: %d\n" length(nth(5 deviceCategories)))
      
      ;; If there are cells, display them
      when(length(cellNames) > 0
        hiDisplayListBox(
          ?name           'cellListDialog
          ?dboxBanner     sprintf(nil "Devices in %s" libName)
          ?buttonLayout   'OKCancel
          ?choices        cellNames
          ?numVisChoice   15
          ?itemAction     sprintf(nil "viewDeviceDetails(\"%s\")" libName)
        )
      )
    else
      hiDisplayAppDBox(
        ?name           'noCellsDialog
        ?dboxBanner     "No Cells Found"
        ?dboxText       sprintf(nil "No cells found in library %s" libName)
        ?buttonLayout   'OK
      )
    )
  )
)

;; Main function to show the library browser
procedure(showLibraryBrowser()
  let((libs libNames)
    printf("Starting Library Browser...\n")
    
    ;; Get list of libraries
    libs = ddGetLibList()
    libNames = '()
    foreach(lib libs
      libNames = append(libNames list(lib->name))
    )
    printf("Found %d libraries\n" length(libNames))
    
    ;; Sort library names alphabetically
    libNames = sort(libNames 'lexLess)
    
    ;; Display library list dialog
    hiDisplayListBox(
      ?name           'libBrowserDialog
      ?dboxBanner     "Library Browser"
      ?buttonLayout   'OKCancel
      ?choices        libNames
      ?numVisChoice   20
      ?itemAction     "browseLibraryContents()"
    )
    
    printf("Library Browser displayed\n")
  )
)

;; Initialize the browser
printf("\n====================================\n")
printf("Starting Library and Device Browser\n")
printf("====================================\n")
showLibraryBrowser()
