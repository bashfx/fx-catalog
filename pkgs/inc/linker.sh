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



  # does a grep check for src in profile
  has_profile_link(){
    local res ret src=$1 prof=$FX_PROFILE _line;
    _line="source \"$src\";"
    grep -qF "$_line" "$prof" && return 0;
    return 1;
  }

  # links src (rc) to profile
  set_profile_link(){
    local res ret src=$1 prof=$FX_PROFILE _line;

    # src must exist or linking it doesnt make sense
    [ -z "$src" ] || [ ! -f "$src" ] && { 
      error "[LNK] Invalid src ($src). File must exist to link.";
      return 1; 
    }

    if has_profile_link "$src"; then
      warn "already linked";
    else
      _line="source \"$src\";"
      grep -qF "$_line" "$prof" || echo "$_line" >> "$prof";
      return 0;
    fi
    return 1;
  }

  # remove src (rc) from profile
  rem_profile_bak(){
    local res ret src=$1 prof=$FX_PROFILE _line;
    if has_profile_link "$src"; then
      _line="source \"$src\";"
      sed -i.bak "\|^$_line\$|d" "$prof";
      [ -f $prof.bak ] && rm "$prof.bak";
      return 0;
    fi
    return 1;
  }


#-------------------------------------------------------------------------------
# Dev Drivers 
#-------------------------------------------------------------------------------


  dev_dump_profile(){
    local prof=$(canonical_profile);
    trace "profile:$prof";
    res=$(cat $prof);
    __docbox "$res";
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

