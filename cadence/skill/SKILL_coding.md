# SKILL Programming Guidelines for Auto RFIC Project

## Table of Contents
1. [Language Basics](#language-basics)
2. [Variable Scope and Declaration](#variable-scope-and-declaration)
3. [Function Definitions](#function-definitions)
4. [Module Organization](#module-organization)
5. [Data Structures and Tables](#data-structures-and-tables)
6. [Error Handling](#error-handling)
7. [Path Handling](#path-handling)
8. [Database Operations](#database-operations)
9. [Circuit Creation](#circuit-creation)
10. [GUI Programming](#gui-programming)
11. [Documentation References](#documentation-references)

## Language Basics

1. **Return Values**
   - The `return` statement can only be used within a `prog` block, not within a `let` block
   - In a `let` block, the return value is the last expression evaluated

2. **Logical Operators**
   - Use `&&` for logical AND, `||` for logical OR
   - Use `when` for single-condition blocks
   - Use `unless` for negated single-condition blocks
   - Use `if` for if-then-else constructs

3. **Data Type Conversions**
   - String to Symbol: `car(parseString(strcat("(" stringValue ")")))` 
   - Symbol to String: `symbolToString('symbolName)`
   - **NOT** `read(strcat("'" stringValue))` - requires an I/O port
   - **NOT** `intern(stringValue)` - expects a symbol, not a string

## Variable Scope and Declaration

1. **Let Block Usage**
   - Each let block creates a new scope for its variables
   - Declare ALL variables at block start, even if used later
   ```lisp
   let((state result)  ;; declare all variables upfront
       state = doSomething()
       unless(state return(nil))
       result = processState(state)
   )
   ```

2. **Variable Naming**
   - Use descriptive prefixes for variables of specific types
   - Use 'current' prefix for variables holding transformed input

## Function Definitions

1. **Function Name Spacing**
   - SKILL requires whitespace between function name and parameter list
   - Correct: `defun(myFunction (args))`
   - Incorrect: `defun(myFunction(args))`

2. **Optional Parameters**
   - Use `optional` keyword followed by parameter name
   - Correct: `(paramName optional defaultValue)`
   - Incorrect: `(paramName (optional defaultValue))`
   - No parentheses around optional parameters
   - No @ symbol prefix for optional parameters

3. **Block Structure**
   - Function bodies should be wrapped in a `let` or `prog` block
   - Every block (`let`, `when`, `if`, etc.) must be properly closed
   ```lisp
   defun(myFunction (args)
       let((vars)
           ;; function body
           result
       )
   )
   ```

## Module Organization

1. **File Organization**
   - Define all functions at the top of the file before using them
   - Initialize namespaces and tables after function definitions
   - Add functions to namespaces at the end of the file

2. **Namespace Management**
   - Each module should use the namespace table created in main.il
   - Never redefine an existing namespace table with a list
   - Always check if a namespace exists using boundp() before using it
   ```lisp
   ;; DON'T do this in a module file:
   autoRficModule = list(nil)
   
   ;; INSTEAD, use the existing table:
   ;; (no initialization needed, table already created in main.il)
   
   ;; Then, add functions to namespace:
   when(boundp('autoRficModule)
       autoRficModule['function1] = 'function1
       autoRficModule['function2] = 'function2
   )
   
   ;; Export namespace as last expression
   autoRficModule
   ```

3. **Module Dependencies**
   - Dependencies must be loaded using absolute paths
   - Load modules in dependency order (dependencies before dependents)
   - Avoid circular dependencies using default values
   - Check for module availability using boundp()

4. **Module Self-Sufficiency**
   - Each module should be able to function with safe defaults
   - Don't rely on configuration being loaded for core functionality
   - Use fallback values when dependencies aren't available
   ```lisp
   ;; Good - safe fallback
   configLevel = if(boundp('autoRficConfig)
       get(autoRficConfig "logLevel")
       'info  ; default if config not available
   )
   ```

## Data Structures and Tables

1. **Table Creation**
   - `makeTable()` accepts at most 3 arguments:
     - name (required): string identifying the table
     - size (optional): initial size hint
     - default value (optional): value for unassigned entries
   - Example: `myTable = makeTable("myTable")`

2. **Table Population**
   - Use individual assignments for table entries
   - Use table['key] syntax for setting values
   ```lisp
   myTable = makeTable("myTable")
   myTable['key1] = value1
   myTable['key2] = value2
   ```

3. **Table Access Patterns**
   - Always check table existence and type before access:
   ```skill
   when(and(boundp('tableName) tablep(tableName))
       // table operations here
   )
   ```

   - For accessing table entries:
     - Use `assoc` for association lists: `assoc('keySymbol table)`
     - Use `getq` for symbol-indexed tables: `getq(table 'keySymbol)`
     - Use `get()` for safe table value access
     - Check return values before use

4. **Symbol Handling**
   - Always validate symbol type:
   ```skill
   unless(symbolp(var)
       error("Invalid symbol")
   )
   ```

## Error Handling

1. **Data Type Validation**
   - Always check data types before operations
   - For table lookups with `get()`, ensure the first argument is a valid table
   - For symbol lookups, ensure inputs are symbols with `symbolp()`
   - Convert strings to symbols with `car(parseString(strcat("(" stringValue ")")))`

2. **Handling Nil Values**
   - Always check for nil values before performing comparisons
   - Use `numberp()` before numeric comparisons
   - Use `stringp()` before string operations
   - Use `symbolp()` before symbol operations
   ```lisp
   ;; Safe numeric comparison
   if(numberp(val1) && numberp(val2)
       val1 >= val2
       ;; Default behavior if values aren't numeric
   )
   ```

3. **Debugging Tips**
   - Use `println(object)` to debug object types and values
   - Check if objects are valid before using them
   - Save and reload often to test small portions of code
   - Use tables for organizing objects to make debugging easier

## Path Handling

1. **Base Directory Configuration**
   - Use environment variables for configurable paths
   - Provide sensible defaults using `getShellEnvVar("HOME")`
   ```lisp
   baseDir = getShellEnvVar("AUTO_RFIC_DIR")
   unless(baseDir
       baseDir = strcat(getShellEnvVar("HOME") "/projects/auto_rfic/cadence/skill")
   )
   ```

2. **Module Loading Paths**
   - Use absolute paths or paths relative to a known base directory
   - Avoid paths relative to current directory (./)
   ```lisp
   ;; Good - using base directory
   load(strcat(baseDir "/simulation/analyses.il"))
   
   ;; Bad - using relative path
   load("./analyses.il")
   ```

## Database Operations

1. **Loading Cell Views**
   ```scheme
   ;; Open a cell view in read mode (default)
   cv = autoRficLoadDatabase("myLib" "myCell" "layout")
   
   ;; Open a cell view in write mode
   cv = autoRficLoadDatabase("myLib" "myCell" "layout" "w")
   ```

2. **Cell View Cleanup**
   - Always close cell views after use with `dbClose()`
   - Close source cell views only if they're from a different library
   ```lisp
   ;; Save and close cell views
   dbSave(targetCv)
   when(sourceLib != targetCv->libName
       dbClose(sourceCv)  ; Close source only if from different lib
   )
   dbClose(targetCv)
   ```

## Circuit Creation

### Net and Pin Creation (Consolidated)

Creating circuit elements in Cadence SKILL can be version-dependent. Here's a compatible approach:

1. **Creating Nets**
   ```skill
   myNet = dbCreateNet(cvId "NET_NAME")
   ```

2. **Creating Pins for External Connections**
   ```skill
   ;; Method 1: Using terminals (older versions)
   ;; NOTE: dbCreateTerm has inconsistent implementation across versions!
   ;; Some versions expect a net object, others expect a net name
   ;; Due to this inconsistency, method 2 (rectangle shapes) is recommended
   
   ;; Method 2: Simple pins as rectangles (MOST COMPATIBLE)
   ;; Create pin shape
   dbCreateRect(cvId "pin" list(x1:y1 x2:y2))
   ;; Add label to identify the pin
   dbCreateLabel(cvId "pin" list(x:y) "PIN_NAME" "centerLeft" "R0" "stick" 1.0)
   ;; Connect the pin to its corresponding net
   dbCreateLine(cvId "route" list(x:y netObj))
   
   ;; Method 3: Using ioPin symbols (more visual but version-specific)
   ;; NOTE: Syntax varies between Cadence versions! Use one of these formats:
   ;; For older versions:
   pinInst = dbCreateInst(cvId "basic" "iopin" "symbol" "PIN_NAME" list(x y))
   ;; For newer versions (library as separate parameter):
   pinInst = dbCreateInst(cvId "basic/iopin/symbol" "PIN_NAME" list(x y))
   ;; For some IC versions (library and cell as separate parameters):
   pinInst = dbCreateInst(cvId "basic" "iopin/symbol" "PIN_NAME" list(x y))
   ```

3. **Creating Instances**
   ```skill
   ;; Create an instance
   myInst = dbCreateInst(cvId masterName instName position)
   
   ;; Set instance properties
   schSetFigProperty(myInst list("propName" propValue))
   ```

4. **Connecting Components with Wires**
   ```skill
   ;; Connect points with wires
   dbCreateWire(cvId "route" list(list(x1:y1 "auto") list(x2:y2 "auto")))
   
   ;; Connect to a net
   dbCreateWire(cvId "route" list(list(x:y "auto") list(netObj "auto")))
   ```

### Connecting Components 

Different Cadence versions offer different functions for connecting components in a schematic:

1. **Using dbCreateLine (most compatible)**
   ```skill
   ;; Connect a point to a net
   dbCreateLine(cvId "route" list(x:y netObj))
   
   ;; Connect two points
   dbCreateLine(cvId "route" list(x1:y1 x2:y2))
   ```

2. **Using dbCreateWire (newer versions)**
   ```skill
   ;; Connect points with wires
   dbCreateWire(cvId "route" list(list(x1:y1 "auto") list(x2:y2 "auto")))
   
   ;; Connect to a net
   dbCreateWire(cvId "route" list(list(x:y "auto") list(netObj "auto")))
   ```

3. **Using schConnect (some versions)**
   ```skill
   ;; Connect instance terminals directly
   schConnect(inst1 "termName1" inst2 "termName2")
   ```

For maximum compatibility, prefer `dbCreateLine` when `dbCreateWire` is unavailable.

### Common dbCreateInst Formats for Pins

The `dbCreateInst` function has different formats across Cadence versions for creating pin instances:

1. **Older IC Versions**:
   ```skill
   pinInst = dbCreateInst(cvId libName cellName viewName instName position)
   ```
   Example:
   ```skill
   pinInst = dbCreateInst(cvId "basic" "iopin" "symbol" "VDD" list(100 100))
   ```

2. **Some IC Versions**:
   ```skill
   pinInst = dbCreateInst(cvId libName cellViewName instName position)
   ```
   Example:
   ```skill
   pinInst = dbCreateInst(cvId "basic" "iopin/symbol" "VDD" list(100 100))
   ```

3. **Newer IC Versions**:
   ```skill
   pinInst = dbCreateInst(cvId libCellViewName instName position)
   ```
   Example:
   ```skill
   pinInst = dbCreateInst(cvId "basic/iopin/symbol" "VDD" list(100 100))
   ```

The most compatible approach is to use shape-based pins with `dbCreateRect` and connections with `dbCreateWire`, which works across more Cadence versions.

### Organization for Circuit Creation

1. **Create All Nets First**
   - Create all nets before creating pins or connecting instances
   - Store nets in variables with clear names (`vdd`, `gnd`, etc.)

2. **Create Input/Output Pins**
   - Create pins for external connections
   - Connect pins to nets

3. **Create and Place Instances**
   - Create all instances with meaningful variable names
   - Set properties for all instances

4. **Connect Everything**
   - Connect instances to nets using wires
   - Connect pins to nets

5. **Save and Close**
   - Save and close the cell view when done

### Version-Specific Issues

Different Cadence versions have different API functions:

1. **Terminal vs. Pin Confusion**
   - Some versions use `dbCreateTerm` and parameters differ
   - Some versions prefer shape-based pins with `dbCreateRect`
   - When creating pins as rectangles, no need to set pin name as last parameter

2. **Connection Methods**
   - Use explicit wire connections with `dbCreateWire` for best compatibility
   - Specify coordinates for clarity: `dbCreateWire(cvId "route" list(list(100:100 "auto") list(netObj "auto")))`

## GUI Programming

1. **Virtuoso UI Initialization**
   ```lisp
   hiDrLoadLibrary("basic")
   hiSetBindKeys("Emacs")
   ```

2. **Virtuoso UI Functions**
   - Common functions:
   ```lisp
   hiDisplayDialog()    ; For message and confirmation dialogs
   hiCreateStringField() ; For text input fields
   hiCreateProgressBar() ; For progress indicators
   hiCreateAppForm()    ; For complex forms
   ```

3. **Dialog Types**
   - Use appropriate icon types:
     - "information" for info messages
     - "warning" for warnings
     - "error" for errors
     - "question" for confirmations

## UI Function Parameter Differences

### Dialog Box Functions (hiDisplayAppDBox)

1. **Valid parameters:**
   - `?name`: Unique identifier for the dialog box
   - `?dboxBanner`: Title displayed in window banner (NOT `?title` or `?dboxTitle`)
   - `?dboxText`: Main message text
   - `?buttons`: List of button definitions
   - `?buttonLayout`: Must be one of these predefined values:
     - 'Close
     - 'Quit
     - 'CloseHelp
     - 'QuitHelp
     - 'OKCancel (default)
     - 'YesNo
     - 'YesNoCancel
     - 'CloseMore
   
2. **Invalid parameters:**
   - `?unmapAfterCB`: Not supported in hiDisplayAppDBox (use only in hiCreateAppForm)
   - `?title`: Not recognized, use `?dboxBanner` instead
   - Custom button layouts like 'Vertical' or 'Horizontal' are not supported

### Form Functions (hiCreateAppForm)

1. **Valid parameters:**
   - `?name`: Unique identifier for the form
   - `?formTitle`: Title displayed in form window
   - `?callback`: Callback procedure
   - `?buttonLayout`: Button layout ('OK, 'OKCancel, 'OKCancelApply etc)
   - `?unmapAfterCB`: Whether to unmap form after callback

### List Box Functions (hiDisplayListBox)

1. **Valid parameters:**
   - `?name`: Unique identifier for the list box
   - `?dboxBanner`: Title displayed in window banner (NOT `?title` or `?dlgTitle`)
   - `?buttonLayout`: Button configuration
   - `?choices`: List of items to display
   - `?numVisChoice`: Number of visible items
   - `?itemAction`: Procedure called when item selected

## Common Patterns

1. **Dialog boxes vs Forms:**
   - Use hiDisplayAppDBox for simple message boxes and confirmations
   - Use hiCreateAppForm for more complex input forms with multiple fields

2. **Button callbacks:**
   - For form buttons, use hiSetFormCallbacks to set the actions
   - For dialog box buttons, provide callbacks directly in button creation

## Documentation References

- **SKILL Language Reference**
  - Located at: `cadence/skill/skill_ref/sklangref/sklangref.xml`
  - Contains core language documentation

- **Cadence API/Functions Reference**
  - Brief index: `cadence/skill/skill_ref/skdfref/related.xml`
  - Complete index: `cadence/skill/skill_ref/skdfref/skdfref.xml`
  - Contains documentation for Cadence-specific API functions

# SKILL Coding Guidelines

## Database Functions

### Creating Instances (dbCreateInst)

When creating instances in a schematic using `dbCreateInst`, you need to pass a cell view object as the second argument, not just a library or cell name string:

```skill
;; INCORRECT:
transistor = dbCreateInst(cvId "analogLib" "nmos4" "M1" list(100 100) "R0")

;; CORRECT:
nmosCellView = dbOpenCellViewByType("analogLib" "nmos4" "symbol")
transistor = dbCreateInst(cvId nmosCellView "M1" list(100 100) "R0")
```

The correct syntax is:
```skill
dbCreateInst(destinationCellView masterCellView instanceName location orientation)
```

Where:
- destinationCellView: The cell view where you're creating the instance
- masterCellView: A database object representing the cell to instantiate (obtained via dbOpenCellViewByType or similar)
- instanceName: String name for the instance
- location: Placement coordinates as a list(x y)
- orientation: Rotation string like "R0", "R90", etc.

### Creating Labels (dbCreateLabel)

For creating labels, use the direct coordinate syntax:

```skill
dbCreateLabel(cvId "pin" 50:50 "VDD" "centerLeft" "R0" "stick" 1.0)
```

Not:

```skill
dbCreateLabel(cvId "pin" list(50:50) "VDD" "centerLeft" "R0" "stick" 1.0)
```

## GUI Function Parameter Differences

When working with SKILL UI functions, note that parameters differ between functions:

1. **hiDisplayAppDBox** does NOT support:
   - `?unmapAfterCB` parameter (use this only in hiCreateAppForm)

2. **Parameter naming conventions:**
   - Use `?dboxBanner` for dialog titles in hiDisplayAppDBox
   - Use `?formTitle` for form titles in hiCreateAppForm 
   - Use `?buttonText` for button labels

3. **Button layout management:**
   - Valid button layout options include: 'OKCancel, 'OK, 'YesNo, etc.
   - For custom buttons, use `?buttonLayout 'Vertical` or `'Horizontal`

Always refer to the official Cadence SKILL documentation or the SKILL_UI_API.md file in this project for the correct parameters.
