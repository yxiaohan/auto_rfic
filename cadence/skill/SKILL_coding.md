# Coding Notes

## Programming in SKILL

1. The `return` statement can only be used within a `prog` block, not within a `let` block
2. In a `let` block, the return value is the last expression evaluated

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

## Module Organization

1. **Namespace Management**
   - Each module should define its own namespace using makeTable
   - Never use `export` - SKILL doesn't have this function
   - Export the namespace by making it the last expression in the file
   Example:
   ```lisp
   unless(boundp('autoRficModule)
       autoRficModule = makeTable("module" nil)
   )
   
   ;; Define functions...
   
   ;; Add functions to namespace
   autoRficModule['function1] = 'function1
   
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
   - Always initialize tables before use
   - Use unless(boundp()) to check for existence
   ```lisp
   unless(boundp('myTable)
       myTable = makeTable("myTable" nil)
   )
   ```

2. **Table Access**
   - Use get() for safe table value access
   - Use table index syntax for assignment: table[key] = value
   - Check tablep() before accessing a table

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
