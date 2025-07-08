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

  get_this_rc_val(){
    local this=${!THIS_RC_VAR};
    if [ -n "$this" ]; then
      echo "$this";
      return 0;
    fi
    return 1;
  }


	save_rc_file(){
    local rc ret src=$1 dest=$2 lbl=$3; #src has embedded doc
    trace "save rc file args (src=$1) (dest=$2) (lbl=$3)";

    res="$(get_embedded_doc $src $lbl)";ret=$?;
    
    if [ $ret -eq 0 ]; then
      echo "$res" > "$dest";
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


  get_this_rc_file(){
    local this=${!THIS_RC_VAR};
    [ -n "$this" ] && [ -f "$this" ] && { 
      echo "$this";
      return 0;
    }
    return 1;
  }

  
  del_this_rc_file(){
    local this=${!THIS_RC_VAR};

    if [ ! -z "$this" ]; then
      trace "[RC] rc file found $this, deleting...";
      [ -f "$this" ] && { rm "$this"; } || :
      # should have been removed. permission error?
      [ ! -f "$this" ] && { return 0; } || :
      return 1;
    fi
    
    warn "[RC] rc file not found...";
    return 0;
  }


	load_this_rc_file(){
    local this=${!THIS_RC_VAR};
    if [ -n "$this" ] && [ -f $this ]; then  # must pass 
      source "$this" --load-vars;
      return 0;
    fi
    return 1;
	}


  dump_this_rc_file(){
    local this=${!THIS_RC_VAR};
    if [ -f $this ]; then 
      local text="$(cat ${this}; printf '@@')";
      text="${text%@@}"
      __docbox "$text";
      return 0;
    else
      error "[RC] Cannot find [this] rcfile ($this). Nothing to dump.";
    fi
    return 1;
  }
