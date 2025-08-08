#!/usr/bin/env bash
# dropl v5 (fx): launcher/manager for dropx with fx paths and nuking tails

set -euo pipefail

CONF="${DROPX_CONF:-$HOME/.local/etc/fx/drop.conf}"
[ -f "$CONF" ] && . "$CONF" || true

RUN_DIR="${DROPX_RUN_DIR:-$HOME/.local/run/fx}"
LOG_DIR="${DROPX_LOG_DIR:-$HOME/.local/var/fx}"
BIN="${DROPX_BIN:-$HOME/.my/bin/dropx}"
PID_FILE="$RUN_DIR/dropx.pid"
LOG_FILE="$LOG_DIR/dropx.log"

mkdir -p "$RUN_DIR" "$LOG_DIR"

usage(){
  echo "Usage: dropl {start|stop|tail|status|nuke} [--] [args to dropx]"
}

is_running(){
  [ -f "$PID_FILE" ] || return 1
  local pid; pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null
}

start(){
  if is_running; then
    echo "Already running (PID $(cat "$PID_FILE")). Log: $LOG_FILE"
    exit 0
  fi
  : > "$LOG_FILE"
  ( setsid nohup "$BIN" "$@" >>"$LOG_FILE" 2>&1 & echo $! > "$PID_FILE" ) </dev/null
  sleep 0.2
  local pid; pid="$(cat "$PID_FILE")"
  echo "Started dropx (PID $pid). Log: $LOG_FILE"
}

stop(){
  if ! is_running; then
    echo "Not running."
  else
    local pid; pid="$(cat "$PID_FILE")"
    echo "Stopping dropx (PID $pid)..."
    kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
    for i in {1..20}; do
      sleep 0.2
      if ! kill -0 "$pid" 2>/dev/null; then break; fi
    done
    if kill -0 "$pid" 2>/dev/null; then
      echo "Force killing..."
      kill -KILL "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
  nuke silent
  echo "Stopped."
}

tail_log(){
  [ -f "$LOG_FILE" ] || { echo "No log at $LOG_FILE"; exit 1; }
  exec tail -n +1 -F "$LOG_FILE"
}

status(){
  if is_running; then
    local pid; pid="$(cat "$PID_FILE")"
    echo "Running. PID $pid  BIN=$BIN  LOG=$LOG_FILE  CONF=${CONF:-<none>}"
    ps -o pid,ppid,pgid,cmd -p "$pid"
  else
    echo "Stopped. BIN=$BIN  LOG=$LOG_FILE  CONF=${CONF:-<none>}"
  fi
}

nuke(){
  local silent="${1:-}"
  pkill -9 -f "^inotifywait .*" 2>/dev/null || true
  pkill -9 -f "[/]local/bin/dropx" 2>/dev/null || true
  pkill -9 -f "tail -n \+1 -F $LOG_FILE" 2>/dev/null || true
  pkill -9 -f "tail -F $LOG_FILE" 2>/dev/null || true
  if [ "$silent" != "silent" ]; then
    echo "Nuked inotifywait, stray dropx, and log tails."
  fi
}

case "${1:-}" in
  start) shift; start "$@";;
  stop) shift; stop;;
  tail) shift; tail_log;;
  status) shift; status;;
  nuke) shift; nuke "$@";;
  *) usage; exit 2;;
esac
