#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

  echo "loaded base.sh" >&2;

#-------------------------------------------------------------------------------
# Mini Base Utils
#-------------------------------------------------------------------------------

  stderr(){ printf "%b\n" "$@" 1>&2; }
  
  command_exists(){ type "$1" &> /dev/null; }
  function_exists(){ [ -n "$1" ] && declare -F "$1" >/dev/null; };

  # command for testing options and flow
  # silent return if no text set
  noop(){ [ -n "$1" ] && stderr "NOOP: [$1]";  return 0; }

  #debug command for incomplete execution
  noimp(){ [ -n "$1" ] && ctx="[$1]"; stderr "NOIMP: ${FUNCNAME[1]} $ctx";  return 1; }

  #debug command for unavailable features
  nosup(){ [ -n "$1" ] && ctx="[$1]"; stderr "NOSUP: ${FUNCNAME[1]} $ctx";  return 1; }

  #debug command for todo items
  todo(){ [ -n "$1" ] && ctx="[$1]"; stderr "TODO: ${FUNCNAME[1]} $ctx";  return 1; }



#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  # INC BASE set in include.sh
  if [ -n "$__INC_BASE" ] && [ -d "$__INC_BASE" ]; then
    #incbase usually comes from the toplevel caller if so just use it
    __INC_BASE="${FX_INC_BASE_OVERRIDE:-$__INC_BASE}";

  else
    #incbase isnt found, could be text content or unintalled, we should try to use relative paths 
    #since all includes here have the same base dir as base.sh
    __INC_BASE="$(dirname "${BASH_SOURCE[0]}")"

  fi


  source "${__INC_BASE}/portable.sh";
  source "${__INC_BASE}/stdfx.sh";
  source "${__INC_BASE}/stdutils.sh";
  source "${__INC_BASE}/stderr.sh";





