#!/usr/bin/env bash
#-----------------------------><-----------------------------#
#$ name:xdg
#$ author:qodeninja
#$ date:
#$ semver:
#$ autobuild: 00001
#-----------------------------><-----------------------------#
#=====================================code!=====================================


  echo "loaded paths.sh";



  init_xdg(){
    info "[VAR] Root XDG vars loading (overridable)...";

    # Fallback base for $XDG_FX_HOME if needed
    : "${XDG_FX_HOME:=$HOME}"

    export XDG_FX_HOME="${XDG_FX_CONFIG:-$HOME}";
    export XDG_FX_CONFIG="${XDG_FX_CONFIG:-$XDG_FX_HOME/.config}";
    export XDG_FX_CACHE="${XDG_FX_CACHE:-$XDG_FX_HOME/.cache}";
    export XDG_FX_LOCAL="${XDG_FX_LOCAL:-$XDG_FX_HOME/.local}";
    export XDG_FX_SHARE="${XDG_FX_SHARE:-$XDG_FX_LOCAL/share}";
    export XDG_FX_LIB="${XDG_FX_LIB:-$XDG_FX_LOCAL/lib}";
    export XDG_FX_BIN="${XDG_FX_BIN:-$XDG_FX_LOCAL/bin}";
    export XDG_FX_STATE="${XDG_FX_STATE:-$XDG_FX_HOME/.local/state}";

  }

  canonical_profile() {
    trace "Checking canonical profile";

    local BASH_PROFILE LAST_BASH_PROFILE;

    if [ -f "$HOME/.profile" ]; then
      BASH_PROFILE="$HOME/.profile";
    else
      BASH_PROFILE="$HOME/.bash_profile";
    fi

    if [ -L "$BASH_PROFILE" ]; then
      LAST_BASH_PROFILE="$BASH_PROFILE" #origin if linked
      if command -v realpath >/dev/null 2>&1; then
        BASH_PROFILE=$(realpath --logical "$BASH_PROFILE");
      else
      
        # Fallback if realpath is not available (macOS, older systems).
        # This may not fully resolve symlinks in all cases, but it's better than nothing.
        warn "realpath not found. Profile path may not be fully resolved."
        # Use `readlink` if available as a slightly better alternative to just echoing
        command -v readlink >/dev/null 2>&1 && BASH_PROFILE=$(readlink "$BASH_PROFILE") || :


      fi
    fi

    echo "$BASH_PROFILE"
  }
