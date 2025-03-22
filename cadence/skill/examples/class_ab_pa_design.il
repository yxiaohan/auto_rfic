;; ================================================================
;; Class AB Power Amplifier Design Script for 65nm CMOS Process
;; Frequency: 3.3-3.8 GHz
;; Specifications:
;; - Output Power: 23 dBm
;; - Gain: 25 dB
;; - Power Added Efficiency (PAE): 45%
;; - Supply Voltage: 3.3 V
;; - Linearity Requirement (ACLR): -35 dBc
;; - EVM: 5%
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

;; Helper function to list available views for a cell
procedure(listViewsForCell(libName cellName)
  let((cellObj views)
    cellObj = ddGetObj(libName cellName)
    unless(cellObj
      printf("Cell %s not found in library %s.\n", cellName, libName)
      nil
    )
    
    views = cellObj->views
    printf("Views for cell %s in library %s:\n", cellName, libName)
    foreach(view views
      printf("  - %s\n", view->name)
    )
    views
  )
)

;; Helper function to display a form for device selection
procedure(showDeviceSelectionForm(deviceLib)
  let((form nmosChoices pmosChoices indChoices capChoices resChoices
       nmosMaster pmosMaster indMaster capMaster resMaster)
    
    ;; Get all cells from the device library
    libObj = ddGetObj(deviceLib)
    unless(libObj
      error("Library %s not found" deviceLib)
      return(nil)
    )
    
    ;; Initialize choice lists
    nmosChoices = '()
    pmosChoices = '()
    indChoices = '()
    capChoices = '()
    resChoices = '()
    
    ;; Populate choice lists by examining cell names
    foreach(cell libObj->cells
      cellName = cell->name
      
      ;; Check for NMOS transistors
      when(rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName)
        nmosChoices = append(nmosChoices list(cellName))
      )
      
      ;; Check for PMOS transistors
      when(rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName)
        pmosChoices = append(pmosChoices list(cellName))
      )
      
      ;; Check for inductors
      when(rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName)
        indChoices = append(indChoices list(cellName))
      )
      
      ;; Check for capacitors
      when(rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName)
        capChoices = append(capChoices list(cellName))
      )
      
      ;; Check for resistors
      when(rexMatchp("res" cellName) || rexMatchp("poly" cellName) || rexMatchp("r[0-9]+" cellName)
        resChoices = append(resChoices list(cellName))
      )
    )
    
    ;; If no devices found, use generic names
    when(length(nmosChoices) == 0 nmosChoices = '("nmos" "nfet"))
    when(length(pmosChoices) == 0 pmosChoices = '("pmos" "pfet"))
    when(length(indChoices) == 0 indChoices = '("inductor" "ind"))
    when(length(capChoices) == 0 capChoices = '("capacitor" "cap"))
    when(length(resChoices) == 0 resChoices = '("resistor" "res"))
    
    ;; Create form for device selection
    form = hiCreateAppForm(
      ?name           'deviceSelectionForm
      ?formTitle      "Device Selection Form"
      ?callback       nil
      ?buttonLayout   'OKCancelApply
      ?unmapAfterCB   t
    )
    
    ;; Device Library field
    hiCreateStringField(
      ?parent         form 
      ?name           'deviceLibField
      ?prompt         "Device Library:"
      ?value          deviceLib
      ?editable       nil
    )
    
    ;; NMOS device selection
    hiCreateCyclicField(
      ?parent         form
      ?name           'nmosField
      ?prompt         "NMOS Device:"
      ?choices        nmosChoices
      ?value          car(nmosChoices)
    )
    
    ;; PMOS device selection
    hiCreateCyclicField(
      ?parent         form
      ?name           'pmosField
      ?prompt         "PMOS Device:"
      ?choices        pmosChoices
      ?value          car(pmosChoices)
    )
    
    ;; Inductor selection
    hiCreateCyclicField(
      ?parent         form
      ?name           'indField
      ?prompt         "Inductor:"
      ?choices        indChoices
      ?value          car(indChoices)
    )
    
    ;; Capacitor selection
    hiCreateCyclicField(
      ?parent         form
      ?name           'capField
      ?prompt         "Capacitor:"
      ?choices        capChoices
      ?value          car(capChoices)
    )
    
    ;; Resistor selection
    hiCreateCyclicField(
      ?parent         form
      ?name           'resField
      ?prompt         "Resistor:"
      ?choices        resChoices
      ?value          car(resChoices)
    )
    
    ;; Set form callback
    hiSetFormCallbacks(form
      ?okCallBack     "deviceSelectionFormOK()"
    )
    
    ;; Display the form
    hiDisplayForm(form)
    
    ;; Create global variables to store the selections
    setq(_deviceSelectionForm form)
    setq(_deviceLibrary deviceLib)
    
    ;; Return the form
    form
  )
)

;; Callback function for form OK button
procedure(deviceSelectionFormOK()
  let((form)
    form = _deviceSelectionForm
    
    ;; Store selections in global variables
    setq(_nmosDevice hiGetCyclicFieldValue(form 'nmosField))
    setq(_pmosDevice hiGetCyclicFieldValue(form 'pmosField))
    setq(_indDevice hiGetCyclicFieldValue(form 'indField))
    setq(_capDevice hiGetCyclicFieldValue(form 'capField))
    setq(_resDevice hiGetCyclicFieldValue(form 'resField))
    
    ;; Print selections
    printf("Selected devices:\n")
    printf("  NMOS: %s\n", _nmosDevice)
    printf("  PMOS: %s\n", _pmosDevice)
    printf("  Inductor: %s\n", _indDevice)
    printf("  Capacitor: %s\n", _capDevice)
    printf("  Resistor: %s\n", _resDevice)
    
    ;; Continue with design after selections are made
    setq(_deviceSelectionComplete t)
  )
)

;; Helper function to select library
procedure(selectLibrary()
  let((availLibs selectedLib)
    availLibs = listAvailableLibraries()
    
    ;; Create form to select library
    form = hiCreateAppForm(
      ?name           'librarySelectionForm
      ?formTitle      "Library Selection"
      ?callback       nil
      ?buttonLayout   'OKCancel
      ?unmapAfterCB   t
    )
    
    ;; Convert library list to string list for form display
    libNames = '()
    foreach(lib availLibs
      libNames = append(libNames list(lib->name))
    )
    
    ;; Sort library names alphabetically - using lexLess instead of alphLessp
    libNames = sort(libNames 'lexLess)
    
    ;; Library selection field
    hiCreateCyclicField(
      ?parent         form
      ?name           'libField
      ?prompt         "Select a device library:"
      ?choices        libNames
      ?value          if(member("analogLib" libNames) "analogLib" car(libNames))
    )
    
    ;; Set form callback
    hiSetFormCallbacks(form
      ?okCallBack     "librarySelectionFormOK()"
    )
    
    ;; Display the form
    hiDisplayForm(form)
    
    ;; Create global variable to store form
    setq(_librarySelectionForm form)
    
    ;; Wait for selection (this is a blocking approach)
    setq(_librarySelectionComplete nil)
    while(!_librarySelectionComplete 
      hiDisplayForm(form)
      sleep(1)
    )
    
    ;; Return the selected library
    _selectedLibrary
  )
)

;; Callback function for library selection form
procedure(librarySelectionFormOK()
  form = _librarySelectionForm
  setq(_selectedLibrary hiGetCyclicFieldValue(form 'libField))
  setq(_librarySelectionComplete t)
  printf("Selected library: %s\n", _selectedLibrary)
)

;; Modified function to load required libraries with user selection
procedure(createClassABPA()
  let((lib cell view cvId tech deviceLib
       driverNmos powerNmos
       inst1 inst2 inst3 inst4 inst5 inst6 inst7 inst8 inst9 inst10
       powerInst1 powerInst2 powerInst3 powerInst4)
    
    ;; Set technology library and views
    lib = "RFIC_Designs"
    cell = "ClassAB_PA_65nm"
    view = "schematic"
    tech = "65nm_CMOS"
    
    ;; Create new cell view
    unless(ddGetObj(lib cell view)
      dbCreateLib(lib)
    )
    
    ;; Open a new cellview
    cvId = dbOpenCellViewByType(lib cell view "schematic" "w")
    
    ;; First let user select library
    printf("Please select a library for devices...\n")
    deviceLib = selectLibrary()
    
    unless(deviceLib
      error("No library selected.")
      dbClose(cvId)
      return(nil)
    )
    
    ;; Show device selection form
    printf("Please select devices from the form...\n")
    showDeviceSelectionForm(deviceLib)
    
    ;; Wait for device selection to complete (blocking approach)
    setq(_deviceSelectionComplete nil)
    while(!_deviceSelectionComplete
      sleep(1)
    )
    
    ;; Use the selected devices
    nmosLib = deviceLib
    pmosLib = deviceLib
    indLib = deviceLib
    capLib = deviceLib
    resLib = deviceLib
    
    nmosMaster = _nmosDevice
    pmosMaster = _pmosDevice
    indMaster = _indDevice
    capMaster = _capDevice
    resMaster = _resDevice
    
    ;; Check available views for each component
    nmosCellView = nil
    pmosCellView = nil
    indCellView = nil
    capCellView = nil
    resCellView = nil
    
    ;; Try common view names - fixing foreach syntax
    viewNames = '("symbol" "schematic")
    foreach(viewName viewNames
      when(ddGetObj(nmosLib nmosMaster viewName)
        nmosCellView = dbOpenCellViewByType(nmosLib nmosMaster viewName)
        printf("Found NMOS view: %s\n", viewName)
        break()
      )
    )
    
    foreach(viewName viewNames
      when(ddGetObj(pmosLib pmosMaster viewName)
        pmosCellView = dbOpenCellViewByType(pmosLib pmosMaster viewName)
        printf("Found PMOS view: %s\n", viewName)
        break()
      )
    )
    
    foreach(viewName viewNames
      when(ddGetObj(indLib indMaster viewName)
        indCellView = dbOpenCellViewByType(indLib indMaster viewName)
        printf("Found inductor view: %s\n", viewName)
        break()
      )
    )
    
    foreach(viewName viewNames
      when(ddGetObj(capLib capMaster viewName)
        capCellView = dbOpenCellViewByType(capLib capMaster viewName)
        printf("Found capacitor view: %s\n", viewName)
        break()
      )
    )
    
    foreach(viewName viewNames
      when(ddGetObj(resLib resMaster viewName)
        resCellView = dbOpenCellViewByType(resLib resMaster viewName)
        printf("Found resistor view: %s\n", viewName)
        break()
      )
    )
    
    ;; Check if we were able to open all required cell views
    if(nmosCellView && pmosCellView && indCellView && capCellView && resCellView then
      printf("All cell views opened successfully.\n")
    else
      error("Could not open all required cell views.")
      dbClose(cvId)
      return(nil)
    )
    
    ;; Create nets first
    vdd = dbCreateNet(cvId "VDD")
    gnd = dbCreateNet(cvId "GND")
    rf_in = dbCreateNet(cvId "RF_IN")
    rf_out = dbCreateNet(cvId "RF_OUT")
    bias1 = dbCreateNet(cvId "BIAS1")
    bias2 = dbCreateNet(cvId "BIAS2")
    rf_in_ext = dbCreateNet(cvId "RF_IN_EXT")
    ant_in = dbCreateNet(cvId "ANT_IN")
    interstage = dbCreateNet(cvId "INTERSTAGE")
    out_match = dbCreateNet(cvId "OUT_MATCH")
    ant_out = dbCreateNet(cvId "ANT_OUT")
    
    ;; Create pins using rectangle shapes (most compatible approach)
    dbCreateRect(cvId "pin" list(25:25 75:75))
    dbCreateRect(cvId "pin" list(625:25 675:75))
    dbCreateRect(cvId "pin" list(25:325 75:375))
    dbCreateRect(cvId "pin" list(25:525 75:575))
    dbCreateRect(cvId "pin" list(-75:25 -25:75))
    dbCreateRect(cvId "pin" list(700:25 750:75))
    
    ;; Place labels for visual identification
    dbCreateLabel(cvId "pin" 50:50 "RF_IN" "centerRight" "R0" "stick" 1.0)
    dbCreateLabel(cvId "pin" 650:50 "RF_OUT" "centerLeft" "R0" "stick" 1.0)
    dbCreateLabel(cvId "pin" 50:350 "VDD" "centerRight" "R0" "stick" 1.0)
    dbCreateLabel(cvId "pin" 50:550 "GND" "centerRight" "R0" "stick" 1.0)
    dbCreateLabel(cvId "pin" -50:50 "ANT_IN" "centerLeft" "R0" "stick" 1.0)
    dbCreateLabel(cvId "pin" 725:50 "ANT_OUT" "centerLeft" "R0" "stick" 1.0)
    
    ;; ===== Driver Stage =====
    ;; Driver transistor - sized for pre-amplification
    driverNmos = dbCreateInst(cvId nmosCellView "M1" list(100 100) "R0")
    schSetFigProperty(driverNmos list("w" 240u))
    schSetFigProperty(driverNmos list("l" 0.06u))
    schSetFigProperty(driverNmos list("fingers" 20))
    
    ;; Connect instances using dbCreateLine instead of dbCreateWire
    dbCreateLine(cvId "route" list(100:100 rf_in))
    dbCreateLine(cvId "route" list(100:130 bias1))
    dbCreateLine(cvId "route" list(100:70 gnd))
    dbCreateLine(cvId "route" list(130:100 gnd))
    
    ;; Driver bias circuit
    inst1 = dbCreateInst(cvId resCellView "R1" list(100 200) "R0")
    schSetFigProperty(inst1 list("resistance" 5k))
    dbCreateLine(cvId "route" list(100:230 vdd))
    dbCreateLine(cvId "route" list(100:170 bias1))
    
    ;; Gate bias resistor
    inst2 = dbCreateInst(cvId resCellView "R_BIAS1" list(50 100) "R0")
    schSetFigProperty(inst2 list("resistance" 10k))
    dbCreateLine(cvId "route" list(50:130 bias1))
    dbCreateLine(cvId "route" list(50:70 rf_in))
    
    ;; DC blocking capacitor for input
    inst3 = dbCreateInst(cvId capCellView "C_IN" list(0 100) "R0")
    schSetFigProperty(inst3 list("capacitance" 2p))
    dbCreateLine(cvId "route" list(20:100 rf_in))
    dbCreateLine(cvId "route" list(-20:100 rf_in_ext))
    
    ;; Input matching network for 3.3-3.8 GHz (L-network)
    inst4 = dbCreateInst(cvId indCellView "L_IN" list(-50 100) "R0")
    schSetFigProperty(inst4 list("inductance" 1.8n))
    dbCreateLine(cvId "route" list(-30:100 rf_in_ext))
    dbCreateLine(cvId "route" list(-70:100 ant_in))
    
    inst5 = dbCreateInst(cvId capCellView "C_IN_SHUNT" list(0 50) "R0")
    schSetFigProperty(inst5 list("capacitance" 0.8p))
    dbCreateLine(cvId "route" list(0:70 rf_in))
    dbCreateLine(cvId "route" list(0:30 gnd))
    
    ;; Interstage matching (between driver and power stage)
    inst6 = dbCreateInst(cvId capCellView "C_INTER" list(150 100) "R0")
    schSetFigProperty(inst6 list("capacitance" 1.2p))
    dbCreateLine(cvId "route" list(130:100 bias1))
    dbCreateLine(cvId "route" list(170:100 interstage))
    
    inst7 = dbCreateInst(cvId indCellView "L_INTER" list(200 150) "R0")
    schSetFigProperty(inst7 list("inductance" 1.5n))
    dbCreateLine(cvId "route" list(180:150 interstage))
    dbCreateLine(cvId "route" list(220:150 bias2))
    
    ;; ===== Power Stage =====
    ;; Power transistor - sized for 23 dBm output power
    powerNmos = dbCreateInst(cvId nmosCellView "M2" list(250 100) "R0")
    schSetFigProperty(powerNmos list("w" 1200u))
    schSetFigProperty(powerNmos list("l" 0.06u))
    schSetFigProperty(powerNmos list("fingers" 80))
    
    dbCreateLine(cvId "route" list(250:100 bias2))
    dbCreateLine(cvId "route" list(250:130 bias2))
    dbCreateLine(cvId "route" list(250:70 gnd))
    dbCreateLine(cvId "route" list(280:100 gnd))
    
    ;; Power bias circuit
    inst8 = dbCreateInst(cvId resCellView "R2" list(250 200) "R0")
    schSetFigProperty(inst8 list("resistance" 3k))
    dbCreateLine(cvId "route" list(250:230 vdd))
    dbCreateLine(cvId "route" list(250:170 bias2))
    
    ;; Output matching network for 3.3-3.8 GHz
    inst9 = dbCreateInst(cvId capCellView "C_OUT" list(300 100) "R0")
    schSetFigProperty(inst9 list("capacitance" 1.5p))
    dbCreateLine(cvId "route" list(280:100 bias2))
    dbCreateLine(cvId "route" list(320:100 out_match))
    
    inst10 = dbCreateInst(cvId indCellView "L_OUT" list(350 100) "R0")
    schSetFigProperty(inst10 list("inductance" 2.2n))
    dbCreateLine(cvId "route" list(330:100 out_match))
    dbCreateLine(cvId "route" list(370:100 rf_out))
    
    ;; DC blocking capacitor for output
    powerInst1 = dbCreateInst(cvId capCellView "C_OUT_DC" list(400 100) "R0")
    schSetFigProperty(powerInst1 list("capacitance" 2p))
    dbCreateLine(cvId "route" list(380:100 rf_out))
    dbCreateLine(cvId "route" list(420:100 ant_out))
    
    ;; Supply choke
    powerInst2 = dbCreateInst(cvId indCellView "L_CHOKE" list(250 250) "R0")
    schSetFigProperty(powerInst2 list("inductance" 5n))
    dbCreateLine(cvId "route" list(230:250 vdd))
    dbCreateLine(cvId "route" list(270:250 bias2))
    
    ;; Stability network
    powerInst3 = dbCreateInst(cvId resCellView "R_STAB" list(200 100) "R0")
    schSetFigProperty(powerInst3 list("resistance" 300))
    dbCreateLine(cvId "route" list(200:130 bias2))
    dbCreateLine(cvId "route" list(200:70 gnd))
    
    powerInst4 = dbCreateInst(cvId capCellView "C_STAB" list(200 50) "R0")
    schSetFigProperty(powerInst4 list("capacitance" 0.5p))
    dbCreateLine(cvId "route" list(200:70 bias2))
    dbCreateLine(cvId "route" list(200:30 gnd))
    
    ;; Save the cellview
    dbSave(cvId)
    dbClose(cvId)
    
    ;; Print message when done
    printf("Class AB Power Amplifier design complete:\n")
    printf("- Design specifications:\n")
    printf("  * Frequency: 3.3-3.8 GHz\n")
    printf("  * Output Power: 23 dBm\n")
    printf("  * Gain: 25 dB\n")
    printf("  * PAE: 45%%\n")
    printf("  * Supply: 3.3 V\n")
    printf("  * ACLR: -35 dBc\n")
    printf("  * EVM: 5%%\n")
    printf("- Library: %s\n", lib)
    printf("- Cell: %s\n", cell)
    printf("- View: %s\n", view)
    
    return(t)
  )
)

;; Improved procedure for displaying a GUI based on Cadence samples
procedure(showDesignToolUI()
  printf("\n[DEBUG] Starting showDesignToolUI procedure...\n")
  printf("[DEBUG] Creating form interface...\n")
  
  let((descTitle operationsFrame designButton listLibButton browseButton recommendButton form)
    ;; Create title label
    descTitle = hiCreateLabel(
      ?name           'descTitle
      ?labelText      "Class AB Power Amplifier Design (3.3-3.8 GHz, 23 dBm)"
      ?justification  'center
    )
    
    ;; Create a frame to group operations - fixing param name from ?title to ?labelText
    operationsFrame = hiCreateFrameField(
      ?name           'operationsFrame
      ?labelText      "Design Operations"
    )
    
    ;; Add description label inside frame
    hiCreateLabel(
      ?parent         operationsFrame
      ?name           'descriptionLabel
      ?labelText      "Select an operation:"
    )
    
    ;; Create buttons inside the operations frame
    designButton = hiCreateButton(
      ?parent         operationsFrame
      ?name           'designButton
      ?buttonText     "Design PA"
      ?callback       "createClassABPA()"
    )
    
    listLibButton = hiCreateButton(
      ?parent         operationsFrame
      ?name           'listLibButton
      ?buttonText     "List Libraries"
      ?callback       "listAvailableLibraries()"
    )
    
    browseButton = hiCreateButton(
      ?parent         operationsFrame
      ?name           'browseButton
      ?buttonText     "Browse Libraries"
      ?callback       "browseLibraries()"
    )
    
    recommendButton = hiCreateButton(
      ?parent         operationsFrame
      ?name           'recommendButton
      ?buttonText     "Recommend Devices"
      ?callback       "recommendDevices()"
    )
    
    ;; Create the form with pre-created fields
    form = hiCreateAppForm(
      ?name           'designToolForm
      ?formTitle      "Class AB Power Amplifier Design Tool"
      ?fields         list(descTitle operationsFrame)
      ?buttonLayout   'OKCancel
      ?unmapAfterCB   nil
    )
    
    ;; Set form callbacks using sample-based pattern
    hiSetFormCallbacks(form
      ?okCallBack       "designFormOK()"
      ?cancelCallBack   "designFormCancel()"
    )
    
    ;; Display the form - as done in sample code
    hiDisplayForm(form)
    printf("[DEBUG] Form created and displayed\n")
    
    ;; Store form for global reference
    setq(_designToolForm form)
    
    ;; Return the form handle
    form
  )
)

;; Callback functions for the design form
procedure(designFormOK()
  let((form)
    form = hiGetCurrentForm()
    printf("[DEBUG] Form OK clicked, closing form\n")
    hiFormDone(form)
    t  ;; Return t to indicate successful completion
  )
)

procedure(designFormCancel()
  let((form)
    form = hiGetCurrentForm()
    printf("[DEBUG] Form Cancel clicked, closing form\n")
    hiFormCancel(form)
    t  ;; Return t to indicate successful completion
  )
)

;; Helper function to browse libraries with GUI
procedure(browseLibraries()
  printf("[DEBUG] Starting browseLibraries procedure...\n")
  let((form libs libNames selectedLib)
    ;; Get list of libraries
    printf("[DEBUG] Fetching library list...\n")
    libs = ddGetLibList()
    libNames = '()
    foreach(lib libs
      libNames = append(libNames list(lib->name))
    )
    printf("[DEBUG] Found %d libraries\n" length(libNames))
    
    ;; Sort library names alphabetically - using lexLess which is a standard function
    libNames = sort(libNames 'lexLess)
    printf("[DEBUG] Sorted library names\n")
    
    ;; Display library list dialog
    printf("[DEBUG] Creating library list dialog...\n")
    hiDisplayListBox(
      ?name           'libListDialog
      ?dboxBanner     "Select a Library"
      ?buttonLayout   'OKCancel
      ?choices        libNames
      ?numVisChoice   15
      ?itemAction     "browseLibraryContents()"
    )
    printf("[DEBUG] Library list dialog displayed\n")
  )
)

;; Enhanced function to display device details when browsing libraries
procedure(browseLibraryContents()
  printf("[DEBUG] Starting browseLibraryContents procedure...\n")
  let((libName cells cellNames)
    ;; Use hiGetSelectedItem as shown in samples
    libName = hiGetSelectedItem()
    printf("[DEBUG] Selected library: %L\n" libName)
    
    ;; Get cells
    printf("[DEBUG] Fetching cells from library %L...\n" libName)
    cells = listCellsInLibrary(libName)
    
    ;; Display in a new list box or dialog
    if(cells != nil then
      cellNames = '()
      foreach(cell cells
        cellNames = append(cellNames list(cell->name))
      )
      printf("[DEBUG] Found %d cells in library\n" length(cellNames))
      
      ;; If there are cells, display them
      if(length(cellNames) > 0 then
        printf("[DEBUG] Creating cell list dialog...\n")
        hiDisplayListBox(
          ?name           'cellListDialog
          ?dboxBanner     sprintf(nil "Cells in %s" libName)
          ?buttonLayout   'OKCancel
          ?choices        cellNames
          ?numVisChoice   15
          ?itemAction     sprintf(nil "viewDeviceDetails(\"%s\")" libName)
        )
        printf("[DEBUG] Cell list dialog displayed\n")
      else
        printf("[DEBUG] No cells found, displaying message box\n")
        hiDisplayAppDBox(
          ?name           'noCellsDialog
          ?dboxBanner     "No Cells"
          ?dboxText       sprintf(nil "No cells found in library %s" libName)
          ?buttonLayout   'OK
        )
      )
    )
  )
)

;; New function to view details of selected device
procedure(viewDeviceDetails(libName)
  let((cellName views viewNames parameters)
    cellName = hiGetSelectedItem()
    printf("[DEBUG] Viewing details for %s in library %s\n" cellName libName)
    
    ;; Get views for the cell
    views = ddGetObj(libName cellName)->views
    viewNames = '()
    foreach(view views
      viewNames = append(viewNames list(view->name))
    )
    
    ;; Try to get device parameters if a symbol or model view exists
    parameters = getDeviceParameters(libName cellName)
    
    ;; Create a dialog to show device details
    hiDisplayAppDBox(
      ?name           'deviceDetailsDialog
      ?dboxBanner     sprintf(nil "Device Details: %s" cellName)
      ?dboxText       sprintf(nil "Library: %s\nCell: %s\nAvailable Views: %L\n%s" 
                              libName cellName viewNames parameters)
      ?buttonLayout   'OK
    )
  )
)

;; Helper function to extract device parameters based on device type
procedure(getDeviceParameters(libName cellName)
  let((result paramStr viewObj paramNames)
    result = ""
    
    ;; Determine likely device type based on name
    cond(
      ((rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
        paramStr = "Device Type: NMOS Transistor\n"
        paramNames = '("w" "l" "fingers" "m" "nf")
      )
      ((rexMatchp("p[a-z]*" cellName) || rexMatchp("pmos" cellName) || rexMatchp("pfet" cellName))
        paramStr = "Device Type: PMOS Transistor\n"
        paramNames = '("w" "l" "fingers" "m" "nf")
      )
      ((rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName))
        paramStr = "Device Type: Inductor\n"
        paramNames = '("inductance" "q" "dcr")
      )
      ((rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName))
        paramStr = "Device Type: Capacitor\n"
        paramNames = '("capacitance" "tc")
      )
      ((rexMatchp("res" cellName) || rexMatchp("poly" cellName) || rexMatchp("r[0-9]+" cellName))
        paramStr = "Device Type: Resistor\n"
        paramNames = '("resistance" "tc")
      )
      (t
        paramStr = "Device Type: Unknown\n"
        paramNames = '()
      )
    )
    
    ;; Try to get parameters from master
    foreach(viewName '("symbol" "schematic" "spectre"))
      when(ddGetObj(libName cellName viewName)
        viewObj = dbOpenCellViewByType(libName cellName viewName "r")
        when(viewObj
          paramStr = strcat(paramStr "Default Values:\n")
          foreach(param paramNames
            paramValue = dbGetPropByName(viewObj param)
            when(paramValue
              paramStr = strcat(paramStr sprintf(nil "  %s: %L\n" param paramValue))
            )
          )
          dbClose(viewObj)
        )
        break()
      )
    )
    
    ;; Add suitability assessment for our design
    paramStr = strcat(paramStr "\nSuitability Assessment:\n")
    cond(
      ((rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName))
        paramStr = strcat(paramStr "  - Can be used for driver or power stage\n")
        paramStr = strcat(paramStr "  - Check W/L ratio for current capability\n")
        paramStr = strcat(paramStr "  - Verify ft/fmax at 3.3-3.8 GHz\n")
      )
      ((rexMatchp("ind" cellName))
        paramStr = strcat(paramStr "  - Suitable for matching networks\n")
        paramStr = strcat(paramStr "  - Check Q factor at 3.3-3.8 GHz\n")
      )
      ((rexMatchp("cap" cellName))
        paramStr = strcat(paramStr "  - Suitable for DC blocking and matching\n")
        paramStr = strcat(paramStr "  - Verify self-resonance > 3.8 GHz\n")
      )
      ((rexMatchp("res" cellName))
        paramStr = strcat(paramStr "  - Can be used for bias networks\n")
      )
    )
    
    paramStr
  )
)

;; New function to recommend devices from available libraries
procedure(recommendDevices()
  let((libs recommendations nmosRecs indRecs capRecs resRecs)
    printf("Analyzing libraries for PA design recommendations...\n")
    
    ;; Get all libraries
    libs = ddGetLibList()
    
    ;; Initialize recommendation lists
    nmosRecs = '()
    indRecs = '()
    capRecs = '()
    resRecs = '()
    
    ;; Search each library
    foreach(lib libs
      ;; Skip system libraries
      unless(member(lib->name '("NCSU_TechLib_FreePDK45" "NCSU_Devices_FreePDK45" 
                               "basic" "analogLib" "US_8ths"))
        cellObjs = lib->cells
        foreach(cell cellObjs
          cellName = cell->name
          
          ;; Check for NMOS with appropriate specs
          when(rexMatchp("n[a-z]*" cellName) || rexMatchp("nmos" cellName) || rexMatchp("nfet" cellName)
            nmosRecs = append(nmosRecs list(list(lib->name cellName)))
          )
          
          ;; Check for inductors with appropriate specs
          when(rexMatchp("ind" cellName) || rexMatchp("spiral" cellName) || rexMatchp("coil" cellName)
            indRecs = append(indRecs list(list(lib->name cellName)))
          )
          
          ;; Check for capacitors with appropriate specs
          when(rexMatchp("cap" cellName) || rexMatchp("mim" cellName) || rexMatchp("c[0-9]+" cellName)
            capRecs = append(capRecs list(list(lib->name cellName)))
          )
          
          ;; Check for resistors with appropriate specs
          when(rexMatchp("res" cellName) || rexMatchp("poly" cellName) || rexMatchp("r[0-9]+" cellName)
            resRecs = append(resRecs list(list(lib->name cellName)))
          )
        )
      )
    )
    
    ;; Display recommendations
    displayRecommendations(nmosRecs indRecs capRecs resRecs)
  )
)

;; Helper function to display device recommendations
procedure(displayRecommendations(nmosRecs indRecs capRecs resRecs)
  let((recText)
    recText = "DEVICE RECOMMENDATIONS FOR CLASS AB PA DESIGN\n\n"
    
    ;; NMOS recommendations
    recText = strcat(recText "NMOS TRANSISTORS (for driver and power stages):\n")
    if(length(nmosRecs) > 0 then
      foreach(rec nmosRecs
        recText = strcat(recText sprintf(nil "  - %s::%s\n" car(rec) cadr(rec)))
      )
    else
      recText = strcat(recText "  No suitable NMOS transistors found\n")
    )
    
    ;; Inductor recommendations
    recText = strcat(recText "\nINDUCTORS (for matching networks):\n")
    if(length(indRecs) > 0 then
      foreach(rec indRecs
        recText = strcat(recText sprintf(nil "  - %s::%s\n" car(rec) cadr(rec)))
      )
    else
      recText = strcat(recText "  No suitable inductors found\n")
    )
    
    ;; Capacitor recommendations
    recText = strcat(recText "\nCAPACITORS (for DC blocking & matching):\n")
    if(length(capRecs) > 0 then
      foreach(rec capRecs
        recText = strcat(recText sprintf(nil "  - %s::%s\n" car(rec) cadr(rec)))
      )
    else
      recText = strcat(recText "  No suitable capacitors found\n")
    )
    
    ;; Resistor recommendations
    recText = strcat(recText "\nRESISTORS (for biasing):\n")
    if(length(resRecs) > 0 then
      foreach(rec resRecs
        recText = strcat(recText sprintf(nil "  - %s::%s\n" car(rec) cadr(rec)))
      )
    else
      recText = strcat(recText "  No suitable resistors found\n")
    )
    
    ;; Display recommendations in a dialog
    hiDisplayAppDBox(
      ?name           'recommendationsDialog
      ?dboxBanner     "Device Recommendations"
      ?dboxText       recText
      ?buttonLayout   'OK
    )
  )
)

;; Helper function to prompt for library and list cells
procedure(promptAndListCells()
  browseLibraries()
)

;; Main startup procedure - completely GUI-based
procedure(main()
  printf("\n[DEBUG] ====================================\n")
  printf("[DEBUG] Starting Class AB PA Design Tool...\n")
  printf("[DEBUG] ====================================\n")
  printf("Class AB Power Amplifier Design Tool (65nm CMOS)\n")
  printf("=============================================\n")
  printf("Starting GUI interface...\n")
  
  ;; Display the main interface directly without error protection for debugging
  printf("[DEBUG] Calling showDesignToolUI...\n")
  showDesignToolUI()
  printf("[DEBUG] GUI initialization complete\n")
)

;; Launch the main function directly without error protection for debugging
main()