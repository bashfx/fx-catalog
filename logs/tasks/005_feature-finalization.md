# TASK-005: Implement FEATURE-005 (Finalize & Stage Unwind)

- **Date**: 2023-10-27
- **Objective**: Implement the finalization logic that transitions the system from the temporary setup stage to a permanent, self-contained installation. This involves making the `devfx` script persistent and cleaning up all temporary artifacts.
- **Branch**: `g-feat-finalization-20231027`

---

## Strategy & Code Plan

This is the last step of the `setup` command's orchestration. It ensures that once the installation is successful, the temporary scaffolding (`fxi_*` environment) is cleanly removed, leaving only the persistent `fx` command.

### Sub-task 5.1: Self-Promotion

**Function:** `fx_promote_self`

**Purpose:**
- Copy the `devfx` script itself to the permanent bin directory (`$FX_BIN_DIR`) with the name `fx`. This makes it a first-class command on the user's `$PATH`.

**Implementation Steps:**
1.  This function must be called *before* the teardown is triggered.
2.  It will use `cp "$THIS_SELF" "$FX_BIN_DIR/fx"` to create the permanent command.
3.  It should also ensure the new `fx` command is executable with `chmod +x "$FX_BIN_DIR/fx"`.

### Sub-task 5.2: Teardown Execution

**Function:** `fx_trigger_teardown`

**Purpose:**
- Execute the `setup.dev` script with the `reset` command to perform a full cleanup of the temporary environment.

**Implementation Steps:**
1.  The path to the original `setup.dev` script is available via the initial `FXI_ROOT_DIR` variable.
2.  The function will call `"$FXI_ROOT_DIR/setup.dev" reset`.

### Sub-task 5.3: Session Reload Hint

- After `fx_trigger_teardown` completes successfully, the `setup` command will print a final message advising the user to reload their shell (`source ~/.profile` or start a new terminal session) to activate the new environment.

### Orchestration

The main `setup` command in `devfx` will be updated to call these functions as the final steps of a successful installation, after linking.
