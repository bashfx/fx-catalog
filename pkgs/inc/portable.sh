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

  _known=( sed grep awk md5 realpath readlink /
          find date column wc head tail cat  /
          tree git tput fswatch rsync

        );

  cmd_wrapper() {
    local cmd_name="$1"
    local global_var_name="$2"
    local cmd_path=""

    if command -v "$cmd_name" >/dev/null 2>&1; then
      cmd_path=$(command -v "$cmd_name")
    fi
    eval "$global_var_name=\"$cmd_path\"" # Set the global variable
  }

  check_type(){ noimp; }

  sed_test(){ noimp; }
  grep_test(){ noimp; }
  find_test(){ noimp; }

#-------------------------------------------------------------------------------
# Load Guard Error
#-------------------------------------------------------------------------------

else

  error "Library LIB_PORTABLE found at index [$_index]";
  exit 1;

fi
