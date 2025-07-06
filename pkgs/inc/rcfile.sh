#!/usr/bin/env bash
#===============================================================================
#-----------------------------><-----------------------------#
#$ name:templating
#$ author:qodeninja
#$ desc:
#-----------------------------><-----------------------------#
#=====================================code!=====================================

  echo "loaded rcfile.sh";

  # LOCAL_LIB_DIR="$(dirname ${BASH_SOURCE[0]})";
  # source "${LOCAL_LIB_DIR}/stderr.sh";


#-------------------------------------------------------------------------------
# Universal Link Functions
#-------------------------------------------------------------------------------

  get_next_rc(){
    local next=${!THIS_RC_VAR};
    if [ -n "$next" ]; then
      echo "$next";
      return 0;
    fi
    return 1;
  }


	save_rc_file(){
    local rc ret src=$1 dest=$2 lbl=$3; #src has embedded doc
    res="$(get_embedded_doc $src $lbl)";ret=$?;
    if [ $ret -eq 0 ]; then
      echo "$res" > ${dest};
      if is_empty_file "$dest"; then
        warn "File is empty or whitespace only!";
        return 1;
      else
        okay "We found ze file!";
      fi
    fi
    return $ret;
	}





#-------------------------------------------------------------------------------
# 
#-------------------------------------------------------------------------------


  get_rc_file(){
    if [ -n "$FX_RC" ] && [ -f "$FX_RC" ]; then
      echo "$FX_RC";
      return 0;
    fi
    return 1;
  }

  dump_rc_file(){
    local text="$(cat ${FX_RC}; printf '@@')";
    text="${text%@@}"
    __docbox "$text";
  }

	load_rc_file(){
    local rc ret; rc=$(get_rc_file); ret=$?;
    if [ $ret -ne 0 ]; then  # must pass 
      warn "Unable to load fx.rc file. (got:$rc)";
      return 1;
    fi
		source "$FX_RC" --load-vars;
    return 0;
	}



