# SKILL API Quick Reference

## Graphics Editor Functions

### Design Functions
- `geChangeCellView(libName cellName viewName)`
  Input:
    - libName: string - Library name
    - cellName: string - Cell name
    - viewName: string - View name
  Returns: window - Window object of opened cellview

- `geSave(window)`
  Input:
    - window: window - Window object to save
  Returns: boolean - True if save successful

- `geSaveAs(window libName cellName viewName)`
  Input:
    - window: window - Source window
    - libName: string - Target library name
    - cellName: string - Target cell name
    - viewName: string - Target view name
  Returns: window - New window object

### Selection Functions
- `geSelectObject(window obj)`
  Input:
    - window: window - Target window
    - obj: dbObject - Object to select
  Returns: boolean - True if selection successful

- `geSelectArea(window bBox)`
  Input:
    - window: window - Target window
    - bBox: list - Selection area ((llx lly) (urx ury))
  Returns: list - List of selected objects

- `geDeselectAll(window)`
  Input:
    - window: window - Target window
  Returns: boolean - True if deselection successful

- `geGetSelSet(window)`
  Input:
    - window: window - Source window
  Returns: list - List of currently selected objects

### Display Functions
- `geRefresh(window)`
  Input:
    - window: window - Window to refresh
  Returns: boolean - True if refresh successful

- `geRefreshWindow(window)`
  Input:
    - window: window - Window to refresh
  Returns: boolean - True if refresh successful

- `geGetWindowCellView(window)`
  Input:
    - window: window - Source window
  Returns: cellView - Cellview object associated with window

## Database Access Functions

### Shape Creation
- `dbCreateLine(cv points [?layer "drawing"] [?width 0.0] [?purpose nil])`
  Input:
    - cv: cellView - Target cellview
    - points: list - List of points ((x1 y1) (x2 y2) ...)
    - ?layer: string - Optional layer name
    - ?width: float - Optional line width
    - ?purpose: string - Optional purpose name
  Returns: dbObject - The created line object

- `dbCreatePath()` - Create a path shape
- `dbCreatePolygon()` - Create a polygon shape
- `dbCreateRect(cv bBox [?layer "drawing"] [?purpose nil])`
  Input:
    - cv: cellView - Target cellview
    - bBox: list - Bounding box ((llx lly) (urx ury))
    - ?layer: string - Optional layer name
    - ?purpose: string - Optional purpose name
  Returns: dbObject - The created rectangle object

- `dbCreateEllipse()` - Create an ellipse shape
- `dbCreateArc()` - Create an arc shape

### Instance Management
- `dbCreateInst(cv libName cellName viewName xy [?orient "R0"])`
  Input:
    - cv: cellView - Target cellview
    - libName: string - Library name
    - cellName: string - Cell name
    - viewName: string - View name
    - xy: list - Instance origin point (x y)
    - ?orient: string - Optional orientation
  Returns: dbObject - The created instance object

- `dbCreateParamInst()` - Create a parameterized instance
- `dbFindAnyInstByName()` - Find instance by name
- `dbGetInstTransform()` - Get instance transformation

### Connectivity
- `dbCreateNet(cv name)`
  Input:
    - cv: cellView - Target cellview
    - name: string - Net name
  Returns: dbObject - The created net object

- `dbCreateTerm()` - Create a terminal
- `dbCreatePin(net term [?name nil] [?accessDir "input"])`
  Input:
    - net: dbObject - Net object
    - term: dbObject - Terminal object
    - ?name: string - Optional pin name
    - ?accessDir: string - Optional access direction
  Returns: dbObject - The created pin object

- `dbFindNetByName()` - Find net by name
- `dbGetNetTerms()` - Get terminals of a net

### File Operations
- `dbOpenCellViewByType()` - Open a cellview
- `dbSave()` - Save current cellview
- `dbClose()` - Close a cellview
- `dbPurge()` - Purge cellview from memory

### Property Management
- `dbCreateProp()` - Create a property
- `dbFindProp()` - Find a property
- `dbReplaceProp()` - Replace property value
- `dbCopyProp()` - Copy properties

### Shape Transformation
- `dbTransformPoint()` - Transform a point
- `dbTransformBBox()` - Transform a bounding box

### Design Management
- `ddCreateLib()` - Create a library
- `ddGetObj()` - Get design object
- `ddGetObjName()` - Get object name
- `ddIsObjReadable()` - Check if object is readable
- `ddIsObjWritable()` - Check if object is writable

## Layout Functions

### Placement
- `dbCreatePlaceArea()` - Define placement area
- `dbSetPlaceAreaOrient()` - Set placement area orientation
- `dbSetPlacementGrid()` - Set placement grid
- `dbCreateRow()` - Create a placement row

### Layout Operations
- `dbCompressPointArray()` - Compress point array data
- `dbLayerAnd()` - Perform AND operation on layers
- `dbLayerOr()` - Perform OR operation on layers
- `dbLayerXor()` - Perform XOR operation on layers
- `dbLayerSize()` - Size a layer

