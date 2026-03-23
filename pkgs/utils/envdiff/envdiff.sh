#!/usr/bin/env bash
# Compare system-only exported env vs current session exported env
# Default: compare ALL exported vars (no filtering).
# Optional: --clean (use built-in noise filter) or --noise 'REGEX'
set -euo pipefail

C="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$C"
SYS="$C/env.system"
USR="$C/env.user"
SYSK="$C/env.system.keys"
USRK="$C/env.user.keys"

NOISE='' ; MODE='all'
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean) NOISE='^(PWD|OLDPWD|SHLVL|_|\\?|PS1|PROMPT_COMMAND|LINES|COLUMNS|EUID|PPID|UID|RANDOM|SHELL|TERM|TERM_PROGRAM|TERM_PROGRAM_VERSION|XPC_.*|GPG_TTY)$'; shift;;
    --noise) NOISE="$2"; shift 2;;
    --help|-h) echo "usage: envdiff.sh [--clean] [--noise 'REGEX']"; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done

tmp="$(mktemp)"
cat >"$tmp"<<'RC'
[[ -r /etc/profile ]] && . /etc/profile
[[ -r /etc/bash.bashrc ]] && . /etc/bash.bashrc
[[ -r /etc/bashrc ]] && . /etc/bashrc
for f in /etc/profile.d/*.sh; do [[ -r "$f" ]] && . "$f"; done
export -p
RC

dump_keys(){ # extract var names from `export -p`
  awk '
    match($0, /^declare -x[[:space:]]+([^=+[:space:]]+)/, a){print a[1]}
  '
}

# --- system snapshot ---
sys_raw="$(BASH_ENV="$tmp" bash -c 'export -p')"
rm -f "$tmp"
if [[ -n "$NOISE" ]]; then
  printf "%s\n" "$sys_raw" | grep -Ev "$NOISE" | LC_ALL=C sort >"$SYS"
  printf "%s\n" "$sys_raw" | dump_keys     | grep -Ev "$NOISE" | sort -u >"$SYSK"
else
  printf "%s\n" "$sys_raw" | LC_ALL=C sort >"$SYS"
  printf "%s\n" "$sys_raw" | dump_keys     | sort -u >"$SYSK"
fi

# --- user snapshot (current shell) ---
usr_raw="$(export -p)"
if [[ -n "$NOISE" ]]; then
  printf "%s\n" "$usr_raw" | grep -Ev "$NOISE" | LC_ALL=C sort >"$USR"
  printf "%s\n" "$usr_raw" | dump_keys     | grep -Ev "$NOISE" | sort -u >"$USRK"
else
  printf "%s\n" "$usr_raw" | LC_ALL=C sort >"$USR"
  printf "%s\n" "$usr_raw" | dump_keys     | sort -u >"$USRK"
fi

# --- show delta ---
echo "### KEYS delta:"
diff -u "$SYSK" "$USRK" | sed -n '1,2d; s/^+/\+ /p; s/^-/\- /p' || true
echo
echo "### VALUES delta:"
diff -u "$SYS" "$USR"   | sed -n 's/^+declare -x /+ /p; s/^-declare -x /- /p' || true
