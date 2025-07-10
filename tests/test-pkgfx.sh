#!/usr/bin/env bash
#
# Test driver for FEATURE-007: pkgfx - The Dedicated Package Manager
#

fx_f007_driver() {
    info "DRIVER: Testing FEATURE-007 (pkgfx - The Dedicated Package Manager)"
    local ret=0
    local test_pkg_id="fx.testpkg"
    local test_pkg_name="testpkg"
    local test_pkg_lib_path="${FX_LIB}/fx/${test_pkg_name}"
    local test_pkg_bin_link="${FX_BIN}/${test_pkg_name}"

    # Ensure pkgfx is executable
    if [ ! -x "${FX_BIN}/pkgfx" ]; then
        error "pkgfx is not executable. Cannot run tests."
        return 1
    fi

    # --- Cleanup from previous runs ---
    info "Cleaning up any previous testpkg installations..."
    "${FX_BIN}/pkgfx" uninstall "${test_pkg_id}" >/dev/null 2>&1
    rm -rf "${test_pkg_lib_path}" >/dev/null 2>&1
    rm -f "${test_pkg_bin_link}" >/dev/null 2>&1

    # --- Test Installation ---
    info "Testing 'pkgfx install ${test_pkg_id}'..."
    if "${FX_BIN}/pkgfx" install "${test_pkg_id}"; then
        okay "Installation of ${test_pkg_id} succeeded."
    else
        error "Installation of ${test_pkg_id} failed."
        ret=1
    fi

    # Verify installation
    if [ -d "${test_pkg_lib_path}" ] && [ -L "${test_pkg_bin_link}" ]; then
        okay "${test_pkg_id} files and symlink found."
    else
        error "${test_pkg_id} files or symlink missing after install."
        ret=1
    fi

    # --- Test Listing ---
    info "Testing 'pkgfx list'..."
    if "${FX_BIN}/pkgfx" list | grep -q "${test_pkg_id}"; then
        okay "${test_pkg_id} found in pkgfx list output."
    else
        error "${test_pkg_id} not found in pkgfx list output."
        ret=1
    fi

    # --- Test Verification ---
    info "Testing 'pkgfx verify ${test_pkg_id}'..."
    if "${FX_BIN}/pkgfx" verify "${test_pkg_id}"; then
        okay "Verification of ${test_pkg_id} succeeded (placeholder)."
    else
        error "Verification of ${test_pkg_id} failed (placeholder)."
        ret=1
    fi

    # --- Test Uninstallation ---
    info "Testing 'pkgfx uninstall ${test_pkg_id}'..."
    if "${FX_BIN}/pkgfx" uninstall "${test_pkg_id}"; then
        okay "Uninstallation of ${test_pkg_id} succeeded."
    else
        error "Uninstallation of ${test_pkg_id} failed."
        ret=1
    fi

    # Verify uninstallation
    if [ ! -d "${test_pkg_lib_path}" ] && [ ! -L "${test_pkg_bin_link}" ]; then
        okay "${test_pkg_id} files and symlink removed after uninstall."
    else
        error "${test_pkg_id} files or symlink still present after uninstall."
        ret=1
    fi

    if [ $ret -eq 0 ]; then
        okay "DRIVER F007: PASSED"
    else
        error "DRIVER F007: FAILED"
    fi

    return $ret
}