## Verification Functions

### DRC/LVS
- `geValidP()` - Validate design object
- `dbCheckParamCell()` - Check parameterized cell
- `dbDumpPcell()` - Dump pcell definition
- `dbEvalParamCell()` - Evaluate parameterized cell

### EM Analysis
- `txCreateFigSet()` - Create figure set for EM analysis
- `txGetFigSetBBox()` - Get figure set bounding box
- `txMoveFigSet()` - Move figure set
- `txConcatFigSet()` - Concatenate figure sets

### Verification
- `autoRfic->runDrc(layout)`
  Input:
    - layout: dbObject - Target layout
  Returns: list - List of DRC violations or nil if clean

- `autoRfic->runLvs(layout schematic)`
  Input:
    - layout: dbObject - Layout cellview
    - schematic: dbObject - Schematic cellview
  Returns: list - LVS comparison results

- `autoRfic->extractParasitics(layout)`
  Input:
    - layout: dbObject - Layout cellview
  Returns: dbObject - Extracted netlist with parasitics

## RF-Specific Functions

### RF Analysis
- `setupAnalysis(testbench type params)`
  Input:
    - testbench: dbObject - Target testbench
    - type: string - Analysis type ("sp", "harmonic", "envelope")
    - params: list - Analysis parameters (frequency range, harmonics, etc.)
  Returns: boolean - True if analysis setup successful

- `runEMAnalysis(component freqRange)` - Run electromagnetic analysis
- `runHarmonicBalance(testbench params)`
  Input:
    - testbench: dbObject - Target testbench
    - params: list - HB parameters (fundamentals, harmonics, sweep)
  Returns: list - Analysis results including harmonics

- `runEnvelopeAnalysis(testbench params)`
  Input:
    - testbench: dbObject - Target testbench
    - params: list - Envelope parameters (carrier, modulation)
  Returns: list - Envelope simulation results

### RF Layout
- `createRfStructure(layout type params)`
  Input:
    - layout: dbObject - Target layout
    - type: string - Structure type ("inductor", "balun", etc.)
    - params: list - Structure parameters (geometry, metal layers)
  Returns: dbObject - Created RF structure

- `optimizeRfPlacement(layout constraints)`
  Input:
    - layout: dbObject - Target layout
    - constraints: list - EM and routing constraints
  Returns: boolean - True if optimization successful

- `createShieldingStructure(component params)`
  Input:
    - component: dbObject - Component to shield
    - params: list - Shielding parameters (layers, spacing)
  Returns: dbObject - Created shielding structure

- `createSymmetricLayout(component axis)`
  Input:
    - component: dbObject - Component to symmetrize
    - axis: string - Symmetry axis ("vertical" or "horizontal")
  Returns: dbObject - Modified symmetric layout

## Auto RFIC Framework

### Configuration
- `autoRfic->getParameter(name [default])`
  Input:
    - name: string - Parameter name
    - default: any - Optional default value
  Returns: any - Parameter value or default if not found

- `autoRfic->setParameter(name value)`
  Input:
    - name: string - Parameter name
    - value: any - Value to set
  Returns: boolean - True if successful

- `autoRfic->saveConfig(filename)` - Save configuration to file
- `autoRfic->loadConfig(filename)` - Load configuration from file

### Schematic Design
- `autoRfic->createTemplate(name params)`
  Input:
    - name: string - Template name (e.g., "lna", "mixer")
    - params: list - Parameter list (e.g., list('gain 20.0 'nf 2.0))
  Returns: dbObject - Created template object

- `autoRfic->generateSchematic(template params)`
  Input:
    - template: dbObject - Template object
    - params: list - Generation parameters
  Returns: dbObject - Generated schematic cellview

- `autoRfic->optimizeParameters(schematic params constraints)` - Optimize parameters

### Simulation
- `autoRfic->createTestbench(schematic)`
  Input:
    - schematic: dbObject - Source schematic
  Returns: dbObject - Created testbench

- `autoRfic->setupAnalysis(testbench type params)`
  Input:
    - testbench: dbObject - Testbench object
    - type: string - Analysis type ("sp", "dc", "tran", etc.)
    - params: list - Analysis parameters
  Returns: boolean - True if setup successful

- `autoRfic->runSimulation(testbench)` - Run simulation
- `autoRfic->getResults(testbench)` - Get simulation results

### Layout Generation
- `autoRfic->createFloorplan(schematic)`
  Input:
    - schematic: dbObject - Source schematic
  Returns: dbObject - Created layout cellview

- `autoRfic->placeComponents(layout)`
  Input:
    - layout: dbObject - Target layout
  Returns: boolean - True if placement successful

- `autoRfic->routeNets(layout)` - Route nets in layout
- `autoRfic->createRfStructure(layout type params)`
  Input:
    - layout: dbObject - Target layout
    - type: string - Structure type ("inductor", "transmission_line", etc.)
    - params: list - Structure parameters
  Returns: dbObject - Created RF structure

