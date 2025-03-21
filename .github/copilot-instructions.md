# GitHub Copilot Instructions for SKILL Programming

This document provides instructions for GitHub Copilot when working with SKILL language in the auto_rfic project.

## SKILL Language Specifics

**Needs Update**
You can update and take nots of this section, if finding something needs special treatment for coding with SKILL, during error corrections.

When generating or suggesting code in SKILL:

1. **Return Statement Usage**
   - The `return` statement can only be used within a `prog` block
   - Do not use `return` statements within a `let` block
   - In a `let` block, the last expression evaluated becomes the return value

2. **Block Structure**
   - Use `prog()` when control flow statements like return are needed
   - Use `let()` for more functional-style programming where the last expression is the return value

## Documentation References

The project includes these documentation references for SKILL:

- **SKILL Language Reference Index**
  - Located at: `cadence/skill/skill_ref/sklangref/sklangref.xml`
  - Contains core language documentation

- **Cadence API/Functions Reference Index**
  - A brief index: `cadence/skill/skill_ref/skdfref/related.xml`
  - Complete index located at: `cadence/skill/skill_ref/skdfref/skdfref.xml`
  - Contains documentation for Cadence-specific API functions

## Project Structure

This project involves SKILL programming for Cadence Virtuoso automation. When suggesting code:
- Consider the existing files in the skill/ directory
- Follow the project patterns for remote server operations
- Reference the included documentation when suggesting functions and methods