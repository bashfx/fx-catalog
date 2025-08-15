#!/usr/bin/env bash
# watchdomain.sh — poll registry WHOIS for a domain until an expected status appears.
# Supports: .com/.net (Verisign), .org (PIR)
# Exits 0 when EXPECT pattern is seen, 1 if max checks exhausted, 2 bad input, 3 whois missing.

set -euo pipefail

# ANSI colors
GREY="\033[90m"
GREEN="\033[92m"
NC="\033[0m" # reset

usage() {
  cat <<EOF
Usage: $0 DOMAIN [-i SECONDS] [-e EXPECT_REGEX] [-n MAX_CHECKS]

  DOMAIN         Domain to watch (must be .com, .net, or .org)
  -i SECONDS     Poll interval (default: 60). Warns if < 10s (rate-limit risk).
  -e REGEX       Expected pattern to detect (default: registry 'available' text)
                 Examples:
                   -e 'No match'            # Verisign available
                   -e 'pendingDelete'       # watch for pendingDelete
  -n MAX_CHECKS  Stop after N checks (default: unlimited)

Exit codes: 0 success (pattern seen) | 1 not seen | 2 invalid args | 3 whois missing
EOF
}

DOMAIN="${1:-}"
if [[ -z "${DOMAIN}" || "${DOMAIN}" == -* ]]; then usage; exit 2; fi
shift || true

INTERVAL=60
EXPECT=""
MAX_CHECKS=0

while getopts ":i:e:n:h" opt; do
  case "$opt" in
    i) INTERVAL="${OPTARG}" ;;
    e) EXPECT="${OPTARG}" ;;
    n) MAX_CHECKS="${OPTARG}" ;;
    h) usage; exit 0 ;;
    \?) usage; exit 2 ;;
  esac
done

if ! command -v whois >/dev/null 2>&1; then
  echo "ERR: 'whois' command not found. Install 'whois' first." >&2
  exit 3
fi

TLD=".${DOMAIN##*.}"
REGISTRY=""
SERVER=""
DEFAULT_EXPECT=""

case "$TLD" in
  .com|.net)
    REGISTRY="verisign"
    SERVER="whois.verisign-grs.com"
    DEFAULT_EXPECT="No match for"
    ;;
  .org)
    REGISTRY="pir"
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
  echo "WARN: Interval ${INTERVAL}s is aggressive and can trigger rate limiting. Consider >= 30s." >&2
fi

echo "Watching ${DOMAIN} via ${SERVER} every ${INTERVAL}s; looking for /${EXPECT}/i"
echo "(Ctrl-C to stop)"

COUNT=0
while :; do
  TS="$(date -Is)"
  OUTPUT="$(whois -h "$SERVER" "$DOMAIN" 2>/dev/null || true)"
  
  if echo "$OUTPUT" | grep -Eiq -- "$EXPECT"; then
    echo -e "${GREEN}[$TS] SUCCESS: Pattern found for ${DOMAIN}${NC}"
    echo "$OUTPUT" | sed -n '1,20p'
    exit 0
  else
    echo -e "${GREY}[$TS] not yet — status does not match${NC}"
  fi

  COUNT=$((COUNT+1))
  if [[ "$MAX_CHECKS" -gt 0 && "$COUNT" -ge "$MAX_CHECKS" ]]; then
    echo "DONE: Max checks ($MAX_CHECKS) reached without matching pattern."
    exit 1
  fi

  sleep "$INTERVAL"
done
