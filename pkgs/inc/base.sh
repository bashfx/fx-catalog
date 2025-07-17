#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

  if [ -n "$__INC_BASE" ]; then
    error "[BASE] Fatal reference, do not include base.sh more than once";
    exit 1;
  fi

  readonly LIB_BASE="${BASH_SOURCE[0]}";

  FX_HOOKS=();
  FX_LIBS=();
  FX_LIB_FILES=();

#-------------------------------------------------------------------------------
# Basic Stderr Helpers overridden later by stderr.sh
#-------------------------------------------------------------------------------



  red=$'\x1B[31m';
  orange=$'\x1B[38;5;214m';
  green=$'\x1B[32m';
  blue=$'\x1B[36m';
  xx=$'\x1B[0m';     # Alias for reset

  # note: these mini stderr functions dont respect quiet or verbose flags
  # you will need global level QUIET_MODE to shut these ones up
  stderr(){ [ -z "$QUIET_MODE" ] &&  printf "%b\n" "$@" 1>&2; }
  fatal(){ stderr "${red}" "$1" "${xx}"; exit 1; }
  error(){ stderr "${red}" "$1" "${xx}"; }
  warn(){ stderr "${orange}" "$1" "${xx}"; }
  okay(){ stderr "${green}" "$1" "${xx}"; }
  info(){ stderr "${blue}" "$1" "${xx}"; }


#-------------------------------------------------------------------------------
# Base Utils
#-------------------------------------------------------------------------------
  
  command_exists(){ type "$1" &> /dev/null; }
  function_exists(){ [ -n "$1" ] && declare -F "$1" >/dev/null; };

  in_array() {
    local this="$1" item; shift;
    for item in "$@"; do
      [[ "$item" == "$this" ]] && return 0;
    done
    return 1;
  }


  index_of(){
    local this=$1 args i=-1 j list; shift; 
    list=("${@}");
    for ((j=0;j<${#list[@]};j++)); do
      [ "${list[$j]}" = "$this" ] && { i=$j; break; }
    done;
    echo $i;
    [[ "$i" == "-1" ]] && return 1 || return 0
  }

  # command for testing options and flow
  # silent return if no text set
  noop(){ [ -n "$1" ] && info "NOOP: [$1]";  return 0; }

  #debug command for incomplete execution
  noimp(){ [ -n "$1" ] && ctx="[$1]"; warn "NOIMP: ${FUNCNAME[1]} $ctx";  return 1; }

  #debug command for unavailable features
  nosup(){ [ -n "$1" ] && ctx="[$1]"; warn "NOSUP: ${FUNCNAME[1]} $ctx";  return 1; }

  #debug command for todo items
  todo(){ [ -n "$1" ] && ctx="[$1]"; warn "TODO: ${FUNCNAME[1]} $ctx";  return 1; }

#-------------------------------------------------------------------------------
# Hook Helpers
#-------------------------------------------------------------------------------

  # todo
  register_hook(){
    noimp;
  }

  # generalized from stdopts
  run_hook(){
    local lable="$1" pattern="$2" hook_funcs;
    shift; shift;
    
    # Find all functions matching the pattern, then sort them.
    # The `sed` command extracts just the function name.
    hook_funcs=$(declare -F | sed -n "s/^declare -f //p" | grep "${pattern}$" | sort)
    for func in $hook_funcs; do
      if function_exists "$func"; then
        trace "[HOOK] Running ${pattern} hook: $func"
        "$func" "$@" # Pass along the original script arguments
      fi
    done
  }


  _main(){
    # _fx_run_hook "_pre_main" "$@";
    noimp;
  }

#-------------------------------------------------------------------------------
# Library Helpers
#-------------------------------------------------------------------------------

  register_lib(){
    local i file name=$1 path;

    [ -z "$name" ] &&  error "[LIB] No library variable name provided for registration." &&  exit 1;

    # derefencing can be problematic, but fine for now
    path=${!name};


    if [ -e $path ]; then

      if i=$(is_lib_registered $name); then 
        file=$(basename "$path");
        info "[LIB] Registered  [$name] [${file}]";
        FX_LIBS+="$name";
        FX_LIB_FILES+="$file";
      else
        fatal "[LIB] Fatal Circular Reference. [$name] already registered. Exiting.";
      fi

    fi
  }

  is_lib_registered(){
    index_of "$1" "${FX_LIBS[@]}";
  }

#-------------------------------------------------------------------------------
# Micro Lib Utilities
#-------------------------------------------------------------------------------

  ls_funcs(){
    local this_file="$1";
    grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{' "$this_file" \
      | grep -vE '^[[:space:]]*(#|source|\.)' \
      | sort -u;
  }


  func_stats(){
    local this_file="$1";
    ls_funcs "$this_file" | wc -l;
  }


#-------------------------------------------------------------------------------
# Library Bootstrap
#-------------------------------------------------------------------------------

  # When Base loads, it needs to check for FX
  if [ -d "$FX_INC_DIR" ]; then
    __INC="$FX_INC_DIR";
  else
    # fallback on the neighborly version
    __INC="$(dirname $LIB_BASE)";
  fi


  if [ -n "$__INC" ] && [ -d "$__INC" ]; then
    #incbase usually comes from the toplevel caller if so just use it
    readonly __INC_BASE="$__INC";
    unset __INC;
    info "Runtime include path set to [$_INC_BASE]";
  else
    fatal "[BASE] Nope."; # pretty fatal dont even try
  fi

  register_lib LIB_BASE;

  # only include enough to get library access
  # let scripts pick what they need
  source "${__INC_BASE}/portable.sh";
  source "${__INC_BASE}/include.sh";

  #source "${__INC_BASE}/stdfx.sh";
  #source "${__INC_BASE}/stdutils.sh";
  #source "${__INC_BASE}/stderr.sh";





  # func_stack(){
  #   echo "--- Call Stack ---" >&2;
  #   for i in "${!BASH_SOURCE[@]}"; do
  #     printf "  [%d] %s (in function: %s)\n" "$i" "${BASH_SOURCE[$i]}" "${FUNCNAME[$i]:-main}" >&2;
  #   done
  #   echo "--- Functions in this file (${BASH_SOURCE[0]}) ---" >&2;
  # }
