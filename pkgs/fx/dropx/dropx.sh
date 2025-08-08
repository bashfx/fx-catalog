#!/usr/bin/env bash
# dropx: watch-restore v4 + DEBUG + ADS ignore
# - Baseline is your last working v4 (watching behavior unchanged)
# - Adds DEBUG_MODE (0/1) gating for noisy logs
# - Ignores Windows attachment/ADS artefacts:
#     * Names containing ':Zone.Identifier' or ending in '.Zone.Identifier'
#     * 'Zone.Identifier' files
#     * 'desktop.ini', 'Thumbs.db', 'ehthumbs.db'
#     * Apple '._*' resource forks (just in case)
# - Everything else from v4 preserved: multi-match non-colliding, collision detection, CRLF strip,
#   empty-src guard, root guard, assoc-array reset.

set -euo pipefail

# ---------- colors ----------
readonly red2=$'\x1B[38;5;197m'
readonly red=$'\x1B[38;5;1m'
readonly deep=$'\x1B[38;5;61m'
readonly deep_green=$'\x1B[38;5;60m'
readonly orange=$'\x1B[38;5;214m'
readonly orange2=$'\x1B[38;5;221m'
readonly yellow=$'\x1B[33m'
readonly green2=$'\x1B[38;5;156m'
readonly green=$'\x1B[38;5;10m'
readonly blue=$'\x1B[36m'
readonly blue2=$'\x1B[38;5;39m'
readonly cyan=$'\x1B[38;5;51m'
readonly magenta=$'\x1B[35m'
readonly purple=$'\x1B[38;5;213m'
readonly purple2=$'\x1B[38;5;141m'
readonly white=$'\x1B[38;5;247m'
readonly white2=$'\x1B[38;5;15m'
readonly grey=$'\x1B[38;5;242m'
readonly grey2=$'\x1B[38;5;240m'
readonly grey3=$'\x1B[38;5;237m'
readonly xx=$'\x1B[0m'

DEBUG_MODE="${DEBUG_MODE:-0}"
ts(){ date +'%F %T'; }
log()   { echo "${grey}[$(ts)]${xx} ${grey}$*${xx}"; }
ok()    { echo "${grey}[$(ts)]${xx} ${green}$*${xx}"; }
note()  { echo "${grey}[$(ts)]${xx} ${blue}$*${xx}"; }
warn()  { echo "${grey}[$(ts)]${xx} ${yellow}$*${xx}"; }
err()   { echo "${grey}[$(ts)]${xx} ${red}$*${xx}"; }
dlog()  { [ "$DEBUG_MODE" -eq 1 ] && log "$@"; }

# ---------- bootstrap ----------
mkdir -p "$HOME/.local/etc" "$HOME/.local/var" "$HOME/.local/run"

# ---------- load defaults (conf -> cursor -> CLI overrides) ----------
CONF="${DROPX_CONF:-$HOME/.local/etc/drop.conf}"
[ -f "$CONF" ] && . "$CONF" || true

CURSOR_FILE="$HOME/.droprc"
[ -f "$CURSOR_FILE" ] && . "$CURSOR_FILE" || true

DRYRUN=0
VERBOSE="${CURSOR_VERBOSE:-${DROPX_VERBOSE:-0}}"
MANIFEST="${CURSOR_MANIFEST:-${DROPX_MANIFEST:-}}"
SRC_DIR="${CURSOR_SRC_DIR:-${DROPX_SRC_DIR:-}}"
POLL_SEC="${DROPX_POLL_SEC:-2}"
ONCE=0

usage(){ cat <<EOF
Usage: dropx [-m manifest.rc] [-s /mnt/c/DropZone] [-n] [-v] [--once] [--poll N]
EOF
}

# ---------- args ----------
ARGS=()
while (( $# )); do
  case "${1:-}" in
    -m) MANIFEST="${2:-}"; shift 2;;
    -s) SRC_DIR="${2:-}"; shift 2;;
    -n) DRYRUN=1; shift;;
    -v) VERBOSE=1; shift;;
    --once) ONCE=1; shift;;
    --poll) POLL_SEC="${2:-2}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) ARGS+=("$1"); shift;;
  esac
