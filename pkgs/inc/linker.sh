#!/usr/bin/env bash
#===============================================================================
#-----------------------------><-----------------------------#
#$ name:linker
#$ author:qodeninja
#$ desc:
#-----------------------------><-----------------------------#
#=====================================code!=====================================



#-------------------------------------------------------------------------------
# Universal Link Functions
#-------------------------------------------------------------------------------


  # returns canonical prof it found the src in
  has_profile_link(){
    local res ret src=$1 prof _line;
    prof=$FX_PROFILE;
    _line="source \"$src\";"
    grep -qF "$_line" "$prof" && return 0;
    return 1;
  }

  set_profile_link(){
    local res ret src=$1 prof=$FX_PROFILE _line;
    [ -z "$src" ] && return 1;

    if has_profile_link "$src"; then
      warn "already linked";
    else
      _line="source \"$src\";"
      grep -qF "$_line" "$prof" || echo "$_line" >> "$prof";
      return 0;
    fi
    return 1;
  }

  rem_profile_bak(){
    local res ret src=$1 prof=$FX_PROFILE _line;
    if has_profile_link "$src"; then
      _line="source \"$src\";"
      sed -i.bak "\|^$_line\$|d" "$prof";
      [ -f $prof.bak ] && rm "$prof.bak";
    else
      warn "already unlinked";
    fi
  }




#-------------------------------------------------------------------------------
# Dev Only
#-------------------------------------------------------------------------------

  dev_show_link(){
    if require_dev; then 
      local rc ret; rc=$(get_rc_file); ret=$?;
      data="$(link_profile_str)";

# @ai rec 
      # data="$(get_embedded_doc "$THIS_SELF" "$THIS_LINK_BLOCK")";

      __docbox "$data";
    else
      error "[DEV GUARD]. 'dev_show_link' aborted.";
    fi
  }


#-------------------------------------------------------------------------------
# Use case 1 > fx.rc to profile
#-------------------------------------------------------------------------------

# @clean nuke unused linker code

	# link_profile_str(){
  #   trace "Getting embedded link.";
  #   local str ret;

  #   str=$(block_print "link:bashfx" "${SELF_PATH}");

  #   if [ ${#str} -gt 0 ]; then
  #     echo -e "$str"
  #   else 
  #     error "Problem reading embedded link";
  #     exit 1;
  #   fi
	# }


  # link_profile(){
  #   trace "Linking fx.rc to profile"
  #   local res ret src;
  #   src=$(canonical_profile);
  #   res=$(sed -n "/#### bashfx ####/,/########/p" "$src");

  #   if [ -z "$FX_RC" ] || [ ! -f "$FX_RC" ]; then
  #     error "Cannot update profile, missing fx.rc. ($FX_RC)"
  #     return 1
  #   fi

  #   [ -z "$res" ] && ret=1 || ret=0;

  #   if [ $ret -eq 1 ]; then

  #     data="$(link_profile_str)";
  #     printf "$data" >> "$src";

  #     okay "Bashfx FX(1) has been installed ...";
  #   else
  #     warn "fx.rc already linked to profile. Skipping.";
  #   fi
  # }


  # unlink_profile(){
  #   trace "Unlinking fx.rc from profile";
  #   local res ret src=$(canonical_profile);

  #   if grep -q "#### bashfx ####" "$src"; then
  #     #sed delete
  #     sed -i.bak "/#### bashfx ####/,/########/d" "$src"; ret=$?;
  #     rm -f "${src}.bak";
  #     okay "-> Bashfx FX(1) has been uninstalled ...";
  #   else
  #     warn "-> fx.rc was already unlinked.";
  #   fi

  # }

  # has_profile_link(){
  #   trace "Linking fx.rc to profile"
  #   local res ret src;
  #   src=$(canonical_profile);
  #   res=$(sed -n "/#### bashfx ####/,/########/p" "$src");
  #   [ -z "$res" ] && ret=1 || ret=0;
  #   return $ret;
  # }

