#!/usr/bin/env bash
# dropl: launcher for dropx (nohup+PID+log), with conf + bootstrap of ~/.local dirs
set -euo pipefail

# ---------- bootstrap local dirs ----------
mkdir -p "$HOME/.local/etc/fx" "$HOME/.local/var/fx" "$HOME/.local/run/fx"

# ---------- load defaults from user config ----------
CONF="${DROPX_CONF:-$HOME/.local/etc/fx/drop.conf}"
[ -f "$CONF" ] && . "$CONF" || true


# paths from conf or defaults
PIDF="${DROPX_PID:-$HOME/.dropx.pid}"
LOGF="${DROPX_LOG:-$HOME/dropx.log}"

# ensure parent dirs for pid/log
mkdir -p "$(dirname "$PIDF")" "$(dirname "$LOGF")"

usage(){ cat <<EOF
Usage: dropl start [args...] | stop | status | tail | conf
  start [args...]  -> nohup dropx [args...] >> \$LOGF 2>&1 & ; save \$PIDF
                      (runs 'conf' first if config missing)
  stop             -> kill PID from \$PIDF
  status           -> show PID if running
  tail             -> tail -f \$LOGF
  conf             -> ensure config file exists and open in \$EDITOR (or nano)
Files:
  Conf: $CONF
  PID:  $PIDF
  LOG:  $LOGF
EOF
}

ensure_conf() {
  mkdir -p "$(dirname "$CONF")"
  if [ ! -f "$CONF" ]; then
    touch "$CONF"
    echo "# dropx config" >> "$CONF"
    echo "Created new config at $CONF"
  fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
  conf)
    ensure_conf
    ${EDITOR:-nano} "$CONF"
    ;;
  start)
    ensure_conf
    if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then
      echo "dropx already running (PID $(cat "$PIDF")). Log: $LOGF"; exit 0
    fi
    : > "$LOGF"
    nohup dropx "$@" >>"$LOGF" 2>&1 &
    echo $! > "$PIDF"
    echo "Started dropx (PID $(cat "$PIDF")). Log: $LOGF"
    ;;
  stop)
    if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then
      kill "$(cat "$PIDF")" && rm -f "$PIDF"
      echo "Stopped dropx."
    else
      echo "No running dropx."
      rm -f "$PIDF" || true
    fi
    ;;
  status)
    if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then
      echo "dropx running (PID $(cat "$PIDF")). Log: $LOGF"
    else
      echo "dropx not running."
    fi
    ;;
  tail)
    [ -f "$LOGF" ] || { echo "No log at $LOGF"; exit 1; }
    tail -f "$LOGF"
    ;;
  *) usage; exit 2;;
esac
