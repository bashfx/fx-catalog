
# KNIFE: A Surgical Bash Utility 🔪
*Part of the BASHFX Framework*

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/badge/semver-0.3.4-orange)
![Framework](https://img.shields.io/badge/framework-BASHFX-lightgrey)

**KNIFE(1)** is a modular, command-line utility for structured file introspection and manipulation. It replaces repetitive, error-prone shell one-liners with a robust, verb-like interface for operating on configuration files, scripts, and other text-based documents directly from your terminal.

## Table of Contents
- [Why KNIFE? The Problem & The Solution](#why-knife-the-problem--the-solution)
- [Command Reference](#command-reference)
  - [File Inspection & Search](#file-inspection--search)
  - [Variable Management](#variable-management-shell-style-keyvalue)
  - [File & Block Manipulation](#file--block-manipulation)
  - [Linking & Injection](#linking--injection)
  - [History & Cleanup](#history--cleanup)
- [Practical Workflow Example](#practical-workflow-example)
- [Installation](#installation)
- [Management](#management)

## Why KNIFE? The Problem & The Solution

Are you tired of googling the same `sed` syntax to replace a variable? Do you constantly rewrite `awk` snippets to extract a block of text? Standard shell commands are powerful but often have an arcane, unforgiving syntax.

**The Old Way (Complex & Error-Prone):**
```bash
# Update a variable in a config file, being careful to handle backups and regex escaping...
sed -i.bak "s|^DEBUG_MODE=.*|DEBUG_MODE=\"true\"|" my_config.sh
```

**The KNIFE Way (Simple & Readable):**
```bash
# Same operation, but clear, self-documenting, and safe.
knife setv DEBUG_MODE "true" my_config.sh
```

---

## Core Principles & Safety Features

KNIFE is built on a philosophy of providing high-level, human-readable abstractions ("verbs") for common file operations. This allows you to focus on your script's logic, not on esoteric command-line flags. Its design is guided by the following principles:

*   **BashFX Integration:** As a core part of the BashFX Framework, KNIFE leverages global modes like `DEV_MODE` and `DANGER_MODE` to guard sensitive operations.
*   **Rewindability:** Destructive commands are designed to be reversible wherever possible, often by creating automatic backups. This helps prevent accidental data loss.
*   **Visual Logging:** KNIFE uses the BashFX `stderr` library for clear, color-coded logging, making it easy to distinguish between normal output, warnings, and errors.

### Built-in Safety Guards

To prevent unintended consequences, KNIFE includes several safety mechanisms:

*   **Destructive Command Warnings:** Commands that can alter or delete data are marked internally as "destructive." By default, KNIFE will prompt for confirmation before running them.
*   **Filesystem Protection:** KNIFE prevents certain operations from running in critical directories (like the filesystem root `/`) to protect your system.

These guards are controlled by two primary modes:

#### `DEV_MODE` (Developer Mode)
This mode is for framework developers or users performing advanced modifications. When enabled, it reveals detailed debug logs and bypasses guards on developer-only functions.
*   **To activate for a single command:**
    ```bash
    knife -D <subcommand> <args...>
    ```
*   **To activate for the current shell session:**
    ```bash
    export DEV_MODE=true
    ```

#### `DANGER_MODE` (Danger Mode)
This mode is required for functions that may cause irreversible changes. Since KNIFE is not a version control system, this guard forces you to explicitly acknowledge the risk of a destructive action. There is no single-command flag for this mode.
*   **To activate for the current shell session:**
    ```bash
    export DANGER_MODE=true
    ```

> **Note:** To bypass all guards and prompts, you can enable both modes (`export DEV_MODE=true DANGER_MODE=true`). KNIFE will still attempt to create backups for critical operations, but it will not ask for confirmation.

### Interoperability & Portability

KNIFE is designed to be flexible:
*   **Standalone Utility:** Use it directly from the command line for daily tasks.
*   **Importable Library:** `source` the KNIFE script in your own projects to use its functions directly.
*   **Portable Executable:** For use in environments without the full BashFX framework, you can create a single, self-contained KNIFE script with all dependencies included.
    ```bash
    # Run this from the BASHFX project root
    fxdev package knife
    ```
---

## Command Reference

### File Inspection & Search

#### `knife line`
Prints the content of a specific line number.
- **Syntax:** `knife line <line_number> <file>`
- **Example:**
  ```bash
  knife line 5 my_script.sh
  ```
- **Output:**
  ```
  # Version: 1.2.0
  ```

#### `knife lines`
Quickly counts and prints the total number of lines in a file.
- **Syntax:** `knife lines quick <file>`
- **Example:**
  ```bash
  knife lines quick my_script.sh
  ```
- **Output:**
  ```
  142
  ```

#### `knife has`
Checks if a file contains a given string. Exits with `0` (success) if found, `1` (failure) if not.
- **Syntax:** `knife has <string> <file>`
- **Example (for scripting):**
  ```bash
  if knife has "MY_API_KEY" config.env; then
    echo "Key found!"
  fi
  ```
- **Output:**
  ```
  Key found!
  ```

#### `knife show`
Prints all lines that match a string, prefixed with their line numbers.
- **Syntax:** `knife show <string> <file>`
- **Example:**
  ```bash
  knife show "export" ~/.bash_profile
  ```
- **Output:**
  ```
  23:export PATH="/usr/local/bin:$PATH"
  45:export EDITOR="vim"
  ```

#### `knife search`
Recursively finds all files in the current directory containing a string. Respects common exclusions like `.git` and 
`node_modules`.

- **Syntax:** `knife search <string>`
- **Example:**
  ```bash
  knife search "TODO:"
  ```
- **Output:**
  ```
  ./scripts/deploy.sh
  ./src/main.js
  ```

Note: by default knife will not let you search from root '\' or any system directory outside of `$HOME`, and attempts to do so will be nagged by a guard prompt.  

### Variable Management (Shell-style `KEY=VALUE`)

#### `knife getv`
Gets the value of a shell-style variable (`KEY=VALUE`).
- **Syntax:** `knife getv <key> <file>`
- **Example:**
  ```bash
  DB_USER=$(knife getv DB_USER .env)
  echo "Database user is: $DB_USER"
  ```
- **Output:**
  ```
  Database user is: admin_user
  ```

#### `knife setv`
Sets or updates the value of a shell-style variable. If the key does not exist, it is added. A backup (`.bak`) file is created automatically.
- **Alias:** `defv`
- **Syntax:** `knife setv <key> <value> <file>`
- **Example:**
  ```bash
  knife setv API_ENDPOINT "https://api.prod.com/v2" config.ini
  grep API_ENDPOINT config.ini
  ```
- **Output:**
  ```
  API_ENDPOINT="https://api.prod.com/v2"
  ```

### File & Block Manipulation

#### `knife block`
Extracts a named block of text demarcated by `### open:block_name` and `### close:block_name` markers.
- **Alias:** `extract`
- **Syntax:** `knife block <block_name> <file>`
- **Example:**
  ```bash
  knife block core_functions my_lib.sh
  ```
- **Output:**
  ```
  function my_helper() {
    echo "Helper function executed."
  }
  ```

#### `knife delete`
Replaces a specific line with a timestamped placeholder comment, preserving line numbering.
- **Syntax:** `knife delete <line_number> <file>`
- **Example:**
  ```bash
  knife delete 45 obsolete_code.sh
  knife line 45 obsolete_code.sh
  ```
- **Output:**
  ```
  #knife deleted line 2023-10-28 11:45:01
  ```

### Linking & Injection

#### `knife link`
Binds two shell scripts by adding a `source` statement to the end of the destination file.
- **Syntax:** `knife link <source_file> <destination_file>`
- **Example:**
  ```bash
  knife link my_aliases.sh ~/.bashrc
  tail -n 1 ~/.bashrc
  ```
- **Output:**
  ```
  source "/home/user/my_aliases.sh" # knife:link
  ```

#### `knife inject`
Injects the content of a source file at a specific marker in a destination file (e.g., `### include:plugin_a.sh ###`).
- **Syntax:** `knife inject <source_file> <destination_file>`
- **Example:**
  ```bash
  # Injects content of plugin_a.sh after the include marker in main_script.sh
  knife inject plugin_a.sh main_script.sh
  ```

### History & Cleanup

#### `knife history`
Displays a log of all destructive operations performed by KNIFE.
- **Syntax:** `knife history [:field...] [file]`
- **Example:**
  ```bash
  # Show time, command, and filename for operations on my_config.sh
  knife history :time :cmd :vanity my_config.sh
  ```
- **Output:**
  ```
  Time                 Command   File
  2023-10-28 10:30:15  setv      my_config.sh
  2023-10-28 10:32:01  link      my_config.sh
  ```

#### `knife cleanup`
Interactively prompts to remove all KNIFE-generated artifacts (`.bak` files, history logs, etc.).
- **Syntax:** `knife cleanup`
- **Example:**
  ```bash
  knife cleanup
  ```

---

## Practical Workflow Example

Here’s how you might use KNIFE in a typical project setup:

```bash
# 1. Initialize a new config file by setting its first variable
knife setv API_URL "http://localhost:8080" config.ini

# 2. Add a debug flag
knife setv DEBUG_MODE "true" config.ini

# 3. Check the value you just set
DB_DEBUG_MODE=$(knife getv DEBUG_MODE config.ini)
echo "Debug mode is: $DB_DEBUG_MODE"

# 4. Link a shared function library into your main script
knife link shared_functions.sh main_script.sh

# 5. Inject a plugin that handles authentication
knife inject auth_plugin.sh main_script.sh

# 6. Find where we set the API URL across all files
knife search "API_URL"

# 7. See what we've done by checking the history
knife history
```

---

## Installation

KNIFE is a core component of the **BASHFX framework** and is installed as part of it.

### via BASHFX (Recommended)
1.  **Download BASHFX:**
    ```bash
    git clone https://github.com/qodeninja/bashfx.git
    cd bashfx
    ```
2.  **Run the BASHFX Launcher:**
    This primes your shell for installation and enables debug commands.
    ```bash
    source launcher.dev launch
    ```
3.  **Install the Framework:**
    This command deploys the BASHFX core scripts, including KNIFE.
    ```bash
    fxinstall
    ```

### Standalone Version (Optional)
If you only need KNIFE, you can package a portable, standalone version with all dependencies included.
```bash
# Run this from the BASHFX project root
fxdev portable knife
```

## Management

### Verifying the Installation
Check that KNIFE is installed and available on your `PATH`.
```bash
type knife
# or
which knife #if using an alias
```

### Disabling/Sleeping the Package
If you need to temporarily disable the `knife` command, you can put the package to "sleep". Underlying tools that depend on it will still function correctly.
```bash
pkgfx adios knife
#re-enable it
pkgfx hola knife
```


There is no "uninstall" for a core package like KNIFE, but sleeping it effectively removes it from your active shell commands.
