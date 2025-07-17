#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

  readonly LIB_PORTABLE="${BASH_SOURCE[0]}";
  _index=

#-------------------------------------------------------------------------------
# Load Guard
#-------------------------------------------------------------------------------

if ! _index=$(is_lib_registered "LIB_PORTABLE"); then 

  register_lib LIB_PORTABLE;

#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  readonly BASH_MAJOR=${BASH_VERSINFO[0]};

  # ? basename file type which printf? read dirname cp mv chmod compgen unset unalias
  # sleep kill declare

  _known=( sed grep awk md5 realpath readlink
          find date column wc head tail cat  
          tree git tput fswatch rsync sort tr

         );

  cmd_wrapper() {
    local T_name="$1"
    local T_global="$2"
    local T_path=""

    if command -v "$T_name" >/dev/null 2>&1; then
      T_path=$(command -v "$T_name")
    fi
    eval "$T_global=\"$T_path\"" # Set the global variable
  }

  depends_on(){
    noimp;
  }

  check_type(){ noimp; }

  sed_test(){ noimp; }
  grep_test(){ noimp; }
  find_test(){ noimp; }

#-------------------------------------------------------------------------------
# Load Guard Error
#-------------------------------------------------------------------------------

else
  dump_libs;
  error "Library LIB_PORTABLE already loaded [$_index]";
  exit 1;

fi
