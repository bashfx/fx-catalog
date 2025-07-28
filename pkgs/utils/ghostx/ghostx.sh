#!/bin/bash
#
# ghostx.sh - Conditionally defines shell tracing functions.
# To use, source this file into your shell: `source /path/to/this/file.sh`
#
# The functions will only be defined if GHOST_MODE is not set to "0".
# You can disable this utility by setting `export GHOST_MODE=0` in your .bashrc.

# Proceed only if GHOST_MODE is not explicitly set to "0".
# The `-z "${GHOST_MODE}"` check handles the case where the variable is unset.
if [ -z "${GHOST_MODE}" ] || [ "${GHOST_MODE}" != "0" ]; then

  # Store the original PS4, if it exists, so we can restore it.
  # This is only defined if the functions are being created.
  _GHOST_HUNTER_ORIGINAL_PS4="${PS4:-}"

  # --- Function to turn Ghost Mode ON ---
  ghost_mode_on() {
    export PS4='+ $(basename "${BASH_SOURCE[0]}"):$LINENO '
    set -o xtrace
    echo "👻 Ghost Mode: ON (Tracing enabled)"
  }

  # --- Function to turn Ghost Mode OFF ---
  ghost_mode_off() {
    set +o xtrace
    export PS4="${_GHOST_HUNTER_ORIGINAL_PS4}"
    echo "✅ Ghost Mode: OFF (Tracing disabled)"
  }

  # --- A simple status checker ---
  ghost_mode_status() {
    if [[ "$-" == *x* ]]; then
      echo "👻 Ghost Mode is currently ON"
      echo "   PS4 is set to: '${PS4}'"
    else
      echo "✅ Ghost Mode is currently OFF"
    fi
  }

else
  # If GHOST_MODE=0, we must ensure the functions do not exist or are removed.
  # `unset -f` removes function definitions.
  unset -f ghost_mode_on ghost_mode_off ghost_mode_status 2>/dev/null
fi
