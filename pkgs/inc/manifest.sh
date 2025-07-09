#!/usr/bin/env bash
#===============================================================================
#$ name: manifest.sh
#$ author: Ahab & Ishmael (Final)
#$ desc: Core functions for managing the BashFX package manifest.
#===============================================================================

# Note: This library assumes integrity.sh has been sourced.

# --- Manifest API ---

fx_manifest_add_entry() {
  think "fx_manifest_add_entry ($1)"
  local path="$1"
  local file="${FX_ETC}/manifest.log"
  local sum name
  
  info "Adding '$path' to manifest..."
  sum=$(_integrity_get_checksum "$path") || return 1
  name=$(_manifest_get_alias_from_source "$path") || return 1
  
  echo "$sum $path $name" >> "$file" || {
    error "Failed to write to manifest file: $file"
    return 1
  }
  return 0
}

fx_manifest_remove_entry() {
  think "fx_manifest_remove_entry ($1)"
  local path="$1"
  local file="${FX_ETC}/manifest.log"
  local tmp="${file}.tmp.$$"
  
  info "Removing '$path' from manifest..."
  grep -v " $path " "$file" > "$tmp" || {
    if [[ $? -gt 1 ]]; then
      error "Failed to read manifest file: $file"
      rm -f "$tmp"
      return 1
    fi
  }
  
  mv "$tmp" "$file" || {
    error "Failed to update manifest file: $file"
    rm -f "$tmp"
    return 1
  }
  return 0
}

fx_manifest_get_entry_by_alias() {
  think "fx_manifest_get_entry_by_alias ($1)"
  local name="$1"
  local file="${FX_ETC}/manifest.log"
  grep " $name$" "$file"
}

fx_manifest_clear() {
  think "fx_manifest_clear"
  local file="${FX_ETC}/manifest.log"
  info "Clearing package manifest..."
  > "$file"
  return 0
}


# --- Internal Helpers ---

_manifest_get_alias_from_source() {
  local src="$1"
  local name
  
  name=$(grep -m 1 '^# alias:' "$src" | cut -d: -f2- | xargs)
  [ -z "$name" ] && name=$(basename "${src%.sh}")
  
  echo "$name"
}
