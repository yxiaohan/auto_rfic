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

## SKILL Documentation Files

**SKILL language reference**
cadence/skill/skill_ref/sklangref/sklangref.xml
**Cadence API/Functions reference**
Short index:
cadence/skill/skill_ref/skdfref/related.xml
Full index:
cadence/skill/skill_ref/skdfref/skdfref.xml
