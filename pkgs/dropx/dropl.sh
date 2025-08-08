#!/usr/bin/env bash
# dropl - Dropx launcher v3
# Controls dropx process (start/stop/tail/status) and now nukes all inotifywait + dropx processes.

DROPX_BIN="${DROPX_BIN:-$HOME/.local/bin/dropx}"
DROPX_LOG_DIR="$HOME/.local/var"
DROPX_LOG="$DROPX_LOG_DIR/dropx.log"
DROPX_PID_FILE="$DROPX_LOG_DIR/dropx.pid"

mkdir -p "$DROPX_LOG_DIR"

_usage() {
    echo "Usage: dropl {start|stop|status|tail|nuke}"
    exit 1
}

_start() {
    if [ -f "$DROPX_PID_FILE" ] && kill -0 $(cat "$DROPX_PID_FILE") 2>/dev/null; then
        echo "dropx already running (PID $(cat $DROPX_PID_FILE))"
        exit 0
    fi
    echo "Starting dropx..."
    nohup "$DROPX_BIN" > "$DROPX_LOG" 2>&1 &
    echo $! > "$DROPX_PID_FILE"
    echo "Started dropx (PID $(cat $DROPX_PID_FILE)). Log: $DROPX_LOG"
}

_stop() {
    if [ -f "$DROPX_PID_FILE" ] && kill -0 $(cat "$DROPX_PID_FILE") 2>/dev/null; then
        echo "Stopping dropx (PID $(cat $DROPX_PID_FILE))"
        kill $(cat "$DROPX_PID_FILE") 2>/dev/null
        rm -f "$DROPX_PID_FILE"
    else
        echo "dropx not running (no PID file)"
    fi
    # also kill any stray inotifywait processes
    _nuke_inotify silent
}

_status() {
    if [ -f "$DROPX_PID_FILE" ] && kill -0 $(cat "$DROPX_PID_FILE") 2>/dev/null; then
        echo "dropx running (PID $(cat $DROPX_PID_FILE))"
    else
        echo "dropx not running"
    fi
    pgrep -a inotifywait
}

_tail() {
    tail -f "$DROPX_LOG"
}

_nuke_inotify() {
    local silent="$1"
    local killed_any=false
    pkill -9 -f "^inotifywait .*" && killed_any=true
    pkill -9 -f "[/]local/bin/dropx" && killed_any=true
    if [ "$silent" != "silent" ]; then
        if [ "$killed_any" = true ]; then
            echo "Killed all inotifywait and stray dropx processes."
        else
            echo "No inotifywait or stray dropx processes found."
        fi
    fi
}

case "$1" in
    start) _start ;;
    stop) _stop ;;
    status) _status ;;
    tail) _tail ;;
    nuke) _nuke_inotify ;;
    *) _usage ;;
esac
