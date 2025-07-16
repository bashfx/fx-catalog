#!/usr/bin/env bash
#===============================================================================
#$ name: gnuopt.sh
#$ author: Gemini & Qodeninja
#$ semver: 0.5.0
#-------------------------------------------------------------------------------
#$ desc: A POC for a bitmask-powered, declarative options system.
#=====================================code!=====================================

# --- 1. Bitmask Definitions (would live in flags.sh) ---

# Core Flags (for the global orchestrator)
FLAG_CORE_HELP=1
FLAG_CORE_DEBUG=2

# Knife Namespace Flags
FLAG_KNIFE_ALL=1
FLAG_KNIFE_FORCE=2

# --- 2. Global State Variables (would be in stdopts.sh) ---

# Per-namespace bitmaps to hold state
opt_core_flags=0
opt_knife_flags=0

# Global reservation registry
_FX_RESERVED_SHORT_OPTS=""
_FX_RESERVED_LONG_OPTS=""

# --- 3. Bitmask Helpers (from flags.sh) ---

flag_enable() { eval "$1=$((${!1}|${2}))"; }
flag_on() { [[ $((${!1}&${2})) -ne 0 ]]; }

# --- 4. The Gatekeeper Function (The Brains) ---

fx_define_option() {
  local descriptor="$1" value="$2" OLD_IFS="$IFS"
  IFS=':'
  local parts=($descriptor)
  IFS="$OLD_IFS"

  local ns="${parts[2]}" short="${parts[3]}" long="${parts[4]}" type="${parts[5]}"

  # Collision Check (abbreviated for POC)
  if [[ -n "$long" && ":${_FX_RESERVED_LONG_OPTS}:" == *":$long:"* ]]; then
    fatal "Option --$long is already reserved."
    return 1
  fi
  [[ -n "$long" ]] && _FX_RESERVED_LONG_OPTS+=":$long:"

  # Determine the target bitmap and flag constant
  local bitmap_var="opt_${ns}_flags"
  local flag_const="FLAG_${ns^^}_${long^^}"

  case "$type" in
    boolean)
      # For booleans, we enable a bit in the namespace's bitmap.
      flag_enable "$bitmap_var" "${!flag_const}"
      info "[GATEKEEPER] Bit '$long' enabled in '$bitmap_var'"
      ;;
    string|path)
      # For string values, we still create a dedicated variable.
      local var_name="opt_${ns}_${long}"
      declare -g "$var_name=$value"
      info "[GATEKEEPER] Option Set: ${var_name}=${value}"
      ;;
  esac
}

# --- 5. The Logic Guard Example (The Payoff) ---

flag_guard_example() {
  info "\n--- Running Logic Guard Example ---"

  # Instead of checking a variable like `opt_knife_force`, we use the helper.
  # This is clean, readable, and abstracts away the bitwise logic.
  if flag_on "opt_knife_flags" "$FLAG_KNIFE_FORCE"; then
    okay "Guard PASSED: Knife force mode is enabled."
  else
    warn "Guard FAILED: Knife force mode is not enabled."
  fi

  if flag_on "opt_core_flags" "$FLAG_CORE_DEBUG"; then
    okay "Guard PASSED: Core debug mode is enabled."
  else
    warn "Guard FAILED: Core debug mode is not enabled."
  fi
}

# --- 6. The Orchestrator (The Final Implementation) ---

fx_orchestrator_example() {
  info "[ORCHESTRATOR] Starting option parsing..."

  # 1. Use getopt to normalize arguments.
  local parsed_opts
  parsed_opts=$(getopt -o hda: -l "help,debug,all,force,mode:" -n "example" -- "$@")
  if [[ $? -ne 0 ]]; then return 1; fi
  eval set -- "$parsed_opts"

  # 2. Process all arguments with a single, portable case statement.
  while true; do
    case "$1" in
      -h|--help)  fx_define_option "opt::core:h:help:boolean" ; shift ;;
      -d|--debug)  fx_define_option "opt::core:d:debug:boolean" ; shift ;;
      -a|--all)    fx_define_option "opt::knife:a:all:boolean" ; shift ;;
      --force)    fx_define_option "opt::knife::force:boolean" ; shift ;;
      --mode)     fx_define_option "opt::knife:m:mode:string" "$2"; shift 2 ;;
      --)
        shift
        break
        ;;
      *)
        fatal "Unhandled argument: $1"
        break
        ;;
    esac
  done

  okay "[ORCHESTRATOR] Options parsed successfully."
  info "Core Flags Bitmap: $opt_core_flags"
  info "Knife Flags Bitmap: $opt_knife_flags"

  # 3. Run the example logic guards.
  flag_guard_example

  return 0
}
