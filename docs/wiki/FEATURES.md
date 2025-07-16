# Project Features: BASHFX

This document outlines the phased development roadmap for the BashFX framework.

**Status Legend:**

- ✅ **Complete:** The feature and its sub-tasks are implemented and considered stable.
    
- 🟡 **In Progress:** The feature is actively being developed or refactored.
    
- ⚪ **Planned:** The feature is defined but work has not yet begun.
    

---

## Phase I: Core System Bootstrap (Complete)

This phase establishes the foundational mechanics for installing and configuring the BashFX environment.

- ✅ **FEATURE-001: BASHFX Stage Setup (setup.dev)**
    
    - A fully unwindable setup utility to prime a developer's shell environment for installing BashFX.
        
    - Sub-tasks 1.1 - 1.5 are complete.
        
- ✅ **FEATURE-002: Environment Bootstrap (devfx)**
    
    - The core script's ability to install and configure the permanent BashFX environment.
        
    - Sub-tasks 2.1 - 2.4 are complete.
        
- ✅ **FEATURE-003: Safe Package Deployment**
    
    - The logic for deploying packages from the source repository and generating a package manifest. This is now handled by dedicated library modules.
        
    - Sub-tasks 3.1 - 3.4 are functionally complete and refactored into manifest.sh and helper functions.
        
- ✅ **FEATURE-004: Package Integrity & Linking**
    
    - The logic for verifying package integrity via checksums and creating symlinks for executables. This is now handled by dedicated library modules.
        
    - Sub-tasks 4.1 - 4.3 are functionally complete and refactored into integrity.sh and pkglinker.sh.
        
- ✅ **FEATURE-005: Finalization & Stage Unwind**
    
    - The process by which devfx self-promotes to fx and orchestrates the teardown of the temporary development environment.
        
    - Sub-tasks 5.1 - 5.3 are complete.
        

---

## Phase 1.5: Solidification & Foundational Testing (Current Focus)

This critical phase ensures the architectural refactoring from Phase I is stable and testable before new features are added.

- ✅ **FEATURE-012: Test-Driven Development via Feature Drivers**
    
    - **Description:** Formalizes the testing strategy for the project. Each new feature must be accompanied by a test driver function.
        
    - **12.1: Driver Mechanism:** Implemented a devfx driver [N] subcommand to execute granular, feature-specific test functions named fx_f[N]_driver().
        
    - **12.2: Driver Responsibilities:** Each driver tests the "happy path" of its corresponding feature and is fully "Rewindable," cleaning up any artifacts it creates.
        
    - **12.3: Initial Driver Implementation:** Created fx_f3_driver and fx_f4_driver to validate the now-complete package deployment and integrity logic. The `stdfx-driver.sh` was also implemented and is passing all tests.
        
- ✅ **FEATURE-013: Architectural Refactoring & Integration**
    
    - **Description:** Completed the surgical refactoring of devfx to use the new, modular libraries. This included the development of a new, robust options parsing system featuring declarative option definitions, `getopt` integration for argument normalization, a flexible hook system (`_pre_options`, `_post_options`), and efficient bitmasking for boolean flags, ensuring namespaced option variables (e.g., `opt_namespace_flag`). This refactoring aimed to replace the monolithic `options()` function in `stdopts.sh` with a modular, extensible architecture.
        
    - **13.1: devfx Integration:** The main setup function within devfx was updated to orchestrate calls to manifest.sh, integrity.sh, and pkglinker.sh, replacing its old monolithic logic.
    - **13.2: stdfx.sh Utilities:** Implemented and stabilized core utility functions in `stdfx.sh`, including path manipulation, file system checks, and string operations, with comprehensive test coverage.

- 🟡 **FEATURE-014: Knife Integration & Refactoring**
    - **Description:** Systematic integration of the `knife` utility across the BashFX codebase to replace ad-hoc `grep`, `sed`, and `awk` commands for file and text manipulation. This aims to improve code readability, maintainability, and leverage `knife`'s specialized functions for tasks like linking, unlinking, variable management, and metadata operations.
    - **14.1: Core Replacements:** Replace `grep -qF` with `knife linked` in `devfx` and `proflink.sh`.
    - **14.2: Feature Driver Enhancements:** Replace `grep` checks with `knife has` in feature drivers.
    - **14.3: RC File Variable Management:** Replace manual variable setting/getting with `knife setv`/`knife getv` in `rcfile.sh`.
    - **14.4: Metadata Operations:** Replace `sed` for metadata management with `knife metaset`/`metaget`/`metadel`.
    - **14.5: Visual Element Extraction:** Replace `sed` for logo/banner extraction with `knife blockr`/`knife logo`.

---

## Phase II: User Experience & The Triumvirate (Planned)

This phase focuses on building out the user-facing tools and improving day-to-day usability.

- ⚪ **FEATURE-007: pkgfx - The Dedicated Package Manager**
    
    - **Description:** Formalize the creation of the standalone pkgfx command, which will become the "Quartermaster" of the framework.
        
    - **7.1: Script Formalization:** Create the pkgfx.sh source file. It will be a "Proper Script" with its own dispatcher.
        
    - **7.2: Logic Encapsulation:** The pkgfx script will be built by sourcing the manifest.sh, integrity.sh, and pkglinker.sh libraries.
        
    - **7.3: fx Command Delegation:** The main fx command will be refactored to delegate all package-related tasks (install, uninstall, etc.) to the pkgfx executable.
        
- ⚪ **FEATURE-006: fx - User-Facing QOL Enhancements**
    
    - **Description:** A set of features to improve the usability and maintenance of the BashFX environment, implemented as subcommands in the main fx tool.
        
    - **6.1: System Status (fx status):** A diagnostic tool that will call pkgfx list and pkgfx verify.
        
    - **6.2: Self-Update (fx update):** A command to git pull the source and re-run the core deployment by calling devfx setup.
        
    - **6.3: Tab Completion:** A completion script for both fx and pkgfx commands.
        
    - **6.4: User-Facing Repair Warnings:** The fx.rc startup warning when FX_REPAIR=true is set.
        
    - **6.5: Granular Help Text:** A "Comment Hack" based help system (fx help [command]).
        

---

## Phase III: Developer Experience & Automation (Planned)

This phase evolves fx into a powerful developer assistant for creating new BashFX scripts.

- ⚪ **FEATURE-008: Formalized Metadata Block**
    
    - **Description:** Standardize a # key: value comment block in all "Proper Scripts" for metadata.
        
    - **8.1: Standard Keys:** Define keys for name, desc, author, semver, and alias.
        
    - **8.2: Parser Integration:** Update pkgfx to read the # alias: key during installation.
        
- ⚪ **FEATURE-009: Scaffolding Tool (fx dev create)**
    
    - **Description:** Implement a command to generate a new script from a "Proper Script" template.
        
    - **8.1: Standard Keys:** Define keys for name, desc, author, semver, and alias.
        
    - **8.2: Parser Integration:** Update pkgfx to read the # alias: key during installation.
        
- ⚪ **FEATURE-010: Code Quality Tool (fx dev lint)**
    
    - **Description:** Implement a command to validate script metadata and optionally run shellcheck if it is installed.
        
- 🟡 **FEATURE-011: Metadata Management Tool (fx dev meta)**
    
    - **Description:** Implement a command to programmatically get and set values in a script's metadata block, leveraging `knife metaget`, `knife metaset`, and `knife metadel` for robust and standardized metadata manipulation.