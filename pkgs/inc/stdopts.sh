#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------
  
  # __debug_mode(){ [ -z "$opt_debug" ] && return 1; [ $opt_debug -eq 0 ] && return 0 || return 1; }
  # __quiet_mode(){ [ -z "$opt_quiet" ] && return 1; [ $opt_quiet -eq 0 ] && return 0 || return 1; }
  opt_silly=${opt_silly:-1};
  opt_trace=${opt_trace:-1};
  opt_debug=${opt_debug:-1};
  opt_yes=${opt_yes:-1};



#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------

# @lbl options

  global_options(){

  }

  local_options(){
    # Using local ensures these variables don't leak into the global scope.
    local err

    #these can be overwritten
    opt_debug=${opt_debug:-1};
    opt_quiet=${opt_quiet:-1};
    opt_trace=${opt_trace:-1};
    opt_silly=${opt_silly:-1};
    opt_yes=${opt_yes:-1};
    opt_dev=${opt_dev:-1};
    opt_flags=${opt_flags:-1};

    # Process arguments in a single loop for clarity and efficiency.
    for arg in "$@"; do
      case "$arg" in
        --yes|-y)           opt_yes=0;;
        --flag*|-f)         opt_flags=0;;
        --debug|-d)         opt_debug=0;;
        --tra*|-t)          opt_trace=0;;
        --sil*|--verb*|-V)  opt_silly=0;;
        --dev|-D)           opt_dev=0;;
        --quiet|-q)         opt_quiet=0;;
        -*)                 err="Invalid flag [$arg].";; # Capture unknown flags
      esac
    done



    # Apply hierarchical verbosity rules.
    # Higher levels of verbosity enable lower levels.
    [ "$opt_silly" -eq 0 ] && { opt_trace=0; opt_debug=0; }
    [ "$opt_trace" -eq 0 ] && { opt_debug=0; }
    [ "$opt_dev" -eq 0 ]   && { opt_debug=0; opt_flags=0; }

    # Final override: if quiet is on, it trumps all other verbosity.
    if [ "$opt_quiet" -eq 0 ]; then
      opt_debug=1; opt_trace=1; opt_silly=1;
    else
      warn "Quiet is $opt_quiet";
    fi

    #set any options errors

  }


  options(){
    global_options;
    local_options;
  }

# =================== startup flag =================================
#[ -n "$DEBUG_MODE" ] && echo "[INC] stdopts.sh added $(func_stats) functions" >&2;
