# fx-catalog

A catalog of shell functions and utilities for the BashFX framework.

## Overview

This repository contains the core components, packages, and development tools for `bashfx`. It is designed to be a modular and extensible system for shell scripting.

## Quick Start

1.  **Setup the environment:**
    ```bash
    ./bin/setup.dev
    ```
2.  **Explore available tools:**
    ```bash
    devfx help
    ```

## Global Modes
    
    BashFX respects these global level flags.

    `DEV_MODE`   - enables `dev_log` messages and `require_dev` guards, guards block `dev_` prefixed functions (manually)
    `QUIET_MODE` - disables any and all stderr log messages, this is mostly useful in testing and piping. If you have 
    `DEBUG_MODE` - 
    `TEST_MODE`  - 



## Philosophy

This project adheres to a set of core principles for creating robust, portable, and maintainable shell scripts. See `docs/wiki/PILLARS.md` for more details.
