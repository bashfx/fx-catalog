#!/usr/bin/env bash
# watchdomain.sh — poll registry WHOIS for a domain until an expected status appears.
# Supports: .com/.net (Verisign), .org (PIR)
# Modes:
#   1) Standalone time check:   --time-until "YYYY-MM-DD HH:MM:SS UTC" | <epoch>
#   2) Watch mode (with optional --until to ramp intervals near target time)
#
# Exit codes:
#   0 success (pattern seen) | 1 not seen | 2 invalid args | 3 whois missing | 4 date parsing error

set -euo pipefail

# ----- ANSI colors
GREY="\033[90m"
GREEN="\033[92m"
YEL="\033[93m"
NC="\033[0m"

usage() {
  cat <<EOF
Usage:
  # Standalone: print time remaining and epoch (no WHOIS calls)
  $0 --time-until "YYYY-MM-DD HH:MM:SS UTC"
  $0 --time-until-epoch <EPOCH_SECONDS>

  # Watch a domain
  $0 DOMAIN [-i SECONDS] [-e EXPECT_REGEX] [-n MAX_CHECKS] [--until "YYYY-MM-DD HH:MM:SS UTC"|<EPOCH>]

Options:
  DOMAIN            .com, .net, or .org
  -i SECONDS        Base poll interval (default: 60). Warns if <10s.
  -e REGEX          Expected pattern to detect (default: registry 'available' text)
                    Examples: 'No match' (Verisign available), 'pendingDelete'
  -n MAX_CHECKS     Stop after N checks (default: unlimited)
  --until WHEN      Datetime (e.g., "2025-08-15 18:00:00 UTC") or epoch seconds.
                    Auto-ramps poll interval: >30m -> base, <=30m -> 30s, <=5m -> 10s
  --time-until WHEN Print remaining time (and UNTIL_EPOCH=<epoch>) then exit 0
  --time-until-epoch <EPOCH> Same as above but with epoch seconds
EOF
}

# ----- helpers
human() { # seconds -> "Xd Xh Xm Xs" (compact)
  local s=$1 d h m
  (( d = s/86400, s%=86400, h = s/3600, s%=3600, m = s/60, s%=60 ))
  local out=""
  [[ $d -gt 0 ]] && out+="${d}d "
  [[ $h -gt 0 ]] && out+="${h}h "
  [[ $m -gt 0 ]] && out+="${m}m "
  out+="${s}s"
  echo "$out"
}

parse_when_to_epoch() {
  # Inputs: string WHEN -> echo epoch or return 4
  local WHEN="$1" EPOCH=""
  # If purely digits, treat as epoch
  if [[ "$WHEN" =~ ^[0-9]+$ ]]; then
    echo "$WHEN"; return 0
  fi
  # Try GNU date
  if date -u -d "$WHEN" +%s >/dev/null 2>&1; then
    EPOCH=$(date -u -d "$WHEN" +%s)
    echo "$EPOCH"; return 0
  fi
  # Try gdate (mac coreutils)
  if command -v gdate >/dev/null 2>&1; then
    if gdate -u -d "$WHEN" +%s >/dev/null 2>&1; then
      EPOCH=$(gdate -u -d "$WHEN" +%s); echo "$EPOCH"; return 0
    fi
  fi
  # Try BSD date with strict format "YYYY-MM-DD HH:MM:SS UTC"
  if date -u -j -f "%Y-%m-%d %H:%M:%S %Z" "$WHEN" +%s >/dev/null 2>&1; then
    EPOCH=$(date -u -j -f "%Y-%m-%d %H:%M:%S %Z" "$WHEN" +%s)
    echo "$EPOCH"; return 0
  fi
  return 4
}

print_time_until() {
  local WHEN="$1"
  local EPOCH
  if ! EPOCH=$(parse_when_to_epoch "$WHEN"); then
    echo "ERR: could not parse time: '$WHEN' (use 'YYYY-MM-DD HH:MM:SS UTC' or epoch)" >&2
    exit 4
  fi
  local NOW=$(date -u +%s)
  local REM=$(( EPOCH - NOW ))
  if (( REM < 0 )); then
    echo "Remaining: 0s (time already passed)"
  else
    echo "Remaining: $(human "$REM")"
  fi
  echo "UNTIL_EPOCH=$EPOCH"
}

# ----- parse args (support long options)
DOMAIN=""
INTERVAL=60
EXPECT=""
MAX_CHECKS=0
UNTIL_WHEN=""