done
set -- "${ARGS[@]}"

[ -z "${SRC_DIR:-}" ] && { err "-s drop folder required once (remembered)."; usage; exit 2; }
[ -d "$SRC_DIR" ] || { err "drop folder not found: $SRC_DIR"; exit 1; }

if [ -n "${MANIFEST:-}" ] && [ ! -f "$MANIFEST" ]; then
  dlog "Manifest not found at $MANIFEST — using drop-folder manifests only."
  MANIFEST=""
fi

mkdir -p "$(dirname "$CURSOR_FILE")"
cat > "$CURSOR_FILE" <<EOF
CURSOR_SRC_DIR="$(printf '%s' "$SRC_DIR")"
CURSOR_MANIFEST="$(printf '%s' "${MANIFEST:-}")"
CURSOR_VERBOSE="$VERBOSE"
EOF

shopt -s nullglob nocaseglob

expand_path(){ eval "printf '%s' \"$1\""; }
parse_flags(){ local s="${1:-}"; s="$(echo "$s" | tr -d '[:space:]')"; IFS=';' read -r -a a <<< "$s"; for kv in "${a[@]}"; do [ -n "$kv" ] && printf '%s\n' "$kv"; done; }
git_root_for(){ local p="$1"; local t="$p"; [ -d "$t" ] || t="$(dirname "$t")"; git -C "$t" rev-parse --show-toplevel 2>/dev/null || true; }

ensure_git_safe(){
  local repo="$1" policy="$2"; [ -z "$repo" ] && return 0
  if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    case "$policy" in
      auto)
        local msg="fix: auto sync save $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        note "Repo dirty at ${white2}$repo${xx} — ${cyan}auto committing${xx}."
        [ "$DRYRUN" -eq 1 ] || { git -C "$repo" add -A && git -C "$repo" commit -m "$msg" >/dev/null; }
        ;;
      true)
        if [ "$DRYRUN" -eq 1 ]; then dlog "(dry-run) would prompt to commit at ${white2}$repo${xx}"; return 1; fi
        read -rp "Repo $repo dirty. Commit now? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
          git -C "$repo" add -A && git -C "$repo" commit -m "fix: sync pre-commit $(date -u +'%Y-%m-%dT%H:%M:%SZ')" >/dev/null
        else
          err "Aborting (safe=true declined)."; exit 1
        fi
        ;;
      false|"") err "Aborting: destination repo dirty (safe=false)."; exit 1;;
      *) err "Unknown safe policy: $policy"; exit 1;;
    esac
  fi
}

do_transfer(){
  local src="$1" dst="$2" mode="$3"
  if [ "$DRYRUN" -eq 1 ]; then
    note "(dry-run) ${blue2}$mode${xx} ${white2}$src${xx} -> ${white2}$dst${xx}"
    note "(dry-run) then remove ${white2}$src${xx}"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [ "$mode" = "copy" ]; then
    if [ -d "$src" ]; then cp -a "$src" "$dst"; else cp -f "$src" "$dst"; fi
    ok "Copied: ${white2}$src${xx} -> ${white2}$dst${xx} (source removed)"
    rm -rf "$src"
  else
    if [ -d "$src" ] && [ -d "$dst" ]; then
      mv -f "$src" "$dst/"
      ok "Moved: ${white2}$src${xx} -> ${white2}$dst/${xx}"
    else
      mv -f "$src" "$dst"
      ok "Moved: ${white2}$src${xx} -> ${white2}$dst${xx}"
    fi
  fi
}

do_unzip(){
  local zip="$1" out="$2"
  if [ "$DRYRUN" -eq 1 ]; then
    note "(dry-run) ${cyan}unzip${xx} ${white2}$zip${xx} -> ${white2}$out${xx}"
    note "(dry-run) then remove ${white2}$zip${xx}"
    return 0
  fi
  mkdir -p "$out"; unzip -oq "$zip" -d "$out"
  ok "Extracted: ${white2}$zip${xx} -> ${white2}$out${xx}"
  rm -f "$zip"
}

