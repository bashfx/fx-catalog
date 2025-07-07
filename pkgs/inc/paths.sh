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
    export XDG_FX_DATA="${XDG_FX_BIN:-$XDG_FX_LOCAL/data}";
    export XDG_FX_STATE="${XDG_FX_STATE:-$XDG_FX_HOME/.local/state}";

  }

