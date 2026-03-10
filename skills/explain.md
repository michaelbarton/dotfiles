---
name: explain
description: "Produce a two-part explanation of a given file: an intuitive overview followed by a detailed technical breakdown."
---

# Explain

Generate a two-part report on a given file.

## When to Use

- Understanding an unfamiliar file in a codebase
- Onboarding onto a project and need to build mental models quickly
- Reviewing code where you need both the "why" and the "how"

## Instructions

Given a file path, read the file and produce a report with exactly two sections:

### Part 1 — Intuitive Explanation

Explain what this file does as if describing it to a colleague who understands software but has no context on this project. Cover:

- What problem it solves or what role it plays
- How it fits into the broader system
- The key idea or mental model needed to understand it

Avoid jargon where possible. Use analogy if it genuinely clarifies.

### Part 2 — Technical Explanation

Walk through the implementation with precision. Cover:

- Structure: key functions, classes, or sections and how they relate
- Data flow: what comes in, what goes out, what gets transformed
- Dependencies: what it relies on and what relies on it
- Notable decisions: non-obvious implementation choices, trade-offs, or constraints

Reference specific line numbers and identifiers. Do not restate Part 1 in technical language — add new information.
