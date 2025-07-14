#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

  echo "loaded stdutils.sh" >&2;

#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  #command for testing options and setup
  noop(){ 
    [ -n "$1" ] && trace "Noop: [$1]";
    return 0; 
  }

  #update to take prefix as a paramter isntead of do_
  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^#)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")
    __printf "$LINE\n"
    while IFS= read -r row; do
      info "$row"
    done <<< "$_content"
  }

  function_exists(){
    [ -n "$1" ] && declare -F "$1" >/dev/null
  }


  is_empty_file(){
    local this=$1;
    trace "Checking for empty file ($this)";
    if [[ -s "$this" ]]; then
      if grep -q '[^[:space:]]' "$this"; then
        return 1;
      else
        return 0;
      fi
    fi
    return 0;
  }

  has_subdirs(){
    local dir="$1"
    for d in "$dir"/*; do
      [ -d "$d" ] && return 0
    done
    return 1
  }




# =================== startup flag =================================
[ -n "$DEBUG_MODE" ] && echo "[INC] stdutils.sh added $(func_stats) functions" >&2;
