# Coding Notes

## Programming in SKILL

1. The `return` statement can only be used within a `prog` block, not within a `let` block
2. In a `let` block, the return value is the last expression evaluated

## Path Handling
1. **Base Directory Configuration**
   - Use environment variables for configurable paths
   - Provide sensible defaults using `getShellEnvVar("HOME")`
   - Example:
     ```lisp
     baseDir = getShellEnvVar("AUTO_RFIC_DIR")
     unless(baseDir
         baseDir = strcat(getShellEnvVar("HOME") "/projects/auto_rfic/cadence/skill")
     )
     ```
2. **Module Loading Paths**
   - Use absolute paths or paths relative to a known base directory
   - Avoid paths relative to current directory (./)
   - Example:
     ```lisp
     ;; Good - using base directory
     load(strcat(baseDir "/simulation/analyses.il"))
     
     ;; Bad - using relative path
     load("./analyses.il")
     ```

## SKILL Block Structure and Scoping
1. **Let Block Usage**
   - Each let block creates a new scope for its variables
   - Declare all variables at block start, even if used later
   - Example:
     ```lisp
     let((state result)  ;; declare all variables upfront
         state = doSomething()
         unless(state return(nil))
         result = processState(state)
     )
     ```

2. **State and Resource Management**
   - Create state objects before resource cleanup
   - Use nested let blocks to manage complex state transitions
   - Always cleanup resources in reverse order of creation
   - Example:
     ```lisp
     let((state)
         state = createState(resource)
         unless(state
             return(nil)
         )
         ;; Save and cleanup after state use
         save(resource)
         cleanup(resource)
     )
     ```

# SKILL Programming Style Guide

## File Organization

1. **Function Definition Order**
   - Define all functions at the top of the file before using them
   - Initialize namespaces and tables after function definitions
   - Add functions to namespaces at the end of the file

2. **Namespace Population**
   - Use table assignment syntax for adding functions to namespaces
   - Correct: `namespace['functionName] = 'functionSymbol`
   - Avoid: using makeTable() with a long list of functions

## Module Dependencies

1. **Dependency Loading**
   - Don't load dependencies directly in module files
   - Let the main entry point (main.il) handle module loading order
   - Example: Remove direct `load()` calls from module files

2. **Function Definitions**
   - Define each function exactly once
   - Avoid reloading modules that define functions
   - Use main.il to control the loading sequence

3. **Module Loading Order**
   - Load modules in dependency order (dependencies before dependents)
   - Example order for simulation modules:
     ```lisp
     ;; Load core analysis functionality first
     load("simulation/analyses.il")
     ;; Then load modules that depend on it
     load("simulation/testbench.il")
     load("simulation/results.il")
     ```
   - If module A uses functions from module B, load module B first
   - Consider documenting dependencies in module headers

## Module Dependencies and Initialization

1. **Default Values**
   - Always provide default values for critical system variables
   - Make modules work with defaults before configuration is loaded
   - Use when() to safely override defaults with configuration

2. **Circular Dependencies**
   - Break circular dependencies using default values
   - Check for module availability using boundp()
   - Load core utility modules before configuration

3. **Configuration Loading**
   - Load configuration after core systems are initialized
   - Use defensive checks when applying configuration
   - Allow graceful fallback to defaults

## Module Organization

1. **Namespace Management**
   - Each module should use the namespace table created in main.il
   - Never redefine an existing namespace table with a list
   - Always check if a namespace exists using boundp() before using it
   - Example:
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

2. **Function Definitions**
   - Define all functions before adding them to the namespace
   - Use proper error handling with `error()` function
   - Use optional parameters with `optional` keyword (no @ symbol)
   - Check input validity before performing operations

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

3. **Return Statement Usage**
   - The `return` statement can only be used within a `prog` block
   - Do not use `return` statements within a `let` block
   - In a `let` block, the last expression evaluated becomes the return value

4. **Block Structure**
   - Function bodies should be wrapped in a `let` or `prog` block
   - Every block (`let`, `when`, `if`, etc.) must be properly closed
   - Example:
     ```lisp
     defun(myFunction (args)
         let((vars)
             ;; function body
             result
         )
     )
     ```

5. **Dependencies**
   - Dependencies must be loaded using absolute paths
   - Example: `load("/path/to/utils.il")`
   - This ensures consistent loading regardless of current directory

## Variable and Namespace Initialization

