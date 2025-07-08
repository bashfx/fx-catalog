# Project Doctrine: BashFX

BashFX is a framework for managing a personal library of shell scripts and functions. Its goal is to bring consistency, structure, and an intuitive UX to shell workflows that usually evolve ad-hoc. It favors cognitive clarity and environmental integrity over conventional scripting minimalism.

## Principles

* **Forge a Responsive Instrument:**
  The terminal is not a log file; it's a cockpit. Use color, context, and state to give the operator a clear, interactive view of the environment.

* **Embrace Transactional State:**
  Every action must be reversible. Treat env changes like DB transactions—idempotent on setup, undoable on demand.

* **Isolate, Never Pollute:**
  The global shell environment is sacred. All logic, vars, and functions must live within a namespaced RC file.

* **Impose Order Through Convention:**
  Directory structure and shared libs are enforced, not optional. Consistency is the key to composability.

* **Be Hermetic and Leave No Trace:**
  Scripts must clean themselves after use. They unset all traces of their execution from the shell session.

## Key Design Decisions

1. **Namespace Isolation**

   * `fxi_` for internal boot logic, `FX_` for user-side runtime
   * Prevents collisions in user shells

2. **Central Command Dispatcher**

   * `case` block in `fxi_main` routes subcommands
   * Makes CLI extension predictable and modular

3. **Dynamic Path Resolution**

   * No hardcoded paths; everything derived from `${BASH_SOURCE[0]}`
   * Project is location-independent

4. **Safe File Manipulation**

   * `sed > temp && mv` patterns avoid corrupting user profiles
   * Atomic edits with rollback integrity

5. **Thorough Cleanup**

   * `fxi_uninstall` and `__clean` wipe all trace from session
   * Respect user environment fully

6. **Context-Aware Guidance**

   * `fxi_next` shows different prompts based on state
   * Reduces friction in multi-step flows

## Code Style & Philosophy

* **Functional & Modular**: One task per function. Everything testable.
* **Defensive & Robust**: Always quote vars. Always guard arguments.
* **Elegant Shell Idioms**: The code favors concise, powerful, and idiomatic shell constructs:
  * `[[ ":$PATH:" != *":$DIR:"* ]]` for safe checks
  * `${1:-}` for clean defaults
  * `type` to test commands
* **Avoid Subshells When Mutating State**: Use process substitution instead of pipe loops.`while read ...; done < <(command)`
* **State-Driven Output**: Colored, contextual feedback to guide the user

---

This document acts as the behavioral doctrine and architectural foundation for all Gemini reasoning within BashFX.
