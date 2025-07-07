#!/usr/bin/env bash

#
# Test suite for setup.dev
#
# Runs a series of tests in an isolated environment to verify the
# functionality of the init, reset, and utility commands.
#
shopt -s expand_aliases
# --- Test Runner Setup ---

# Set colors for output
_green="\x1B[32m"
_red="\x1B[31m"
_gold="\x1B[38;5;220m"
_grey="\x1B[90m"
_reset="\x1B[0m"

# --- Global Setup ---
# Get the absolute path of the directory where this test script is located.
# This must be done first, before any other variables use it.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Test counters
tests_run=0
tests_passed=0
tests_failed=0

# Helper functions for reporting
_pass() {
  printf "  ${_green}✔ PASS:${_reset} %s\n" "$1"
}

_fail() {
  printf "  ${_red}✖ FAIL:${_reset} %s\n" "$1"
  # A failed assertion should immediately terminate the test with a failure code.
  exit 1
}

# --- Environment Management ---
# Sets up a clean, isolated environment for a single test.
setup_test_env() {
  # Create a unique, temporary directory for this specific test run.
  # This is the key to isolating tests from each other.
  TEST_DIR=$(mktemp -d "$SCRIPT_DIR/test-env.XXXXXX")
  # Export so teardown (running in the same subshell) can find it.
  export TEST_DIR

  # Create a fake HOME and project directory inside the temp dir
  FAKE_HOME="$TEST_DIR/home"
  PROJECT_DIR="$TEST_DIR/project"
  mkdir -p "$FAKE_HOME" "$PROJECT_DIR" || exit 1

  # Inject the test project directory path into the environment.
  # The setup.dev script will use this instead of calculating its own path.
  export FXI_ROOT_DIR="$PROJECT_DIR"

  # Copy the script to be tested into the fake project dir
  cp "$SCRIPT_DIR/setup.dev" "$PROJECT_DIR/"

  # Override HOME. In a clean environment, setup.dev will choose .bash_profile.
  export HOME="$FAKE_HOME"
  export PROFILE="$FAKE_HOME/.bash_profile" # This is what setup.dev will choose

  # The setup.dev script expects the profile to exist. Create an empty one.
  touch "$PROFILE"

  # Set the test mode flag and source the script to load its functions
  export FX_TEST_MODE=true
  # shellcheck source=/dev/null
  source "$PROJECT_DIR/setup.dev"

  # Most tests should run from the project root
  cd "$PROJECT_DIR"
}

# Tears down the test environment
teardown_test_env() {
  cd /
  # Check that TEST_DIR was set and is a directory before deleting.
  # This prevents accidental deletion of system files if the variable is unset.
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    # Make teardown fatal. If this fails, something is seriously wrong.
    rm -rf "$TEST_DIR" || { printf "${_red}FATAL: Could not remove test directory %s${_reset}\n" "$TEST_DIR"; exit 1; }
  fi
  # Unset all environment variables that were exported for the test
  unset HOME PROFILE FX_TEST_MODE FXI_ROOT_DIR FXI_SETUP_RC TEST_DIR
}

# --- Test Cases ---

test_init_creates_files() {
  printf "Running test: 'init' command creates required files...\n"
  fx_main "init"
  if [ -f ".fxsetuprc" ]; then
    _pass "Creates .fxsetuprc file"
  else
    _fail "Did not create .fxsetuprc file"
  fi
}

test_init_links_profile() {
  printf "Running test: 'init' command links profile...\n"
  fx_main "init"
  if grep -q 'source ".*/.fxsetuprc"' "$PROFILE"; then
    _pass "Adds source line to profile"
  else
    _fail "Did not add source line to profile"
  fi
}

test_init_is_idempotent() {
  printf "Running test: 'init' command is idempotent...\n"
  fx_main "init"
  fx_main "init" # Run a second time
  count=$(grep -c 'source ".*/.fxsetuprc"' "$PROFILE")
  if [ "$count" -eq 1 ]; then
    _pass "Source line is present only once"
  else
    _fail "Source line was added multiple times (count: $count)"
  fi
}

