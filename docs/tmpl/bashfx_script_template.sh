#!/usr/bin/env bash
#===============================================================================
# <+ (Your ASCII art / Logo Hack goes here) +>
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: new_script_template
#$ desc: A boilerplate for creating new BashFX-compliant 'Proper Scripts'.
#$ author: YourName
#$ semver: 0.1.0
#$ alias: new_script
#-------------------------------------------------------------------------------
#=====================================code!=====================================


# --- Standalone Bootstrap ---
# This script requires the 'incx' utility (a core BashFX binary) to be in the
# user's $PATH to locate and load the BashFX environment.
__bootstrap_fx_environment() {
    local include_path

    # Check if the incx command exists.
    if ! command -v incx >/dev/null 2>&1; then
        echo "FATAL: The 'incx' utility was not found in your PATH." >&2
        echo "Please ensure the BashFX bin directory is in your PATH." >&2
        exit 1
    fi

    # Execute incx to get the path to the core include file.
    include_path=$(incx --core) # Assuming 'incx --core' returns the path to include.sh
    if [ -n "$include_path" ] && [ -f "$include_path" ]; then
        source "$include_path"
    else
        echo "FATAL: 'incx' failed to locate the BashFX core library." >&2
        exit 1
    fi
}

# Only run the bootstrap if the FX_LIB variable is not already set.
# This prevents re-sourcing in an already active BashFX shell.
[ -z "$FX_LIB" ] && __bootstrap_fx_environment

# --- Thisness Context & Namespace ---
# Every script must define its own context. This allows it to use generic
# library functions and informs the framework where it belongs.

__this_context() {
  think "Setting script context..."
  
  # DEVELOPER: Replace these placeholder values for your script.
  #-------------------------------------------------------------
  THIS_NAME="<MyScriptName>"     # The proper name of the script.
  THIS_ALIAS="<myscript>"      # The command-line alias used for linking.
  THIS_RC_NAME="${THIS_ALIAS}.rc"  # The name of its state/rc file.
  
  # DEVELOPER: Choose the script's namespace. Uncomment ONE block.
  # This determines the installation path: ~/.local/lib/fx/[namespace]/
  #-----------------------------------------------------------------
  # Option 1: A core framework component.
  # THIS_NAMESPACE="core"
  
  # Option 2: A reusable utility.
  # THIS_NAMESPACE="utils"
  
  # Option 3: A standalone application (default).
  THIS_NAMESPACE="$THIS_ALIAS"
  
  # --- Standard path definitions based on the chosen namespace ---
  THIS_LIB_DIR="${FX_LIB}/fx/${THIS_NAMESPACE}"
  THIS_ETC_DIR="${FX_ETC}/fx/${THIS_NAMESPACE}"
  THIS_RC_FILE="${THIS_ETC_DIR}/${THIS_RC_NAME}"
}
__this_context # Set the context immediately


# --- Standard Library Includes ---
# Now that the environment is bootstrapped, fx_smart_source is available.
fx_smart_source paths       # For path manipulation helpers.
fx_smart_source proflink    # For linking/unlinking from shell profiles.
fx_smart_source rcfile      # For managing state via .rc files.

#===============================================================================
# --- STANDARD BASHFX SKELETON ---
#===============================================================================
# Every "Proper Script" should implement this standard interface.

# @lbl options
options(){
  think "options()"
  local this next opts=("${@}")

  # Initialize standard flags to their 'off' state (1 = false)
  opt_debug=1; opt_trace=1; opt_quiet=1; opt_force=1; opt_yes=1; opt_dev=1;

  for ((i=0; i<${#opts[@]}; i++)); do
    this=${opts[i]}
    case "$this" in
      # DEVELOPER: Add script-specific flags here.
      --force|-f) opt_force=0 ;;
      
      # Standard debugging and verbosity flags
      -d|--debug)   opt_debug=0 ;;
      -t|--trace)   opt_trace=0; opt_debug=0 ;;
      -q|--quiet)   opt_quiet=0 ;;
      -y|--yes)     opt_yes=0 ;;
      -D|--dev)     opt_dev=0; opt_trace=0; opt_debug=0 ;;
      -h|--help)    usage; exit 0 ;;
      -*)           error "Invalid flag: $this"; return 1 ;;
    esac
  done
  return 0
}


#===============================================================================
# >>> SCRIPT-SPECIFIC LOGIC GOES HERE <<<
#===============================================================================
# All functions specific to this script's purpose are defined in this section.
# Use `do_*` for functions called by the dispatcher.

do_example_command() {
  local arg1="$1"
  info "Executing the example command with argument: $arg1"
  [ "$opt_force" -eq 0 ] && warn "Force flag is enabled!"
  okay "Example command finished successfully."
  return 0
}


#===============================================================================
# --- CORE EXECUTION & USAGE ---
#===============================================================================

# @lbl dispatch
dispatch(){
  think "dispatch()"
  local cmd="$1"
  shift # The rest of $@ are now arguments for the subcommand.
  
  case "$cmd" in
    example)
      do_example_command "$@"
      return $? ;;
      
    # DEVELOPER: Add other command mappings here.
    
    "") # No command was given
      usage >&2
      return 1 ;;
    *)
      error "Unknown command: '$cmd'"
      usage >&2
      return 1 ;;
  esac
}


# @lbl main
main(){
  think "main()"
  options "${orig_args[@]}" || exit 1
  
  local args=()
  for arg in "${orig_args[@]}"; do
    [[ "$arg" == -* ]] && continue
    args+=("$arg")
  done
  
  # If no positional args are given after filtering flags, show usage.
  [ ${#args[@]} -eq 0 ] && { usage; exit 0; }
  
  dispatch "${args[@]}"
  return $?
}


# @lbl usage
usage(){
  # This function prints the usage/help text.
  # For now, we use a simple heredoc. This should be manually updated
  # to use the 'Comment Hack' pattern with sed/awk once the documentation
  # block is written at the end of the file.
  cat << EOF >&2
Usage: $THIS_ALIAS <command> [options]
  
  A brief description of what this script does.
  
Commands:
  example   - A simple example command.

Options:
  -f, --force - Force an action.
  -h, --help  - Show this help text.
EOF
}

#===============================================================================
# --- MAIN EXECUTION ---
#===============================================================================
# This block ensures the script runs when executed, but not when sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  orig_args=("${@}")
  main "${orig_args[@]}"
  exit $?
fi

#===============================================================================
# --- EMBEDDED DOCUMENTATION (COMMENT HACKS) ---
#===============================================================================
#
# <+ To enable embedded docs, create a block like the one below +>
# <+ and update the `usage()` function to parse it with sed/awk. +>
#
# #### usage ####
#
#  (Your detailed, formatted help text goes here)
#
# #### /usage ####

