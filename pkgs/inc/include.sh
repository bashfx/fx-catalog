#!/usr/bin/env bash


#-------------------------------------------------------------------------------
# Library Identity
#-------------------------------------------------------------------------------
  readonly LIB_INCLUDE="${BASH_SOURCE[0]}";
  _index=

#-------------------------------------------------------------------------------
# Load Guard
#-------------------------------------------------------------------------------



if ! _index=$(is_lib_registered "LIB_INCLUDE"); then 

  register_lib LIB_INCLUDE;

#-------------------------------------------------------------------------------
# Experiments
#-------------------------------------------------------------------------------

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

    ! is_base_ready && fatal "[INC] Base not ready. Critical paths missing.";

    if [ -z "$lib" ]; then
      error "[INC] smart_source: No lib name provided."
      return 1
    fi

    

    inc_path=$__INC_BASE; ret=$?;

    if [ -n "$inc_path" ] && [ -d "$inc_path" ]; then
      lib_path="$inc_path/$lib.sh";
      if [ -f "$lib_path" ]; then
        source "$lib_path" && {
          #okay "Sourced '$lib' from: ($lib_path)";
          return 0
        }
        error "[INC] source failed to load the '$lib' package at: ($lib_path)."
      else
        error "[INC] Library '$lib' not found at: ($lib_path)";
      fi
    fi  

    return 1;
  }


  convert_pkg(){
    trace "[INC] checking for valid package name ($1)"
    local this="$1"
    local group pkg base group_path path


    case "$this" in
      (*[:.]*) group="${this%%[:.]*}"; pkg="${this#*[:.]}" ;;
      (*) group="$this"; pkg="all" ;;
    esac

    group_path="$base/$group"


    if [ -z "$pkg" ] || [ "$pkg" = "all" ]; then
      path="$group_path"
    elif [ -d "$group_path/$pkg" ]; then
      path="$group_path/$pkg";
    fi

  }



#-------------------------------------------------------------------------------
# Load Guard Error
#-------------------------------------------------------------------------------

else

  error "Library LIB_INCLUDE found at index [$_index]";
  exit 1;

fi
