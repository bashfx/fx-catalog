#!/usr/bin/env bash
#===============================================================================
#$ name: pkglinker.sh
#$ author: Ahab & Ishmael (Final)
#$ desc: Manages symlinks for BashFX package executables.
#===============================================================================

# Note: This library assumes manifest.sh has been sourced.

# --- Package Linker API ---

fx_pkglinker_link_by_alias() {
  think "fx_pkglinker_link_by_alias ($1)"
  local name="$1"
  local str path
  
  str=$(fx_manifest_get_entry_by_alias "$name") || {
    warn "No manifest entry found for name '$name'. Cannot link."
    return 1
  }
  
  path=$(echo "$str" | awk '{print $2}')
  [ ! -f "$path" ] && { error "Source file for name '$name' does not exist at '$path'."; return 1; }
  
  mkdir -p "$FX_BIN_DIR"
  info "Linking '$name' -> '$path'"
  ln -sf "$path" "$FX_BIN_DIR/$name" || {
    error "Failed to create symlink for '$name'."
    return 1
  }
  return 0
}

fx_pkglinker_unlink_by_alias() {
  think "fx_pkglinker_unlink_by_alias ($1)"
  local name="$1"
  local path="${FX_BIN_DIR}/$name"
  
  info "Unlinking '$name'..."
  rm -f "$path" || {
    error "Failed to remove symlink for '$name'."
    return 1
  }
  return 0
}

fx_pkglinker_link_all() {
  think "fx_pkglinker_link_all"
  local file="${FX_ETC}/manifest.log"
  info "Linking all executables from manifest..."

  [ ! -f "$file" ] && { error "Manifest not found. Cannot link."; return 1; }
  
  local count=0
  local _sum _path name
  while IFS= read -r line || [ -n "$line" ]; do
    read -r _sum _path name <<< "$line"
    [ -z "$name" ] && continue
    fx_pkglinker_link_by_alias "$name" && ((count++))
  done < "$file"
  
  okay "Linking complete. $count executables are now in your PATH."
  return 0
}