is_ads_junk(){
  local b="$(basename "$1")"
  [[ "$b" == *:Zone.Identifier* ]] && return 0
  [[ "$b" == *.Zone.Identifier ]] && return 0
  [[ "$b" == Zone.Identifier ]] && return 0
  [[ "$b" == desktop.ini ]] && return 0
  [[ "$b" == Thumbs.db || "$b" == ehthumbs.db ]] && return 0
  [[ "$b" == ._* ]] && return 0
  return 1
}

dest_path_for_file(){
  local src="$1" dir="$2" ali="$3"; local base ext; base="$(basename "$src")"
  if [ "$ali" = "self" ]; then echo "${dir%/}/$base"; return; fi
  if [[ "$ali" == *.* ]]; then echo "${dir%/}/$ali"; else ext=""; [[ "$base" == *.* ]] && ext=".${base##*.}"; echo "${dir%/}/$ali$ext"; fi
}
dest_path_for_dir(){
  local src="$1" dir="$2" ali="$3"
  local name
  if [ "$ali" = "self" ]; then name="$(basename "$src")"; else name="$ali"; fi
  echo "${dir%/}/$name"
}
extract_dir_for_zip(){
  local src="$1" dir="$2" ali="$3"
  local name
  if [ "$ali" = "self" ]; then name="${src##*/}"; name="${name%.*}"; else name="$ali"; fi
  echo "${dir%/}/$name"
}

is_drop_root(){
  local p="$1"
  [[ "$p" = "$SRC_DIR" || "$p" = "$SRC_DIR/" || "$p" = "$SRC_DIR/." ]]
}

touched_reset(){
  unset _touched 2>/dev/null || true
  declare -gA _touched
}
declare -gA _touched

match_items(){
  local pat="$1" saved
  if [ -z "${pat:-}" ] || [ "$pat" = "." ] || [ "$pat" = "./" ]; then
    printf ''
    return 0
  fi
  saved="$(pwd)"
  cd "$SRC_DIR"
  # shellcheck disable=SC2206
  local m=( $pat )
  cd "$saved"
  local out=()
  for x in "${m[@]:-}"; do
    local full="$SRC_DIR/$x"
    is_drop_root "$full" && continue
    is_ads_junk "$full" && continue
    out+=( "$full" )
  done
  printf '%s\n' "${out[@]:-}"
}

collect_manifests(){
  local out=()
  mapfile -t dm < <(find "$SRC_DIR" -maxdepth 1 -type f -iname '*manifest.rc' -printf '%f\n' | sort)
  for f in "${dm[@]}"; do out+=( "$SRC_DIR/$f" ); done
  if [ -n "${MANIFEST:-}" ] && [ -f "$MANIFEST" ]; then out+=( "$MANIFEST" ); fi
  printf '%s\n' "${out[@]}"
}

manifest_signature(){
  mapfile -t mfs < <(collect_manifests)
  if [ "${#mfs[@]}" -eq 0 ]; then echo "NONE"; return; fi
  for f in "${mfs[@]}"; do
    if [ -f "$f" ]; then
      printf "%s:%s:%s\n" "$f" "$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")" "$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f")"
    fi
  done | sort
}

drop_signature(){
  local saved
  saved="$(pwd)"
  cd "$SRC_DIR"
  while IFS= read -r -d '' p; do
    if [ -d "$p" ]; then t="d"; else t="f"; fi
    sz="$(stat -c %s "$p" 2>/dev/null || stat -f %z "$p")"
    mt="$(stat -c %Y "$p" 2>/dev/null || stat -f %m "$p")"
    printf "%s|%s|%s|%s\n" "$(basename "$p")" "$t" "$sz" "$mt"
  done < <(find . -maxdepth 1 -mindepth 1 -print0)
  cd "$saved" >/dev/null 2>&1
}