1. **Table Initialization**
   - Tables should be initialized in the main.il file
   - Module files should NOT reinitialize namespace tables
   - Use unless(boundp()) to check for existence before use
   ```lisp
   ;; In main.il:
   unless(boundp('myNamespace)
       myNamespace = makeTable("myNamespace" nil)
   )
   
   ;; In module files:
   ;; DON'T recreate the namespace table
   ;; Just use the existing one
   ```

2. **Table Access**
   - Use get() for safe table value access
   - Use table index syntax for assignment: table[key] = value
   - Check tablep() before accessing a table

3. **Namespace Handling**
   - Never overwrite a namespace table with a list
   - Always check if a namespace exists using boundp() before adding functions
   - Use when() to safely add functions to a namespace
   ```lisp
   ;; Safe namespace function assignment
   when(boundp('autoRficModule)
       autoRficModule['functionName] = 'functionSymbol
   )
   ```

## Configuration Management

1. **Table-Based Config**
   - Use tables for configuration storage
   - Initialize config tables before use with `makeTable()`
   - Access config values with table syntax: `configTable[key]`

2. **Variable Initialization**
   - Always check if variables exist before use with `boundp()`
   - Initialize shared variables at the start of library files
   - Example:
     ```lisp
     unless(boundp('configTable)
         configTable = makeTable("")
     )
     ```

## Table Operations

1. **Table Creation**
   - `makeTable()` accepts at most 3 arguments:
     - name (required): string identifying the table
     - size (optional): initial size hint
     - default value (optional): value for unassigned entries
   - Example: `myTable = makeTable("myTable")`

