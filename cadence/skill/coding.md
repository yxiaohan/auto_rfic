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

## Function Definitions

1. **Function Name Spacing**
   - SKILL requires whitespace between function name and parameter list
   - Correct: `defun(myFunction (args))`
   - Incorrect: `defun(myFunction(args))`

2. **Return Statement Usage**
   - The `return` statement can only be used within a `prog` block
   - Do not use `return` statements within a `let` block
   - In a `let` block, the last expression evaluated becomes the return value

3. **Block Structure**
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

4. **Dependencies**
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

1. **Virtuoso UI Functions**
   - Use hiUI functions for Virtuoso GUI operations
   - hiUI functions are built-in, no need to load additional packages
   - Common functions:
     ```lisp
     hiDisplayDialog()    ; For message and confirmation dialogs
     hiCreateStringField() ; For text input fields
     hiCreateProgressBar() ; For progress indicators
     hiCreateAppForm()    ; For complex forms
     ```

2. **Dialog Types**
   - Use appropriate icon types:
     - "information" for info messages
     - "warning" for warnings
     - "error" for errors
     - "question" for confirmations

## SKILL Documentation Files

**SKILL language reference**
cadence/skill/skill_ref/sklangref/sklangref.xml
**Cadence API/Functions reference**
Short index:
cadence/skill/skill_ref/skdfref/related.xml
Full index:
cadence/skill/skill_ref/skdfref/skdfref.xml