# manual long option parsing
while (( "$#" )); do
  case "$1" in
    --time-until)
      shift; [[ $# -ge 1 ]] || { usage; exit 2; }
      print_time_until "$1"; exit 0;;
    --time-until-epoch)
      shift; [[ $# -ge 1 ]] || { usage; exit 2; }
      print_time_until "$1"; exit 0;;
    --until)
      shift; [[ $# -ge 1 ]] || { usage; exit 2; }
      UNTIL_WHEN="$1"; shift || true; continue;;
    -i) shift; INTERVAL="${1:-}"; shift || true; continue;;
    -e) shift; EXPECT="${1:-}"; shift || true; continue;;
    -n) shift; MAX_CHECKS="${1:-}"; shift || true; continue;;
    -h|--help) usage; exit 0;;
    --) shift; break;;
    -*)
      echo "ERR: unknown option '$1'"; usage; exit 2;;
    *)
      if [[ -z "$DOMAIN" ]]; then DOMAIN="$1"; else
        echo "ERR: unexpected arg '$1'"; usage; exit 2
      fi
      shift || true;;
  esac
done

# If no domain, we must have been in time-until mode (handled above)
if [[ -z "$DOMAIN" ]]; then usage; exit 2; fi

# Deps
if ! command -v whois >/dev/null 2>&1; then
  echo "ERR: 'whois' command not found. Install 'whois' first." >&2
  exit 3
fi

# Registry routing
shopt -s nocasematch
TLD=".${DOMAIN##*.}"
SERVER=""
DEFAULT_EXPECT=""
case "$TLD" in
  .com|.net)
    SERVER="whois.verisign-grs.com"
    DEFAULT_EXPECT="No match for"
    ;;
  .org)
    SERVER="whois.pir.org"
    DEFAULT_EXPECT="(NOT FOUND|Domain not found)"
    ;;
  *)
    echo "ERR: Unsupported TLD '$TLD'. Only .com, .net, .org are supported." >&2
    exit 2
    ;;
esac
[[ -z "$EXPECT" ]] && EXPECT="$DEFAULT_EXPECT"

if [[ "$INTERVAL" -lt 10 ]]; then
  echo -e "${YEL}WARN: Base interval ${INTERVAL}s is aggressive and can trigger rate limiting. Consider >= 30s.${NC}" >&2
fi

# Precompute UNTIL_EPOCH if provided
UNTIL_EPOCH=""
if [[ -n "$UNTIL_WHEN" ]]; then
  if ! UNTIL_EPOCH=$(parse_when_to_epoch "$UNTIL_WHEN"); then
    echo "ERR: could not parse --until '$UNTIL_WHEN' (use 'YYYY-MM-DD HH:MM:SS UTC' or epoch)" >&2
    exit 4
  fi
fi

echo "Watching ${DOMAIN} via ${SERVER}; base interval=${INTERVAL}s; expect=/${EXPECT}/i"
[[ -n "$UNTIL_EPOCH" ]] && echo "Until target: $(date -u -d @${UNTIL_EPOCH} 2>/dev/null || date -u -r ${UNTIL_EPOCH}) (epoch ${UNTIL_EPOCH})"
echo "(Ctrl-C to stop)"

COUNT=0
while :; do
  # compute effective interval with ramping if --until set
  EFF_INTERVAL="$INTERVAL"
  if [[ -n "$UNTIL_EPOCH" ]]; then
    NOW=$(date -u +%s)
    REM=$(( UNTIL_EPOCH - NOW ))
    if (( REM <= 300 )); then         # <= 5 minutes
      EFF_INTERVAL=10
    elif (( REM <= 1800 )); then      # <= 30 minutes
      EFF_INTERVAL=30
    fi
  fi
  if (( EFF_INTERVAL < 10 )); then
    echo -e "${YEL}WARN: Effective interval ${EFF_INTERVAL}s is aggressive and may trigger rate limits.${NC}" >&2
  fi

  TS="$(date -Is)"
  OUT="$(whois -h "$SERVER" "$DOMAIN" 2>/dev/null || true)"
  if echo "$OUT" | grep -Eiq -- "$EXPECT"; then
    echo -e "${GREEN}[$TS] SUCCESS: pattern matched for ${DOMAIN}${NC}"
    echo "$OUT" | sed -n '1,20p'
    exit 0
  else
    echo -e "${GREY}[$TS] not yet — effective interval ${EFF_INTERVAL}s${NC}"
  fi

  COUNT=$((COUNT+1))
  if [[ "$MAX_CHECKS" -gt 0 && "$COUNT" -ge "$MAX_CHECKS" ]]; then
    echo "DONE: Max checks ($MAX_CHECKS) reached without matching pattern."
    exit 1
  fi

  sleep "$EFF_INTERVAL"
done
