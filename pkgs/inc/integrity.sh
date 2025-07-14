#!/usr/bin/env bash
#===============================================================================
#$ name: integrity.sh
#$ author: Ahab & Ishmael (Final)
#$ desc: Provides functions for package integrity checks.
#===============================================================================


# --- Integrity API ---

fx_integrity_verify_all() {
  
  think "fx_integrity_verify_all"
  local file="${FX_ETC}/manifest.log"
  local integrity_ok=0 # 0=success, 1=failure
  
  info "Verifying package integrity..."
  [ ! -f "$file" ] && { error "Manifest file not found: $file"; return 1; }

  local expect_sum path name
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    read -r expect_sum path name <<< "$line"

    [ -z "$expect_sum" ] || [ -z "$path" ] && {
      warn "Skipping malformed manifest entry: $line"
      continue
    }

    _integrity_verify_one "$path" "$expect_sum" "$name" || integrity_ok=1
  done < "$file"

  if [ "$integrity_ok" -eq 0 ]; then
    okay "All installed packages verified successfully."
    return 0
  else
    error "One or more package integrity checks failed. Consider re-deploying."
    _integrity_set_tamper_flag
    return 1
  fi
}

# --- Internal Helpers ---

_integrity_verify_one() {
  local path="$1" expect_sum="$2" name="$3"
  local calc_sum msg

  [ ! -f "$path" ] && { error "File not found: $path (from manifest for name: $name)"; return 1; }

  calc_sum=$(_integrity_get_checksum "$path")
  
  if [ "$expect_sum" = "N/A" ] || [ "$calc_sum" = "N/A" ]; then
    warn "Checksum verification skipped for $path (name: $name)."
    return 0
  fi

  if [ "$expect_sum" = "$calc_sum" ]; then
    trace "Verified: $path"
    return 0
  else
    msg="INTEGRITY CHECK FAILED for $path (name: $name)\n\n"
    msg+="  Expected: $expect_sum\n"
    msg+="  Found:    $calc_sum"
    __errbox "$msg"
    return 1
  fi
}

_integrity_get_checksum() {
  local path="$1"
  [ ! -f "$path" ] && return 1
  
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$path" | awk '{print $1}'
  else
    echo "N/A"
  fi
}

_integrity_set_tamper_flag() {
  local file="${FX_ETC}/fx.rc"
  [ ! -f "$file" ] && { error "Cannot set tamper flag: $file not found."; return 1; }
  
  info "Setting tamper flag in $file"
  local tmp="${file}.tmp.$$"
  grep -v '^export FX_REPAIR=' "$file" > "$tmp"
  echo "export FX_REPAIR=true" >> "$tmp"
  mv "$tmp" "$file"
}
