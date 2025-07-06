#!/usr/bin/env bash

#
# Test suite for setup.dev
#
# Runs a series of tests in an isolated environment to verify the
# functionality of the init, reset, and utility commands.
#

# --- Test Runner Setup ---

# Set colors for output
_green="\x1B[32m"
_red="\x1B[31m"
_reset="\x1B[0m"

# Test counters
tests_run=0
tests_passed=0
tests_failed=0

# Helper functions for reporting
_pass() {
  printf "  ${_green}✔ PASS:${_reset} %s\n" "$1"
  ((tests_passed++))
}

_fail() {
  printf "  ${_red}✖ FAIL:${_reset} %s\n" "$1"
  ((tests_failed++))
}

# --- Environment Management ---

# Sets up a clean, isolated environment for a single test.
setup_test_env() {
  # Create a temporary directory for the test run
  TEST_DIR=$(mktemp -d)

  # Create a fake HOME and project directory inside the temp dir
  FAKE_HOME="$TEST_DIR/home"
  PROJECT_DIR="$TEST_DIR/project"
  mkdir -p "$FAKE_HOME" "$PROJECT_DIR"

  # Copy the script to be tested into the fake project dir
  cp ./setup.dev "$PROJECT_DIR/"

  # Override HOME and PROFILE to point to our fake directory
  export HOME="$FAKE_HOME"
  export PROFILE="$FAKE_HOME/.profile" # Be explicit for clarity

  # Set the test mode flag and source the script to load its functions
  export FX_TEST_MODE=true
  # shellcheck source=/dev/null
  source "$PROJECT_DIR/setup.dev"

  # Move into the project directory to run the test
  cd "$PROJECT_DIR" || exit 1
}

# Tears down the test environment
teardown_test_env() {
  cd / >/dev/null # Move out of the temp dir before deleting it
  rm -rf "$TEST_DIR"
  unset HOME PROFILE FX_TEST_MODE
  # Unset all functions to prevent contamination between tests
  declare -F | awk '/^declare -f fx_/ {print $3}' | while read -r f; do unset -f "$f"; done
}

# --- Test Cases ---

test_init_creates_files() {
  ((tests_run++)); printf "Running test: 'init' command creates required files...\n"
  setup_test_env
  fx_main "init" >/dev/null
  [ -f "$PROFILE" ] && _pass "Creates profile file" || _fail "Did not create profile file"
  [ -f ".fxsetuprc" ] && _pass "Creates .fxsetuprc file" || _fail "Did not create .fxsetuprc file"
  teardown_test_env
}

test_init_links_profile() {
  ((tests_run++)); printf "Running test: 'init' command links profile...\n"
  setup_test_env
  fx_main "init" >/dev/null
  grep -q 'source ".*/.fxsetuprc"' "$PROFILE" && _pass "Adds source line to profile" || _fail "Did not add source line to profile"
  teardown_test_env
}

test_init_is_idempotent() {
  ((tests_run++)); printf "Running test: 'init' command is idempotent...\n"
  setup_test_env
  fx_main "init" >/dev/null
  fx_main "init" >/dev/null # Run a second time
  count=$(grep -c 'source ".*/.fxsetuprc"' "$PROFILE")
  [ "$count" -eq 1 ] && _pass "Source line is present only once" || _fail "Source line was added multiple times (count: $count)"
  teardown_test_env
}

test_reset_unlinks_profile() {
  ((tests_run++)); printf "Running test: 'reset' command unlinks profile...\n"
  setup_test_env
  fx_main "init" >/dev/null
  fx_main "reset" >/dev/null
  ! grep -q 'source ".*/.fxsetuprc"' "$PROFILE" && _pass "Removes source line from profile" || _fail "Did not remove source line from profile"
  teardown_test_env
}

test_reset_deletes_rc_file() {
  ((tests_run++)); printf "Running test: 'reset' command deletes .fxsetuprc...\n"
  setup_test_env
  fx_main "init" >/dev/null
  fx_main "reset" >/dev/null
  [ ! -f ".fxsetuprc" ] && _pass "Deletes .fxsetuprc file" || _fail "Did not delete .fxsetuprc file"
  teardown_test_env
}

test_reset_is_fully_rewindable() {
  ((tests_run++)); printf "Running test: 'reset' is stateless and fully rewindable...\n"
  setup_test_env
  fx_main "init" >/dev/null
  # Manually break the setup by deleting the rc file before resetting
  rm .fxsetuprc
  fx_main "reset" >/dev/null
  ! grep -q 'source ".*/.fxsetuprc"' "$PROFILE" && _pass "Removes source line even if .fxsetuprc is missing" || _fail "Failed to clean profile when .fxsetuprc was missing"
  teardown_test_env
}

test_init_loads_env() {
  ((tests_run++)); printf "Running test: 'init' loads environment into current session...\n"
  setup_test_env
  fx_main "init" >/dev/null
  # Check for a variable and an alias that should be defined by sourcing .fxsetuprc
  [ -n "$FXI_ROOT_DIR" ] && _pass "FXI_ROOT_DIR variable is set" || _fail "FXI_ROOT_DIR variable is not set"
  alias fxdel >/dev/null 2>&1 && _pass "'fxdel' alias is set" || _fail "'fxdel' alias is not set"
  teardown_test_env
}


# --- Main Execution ---

main() {
  # Run all functions in this script that start with "test_"
  for test_func in $(declare -F | awk '/^declare -f test_/ {print $3}'); do
    "$test_func"
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

main