process_once(){
  touched_reset

  local mf
  mapfile -t MANIFS < <(collect_manifests)
  if [ "${#MANIFS[@]}" -eq 0 ]; then
    dlog "No manifest found (drop-folder empty and none provided)."
    report_untracked
    return 0
  fi

  if [ "$DEBUG_MODE" -eq 1 ]; then
    echo "${grey}[${xx}$(ts)${grey}]${xx} ${purple}Manifests:${xx}"
    for mf in "${MANIFS[@]}"; do echo "  ${grey}-${xx} ${white2}$mf${xx}"; done
  fi

  local LINE pattern alias dest flags destx MODE EXTRACT SAFE CONFIRM
  for mf in "${MANIFS[@]}"; do
    while IFS= read -r LINE || [ -n "$LINE" ]; do
      LINE="${LINE%"${LINE##*[![:space:]]}"}"; LINE="${LINE#"${LINE%%[![:space:]]*}"}"
      LINE="${LINE%$'\r'}"
      [ -z "$LINE" ] && continue
      case "$LINE" in \#*) continue ;; esac

      pattern=""; alias=""; dest=""; flags=""
      read -r pattern alias dest flags <<<"$LINE"
      pattern="${pattern%$'\r'}"; alias="${alias%$'\r'}"; dest="${dest%$'\r'}"; flags="${flags%$'\r'}"

      if [ -z "$pattern" ] || [ -z "$alias" ] || [ -z "$dest" ]; then
        dlog "Skipping malformed line: ${white2}$LINE${xx}"
        continue
      fi
      if [ "$pattern" = "." ] || [ "$pattern" = "./" ]; then
        warn "Ignoring root pattern '.' in manifest."
        continue
      fi

      destx="$(expand_path "$dest")"
      MODE="move"; EXTRACT="false"; SAFE="false"; CONFIRM="false"
      if [ -n "${flags:-}" ]; then
        while IFS= read -r kv; do
          k="${kv%%=*}"; v="${kv#*=}"
          case "$k" in
            mode) MODE="$v";;
            action) if [ "$v" = "extract" ]; then EXTRACT="true"; else MODE="$v"; fi ;;
            extract) EXTRACT="$v";;
            safe) SAFE="$v";;
            confirm) CONFIRM="$v";;
            *) dlog "Unknown flag '${white2}$k${xx}' ignored." ;;
          esac
        done < <(parse_flags "$flags")
      fi

      mapfile -t matches < <(match_items "$pattern")
      [ "${#matches[@]}" -eq 0 ] && { dlog "No matches for '${white2}$pattern${xx}'"; continue; }

      declare -A rule_dest_map=()
      declare -A rule_src_for_dest=()
      colliding=0

      for src in "${matches[@]}"; do
        if [ -z "${src:-}" ]; then
          dlog "Empty src for pattern '${white2}$pattern${xx}' — skipping this match."
          continue
        fi
        if is_drop_root "$src"; then
          warn "Refusing to act on drop root: ${white2}$src${xx}"
          continue
        fi
        if is_ads_junk "$src"; then
          dlog "Ignoring ADS/attachment artefact: ${white2}$src${xx}"
          continue
        fi

        if [ -f "$src" ]; then
          base="${src##*/}"; ext="${base##*.}"
          if [ "${ext,,}" = "zip" ] && [ "$EXTRACT" = "true" ]; then
            dst_path="$(extract_dir_for_zip "$src" "$destx" "$alias")"
          else
            dst_path="$(dest_path_for_file "$src" "$destx" "$alias")"
          fi
        elif [ -d "$src" ]; then
          if [ "$alias" = "self" ]; then
            dst_path="$destx/"
          else
            dst_path="$(dest_path_for_dir "$src" "$destx" "$alias")"
          fi
        else
          dlog "Skipping unknown type: ${white2}$src${xx}"
          continue
        fi

        key="$dst_path"
        if [[ -n "${rule_dest_map[$key]:-}" ]]; then
          colliding=1
          prev="${rule_src_for_dest[$key]}"
          err "Collision in rule -> dest ${white2}$key${xx} from:"
          echo "  ${grey}- ${white2}$prev${xx}"
          echo "  ${grey}- ${white2}$src${xx}"
        else
          rule_dest_map["$key"]=1
          rule_src_for_dest["$key"]="$src"
        fi
      done

      for key in "${!rule_dest_map[@]}"; do
        src="${rule_src_for_dest[$key]}"
        if [ -z "${src:-}" ]; then continue; fi
        dst_path="$key"
        _touched["$src"]=1 || true

        repo="$(git_root_for "$destx")"; [ -n "$repo" ] && ensure_git_safe "$repo" "$SAFE"
        mkdir -p "$destx"

        if [ -f "$src" ]; then
          base="${src##*/}"; ext="${base##*.}"
          if [ "${ext,,}" = "zip" ] && [ "$EXTRACT" = "true" ]; then
            note "Extract: ${white2}$src${xx} -> ${white2}$dst_path${xx}"
            do_unzip "$src" "$dst_path"
          else
            note "Transfer (${blue2}$MODE${xx}): ${white2}$src${xx} -> ${white2}$dst_path${xx}"
            do_transfer "$src" "$dst_path" "$MODE"
          fi
        elif [ -d "$src" ]; then
          if [ "$alias" = "self" ]; then
            note "Transfer dir (${blue2}$MODE${xx}): ${white2}$src${xx} -> ${white2}$destx/${xx}"
            do_transfer "$src" "$destx" "$MODE"
          else
            note "Transfer dir (${blue2}$MODE${xx}): ${white2}$src${xx} -> ${white2}$dst_path${xx}"
            do_transfer "$src" "$dst_path" "$MODE"
          fi
        fi
      done

      if [ "$colliding" -eq 1 ]; then
        err "One or more destinations collided for pattern '${white2}$pattern${xx}'. Non-colliding items were processed; colliding ones were skipped."
      fi

      unset rule_dest_map rule_src_for_dest colliding key src dst_path prev base ext
    done < "$mf"
  done

  report_untracked
}

