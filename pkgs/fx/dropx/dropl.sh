#!/usr/bin/env bash
# dropl v7 (fx): launcher for dropx with mode-aware status, nuke, timeout override, and check-now

set -euo pipefail

CONF="${DROPX_CONF:-$HOME/.local/etc/fx/drop.conf}"
[ -f "$CONF" ] && . "$CONF" || true

RUN_DIR="${DROPX_RUN_DIR:-$HOME/.local/run/fx}"
LOG_DIR="${DROPX_LOG_DIR:-$HOME/.local/var/fx}"
BIN="${DROPX_BIN:-$HOME/.my/bin/dropx}"
PID_FILE="$RUN_DIR/dropx.pid"
LOG_FILE="$LOG_DIR/dropx.log"
CURSOR_FILE="$HOME/.droprc"

mkdir -p "$RUN_DIR" "$LOG_DIR"

usage(){ cat <<EOF
Usage: dropl {start|stop|tail|status|nuke|timeout <secs|reset>|check} [--] [args to dropx]
EOF
}

is_running(){ [ -f "$PID_FILE" ] || return 1; local pid; pid="$(cat "$PID_FILE" 2>/dev/null || true)"; [ -n "$pid" ] || return 1; kill -0 "$pid" 2>/dev/null; }

mode_from_env(){
  local pid="$1"
  local dbg ver
  dbg="$(tr '\0' '\n' < /proc/"$pid"/environ 2>/dev/null | awk -F= '$1=="DEBUG_MODE"{print $2}')"
  ver="$(tr '\0' '\n' < /proc/"$pid"/environ 2>/dev/null | awk -F= '$1=="DROPX_VERBOSE"{print $2}')"
  [ -z "$dbg" ] && dbg="1"
  [ -z "$ver" ] && ver="0"
  if [ "$dbg" = "0" ]; then echo "DEBUG (DEBUG_MODE=0)"; elif [ "$ver" = "1" ]; then echo "INFO (DROPX_VERBOSE=1)"; else echo "QUIET"; fi
}

start(){
  if is_running; then echo "Already running (PID $(cat "$PID_FILE")). Log: $LOG_FILE"; exit 0; fi
  : > "$LOG_FILE"
  ( setsid nohup "$BIN" "$@" >>"$LOG_FILE" 2>&1 & echo $! > "$PID_FILE" ) </dev/null
  sleep 0.2
  local pid; pid="$(cat "$PID_FILE")"
  echo "Started dropx (PID $pid). Log: $LOG_FILE"
}

stop(){
  if ! is_running; then echo "Not running."; else
    local pid; pid="$(cat "$PID_FILE")"
    echo "Stopping dropx (PID $pid)..."
    kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
    for i in {1..20}; do sleep 0.2; if ! kill -0 "$pid" 2>/dev/null; then break; fi; done
    if kill -0 "$pid" 2>/dev/null; then echo "Force killing..."; kill -KILL "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true; fi
    rm -f "$PID_FILE"
  fi
  nuke silent
  echo "Stopped."
}

tail_log(){ [ -f "$LOG_FILE" ] || { echo "No log at $LOG_FILE"; exit 1; }; exec tail -n +1 -F "$LOG_FILE"; }

status(){
  if is_running; then
    local pid; pid="$(cat "$PID_FILE")"
    local cur=""
    [ -f "$CURSOR_FILE" ] && cur="$(grep -E '^CURSOR_POLL_SEC=' "$CURSOR_FILE" 2>/dev/null | tail -n1 | cut -d= -f2- | tr -d '\"')"
    echo "Running. PID $pid  BIN=$BIN  LOG=$LOG_FILE  CONF=${CONF:-<none>}  Mode=$(mode_from_env "$pid")  PollOverride=${cur:-<none>}"
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
  [ "$silent" != "silent" ] && echo "Nuked inotifywait, stray dropx, and log tails."
}

timeout_cmd(){
  local arg="${1:-}"
  [ -f "$CURSOR_FILE" ] || : > "$CURSOR_FILE"
  # Remove existing override
  sed -i '/^CURSOR_POLL_SEC=/d' "$CURSOR_FILE" 2>/dev/null || true
  case "$arg" in
    reset|"")
      echo "Poll override cleared. Will use default from conf on next loop."
      ;;
    *)
      if ! [[ "$arg" =~ ^[0-9]+$ ]]; then echo "Invalid seconds: $arg"; exit 2; fi
      echo "CURSOR_POLL_SEC=\"$arg\"" >> "$CURSOR_FILE"
      echo "Poll override set to $arg seconds. Takes effect next loop."
      ;;
  esac
}

check_now(){
  if ! is_running; then echo "Not running."; exit 1; fi
  local pid; pid="$(cat "$PID_FILE")"
  # Ask dropx to process immediately (it should trap HUP/USR1)
  if kill -HUP "$pid" 2>/dev/null; then
    echo "Sent HUP to dropx (PID $pid). It should process once immediately."
  else
    echo "Failed to signal dropx (PID $pid)."
  fi
}

case "${1:-}" in
  start) shift; start "$@";;
  stop) shift; stop;;
  tail) shift; tail_log;;
  status) shift; status;;
  nuke) shift; nuke "$@";;
  timeout) shift; timeout_cmd "${1:-}";;
  check) shift; check_now;;
  *) usage; exit 2;;
esac
