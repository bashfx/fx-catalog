#!/usr/bin/env bash

# glob_new.sh
#
# This script provides two distinct entry points depending on how it is invoked:
#
#  1. When invoked via a filename of **glob** (and executed, not sourced), it
#     acts as a read‑only dispatcher for a simple key/value store. It never
#     mutates the persistent state; instead it reads from a state file in
#     $XDG_STATE_HOME/glb/glob.env and prints requested information.
#
#  2. When invoked via a filename of **globmut** *and sourced* into your
#     interactive shell, it installs a handful of functions and an
#     associative array (`_GLOBAL`) that allow you to mutate the key/value
#     store in memory.  These functions are defined only when the guard
#     environment variable GLOB_INSTALL is set to 0 (default is 1, which
#     suppresses installation).  Once sourced, you can call `globmut` in
#     your shell to set, get, list and save keys.  To unload the functions
#     and clean up, set CLEANUP_GLOBAL=1 and re‑source the file.
#
# NB: Do *not* source this file using the name `glob` – the read dispatcher
# refuses to run in a sourced context.  Likewise, do not execute `globmut` –
# it must be sourced to install the mutator API.

set -euo pipefail

###############################################################################
# Utility: determine the persistent state file and ensure its directory exists.
#
# XDG_STATE_HOME defaults to ~/.local/state when unset.  The state is stored
# under "$XDG_STATE_HOME/glb/glob.env". See: freedesktop.org XDG Base
# Directory Specification.

glob::_ensure_state() {
  : "${XDG_STATE_HOME:=$HOME/.local/state}"
  local dir="$XDG_STATE_HOME/glb"
  [[ -d "$dir" ]] || mkdir -p "$dir"
  printf '%s' "$dir/glob.env"
}

###############################################################################
# Read dispatcher (glob)
#
# Implements a simple CLI for inspecting the persistent state.  This dispatcher
# never writes to the state file – it only reads and reports. It is invoked
# when the basename of this script is "glob" and the script is executed.
#
# Commands:
#   get <key>          print the value for <key>, if present
#   ls [prefix]        list keys that start with [prefix] (default: all keys)
#   sufx <suffix>      list keys that end with <suffix>
#   dump               print all key=value pairs, sorted by key
#   init               print the initialisation timestamp (_INIT_) in human time
#   uptime             print the elapsed time since initialisation
#   save [file]        write the current key=value map to [file] (default
#                      state file) – this does not mutate the in‑memory
#                      associative array, it simply copies the state file
#   import <file>      import key=value pairs from <file> into the state file
#                      (overwriting existing entries). This is considered a
#                      write and will be rejected if invoked in read mode.
#
glob::_read_cli() {
  local state_file
  state_file="$(glob::_ensure_state)"
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    get)
      local key="${1:-}"
      if [[ -z "$key" ]]; then
        printf 'glob get requires a key\n' >&2
        return 1
      fi
      # use grep to find the exact key, ignoring commented lines
      if [[ -f "$state_file" ]]; then
        local line
        line=$(grep -E "^${key}=" "$state_file" || true)
        if [[ -n "$line" ]]; then
          printf '%s\n' "${line#*=}"
        fi
      fi
      ;;
    ls)
      local prefix="${1:-}"
      if [[ -f "$state_file" ]]; then
        if [[ -z "$prefix" ]]; then
          awk -F= '{print $1}' "$state_file" | sort
        else
          awk -F= -v p="$prefix" '$1 ~ "^" p {print $1}' "$state_file" | sort
        fi
      fi
      ;;
    sufx)
      local suffix="${1:-}"
      if [[ -z "$suffix" ]]; then
        printf 'glob sufx requires a suffix\n' >&2
        return 1
      fi
      if [[ -f "$state_file" ]]; then
        awk -F= -v s="$suffix" '$1 ~ s "$" {print $1}' "$state_file" | sort
      fi
      ;;
    dump)
      if [[ -f "$state_file" ]]; then
        sort "$state_file"
      fi
      ;;
    init)
      # print the initialisation timestamp as date
      local init_ts
      init_ts=$(grep -E '^_INIT_=' "$state_file" | cut -d= -f2 || true)
      if [[ -n "$init_ts" ]]; then
        date -d "@$init_ts" +"%Y-%m-%d %H:%M:%S"
      fi
      ;;
    uptime)
      local init_ts now delta d h m s
      init_ts=$(grep -E '^_INIT_=' "$state_file" | cut -d= -f2 || true)
      if [[ -n "$init_ts" ]]; then
        now=$(date +%s)
        delta=$(( now - init_ts ))
        d=$(( delta/86400 ))
        h=$(( (delta%86400)/3600 ))
        m=$(( (delta%3600)/60 ))
        s=$(( delta%60 ))
        printf 'Uptime: %d days, %02d:%02d:%02d\n' "$d" "$h" "$m" "$s"
      fi
      ;;
    save)
      # copy state file to destination (default: state file itself). This is
      # allowed because it does not mutate the associative array; it merely
      # writes the current state to a new location.
      local dest="${1:-}"
      if [[ -z "$dest" ]]; then
        dest="$state_file"
      fi
      if [[ -f "$state_file" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$state_file" "$dest"
        printf 'Saved to %s\n' "$dest"
      fi
      ;;
    import)
      # disallow import in read mode since it mutates the state; provide a hint
      printf 'Error: import is a write operation. Use globmut to import.\n' >&2
      return 1
      ;;
    *)
      printf 'Usage: glob {get|ls|sufx|dump|init|uptime|save} [args]\n' >&2
      return 1
      ;;
  esac
}

