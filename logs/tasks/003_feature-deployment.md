# TASK-003: Implement FEATURE-003 (Safe Package Deployment)

- **Date**: 2023-10-27
- **Objective**: Implement the package deployment logic in `devfx`. This involves discovering all source packages, copying them to their structured destinations within `$FX_LIB_HOME`, and generating a manifest file containing checksums and aliases for each deployed file.
- **Branch**: `g-feat-deployment-20231027`

---

## Strategy & Code Plan

This feature builds directly on the foundation laid by `FEATURE-002`. It assumes that the XDG paths and the permanent `.fxrc` file have been established. The logic will be encapsulated in a new `install` command within `devfx`.

### Sub-task 3.1 & 3.2: Package Discovery & Structured Deployment

**Function:** `fx_deploy_packages`

**Purpose:**
- Systematically find all installable packages in the source `pkgs/` directory.
- Copy them to their respective subdirectories (`inc`, `utils`, `core`) within `$FX_LIB_HOME/fx`.

**Implementation Steps:**
1.  Define source directories: `SRC_INC="$FXI_PKG_DIR/inc"`, `SRC_UTILS="$FXI_PKG_DIR/utils"`, `SRC_CORE="$FXI_PKG_DIR/fx"`.
2.  Define destination directories: `DEST_INC="$FX_LIB_HOME/inc"`, `DEST_UTILS="$FX_LIB_HOME/utils"`, `DEST_CORE="$FX_LIB_HOME/core"`.
3.  Use `mkdir -p` to create all destination directories.
4.  Use `find "$SRC_DIR" -type f -name "*.sh" -exec cp {} "$DEST_DIR/" \;` for each source/destination pair to perform the copy.

### Sub-task 3.3 & 3.4: Manifest Generation & Alias Registration

**Function:** `fx_generate_manifest`

**Purpose:**
- Create a `manifest.log` file that serves as the single source of truth for all installed files.
- For each file, record its checksum, its intended alias, and its installed location.

**Implementation Steps:**
1.  Define the manifest path: `MANIFEST_FILE="$FX_CONFIG_DIR/manifest.log"`.
2.  Clear any existing manifest file: `> "$MANIFEST_FILE"`.
3.  Use `find "$FX_LIB_HOME" -type f -name "*.sh"` to iterate through all deployed files.
4.  Inside the loop for each file:
    a.  Calculate the checksum: `CHECKSUM=$(md5sum "$file" | awk '{print $1}')`.
    b.  Extract the alias: `ALIAS=$(grep -m 1 '^# alias:' "$file" | cut -d: -f2)`.
    c.  If `ALIAS` is empty, derive it from the filename: `ALIAS=$(basename "$file" .sh)`.
    d.  Append the record to the manifest: `echo "$CHECKSUM $ALIAS $file" >> "$MANIFEST_FILE"`.

### Orchestration

A new command, `install`, will be added to the main `case` statement in `devfx`. It will call these functions in order:
1. `fx_deploy_packages`
2. `fx_generate_manifest`

The primary `setup` command should be updated to call `install` after the bootstrap is complete.
