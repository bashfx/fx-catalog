- **Label:** FEATURE-013: Architectural Refactoring & Integration
- **Objective:** Complete the surgical refactoring of `devfx` to use the new, modular libraries for package management.
- **Strategy:**
    1.  **Refactor `devfx`'s `setup` function:** Overhaul the main `setup` function in `bin/devfx`, replacing the outdated logic with a new orchestration function.
    2.  **Create `fx_install_system` in `devfx`:** This new function will become the heart of the setup process and will execute these steps in order:
        - **Deploy:** Call a new `fx_deploy_all_packages` function to clear the manifest and deploy all core packages (`inc`, `utils`, `fx`).
        - **Verify:** Call `fx_integrity_verify_all()` from `integrity.sh`.
        - **Link:** Call `fx_pkglinker_link_all()` from `pkglinker.sh`.
        - **Finalize:** Perform the final steps of promoting `devfx` to `fx` and cleaning up the temporary installation environment.
    3.  **Clean up `package.sh`:** Remove the deployment-specific logic (`do_deploy_pkgs`) from `pkgs/inc/package.sh`, as its role will be handled directly by `devfx`.
- **Targets:**
    - `bin/devfx` (Modify)
    - `pkgs/inc/package.sh` (Modify)