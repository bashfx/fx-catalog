#!/usr/bin/env bash
#
# Test driver for FEATURE-007: pkgfx - The Dedicated Package Manager
# This script is self-contained and sets up its own environment.
#

# Suppress boot messages for cleaner test output
export QUIET_BOOT_MODE=1

# --- Bootstrap & Core Includes ---
__self="${BASH_SOURCE[0]}";
SELF_PATH="$(dirname "$__self")";

# Source the master include file which brings in the whole framework
source "$SELF_PATH/../pkgs/inc/base.sh";

# Check if the framework loaded correctly
if ! is_base_ready; then
  # Cannot use 'error' function yet as stderr.sh might not be loaded.
  printf "[FAIL] Base framework did not load. Exiting.\n" >&2;
  exit 1;
fi

# Now that base is loaded, we can use fx_smart_source
fx_smart_source stderr || exit 1; # for info/okay/error
fx_smart_source paths  || exit 1; # for init_xdg, etc.
trace "[TEST] make_tmp function exists: $(function_exists make_tmp)"
fx_smart_source stdfx  || exit 1; # for make_tmp, etc.
trace "[TEST] make_tmp function exists: $(function_exists make_tmp)"

# --- Test Logic ---

fx_f007_driver() {
    info "DRIVER: Testing FEATURE-007 (pkgfx - The Dedicated Package Manager)"
    local ret=0
    local test_pkg_id="fx.testpkg"
    local pkgfx_cmd="${FX_BIN}/pkgfx"

    # --- Pre-flight Check ---
    if [ ! -x "$pkgfx_cmd" ]; then
        error "pkgfx command not found or not executable at: $pkgfx_cmd"
        return 1
    fi

    # --- Test Installation ---
    think "STEP 1: Installing test package ('$test_pkg_id')..."
    if "$pkgfx_cmd" install "$test_pkg_id" --debug --trace --silly; then
      okay "STEP 1 PASSED: Install command succeeded."
    else
      error "STEP 1 FAILED: Install command failed."
      ret=1
    fi

    error "DEBUG: Manifest content after install:"
    cat "${FX_ETC}/manifest.log" 1>&2

    # Verify installation by checking the manifest and the linked file
    think "STEP 2: Verifying test package is listed as installed..."
    local list_output
    list_output="$("$pkgfx_cmd" list --installed --debug --trace --silly)"
    error "DEBUG: Output of pkgfx list --installed: $list_output"
    if echo "$list_output" | grep -q "$test_pkg_id"; then
      okay "STEP 2 PASSED: Test package found in --installed list."
    else
      error "STEP 2 FAILED: Test package not found in --installed list."
      ret=1
    fi

    # --- Test Uninstallation ---
    think "STEP 3: Uninstalling test package ('$test_pkg_id')..."
    # Use --yes to avoid interactive prompts in a test
    if "$pkgfx_cmd" uninstall "$test_pkg_id" --yes --debug --trace --silly; then
      okay "STEP 3 PASSED: Uninstall command succeeded."
    else
      error "STEP 3 FAILED: Uninstall command failed."
      ret=1
    fi

    # Verify uninstallation
    think "STEP 4: Verifying test package is no longer listed..."
    local list_output
    list_output="$("$pkgfx_cmd" list --installed --debug --trace --silly)"
    error "DEBUG: Output of pkgfx list --installed: $list_output"
    if echo "$list_output" | grep -q "$test_pkg_id"; then
      okay "STEP 4 PASSED: Test package successfully removed from --installed list."
    else
      error "STEP 4 FAILED: Test package still found in --installed list after uninstall."
      ret=1
    fi

    # --- Result ---
    if [ $ret -eq 0 ]; then
      okay "DRIVER F007: ALL STEPS PASSED"
    else
      error "DRIVER F007: ONE OR MORE STEPS FAILED"
    fi

    return $ret
}

# --- Main Execution ---

main(){
    # This function sets up the entire test environment from scratch.

    # 1. Set up temporary XDG paths for the test run
    local test_tmp_base
    test_tmp_base=$(make_tmp)
    if [ -z "$test_tmp_base" ]; then
        error "Failed to create temporary directory for test."
        exit 1
    fi
    think "Setting up temporary test environment in $test_tmp_base..."

    export FX_APP_NAME='fx';
    export FX_BIN="$test_tmp_base/bin";
    export FX_ETC="$test_tmp_base/etc";
    export FX_LIB="$test_tmp_base/lib";
    export FX_INC="$FX_LIB/inc";
    export FX_APP="$FX_LIB/pkgs/fx";

    # 2. Create the temporary directories
    rm -rf "$test_tmp_base" # Clean up from any previous failed run
    mkdir -p "$FX_BIN" "$FX_ETC" "$FX_LIB" "$FX_INC" "$FX_APP"

    # 3. Copy the pkgfx script to the temp bin so it can be found.
    # This simulates a real installation.
    cp "$SELF_PATH/../bin/pkgfx" "$FX_BIN/pkgfx"
    chmod +x "$FX_BIN/pkgfx"

    # 4. Set the source directories for pkgfx to find packages to install
    export FXI_ROOT_DIR="$(cd "$SELF_PATH/.." && pwd)"
    export FXI_PKG_DIR="${FXI_ROOT_DIR}/pkgs"

    # 5. Run the driver
    fx_f007_driver
    local ret=$?

    # 6. Cleanup
    think "Cleaning up test environment..."
    rm -rf "$test_tmp_base"

    exit $ret
}

# --- Entry Point ---
# This makes the script executable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
