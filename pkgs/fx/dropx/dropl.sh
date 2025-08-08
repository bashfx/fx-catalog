#!/usr/bin/env bash
# dropl v2: launcher/manager for dropx
# - start: nohup + setsid, write PID + LOG; prints PID and log path
# - tail: follow log
# - stop: kill process group; fallback pkill on inotifywait and dropx patterns; clean pidfile
# - status: show running PID and process tree

set -euo pipefail

RUN_DIR="${DROPX_RUN_DIR:-$HOME/.local/run}"
LOG_DIR="${DROPX_LOG_DIR:-$HOME/.local/var}"
BIN="${DROPX_BIN:-$HOME/.local/bin/dropx}"
PID_FILE="$RUN_DIR/dropx.pid"
LOG_FILE="$LOG_DIR/dropx.log"

mkdir -p "$RUN_DIR" "$LOG_DIR"

usage(){
  echo "Usage: dropl {start|stop|tail|status} [--] [args to dropx]"
}

is_running(){
  [ -f "$PID_FILE" ] || return 1
  local pid; pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null
}

start(){
  if is_running; then
    echo "Already running (PID $(cat "$PID_FILE"))."; exit 0
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
  pkill -f "^inotifywait .*" 2>/dev/null || true
  pkill -f "[/]local/bin/dropx" 2>/dev/null || true
  echo "Stopped."
}

tail_log(){
  [ -f "$LOG_FILE" ] || { echo "No log at $LOG_FILE"; exit 1; }
  exec tail -n +1 -F "$LOG_FILE"
}

status(){
  if is_running; then
    local pid; pid="$(cat "$PID_FILE")"
    echo "Running. PID $pid"
    ps -o pid,ppid,pgid,cmd -p "$pid"
  else
    echo "Stopped."
  fi
}

case "${1:-}" in
  start) shift; start "$@";;
  stop) shift; stop;;
  tail) shift; tail_log;;
  status) shift; status;;
  *) usage; exit 2;;
esac