test_reset_unlinks_profile() {
  printf "Running test: 'reset' command unlinks profile...\n"
  fx_main "init"
  fx_main "reset"
  if ! grep -q 'source ".*/.fxsetuprc"' "$PROFILE"; then
    _pass "Removes source line from profile"
  else
    _fail "Did not remove source line from profile"
  fi
}

test_reset_deletes_rc_file() {
  printf "Running test: 'reset' command deletes .fxsetuprc...\n"
  fx_main "init"
  fx_main "reset"
  if [ ! -f ".fxsetuprc" ]; then
    _pass "Deletes .fxsetuprc file"
  else
    _fail "Did not delete .fxsetuprc file"
  fi
}

test_reset_is_fully_rewindable() {
  printf "Running test: 'reset' is stateless and fully rewindable...\n"
  fx_main "init"
  rm .fxsetuprc
  fx_main "reset"
  if ! grep -q 'source ".*/.fxsetuprc"' "$PROFILE"; then
    _pass "Removes source line even if .fxsetuprc is missing"
  else
    _fail "Failed to clean profile when .fxsetuprc was missing"
  fi
}

test_init_loads_env() {
  printf "Running test: 'init' loads environment into current session...\n"
  fx_main "init"
  source .fxsetuprc
  if [ -n "$FXI_ROOT_DIR" ]; then _pass "FXI_ROOT_DIR variable is set"; else _fail "FXI_ROOT_DIR variable is not set"; fi
  if alias fxdel >/dev/null 2>&1; then _pass "'fxdel' alias is set"; else _fail "'fxdel' alias is not set"; fi
}

test_canonical_profile_resolves_symlink() {
  printf "Running test: 'fx_canonical_profile' resolves symlinks...\n"
  if ! command -v realpath >/dev/null; then
    printf "  ${_gold}⚠ SKIP:${_reset} 'realpath' command not found. Cannot test symlink resolution.\n"
    return
  fi
  touch "$FAKE_HOME/my_real_profile"
  ln -s "$FAKE_HOME/my_real_profile" "$HOME/.profile"

  expected_path=$(realpath "$FAKE_HOME/my_real_profile")
  resolved_path=$(fx_canonical_profile)

  # Sanitize both strings to remove potential carriage returns (^M) which can
  # cause comparisons to fail even when strings look identical in output.
  sanitized_resolved=${resolved_path//$'\r'/}
  sanitized_expected=${expected_path//$'\r'/}

  if [ "$sanitized_resolved" = "$sanitized_expected" ]; then
    _pass "Resolves symlinked .profile correctly"
  else
    _fail "Did not resolve symlinked .profile. Expected '$sanitized_expected', got '$sanitized_resolved'"
  fi
}

# --- Main Execution ---

main() {
  # Define the list of tests to run explicitly. This guarantees order and
  # makes the test suite easier to read, manage, and debug.
  local tests_to_run=(
    test_canonical_profile_resolves_symlink
    test_init_creates_files
    test_init_links_profile
    test_init_is_idempotent
    test_init_loads_env
    test_reset_unlinks_profile
    test_reset_deletes_rc_file
    test_reset_is_fully_rewindable
  )

  # Run all defined tests
  for test_func in "${tests_to_run[@]}"; do
    ((tests_run++))
    # Run each test in a fully isolated subshell.
    # `set -e` ensures the subshell exits on the first error, preventing
    # a partially failed test from continuing.
    (
      # This trap ensures teardown runs for this subshell, even on failure.
      trap teardown_test_env EXIT
      set -e
      setup_test_env
      "$test_func"
    )
    # Check the exit code of the subshell. A non-zero status indicates a failure.
    if [ $? -eq 0 ]; then
      ((tests_passed++))
    else
      printf "  ${_grey}└─ Test failed or was aborted.${_reset}\n"
      ((tests_failed++))
    fi
    echo "" # Add a newline for readability
  done

  # Print final summary
  printf -- "----------------------------------------\n"
  printf "Test Summary:\n"
  printf "Total tests: %d\n" "$tests_run"
  printf "${_green}Passed: %d${_reset}\n" "$tests_passed"
  printf "${_red}Failed: %d${_reset}\n" "$tests_failed"
  printf -- "----------------------------------------\n"

  # Exit with a status code indicating success or failure
  if [ "$tests_failed" -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}

main "$@"