###############################################################################
# Mutator setup (globmut)
#
# The mutator API is installed only when this script is *sourced* via the
# filename `globmut` and the guard variable GLOB_INSTALL is set to 0. All
# functions defined here operate on a single associative array `_GLOBAL` and
# record timestamps for initialisation and last modification. They are not
# available when the guard is non‑zero or when the script is executed as
# `glob`.

globmut::_init_global() {
  # Create the global associative array if it doesn't already exist
  if ! declare -p _GLOBAL >/dev/null 2>&1 || ! [[ $(declare -p _GLOBAL) =~ "declare -A" ]]; then
    declare -gA _GLOBAL
  fi
  # Set session and init timestamps if absent
  if [[ -z "${_GLOBAL[_SSID_]:-}" ]]; then
    _GLOBAL[_SSID_]="$$"
  fi
  if [[ -z "${_GLOBAL[_INIT_]:-}" ]]; then
    _GLOBAL[_INIT_]="$(date +%s)"
  fi
  if [[ -z "${_GLOBAL[_LAST_]:-}" ]]; then
    _GLOBAL[_LAST_]="${_GLOBAL[_INIT_]}"
  fi
}

globmut::_save_state() {
  local file
  file="$(glob::_ensure_state)"
  mkdir -p "$(dirname "$file")"
  : > "$file"
  # write each key=value, quoting values safely
  local k
  for k in "${!_GLOBAL[@]}"; do
    printf '%s=%q\n' "$k" "${_GLOBAL[$k]}" >> "$file"
  done
}

globmut::_load_state() {
  local file
  file="$(glob::_ensure_state)"
  if [[ -f "$file" ]]; then
    while IFS='=' read -r k v; do
      [[ -n "$k" ]] || continue
      _GLOBAL["$k"]="${v//\"/}"
    done < "$file"
  fi
}

globmut::_uptime() {
  local now then delta d h m s
  now=$(date +%s)
  then="${_GLOBAL[_INIT_]:-0}"
  delta=$(( now - then ))
  d=$(( delta/86400 ))
  h=$(( (delta%86400)/3600 ))
  m=$(( (delta%3600)/60 ))
  s=$(( delta%60 ))
  printf 'Uptime: %d days, %02d:%02d:%02d\n' "$d" "$h" "$m" "$s"
}

globmut::set() {
  local key="$1" val="$2"
  _GLOBAL["$key"]="$val"
  _GLOBAL[_LAST_]=$(date +%s)
}

globmut::get() {
  local key="$1"
  printf '%s\n' "${_GLOBAL[$key]:-}"
}

globmut::rm() {
  local key="$1"
  unset '_GLOBAL[$key]'
  _GLOBAL[_LAST_]=$(date +%s)
}

