# Project Features : BASHFX

Note this is a first pass at describing the feature set. These should be broken down with their priority label.

- FEATURE-001: BASHFX Stage Setup (setup.dev) Create a fully unwindable setup utility to prime the user’s shell environment for installing BASHFX tools, scripts, and libraries. Uses FXI_* prefixed setup variables stored into an RC file linked to the user’s profile. If incomplete, the link nudges users to finish installation. Once fully installed, all fxi_* traces are removed in favor of FX_ runtime variants.
    - ✅ **1.1: Profile Detection:** Reliably find the user's canonical shell profile (`.profile` or `.bash_profile`), resolving symlinks.
    - ✅ **1.2: RC File Generation:** Dynamically generate a temporary `.fxsetuprc` file in the project root, populating it with `FXI_*` environment variables.
    - ✅ **1.3: Profile Linking:** Safely append a `source` command to the user's profile to load `.fxsetuprc`.
    - ✅ **1.4: State-Aware Guidance:** Provide contextual instructions to the user based on setup completion status.
    - ✅ **1.5: Transactional Uninstall:** Ensure the `reset` command cleanly removes the profile link, RC file, and all temporary environment variables and aliases.

- FEATURE-002: Package Management Bootstrap (devfx) Installs and configures the base BASHFX package environment. Initializes XDG-compliant paths and creates .fxrc to house pathing, state, and configuration. If .fxrc is missing, devfx generates one using best-guess values from the XDG spec and links it to the shell profile for auto-recovery on restart.
    - ⚪ **2.1: XDG Path Initialization:** On first run, determine or create standard XDG directories (`$XDG_CONFIG_HOME/fx`, `$XDG_BIN_HOME`) and a project-specific library path, `FX_LIB_HOME` (e.g., defaulting to `$HOME/.local/lib`).
    - ⚪ **2.2: Permanent RC Generation:** Create the permanent runtime configuration file at `$XDG_CONFIG_HOME/fx/.fxrc`.
    - ⚪ **2.3: Runtime Environment Definition:** Populate `.fxrc` with the permanent `FX_*` environment variables pointing to the newly established XDG and library directories.
    - ⚪ **2.4: Permanent Profile Link:** Atomically replace the temporary `source` line in the user's profile with one that points to the new, permanent `.fxrc`.

- FEATURE-003: Safe Package Deployment (devfx) Performs safe copy of includes, utils, and core FX packages to proper XDG directories. Optionally hashes each file using MD5 if available. Hashes are stored in ./docs/hash/, including filename, canonical path, timestamp, and alias. An installed.log is maintained in the XDG config directory to track active aliases.
    - ⚪ **3.1: Package Discovery:** Iterate through the `pkgs/` subdirectories (`inc`, `utils`, `fx`).
    - ⚪ **3.2: Structured File Deployment:** Copy discovered packages to their designated subdirectories within `$FX_LIB_HOME/fx/`:
        - `pkgs/inc/*.sh` → `$FX_LIB_HOME/fx/inc/`
        - `pkgs/utils/**/*.sh` → `$FX_LIB_HOME/fx/utils/`
        - `pkgs/fx/**/*.sh` → `$FX_LIB_HOME/fx/core/`
    - ⚪ **3.3: Manifest Generation:** During deployment, generate an `md5sum` checksum for each file and store it in a manifest at `$XDG_CONFIG_HOME/fx/manifest.log`. The manifest will map the checksum to the script's installed path and its intended alias.
    - ⚪ **3.4: Alias Registration:** Parse files for an `# alias:<name>` directive to determine the alias. If none exists, generate a default alias from the filename.

- FEATURE-004: Package Integrity + PATH Linking (devfx) Provides anti-tampering validation using the generated hashes. Validated files are symlinked into the appropriate XDG bin directory (as set in .fxrc) using their registered alias. This ensures user-accessible execution via $PATH and guards against unnoticed modifications.
    - ⚪ **4.1: Integrity Check:** Implement a `devfx verify` command that reads `manifest.log` and validates the checksums of all installed files against their on-disk counterparts.
    - ⚪ **4.2: Tamper Flag:** If a checksum mismatch is detected for any file, set `FX_REPAIR=true` in `$XDG_CONFIG_HOME/fx/.fxrc` and skip symlinking for that file. This flags the environment as corrupted for later user notification.
    - ⚪ **4.3: Executable Symlinking:** For each `core` and `utils` package that passes verification, create a symlink from its location in `$FX_LIB_HOME/fx/` to `$XDG_BIN_HOME/<alias>`, making it available on the user's `$PATH`.

- FEATURE-005: Finalize & Stage Unwind (setup.dev) Cleans up setup traces: removes temporary RC files, clears FXI_* artifacts, and detaches all install aliases. Transitions the shell to rely solely on installed libraries and runtime configuration. Package manager is copied and aliased as fx, becoming a first-class persistent tool available across sessions.
    - ⚪ **5.1: Self-Promotion:** The `devfx setup` command must copy itself to `$XDG_BIN_HOME/fx` to ensure it persists after the temporary environment is torn down.
    - ⚪ **5.2: Teardown Execution:** As the final step of a successful installation, `devfx` must invoke `setup.dev reset` to trigger the complete uninstall of the temporary `fxi_` environment.
    - ⚪ **5.3: Session Reload Hint:** After teardown, instruct the user to reload their shell to activate the new, permanent environment.


## Phase II: User Experience & Maintenance

- FEATURE-006: User Experience & Quality of Life (QOL) Enhancements. A set of features focused on improving the day-to-day usability, discoverability, and maintenance of the BASHFX environment.
    - ⚪ **6.1: System Status Command (`fx status`):** Implement a diagnostic tool that verifies the installation health. It should check for a valid `.fxrc`, sourced profile link, file integrity via the manifest, and list all installed/aliased commands.
    - ⚪ **6.2: Self-Update Mechanism (`fx update`):** Provide a command to pull the latest changes from the source repository and re-run the installation and verification process, allowing for seamless upgrades.
    - ⚪ **6.3: Tab Completion:** Create and install a bash completion script that provides hints for `fx` subcommands and arguments, drastically improving discoverability and speed of use.
    - ⚪ **6.4: User-Facing Repair Warnings:** When `FX_REPAIR=true` is set in `.fxrc`, the shell startup sequence should print a clear, actionable warning to the user, prompting them to run a repair or re-install command.
    - ⚪ **6.5: Granular Help Text:** Ensure every user-facing command (e.g., `fx install`, `fx verify`) supports a `--help` flag that provides detailed usage, options, and examples.