report_untracked(){
  local saved
  saved="$(pwd)"
  cd "$SRC_DIR"
  local all=(*)
  cd "$saved"
  for item in "${all[@]:-}"; do
    local full="$SRC_DIR/$item"
    [[ "$item" == *manifest.rc ]] && continue
    [[ "$item" == . || "$item" == .. ]] && continue
    is_ads_junk "$full" && continue
    if [[ -z "${_touched[$full]:-}" ]]; then
      log "Untracked in drop: ${white2}$full${xx} ${grey}(no matching rule)${xx}"
    fi
  done
}

# ---------- signatures (same as v4) ----------
drop_signature(){
  local saved
  saved="$(pwd)"
  cd "$SRC_DIR"
  while IFS= read -r -d '' p; do
    if [ -d "$p" ]; then t="d"; else t="f"; fi
    sz="$(stat -c %s "$p" 2>/dev/null || stat -f %z "$p")"
    mt="$(stat -c %Y "$p" 2>/dev/null || stat -f %m "$p")"
    printf "%s|%s|%s|%s\n" "$(basename "$p")" "$t" "$sz" "$mt"
  done < <(find . -maxdepth 1 -mindepth 1 -print0)
  cd "$saved" >/dev/null 2>&1
}

manifest_signature(){
  mapfile -t mfs < <(collect_manifests)
  if [ "${#mfs[@]}" -eq 0 ]; then echo "NONE"; return; fi
  for f in "${mfs[@]}"; do
    if [ -f "$f" ]; then
      printf "%s:%s:%s\n" "$f" "$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")" "$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f")"
    fi
  done | sort
}

LAST_DROP_SIG="$(drop_signature || true)"
LAST_MANIF_SIG="$(manifest_signature || true)"

process_once || true
[ "$ONCE" -eq 1 ] && exit 0

echo "${grey}[${xx}$(ts)${grey}]${xx} ${purple}WSL-friendly watch${xx} ${white2}$SRC_DIR${xx} ${grey}(signature every ${POLL_SEC}s). Ctrl-C to stop.${xx}"
while sleep "$POLL_SEC"; do
  CUR_DROP_SIG="$(drop_signature || true)"
  CUR_MANIF_SIG="$(manifest_signature || true)"
  if [ "$CUR_DROP_SIG" != "$LAST_DROP_SIG" ] || [ "$CUR_MANIF_SIG" != "$LAST_MANIF_SIG" ]; then
    process_once || true
    LAST_DROP_SIG="$CUR_DROP_SIG"
    LAST_MANIF_SIG="$CUR_MANIF_SIG"
  fi
done
