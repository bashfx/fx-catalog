#!/usr/bin/env bash

#-------------------------------------------------------------------------------


    # -- stream filtered keys into sub-assoc via name
    glob_pipe() {
      local op="$1" pat="$2" target="$3" file="$4"
      case "$op" in
        to)   # stream to another map
          declare -n dest="$target"
          glob_filter "$pat" | while IFS='=' read -r k v; do
            [[ -n $k ]] && dest["$k"]="${v//\"/}"
          done
          ;;
        from) # import keys from env file
          [[ -f "$file" ]] || return 1
          while IFS='=' read -r k v; do
            [[ "$pat" == "*" || "$k" == $pat ]] && _GLOBAL["$k"]="${v//\"/}"
          done < "$file"
          ;;
        save) # save a subset to env file
          : > "$file"
          glob_filter "$pat" > "$file"
          ;;
        *) echo "Usage: glob_pipe {to|from|save} pattern target [file]"; return 1 ;;
      esac
    }

    glob_session() {
      local cmd="${1:-}" path="${XDG_STATE_HOME:-$HOME/.local/state}/glb/login.d"
      local file subglob k v

      case "$cmd" in
        init)
          mkdir -p "$path"
          for file in "$path"/*.env; do
            [[ -f "$file" ]] || continue
            subglob="$(basename "$file" .env)"
            declare -gA "$subglob"
            declare -n ref="$subglob"
            while IFS='=' read -r k v; do
              [[ -n "$k" ]] && ref["$k"]="${v//\"/}"
            done < "$file"
            _GLOBAL["__session_loaded__$subglob"]=1
            stdprint "Loaded session: $subglob" blue
          done
          ;;
        save)
          for subglob in $(compgen -A variable | grep '^_'); do
            declare -n ref="$subglob"
            [[ "$(declare -p "$subglob" 2>/dev/null)" =~ "declare -A" ]] || continue
            file="$path/${subglob}.env"
            : > "$file"
            for k in "${!ref[@]}"; do
              printf '%s=%q\n' "$k" "${ref[$k]}" >> "$file"
            done
            stdprint "Saved session: $subglob → $file" green
          done
          ;;
        zap)
          for subglob in $(compgen -A variable | grep '^_'); do
            declare -n ref="$subglob"
            [[ "$(declare -p "$subglob" 2>/dev/null)" =~ "declare -A" ]] || continue
            unset "$subglob"
            stdprint "Zapped: $subglob" red
          done
          ;;
        *) echo "Usage: glob_session {init|save|zap}" ;;
      esac
    }

