#!/usr/bin/env bash
# Compare system-provided aliases with user aliases

set -euo pipefail
C="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$C"

sysfile="$C/aliases.system"
usrfile="$C/aliases.user"
tmp=$(mktemp)

# Build a fake rcfile that sources system configs only
cat >"$tmp"<<'RC'
[[ -r /etc/profile ]] && . /etc/profile
[[ -r /etc/bash.bashrc ]] && . /etc/bash.bashrc
[[ -r /etc/bashrc ]] && . /etc/bashrc
for f in /etc/profile.d/*.sh; do [[ -r "$f" ]] && . "$f"; done
shopt -s expand_aliases
RC

# Capture system aliases
BASH_ENV="$tmp" bash -c 'alias -p' | LC_ALL=C sort > "$sysfile"
rm -f "$tmp"

# Capture current aliases
alias -p | LC_ALL=C sort > "$usrfile"

# Show the delta
diff -u "$sysfile" "$usrfile" | sed -n 's/^+alias /+ /p; s/^-alias /- /p'



	# alias asnap="aliasdiff.sh"
	# alias adiff='sh -c '\''C="${XDG_CACHE_HOME:-$HOME/.cache}"; \
	# 	[ -f "$C/aliases.system" ] && [ -f "$C/aliases.user" ] || { echo "no snapshots; run aliasdiff.sh"; exit 1; }; \
	# 	diff -u "$C/aliases.system" "$C/aliases.user" | sed -n "s/^+alias /+ /p; s/^-alias /- /p"'\'

