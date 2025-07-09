- **Label:** FEATURE-012: Test-Driven Development via Feature Drivers
- **Objective:** Formalize the testing strategy by implementing a `devfx driver [N]` subcommand to execute granular, feature-specific test functions.
- **Strategy:**
    1.  **Create Branch & Log:** Create branch `feature/F012-test-drivers` and this task log.
    2.  **Implement Driver Dispatcher:**
        - Add a `driver` command to the `dispatch` function in `bin/devfx`.
        - The dispatcher will support passing all subsequent arguments to the target driver function (e.g., `devfx driver 3 --arg1 val1`).
    3.  **Implement Initial Drivers:**
        - Create `fx_f003_driver()` to test the package deployment system.
        - Create `fx_f004_driver()` to test the package integrity verification.
        - These initial drivers will be self-contained but will demonstrate the "happy path" of their corresponding features.
    4.  **Ensure Rewindability:** Each driver must clean up any artifacts it creates, ensuring tests are idempotent.
- **Targets:**
    - `bin/devfx` (Modify)