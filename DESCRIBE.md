# BashFX: Architectural Principles and Design

This document outlines the core architectural pillars and design philosophy of the BashFX system. It is a living document intended to guide development, ensure consistency, and serve as a reference for why certain design decisions were made.

## Introduction

BashFX is a framework for managing a personal library of shell scripts and functions. Its primary goal is to bring consistency, organization, and a streamlined user experience to a collection of tools that have evolved over time. It achieves this by providing a managed, stateful, and interactive environment that prioritizes user clarity and cognitive ergonomics over strict adherence to traditional shell scripting paradigms.

---

## Core Architectural Pillars

### 1. User-Centric and Interactive Interface

The system is designed primarily for a human operator. Its interface prioritizes clarity, guidance, and ease of use.

*   **Principle:** The user experience is paramount. The system should be intuitive and provide clear feedback about its state and available actions.
*   **In Practice:**
    *   **Colored Output:** `setup.dev` uses distinct colors for success (`_green`), error (`_red`), informational (`_blue`), and secondary (`_grey`) messages. This provides at-a-glance status comprehension.
    *   **Contextual Help:** The `fx_next` function provides dynamic, contextual guidance, telling the user what to do next based on the system's current state (e.g., "Run `source setup.dev init`" vs. "Use `fxinstall` to complete").
*   **Implication:** This deviates from the classic Unix philosophy of small, silent, composable tools. BashFX is more of a user-facing application suite than a collection of pipeline filters.

### 2. Stateful and Rewindable Lifecycle

BashFX explicitly manages the state of the user's shell environment through a well-defined lifecycle. It treats environment modification as a transaction that can be fully and safely reversed.

*   **Principle:** All setup operations must be idempotent and fully "rewindable." The system must be able to clean up after itself, even from a partially broken state.
*   **In Practice:**
    *   **State Machine:** The system moves between distinct states: `uninitialized` -> `initialized` (via `init`) -> `uninstalled` (via `reset`).
    *   **Idempotency:** The `fx_init` command checks if the `source` line already exists in the profile before adding it, preventing duplication on subsequent runs.
    *   **Stateless Uninstall:** The `fx_uninstall` function is self-sufficient. It calculates necessary paths independently rather than relying on the existence of the `.fxsetuprc` file, ensuring it can always clean up the user's profile correctly.
*   **Implication:** This provides a high degree of safety and user trust. Users can experiment with the setup, confident that they can always return their environment to its original state.

### 3. Modular and Contextual Environment

The system avoids polluting the global shell environment or creating a monolithic configuration file. It uses a modular approach to load functionality on demand.

*   **Principle:** Shell environment modifications should be encapsulated and contextual. Functionality should be organized into self-contained, manageable "buckets."
*   **In Practice:**
    *   **RC File Pattern:** Instead of writing many lines to `~/.profile`, `setup.dev` adds a single `source` command that points to a dedicated `.fxsetuprc` file. This file contains all the environment variables, aliases, and functions specific to the BashFX context.
    *   **Future Vision:** This pattern will be extended to the larger system, allowing different script libraries or toolsets to be managed as discrete modules that can be loaded or unloaded as needed.
*   **Implication:** This promotes a clean, organized shell environment. It makes it easier to manage complex configurations and debug issues by isolating variables and functions to a specific context.

### 4. Framework for Consistency

BashFX is not just a collection of scripts; it is a framework that imposes a consistent structure and provides shared utilities. This is its core solution to managing the "inconsistent age and state" of an evolving script library.

*   **Principle:** Enforce consistency through convention and shared infrastructure. Reduce boilerplate and standardize common patterns like argument parsing and error handling.
*   **In Practice:**
    *   **Directory Structure:** The `.fxsetuprc` file establishes a conventional directory structure (`FXI_BIN_DIR`, `FXI_PKG_DIR`, `FXI_INC_DIR`).
    *   **Shared Libraries:** The `FXI_INC_DIR` is envisioned for shared library scripts, allowing common functions to be reused across all tools in the system.
    *   **Unified Entry Point:** The `fxi` alias (pointing to `devfx`) will act as a single, consistent entry point for interacting with the entire system, providing a unified command structure.
*   **Implication:** This reduces technical debt and increases maintainability. New scripts added to the system will automatically benefit from the framework's structure and shared utilities.

### 5. Hermetic and Self-Contained

The system is designed to be self-reliant and to avoid leaving unintended artifacts in the user's environment.

*   **Principle:** A tool should clean up after itself and operate with minimal external dependencies, especially in its target environment.
*   **In Practice:**
    *   **Function Cleanup:** The `setup.dev` script, when sourced, immediately unsets all of its internal functions and temporary variables upon completion, leaving the shell session clean.
    *   **Minimal Dependencies:** The design focuses on using Bash and common shell built-ins, ensuring it runs reliably in constrained environments where higher-level languages like Python may not be available.
    *   **Testability:** The `FX_TEST_MODE` flag allows the script's functions to be loaded without execution, enabling isolated, hermetic testing—a critical practice for ensuring robustness.
*   **Implication:** The system is portable, reliable, and non-intrusive, making it a trustworthy addition to a developer's environment.

---

## System Lifecycle and States

The `setup.dev` script operates as a simple state machine, guiding the user through the installation and removal of the BashFX environment. Understanding these states is key to understanding the system's behavior.

### 1. Uninitialized State

This is the default state of the system before any setup has been performed.

*   **Condition:** The `.fxsetuprc` file does not exist, and the user's shell profile has not been modified.
*   **User Action:** Running `source setup.dev` with no arguments.
*   **Outcome:**
    *   The script detects that the setup is incomplete.
    *   It displays a help message instructing the user to run `source setup.dev init` to begin the setup process.

### 2. Initialized State

This state is reached after the user successfully runs the `init` command. The BashFX environment is now active for the current session and configured to load in future sessions.

*   **Condition:** The `.fxsetuprc` file exists and is linked from the user's shell profile.
*   **User Action:**
    *   To enter this state: `source setup.dev init`.
    *   When in this state: `source setup.dev` (or opening a new shell).
*   **Outcome:**
    *   The `.fxsetuprc` file is created and a `source` line is added to the user's profile.
    *   The BashFX environment (variables like `FXI_ROOT_DIR`, aliases like `fxinstall`, `fxdel`) is loaded.
    *   Running `source setup.dev` now displays a "ready" message and lists the core command aliases available to the user.

### 3. Uninstalled State (Return to Uninitialized)

This is the result of the `reset` command, which completely undoes the setup and returns the system to the **Uninitialized** state.

*   **Condition:** The user wishes to remove the BashFX environment.
*   **User Action:** `source setup.dev reset`.
*   **Outcome:**
    *   The `source` line is removed from the user's shell profile.
    *   The `.fxsetuprc` file is deleted.
    *   All environment variables, aliases, and functions related to BashFX are unset from the current session.
    *   The system is now back in the **Uninitialized** state.
