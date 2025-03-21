# Coding Notes

## Programming in SKILL

1. The `return` statement can only be used within a `prog` block, not within a `let` block
2. In a `let` block, the return value is the last expression evaluated

# SKILL Programming Style Guide

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

## SKILL Documentation Files

**SKILL language reference**
cadence/skill/skill_ref/sklangref/sklangref.xml
**Cadence API/Functions reference**
Short index:
cadence/skill/skill_ref/skdfref/related.xml
Full index:
cadence/skill/skill_ref/skdfref/skdfref.xml
