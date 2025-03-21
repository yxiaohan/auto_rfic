# Coding Notes

## Programming in SKILL

1. The `return` statement can only be used within a `prog` block, not within a `let` block
2. In a `let` block, the return value is the last expression evaluated

# SKILL Programming Style Guide

## Function Definitions

1. **Function Name Spacing**
   - SKILL requires whitespace between function name and parameter list
   - Correct: `defun myFunction (args)`
   - Incorrect: `defun myFunction(args)`

2. **Return Statement Usage**
   - The `return` statement can only be used within a `prog` block
   - Do not use `return` statements within a `let` block
   - In a `let` block, the last expression evaluated becomes the return value

3. **Block Structure**
   - Every block (`let`, `when`, `if`, etc.) must be properly closed with a parenthesis
   - Function bodies should be enclosed in proper parentheses
   - Example:
     ```lisp
     defun(myFunction (args)
         (let((var1 var2)
             ;; function body
             result
         )
     )
     ```

4. **Dependencies**
   - Dependencies must be explicitly loaded using `load()` at the start of the file
   - Example: `load("utils.il")`

## SKILL Documentation Files

**SKILL language reference**
cadence/skill/skill_ref/sklangref/sklangref.xml
**Cadence API/Functions reference**
Short index:
cadence/skill/skill_ref/skdfref/related.xml
Full index:
cadence/skill/skill_ref/skdfref/skdfref.xml