2. **Table Population**
   - Use individual assignments for table entries
   - Use table['key] syntax for setting values
   - Example:
     ```lisp
     myTable = makeTable("myTable")
     myTable['key1] = value1
     myTable['key2] = value2
     ```

## GUI Programming

1. **Virtuoso UI Initialization**
   - Use hiDrLoadLibrary() to load UI libraries
   - Example:
     ```lisp
     hiDrLoadLibrary("basic")
     hiSetBindKeys("Emacs")
     ```
   - Never use Allegro-specific functions (axlUI*)

2. **Virtuoso UI Functions**
   - hiUI functions are built into Virtuoso - no need for explicit loading
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

## Database Operations

### Loading Cell Views

The `autoRficLoadDatabase` function is used to safely load cell views:

```scheme
; Open a cell view in read mode (default)
cv = autoRficLoadDatabase("myLib" "myCell" "layout")

; Open a cell view in write mode
cv = autoRficLoadDatabase("myLib" "myCell" "layout" "w")
```

The function performs these safety checks:
- Verifies library exists
- Ensures cell view can be opened
- Returns the cell view object or errors with descriptive message

### Cell View Cleanup
1. **Resource Management**
   - Always close cell views after use with `dbClose()`
   - Close source cell views only if they're from a different library
   - Example:
     ```lisp
     ;; Save and close cell views
     dbSave(targetCv)
     when(sourceLib != targetCv->libName
         dbClose(sourceCv)  ; Close source only if from different lib
     )
     dbClose(targetCv)
     ```

## Template Management

1. **Template Registry**
   - Use a separate table for template storage
   - Register templates with a function reference, not the function itself
   Example:
   ```lisp
   templateRegistry[templateName] = makeTable(
       'func    'templateFunction  ; Note the quote
       'params  paramDefinitions
   )
   ```

2. **Template Parameters**
   - Define parameters as lists with type and description
   - Example:
     ```lisp
     list(
         list("name" "type" "description")
         list("width" "float" "Width in um")
     )
     ```

## Logical Operators

1. **Boolean Operations**

2. **Conditional Expressions**
   - Use `when` for single-condition blocks
   - Use `unless` for negated single-condition blocks
   - Use `if` for if-then-else constructs

## Error Handling

1. **Data Type Validation**
   - Always check data types before operations
   - For table lookups with `get()`, ensure the first argument is a valid table
   - For symbol lookups, ensure inputs are symbols with `symbolp()`
   - Convert strings to symbols with `symeval(strcat("'" stringValue))`

2. **Handling Nil Values**
   - Always check for nil values before performing comparisons
   - Use `numberp()` before numeric comparisons
   - Use `stringp()` before string operations
   - Use `symbolp()` before symbol operations
   - Example:
     ```lisp
     ;; Safe numeric comparison
     if(numberp(val1) && numberp(val2)
         val1 >= val2
         ;; Default behavior if values aren't numeric
     )
     ```

3. **Logging System Implementation**
   - Log levels should be symbols not strings (`'info` vs `"info"`)
   - When logging with timestamps, use format specifiers to prevent type issues:
     - Use `%s` for raw strings like timestamps
     - Use `%L` for SKILL objects like symbols
   - Example:
     ```lisp
     formattedMessage = sprintf(nil "[%s] [%L] %s" timestamp levelSymbol message)
     ```
   - Always validate log level inputs before using them as lookup keys
   - Never pass timestamps directly as table keys
   - For logging with timestamps:
     ```lisp
     ; Correct
     logMessage = sprintf(nil "[%s] %s" (autoRficTimestamp()) message)
     
     ; Incorrect - will cause type errors
     logMessage = strcat(autoRficTimestamp() message)
     ```

## Logging System Implementation

1. **Log Level Handling**
   - Convert log levels to numbers as early as possible
   - Never mix string/symbol comparisons with numeric comparisons
   - Use a helper function to handle all log level conversions
   ```lisp
   ;; Good - Convert to number early
   levelNum = getLogLevelNumber(level)
   if(levelNum >= minLevel ...)
   
   ;; Bad - Mixing types
   if(get(logLevels level) >= minLevel ...)
   ```

2. **Type Safety in Logging**
   - Always validate input types before operations
   - Use `cond` for multi-type handling
   - Default to safe values for invalid inputs
   - Keep timestamp strings separate from level handling
   - Example:
   ```lisp
   levelSymbol = cond(
       (symbolp(level) level)
       (stringp(level) convertToSymbol(level))
       (t 'info)  ; safe default
   )
   ```

## Data Type Conversions

1. **String to Symbol Conversion**
   - Use `car(parseString(strcat("(" stringValue ")")))` to convert strings to symbols
   - **NOT** `read(strcat("'" stringValue))` - this requires an I/O port 
   - **NOT** `intern(stringValue)` - this expects a symbol, not a string
   - Example:
   ```lisp
   ;; Convert string to symbol
   mySymbol = car(parseString(strcat("(" "info" ")")))  ;; Returns info symbol

   ;; Use in table lookup
   logLevel = get(logLevels car(parseString(strcat("(" "info" ")"))))
   ```

2. **Symbol to String Conversion**
   - Use `symbolToString()` to convert symbols to strings
   - Example: `symbolToString('symbolName)` returns `"symbolName"`

3. **Common Conversion Pitfalls**
   - In SKILL, `read()` takes an I/O port as its first argument
   - `intern()` expects a symbol as input, not a string
   - `parseString()` parses a string into a SKILL expression, and `car()` extracts the first element
   - String-to-symbol conversion is a common source of errors in SKILL programs

## Logging Best Practices

1. **Timestamp Handling**
   - Never use timestamp strings as table keys or in get() operations
   - Always format timestamps within a dedicated formatting function
   - Use sprintf() with %s format specifier for timestamps
   Example:
   ```lisp
   ;; Good - separate formatting function
   defun(formatLogMessage (timestamp level message)
       sprintf(nil "[%s] [%L] %s" timestamp level message)
   )
   
   ;; Bad - using timestamp directly
   strcat("[" timestamp "]")
   ```

2. **Message Formatting**
   - Use sprintf() instead of strcat() for complex string formatting
   - Use %L format specifier for SKILL objects (symbols, lists)
   - Use %s for plain strings and timestamps
   - Validate all inputs before string operations

## SKILL Documentation Files

**SKILL language reference**
cadence/skill/skill_ref/sklangref/sklangref.xml
**Cadence API/Functions reference**
Short index:
cadence/skill/skill_ref/skdfref/related.xml
Full index:
cadence/skill/skill_ref/skdfref/skdfref.xml

## Function Variable Declaration

1. **Variable Declaration in Let Blocks**
   - Always declare ALL variables at the start of let blocks
   - Variables used in function must be declared before use
   - Example:
   ```lisp
   defun(myFunction (arg)
       let((var1 var2 resultVar tempVar)  ;; declare ALL variables
           var1 = getValue()
           var2 = processValue(var1)
           resultVar = finalProcess(var2)
           resultVar
       )
   )
   ```

2. **Variable Naming**
   - Use descriptive prefixes for variables that hold specific types
   - Use 'current' prefix for variables holding transformed input
   Example:
   ```lisp
   let((currentLevel currentValue result)
       currentLevel = processLevel(inputLevel)
       currentValue = getValue(currentLevel)
   )
   ```

## Module Independence and Safe Defaults

1. **Module Self-Sufficiency**
   - Each module should be able to function with safe defaults
   - Don't rely on configuration being loaded for core functionality
   - Use fallback values when dependencies aren't available
   Example:
   ```lisp
   ;; Good - safe fallback
   configLevel = if(boundp('autoRficConfig)
       get(autoRficConfig "logLevel")
       'info  ; default if config not available
   )
   
   ;; Bad - assumes config exists
   configLevel = autoRficConfig["logLevel"]
   ```

2. **Default Value Handling**
   - Use the logical OR operator (||) for numeric/boolean defaults
   - Use null-check with when() for complex defaults
   - Keep defaults close to where they're used
   Example:
   ```lisp
   ;; Numeric default using OR
   level = get(levels symbolName) || 1  ; default to 1
   
   ;; Complex default using when
   when(null result
       result = makeTable("")  ; default to empty table
   )
   ```

3. **Cross-Module Dependencies**
   - Check for module availability using boundp()
   - Provide meaningful error messages when dependencies missing
   - Use conditional feature enabling based on available modules

# SKILL Programming Guidelines

## Table and Symbol Handling

### Table Access Patterns
1. Always check table existence and type before access:
```skill
when(and(boundp('tableName) tablep(tableName))
    // table operations here
)
```

2. For accessing table entries:
- Use `assoc` for association lists: `assoc('keySymbol table)`
- Use `getq` for symbol-indexed tables: `getq(table 'keySymbol)`
- Check return values before use

### Symbol Handling
1. String to symbol conversion:
```skill
; Preferred method
symbolVar = stringToSymbol(stringVar)

; Alternative method for complex cases
symbolVar = car(parseString(strcat("(" stringVar ")")))
```

2. Always validate symbol type:
```skill
unless(symbolp(var)
    error("Invalid symbol")
)
```

## Best Practices

### Error Handling
1. Use proper error logging with descriptive messages
2. Check return values of table operations
3. Provide meaningful error context:
```skill
sprintf(nil "Template not found: %L" templateName)
```

### Function Parameters
1. Document parameter types and requirements
2. Validate input types before use
3. Use descriptive parameter names

### Table Initialization
1. Initialize tables with meaningful names:
```skill
tableVar = makeTable("tableName" nil)
```

2. Use symbol keys for better performance and reliability

### Code Organization
1. Group related functions together
2. Document dependencies
3. Initialize all required variables/tables
4. Use proper namespacing to avoid conflicts

## Common Namespace Errors

1. **Namespace Redefinition**
   - **ERROR**: Redefining a namespace table as a list
   ```lisp
   autoRficModule = list(nil)  ;; WRONG - overwrites the table
   ```
   - **CORRECT**: Use existing namespace table
   ```lisp
   when(boundp('autoRficModule)
       autoRficModule['func] = 'funcSymbol
   )
   ```

2. **Unsafe Namespace Additions**
   - **ERROR**: Adding to namespace without checking existence
   ```lisp
   autoRficModule['func] = 'funcSymbol  ;; WRONG - may fail
   ```
   - **CORRECT**: Check existence before adding
   ```lisp
   when(boundp('autoRficModule)
       autoRficModule['func] = 'funcSymbol
   )
   ```

3. **List-based Namespace Population**
   - **ERROR**: Using append() to populate a table namespace
   ```lisp
   autoRficModule = append(autoRficModule list(
       'func1 funcSymbol1
       'func2 funcSymbol2
   ))  ;; WRONG - treats table as list
   ```
   - **CORRECT**: Individual assignments
   ```lisp
   when(boundp('autoRficModule)
       autoRficModule['func1] = 'funcSymbol1
       autoRficModule['func2] = 'funcSymbol2
   )
   ```

# SKILL Coding Guidelines

## Terminal and Pin Creation

### Creating Cell Pins

When creating pins for a cell in SKILL, use the correct API function:

```skill
dbCreatePin(cellViewId netObj pinName ioType)
```

Where:
- `cellViewId` is the cellview object ID
- `netObj` is the net object returned by dbCreateNet (not a string)
- `pinName` is the pin name
- `ioType` is the I/O type as a string:
  - "inputOutput"
  - "outputOutput"
  - "inoutOutput"
  - etc.

### Creating Instance Connections

When creating connections for instances, use:

```skill
dbCreateInstTerms(instId netList termList)
```

Where:
- `instId` is the instance object ID
- `netList` is a list of net objects
- `termList` is a list of corresponding terminal names

This is more efficient than multiple calls to create instance pins individually.

## Common Mistakes

1. **Using `dbCreateTerm` instead of `dbCreatePin`**
   - For Cadence Virtuoso in modern versions, `dbCreatePin` is preferred
   - `dbCreateTerm` is older and may not work correctly in all contexts

2. **Passing net names instead of net objects**
   - Many Cadence API functions expect net objects returned from `dbCreateNet`
   - When creating pins, you pass the actual net object, not its name as a string

3. **Using numeric constants for I/O types**
   - While some older functions use numeric constants (0, 1, 2)
   - Modern functions like `dbCreatePin` use string values like "inputOutput"

## Efficient Connection Pattern

A recommended pattern for creating nets and pins:

1. Create all nets using `dbCreateNet`
2. Create cell pins with `dbCreatePin` using net objects
3. Connect instance terminals with `dbCreateInstTerms` for multiple connections at once

This approach reduces the number of function calls and follows modern Cadence API best practices.

## Terminal and Pin Creation

### Creating Terminals

When creating terminals in SKILL, use the correct syntax for `dbCreateTerm`:

```skill
dbCreateTerm(cellViewId netName termName direction)
```

Where:
- `cellViewId` is the cellview object ID
- `netName` is the name of the net as a STRING (not the net object)
- `termName` is the terminal name
- `direction` is an INTEGER, not a string:
  - 0 = input
  - 1 = output
  - 2 = inputOutput (or inout)

**Common mistake:** Using the net object instead of the net name, or using a string for direction.

### Creating Instance Pins

When creating instance pins, use the correct syntax for `dbCreateInstPin`:

```skill
dbCreateInstPin(cellViewId instId pinName termName netName direction)
```

Where:
- `cellViewId` is the cellview object ID
- `instId` is the instance object ID
- `pinName` is the pin name
- `termName` is the terminal name
- `netName` is the name of the net as a STRING (not the net object)
- `direction` is an INTEGER, not a string, following the same convention as above

## Net and Terminal Workflow

A typical workflow for creating nets and terminals:

1. Create nets first using `dbCreateNet`
2. Create terminals using `dbCreateTerm` with the net name (as string)
3. Connect instance pins to nets using `dbCreateInstPin` with the net name (as string)

## Common Errors

- Invalid net error: This often occurs when passing a net object instead of its name
- Invalid direction error: This occurs when using a string like "input" instead of the integer code 0

# SKILL Coding Guidelines

## Net and Terminal Management

### Best Practices for Net and Terminal Creation

When creating circuits programmatically in SKILL, follow these patterns:

1. **Use Data Structures for Organization**
   - Use tables (hash maps) to organize nets and instances
   - This makes code more maintainable and less error-prone

2. **Create All Nets First**
   - Create all nets before creating pins or connecting instances
   - Store nets in a table for easy reference: `netList["NET_NAME"] = dbCreateNet(cvId "NET_NAME")`

3. **Terminal Creation**
   - Use `dbCreateTerm` with correct syntax: `dbCreateTerm(cvId netObj termName direction)`
   - Direction is a string value: "input", "output", "inputOutput"

4. **Instance Terminal Connections**
   - Use `dbCreateInstTerm` to connect instance terminals to nets
   - Syntax: `dbCreateInstTerm(instObj termName netObj)`

## Common Errors

1. **Invalid Net Errors**
   - May occur when using net names instead of net objects
   - Always pass the actual net object (from dbCreateNet) to functions

2. **Direction Parameter Inconsistencies**
   - Different Cadence versions and functions may use different direction formats
   - Some use strings ("input"), some use integers (0), some use IO-specific strings ("inputOutput")
   - Consult documentation or working examples for your specific Cadence version

3. **Pin vs. Term Confusion**
   - In older Cadence versions: use `dbCreateTerm` and `dbCreateInstPin`
   - In newer versions: might use `dbCreatePin` and `dbCreateInstTerm`
   - The function names and signatures vary across versions

## Debugging Tips

1. **Print Objects**
   - Use `println(object)` to debug object types and values
   - Check if net objects are valid before using them

2. **Use Tables for Organization**
   - Tables help avoid variable name collisions and make code more readable
   - Example: `netList["VDD"]` is clearer than having many similar variable names

3. **Create All Objects Before Connecting**
   - Create all nets, then all instances, then make all connections
   - This separation makes debugging easier

## Net and Terminal Management

### Function Syntax for Different Cadence Versions

Different versions of Cadence use different function signatures for creating terminals and pins. Here are the key differences:

#### Terminal Creation

```skill
;; Create a terminal for a cell
dbCreateTerm(cellViewId netObj termName direction)
```

Where:
- `cellViewId` is the cellview object ID
- `netObj` is the net object returned by dbCreateNet
- `termName` is the terminal name
- `direction` is an INTEGER:
  - 0 = input
  - 1 = output
  - 2 = inputOutput/inout

#### Instance Pin Creation

```skill
;; Connect an instance pin to a net
dbCreateInstPin(cellViewId instId pinName displayName netObj direction)
```

Where:
- `cellViewId` is the cellview object ID
- `instId` is the instance object ID
- `pinName` is the pin name
- `displayName` is the display name for the pin
- `netObj` is the net object
- `direction` is an INTEGER (0=input, 1=output, 2=inout)

### Organization Best Practices

1. **Use Tables for Net Management**
   ```skill
   netList = makeTable("netList")
   netList["VDD"] = dbCreateNet(cvId "VDD")
   ```

2. **Use Tables for Instance Management**
   ```skill
   instList = makeTable("instList")
   instList["M1"] = dbCreateInst(cvId masterName "M1" position)
   ```

3. **Create All Objects Before Connecting**
   - Create all nets
   - Create all terminals
   - Create all instances
   - Set all instance properties
   - Connect all instance pins

## Common Errors

1. **Direction Parameter Type Mismatch**
   - Most Cadence SKILL functions expect numeric constants for direction parameters
   - Using strings like "input" instead of integers (0) will cause errors
   
2. **Net Reference Issues**
   - Pass the actual net object to functions, not just its name
   - Store net objects in variables or tables for easy reference

3. **API Version Inconsistencies**
   - Some versions use `dbCreateTerm` while others prefer `dbCreatePin`
   - Some versions use `dbCreateInstPin` while others use `dbCreateInstTerm`
   - Check your specific Cadence version's documentation

# SKILL Coding Guidelines

## Net and Terminal Management in Cadence SKILL

### Terminal Creation

When working with terminals in Cadence SKILL, there are important distinctions in how to use the API functions:

```skill
;; Create a terminal for a cell
dbCreateTerm(cellViewId netName termName direction)
```

Where:
- `cellViewId` is the cellview object ID
- `netName` is the NET NAME as a STRING (not the net object)
- `termName` is the terminal name
- `direction` is an INTEGER:
  - 0 = input
  - 1 = output
  - 2 = inputOutput/inout

### Instance Pin Creation

```skill
;; Connect an instance pin to a net
dbCreateInstPin(cellViewId instId pinName displayName netName direction)
```

Where:
- `cellViewId` is the cellview object ID
- `instId` is the instance object ID
- `pinName` is the pin name
- `displayName` is the display name for the pin
- `netName` is the NET NAME as a STRING (not the net object)
- `direction` is an INTEGER (0=input, 1=output, 2=inout)

## Critical Mistakes to Avoid

1. **Passing Net Objects Instead of Net Names**
   - For `dbCreateTerm` and `dbCreateInstPin`, always use net names (strings)
   - Don't pass the net object returned by `dbCreateNet`
   - Example: Use `"VDD"` instead of the variable `vdd`

2. **Direction Parameter Type Mismatch**
   - Most Cadence SKILL functions expect numeric constants for direction
   - Use integers (0, 1, 2) instead of strings ("input", "output", "inout")

3. **Variable Organization**
   - Create all nets first, then create terminals
   - Store nets in variables with clear names (`vdd`, `gnd`, etc.)
   - Create all instances before setting their properties and connections

## Working Pattern

A recommended pattern for creating a schematic:

1. Create all nets with meaningful variable names
2. Create cell terminals using net names (strings)
3. Create all instances with meaningful variable names
4. Set properties for all instances
5. Connect all instance pins using net names (strings)
6. Save and close the cell

This approach provides clarity and minimizes errors in the code.

# SKILL Coding Guidelines

## Creating Circuit Elements in Cadence Virtuoso

### Pin and Net Creation Workflow

When creating pins and nets in Cadence SKILL, follow this pattern:

1. **Create IO Pins First**
   ```skill
   inPin = dbCreateIoPin(cellViewId "PIN_NAME" "direction")
   ```
   Where direction is "input", "output", or "inputOutput"

2. **Create Nets**
   ```skill
   myNet = dbCreateNet(cellViewId "NET_NAME")
   ```

3. **Connect Nets to Pins**
   ```skill
   dbCreateNetPin(netObj pinObj)
   ```

### Instance Creation and Connection

1. **Create Instances**
   ```skill
   myInst = dbCreateInst(cellViewId masterName instName position)
   ```

2. **Set Instance Properties**
   ```skill
   schSetFigProperty(instObj list("propName" propValue))
   ```

3. **Connect Instances to Nets using Wires**
   ```skill
   dbCreateWire(cellViewId "route" list(list(dbGetInstEndPoint(instObj "PIN_NAME") "auto") list(dbGetNetEndPoint(netObj) "auto")))
   ```

## Common Issues and Their Solutions

1. **Invalid Net Error with dbCreateTerm**
   - Incorrect: `dbCreateTerm(cvId netObj "TERM_NAME" 0)`
   - Correct approach: Use `dbCreateIoPin` and `dbCreateNetPin` instead

2. **Connection Methods**
   - Avoid `dbCreateInstPin` which has version-specific requirements
   - Instead, create wires between instance pins and nets using `dbCreateWire`

3. **Proper Object References**
   - Always store and use object references (not just names)
   - Example: `myNet = dbCreateNet(cvId "NET_NAME")`
   - Then use `myNet` in subsequent operations

## Version-Safe Coding Pattern

For maximum compatibility across Cadence versions:

1. Create pins with `dbCreateIoPin`
2. Create nets with `dbCreateNet` 
3. Connect pins to nets with `dbCreateNetPin`
4. Create instances with `dbCreateInst`
5. Connect instances to nets with `dbCreateWire`

This pattern avoids the `dbCreateTerm` and `dbCreateInstPin` functions which have inconsistent behavior across Cadence versions.

# SKILL Coding Guidelines

## Basic Circuit Creation in SKILL

### Compatible Approach for Net and Pin Creation

When creating schematics programmatically in SKILL, use simple, widely compatible functions:

1. **Creating Nets**
   ```skill
   myNet = dbCreateNet(cvId "NET_NAME")
   ```

2. **Creating Pins for External Connections**
   ```skill
   ;; Create pin as a rectangle shape
   myPin = dbCreateRect(cvId "pin" list(x1:y1 x2:y2) "PIN_NAME")
   ```

3. **Connecting Components with Wires**
   ```skill
   ;; Connect points with wires
   dbCreateWire(cvId "route" list(list(x1:y1 "auto") list(x2:y2 "auto")))
   ;; Connect to a net
   dbCreateWire(cvId "route" list(list(x:y "auto") list(netObj "auto")))
   ```

### Instance Creation and Properties

1. **Creating Instances**
   ```skill
   myInst = dbCreateInst(cvId masterName instName position)
   ```

2. **Setting Instance Properties**
   ```skill
   schSetFigProperty(instObj list("propName" propValue))
   ```

### Version Compatibility Issues

Different Cadence versions have different API functions:

1. **Avoid Version-Specific Functions**
   - `dbCreateIoPin` - not available in some versions
   - `dbCreateTerm` - inconsistent behavior across versions
   - `dbCreateInstPin` - parameter requirements vary by version

2. **Use Basic Shape-Based Approach**
   - Create pins as shapes with `dbCreateRect`
   - Create explicit wire connections with `dbCreateWire`
   - This approach works across more Cadence versions

## Debugging Guidelines

1. **Check Function Availability**
   - If you encounter "undefined function" errors, use more basic functions
   - Functions like `dbCreateNet`, `dbCreateRect`, `dbCreateWire`, and `dbCreateInst` are available in most versions

2. **Use Explicit Coordinates**
   - Use explicit coordinates for connecting elements
   - Example: `dbCreateWire(cvId "route" list(list(100:100 "auto") list(netObj "auto")))`

3. **Save and Reload Often**
   - Use frequent saving to avoid losing work
   - Test small portions of code to isolate issues