### Verification
- `autoRfic->runDrc(layout)`
  Input:
    - layout: dbObject - Target layout
  Returns: list - List of DRC violations or nil if clean

- `autoRfic->runLvs(layout schematic)`
  Input:
    - layout: dbObject - Layout cellview
    - schematic: dbObject - Schematic cellview
  Returns: list - LVS comparison results

- `autoRfic->extractParasitics(layout)`
  Input:
    - layout: dbObject - Layout cellview
  Returns: dbObject - Extracted netlist with parasitics

## FigSet Functions

### Basic Operations
- `txCreateFigSet(cellView [name])`
  Input:
    - cellView: dbObject - Target cellview
    - name: string (optional) - Name for the FigSet
  Returns: txObject - Created FigSet object or nil on failure

- `txGetFigSetData(figSet entry)`
  Input:
    - figSet: txObject - Target FigSet
    - entry: number - Index of object to retrieve
  Returns: object - The nth object (dbObject or txObject) or nil if not found

- `txAppendObjectToFigSet(figSet object)`
  Input:
    - figSet: txObject - Target FigSet
    - object: object - Figure or FigSet to append
  Returns: boolean - True if successful

### FigSet Management
- `txClearFigSet(figSet)`
  Input:
    - figSet: txObject - FigSet to clear
  Returns: boolean - True if successful

- `txCloneFigSet(destFigSet srcFigSet)`
  Input:
    - destFigSet: txObject - Target FigSet
    - srcFigSet: txObject - Source FigSet
  Returns: boolean - True if successful
  Note: Creates references, not copies of objects

- `txConcatFigSet(figSet1 figSet2)`
  Input:
    - figSet1: txObject - Target FigSet
    - figSet2: txObject - FigSet to append
  Returns: boolean - True if successful

### FigSet Manipulation
- `txCopyFigSet(srcFigSet transform)`
  Input:
    - srcFigSet: txObject - Source FigSet
    - transform: list - ((offsetX offsetY) orientation [scale])
      - offset: list - (x y) offset coordinates
      - orientation: string - "R0"|"R90"|"R180"|"R270"|"MX"|"MXR90"|"MY"|"MYR90"
      - scale: float (optional) - Scale factor, default 1.0
  Returns: txObject - New FigSet or nil on failure

- `txMoveFigSet(figSet transform)`
  Input:
    - figSet: txObject - Target FigSet
    - transform: list - Same format as txCopyFigSet transform
  Returns: boolean - True if successful

### Query Functions
- `txGetFigSetBBox(figSet [options])`
  Input:
    - figSet: txObject - Target FigSet
    - options: plist - Optional filters:
      - onlyTheseLayers: list - Layer numbers to include
      - onlyTheseLPPs: list - Layer-purpose pairs to include
      - notTheseLayers: list - Layer numbers to exclude
      - notTheseLPPs: list - Layer-purpose pairs to exclude
      - onlyTheseTypes: list - Object types to include
      - notTheseTypes: list - Object types to exclude
  Returns: list - ((llx lly) (urx ury)) bounding box or nil

- `txIsFigSet(object)`
  Input:
    - object: any - Object to test
  Returns: boolean - True if object is a FigSet

## FigSetGroup Functions

### Creation and Management
- `dbMakeFigSetGroup(cellView figSet)`
  Input:
    - cellView: dbObject - Target cellview
    - figSet: txObject - Source FigSet
  Returns: dbObject - Created FigSetGroup or nil on failure

- `dbDeleteFigSetGroup(figSetGroup)`
  Input:
    - figSetGroup: dbObject - FigSetGroup to delete
  Returns: boolean - True if successful

### Query Functions
- `dbFindFigSetGroup(cellView figSet)`
  Input:
    - cellView: dbObject - Target cellview
    - figSet: txObject - FigSet to find group for
  Returns: dbObject - Found FigSetGroup or nil

- `dbFindFigSetGroupByName(cellView name)`
  Input:
    - cellView: dbObject - Target cellview
    - name: string - Name of FigSetGroup to find
  Returns: dbObject - Found FigSetGroup or nil

- `dbGetFigSetGroupName(figSetGroup)`
  Input:
    - figSetGroup: dbObject - FigSetGroup to query
  Returns: string - Name of FigSetGroup or nil

- `dbGetCellViewFigSetGroups(cellView)`
  Input:
    - cellView: dbObject - Target cellview
  Returns: list - List of FigSetGroup objects in cellview

- `dbIsFigSetGroup(object)`
  Input:
    - object: any - Object to test
  Returns: boolean - True if object is a FigSetGroup

## Notes
- For detailed function documentation, refer to the HTML files in the skill_ref directory
- The `return` statement can only be used within a `prog` block, not within a `let` block
- In a `let` block, the last expression evaluated becomes the return value
- Functions that return nil on failure generally print an error message explaining the failure
- FigSets are memory-only objects, while FigSetGroups persist in the database
- Many operations cannot be undone since FigSets are not database objects
- Object IDs are shown as tx@... for FigSets and db:... for database objects