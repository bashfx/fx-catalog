#!/usr/bin/env bash
#===============================================================================
  
  # rc are configuration files that create state via variables and
  # define paths required loading and execution. its essentially the glue
  # includes only work if the base and include path are defined by an 
  # available rc file, either the init (source) one or the user (installed) one.

#-------------------------------------------------------------------------------

  # note: vars like > this ret res err, are common patterns

  # note: Since stderr.sh's print and log utilities are low level fundamental
  #       and used by everything, we will include it here automatically
  #       so that any script loading include.sh will get it by default.
  #       If a script doesnt need include.sh it will have to source stderr.sj
  #       directly.
  #       

#-------------------------------------------------------------------------------

  echo "loaded include.sh" >&2;

#-------------------------------------------------------------------------------
# Basic Stderr Helpers overridden later by stderr.sh
#-------------------------------------------------------------------------------


  BASH_MAJOR=${BASH_VERSINFO[0]};


  red=$'\x1B[31m';
  orange=$'\x1B[38;5;214m';
  green=$'\x1B[32m';
  blue=$'\x1B[36m';
  xx=$'\x1B[0m';     # Alias for reset

  # note: these mini stderr functions dont respect quiet or verbose flags
  # you will need global level QUIET_MODE to shut these ones up
  stderr(){ [ -z "$QUIET_MODE" ] &&  printf "%b\n" "$@" 1>&2; }
  error(){ stderr "${red}" "$1" "${xx}"; }
  warn(){ stderr "${orange}" "$1" "${xx}"; }
  okay(){ stderr "${green}" "$1" "${xx}"; }
  info(){ stderr "${blue}" "$1" "${xx}"; }


#-------------------------------------------------------------------------------
# Experiments
#-------------------------------------------------------------------------------


  func_stats(){
    local this_file="${BASH_SOURCE[0]}"
    grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{' "$this_file" \
      | grep -vE '^[[:space:]]*(#|source|\.)' \
      | wc -l
  }


  # returns any available include directory - prioritizes user over init
  fx_smart_inc(){
    local res;
    [ ! -n "$FX_INC_DIR" ] && [ ! -n "$FXI_INC_DIR" ] && {
      error "[INC] cannot find a path for fxinc directory.";
      return 1;
    }
    if [ -n "$FX_INC_DIR" ] && [ -d "$FX_INC_DIR" ]; then
      res=$FX_INC_DIR; #installed with xdg paths
    elif [ -n "$FXI_INC_DIR" ] && [ -d "$FXI_INC_DIR" ]; then
      res=$FXI_INC_DIR;
    else
      error "[INC] cannot locate an fxinc directory.";
      return 1;
    fi
    echo "$res";
    return 0;
  }



  # returns any available rc file - prioritizes user over init
  fx_smart_rc(){
    local res;

    [ ! -n "$FX_RC" ] && [ ! -n "$FXI_RC" ] &&  {
      error "[INC] cannot find a path for fxrc file.";
      return 1;
    }

    if [ -n "$FX_RC" ] && [ -f "$FX_RC" ]; then
      res="$FX_RC";
    elif [ -n "$FXI_RC" ] && [ -f "$FXI_RC" ]; then
      res="$FXI_RC";
    else
      error "[INC] cannot locate an fxrc file.";
      return 1;
    fi

    echo "$res";
    return 0;
  }




  # attempts to load a known inc location
  fx_smart_source() {
    local lib="$1" ret inc rc lib_path inc_path;

    if [ -z "$lib" ]; then
      error "[INC] smart_source: No lib name provided."
      return 1
    fi

    inc_path=$(fx_smart_inc); ret=$?;

    if [ -n "$inc_path" ] && [ -d "$inc_path" ]; then
      lib_path="$inc_path/$lib.sh";
      if [ -f "$lib_path" ]; then
        source "$lib_path" && {
          okay "Sourced '$lib' from: ($lib_path)";
          return 0
        }
        error "[INC] source failed to load the '$lib' package at: ($lib_path)."
      else
        error "[INC] Library '$lib' not found at: ($lib_path)";
      fi
    fi  

    return 1;
  }

# =================== startup flag =================================
# [ -n "$DEBUG_MODE" ] && echo "[INC] include.sh added $(func_stats) functions" >&2;


  # try to load stderr from user installed path
  if [ -d "$FX_INC_DIR" ]; then
    source "$FX_INC_DIR/stderr.sh";
  else
    # fallback on the neighborly version
    LOCAL_LIB_DIR="$(dirname ${BASH_SOURCE[0]})";
    source "${LOCAL_LIB_DIR}/stderr.sh";
  fi

  if ! declare -F stderr > /dev/null; then
    echo "[INC] Error loading stderr.sh dependency";
    exit 1;
  fi
