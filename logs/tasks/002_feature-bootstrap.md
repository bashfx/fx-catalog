# TASK-002: Implement FEATURE-002 (Package Management Bootstrap)

- **Date**: 2023-10-27
- **Objective**: Implement the core logic in `devfx` to establish the permanent BASHFX environment. This involves creating XDG-compliant directories, generating the permanent `.fxrc` file, and updating the user's shell profile to make the installation persistent.
- **Branch**: `g-feat-bootstrap-20231027`

## Strategy & Code Plan

The implementation will be broken down into distinct functions within `bin/devfx`, each corresponding to a sub-task from `FEATURES.md`.

### Sub-task 2.1: XDG Path Initialization

**Function:** `fx_resolve_paths`

**Purpose:**
- Define and export the core `FX_*` path variables.
- Adhere to the XDG Base Directory Specification, providing sane fallbacks if the standard environment variables (`XDG_CONFIG_HOME`, `XDG_BIN_HOME`) are not set.
- Create the necessary directories if they don't exist.

**Implementation Steps:**
1. Define `FX_CONFIG_DIR` using `${XDG_CONFIG_HOME:-$HOME/.config}/fx`.
2. Define `FX_BIN_DIR` using `${XDG_BIN_HOME:-$HOME/.local/bin}`.
3. Define `FX_LIB_HOME` using a custom variable, defaulting to `${FX_LIB_HOME:-$HOME/.local/lib}/fx`.
4. Use `mkdir -p` to create these directories.
5. The function should `export` these variables so they are available to subsequent functions in the script.

### Sub-task 2.2 & 2.3: Permanent RC Generation & Definition

**Function:** `fx_write_rcfile`

**Purpose:**
- Generate the permanent `.fxrc` file at `$FX_CONFIG_DIR/.fxrc`.
- Populate this file with the necessary `export` commands to define the BASHFX runtime environment for all future shell sessions.

**Implementation Steps:**
1. Use a `cat << EOF > "$FX_CONFIG_DIR/.fxrc"` heredoc to write the file.
2. The heredoc should contain `export` statements for `FX_CONFIG_DIR`, `FX_BIN_DIR`, `FX_LIB_HOME`, and add `FX_BIN_DIR` to the `PATH`.

### Sub-task 2.4: Permanent Profile Link

**Function:** `fx_link_profile`

**Purpose:**
- Atomically replace the temporary `source "$FXI_SETUP_RC"` line in the user's canonical profile with the permanent `source "$FX_CONFIG_DIR/.fxrc"` line.

**Implementation Steps:**
1. Re-use the `fxi_canonical_profile` logic (or source `setup.dev` to use it directly) to find the user's profile file.
2. Use the safe `sed "s|old|new|" "$PROFILE" > "$PROFILE.tmp" && mv "$PROFILE.tmp" "$PROFILE"` pattern to perform the replacement. This ensures the profile is not corrupted on failure.

### Orchestration

A new command, `setup`, will be added to the main `case` statement in `devfx`. It will call these functions in order:
1. `fx_resolve_paths`
2. `fx_write_rcfile`
3. `fx_link_profile`

---### Verification Steps

- **[ ] Sub-task 2.1:** After running, verify that the `$HOME/.config/fx`, `/.local/bin`, and `/.local/lib/fx` directories have been created.
- **[ ] Sub-task 2.2:** Check that `/.config/fx/.fxrc` exists and contains the correct `export` statements for the permanent `FX_*` variables.
- **[ ] Sub-task 2.4:** Confirm that the user's `.profile` now contains a `source` line pointing to the new `.fxrc` and that the old temporary line is gone.