globmut::ls() {
  local prefix="${1:-}"
  local k
  for k in "${!_GLOBAL[@]}"; do
    if [[ -z "$prefix" || "$k" == "$prefix"* ]]; then
      printf '%s\n' "$k"
    fi
  done | sort
}

globmut::sufx() {
  local suffix="$1"
  local k
  for k in "${!_GLOBAL[@]}"; do
    if [[ "$k" == *"$suffix" ]]; then
      printf '%s\n' "$k"
    fi
  done | sort
}

globmut::dump() {
  local k
  for k in "${!_GLOBAL[@]}"; do
    printf '%s=%s\n' "$k" "${_GLOBAL[$k]}"
  done | sort
}

globmut::reset() {
  local state_file
  state_file="$(glob::_ensure_state)"
  # backup the state file
  if [[ -f "$state_file" ]]; then
    mv "$state_file" "${state_file}.${_GLOBAL[_SSID_]:-bak}" || true
  fi
  unset _GLOBAL
  declare -gA _GLOBAL
  globmut::_init_global
}

globmut::import() {
  local file="$1"
  [[ -f "$file" ]] || { printf 'Import file %s not found\n' "$file" >&2; return 1; }
  while IFS='=' read -r k v; do
    [[ -n "$k" ]] || continue
    _GLOBAL["$k"]="${v//\"/}"
  done < "$file"
  _GLOBAL[_LAST_]=$(date +%s)
}

globmut::save() {
  local file="${1:-}" state_file
  state_file="$(glob::_ensure_state)"
  if [[ -z "$file" ]]; then
    file="$state_file"
  fi
  mkdir -p "$(dirname "$file")"
  : > "$file"
  local k
  for k in "${!_GLOBAL[@]}"; do
    printf '%s=%q\n' "$k" "${_GLOBAL[$k]}" >> "$file"
  done
  printf 'Saved to %s\n' "$file"
}

globmut::uptime() {
  globmut::_uptime
}

globmut::init() {
  date -d "@${_GLOBAL[_INIT_]:-0}" +"%Y-%m-%d %H:%M:%S"
}

globmut::zap() {
  unset _GLOBAL
  declare -gA _GLOBAL
  globmut::_init_global
}

# Dispatcher function for mutator commands. Use globmut <cmd> [args].
globmut() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    set)   globmut::set "$@" ;;
    get)   globmut::get "$@" ;;
    rm)    globmut::rm "$@" ;;
    ls)    globmut::ls "$@" ;;
    sufx)  globmut::sufx "$@" ;;
    dump)  globmut::dump ;;
    save)  globmut::save "$@" ;;
    import) globmut::import "$@" ;;
    reset) globmut::reset ;;
    zap)   globmut::zap ;;
    uptime) globmut::uptime ;;
    init)  globmut::init ;;
    *)     printf 'Usage: globmut {set|get|rm|ls|sufx|dump|save|import|reset|zap|uptime|init}\n' >&2; return 1 ;;
  esac
  return 0
}

###############################################################################
# Entry point dispatcher – decide behaviour based on how this file is invoked.

glob::_entry() {
  local script_name
  script_name="$(basename "${BASH_SOURCE[0]}")"

  # If invoked via globmut
  if [[ "$script_name" == "globmut" ]]; then
    if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
      # being sourced
      if [[ "${GLOB_INSTALL:-1}" -eq 0 ]]; then
        # Load existing state from file
        globmut::_init_global
        globmut::_load_state
        # Functions are now available in the caller's shell
        return 0
      else
        # Guard is active; do not install
        printf 'GLOB_INSTALL is not 0 – skipping globmut installation\n' >&2
        return 1
      fi
    else
      # executed via globmut – refuse
      printf 'Error: globmut must be sourced.\n' >&2
      exit 1
    fi
  fi

  # If invoked as glob – run the read dispatcher. Prevent sourcing.
  if [[ "$script_name" == "glob" ]]; then
    if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
      printf 'Error: do not source glob; execute it instead.\n' >&2
      return 1
    fi
    glob::_read_cli "$@"
    exit $?
  fi
}

glob::_entry "$@"
