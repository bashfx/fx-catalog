#!/usr/bin/env bash

#-------------------------------------------------------------------------------
 
 # end/unsource by exporting CLEANUP_GLOBAL=1;     
 if [ -z "$CLEANUP_GLOBAL" ]; then
      
    # Load if not already defined
    [[ "$(declare -p _GLOBAL 2>/dev/null)" =~ "declare -A" ]] || { 
      declare -gA _GLOBAL; 
       if [[ -z ${_GLOBAL[_SSID_]:-} ]]; then
        _GLOBAL[_SSID_]="$$"; 
        _GLOBAL[_INIT_]=$(date +%s);
        stdprint "GLOBAL was initiated. (${_GLOBAL[_SSID_]})" "blue";
      fi
    }

    # Set default state file using XDG
    : "${XDG_STATE_HOME:=$HOME/.local/state}"
    GLOBAL_RC_FILE="$XDG_STATE_HOME/glb/glob.env"
    mkdir -p "$XDG_STATE_HOME/glb";      

    set_glob(){ _GLOBAL["$1"]="$2"      || return 1; }
    rem_glob(){ unset "_GLOBAL[$1]"     || return 1; }
    get_glob(){ echo "${_GLOBAL["$1"]}" || return 1; }

    glob_uptime(){
      local now=$(date +%s)
      local then=${_GLOBAL[init]:-0}
      local delta=$((now - then))

      # Format delta into human-readable time
      local d=$((delta/86400))
      local h=$(( (delta%86400)/3600 ))
      local m=$(( (delta%3600)/60 ))
      local s=$((delta%60))

      printf "Uptime: %d days, %02d:%02d:%02d\n" "$d" "$h" "$m" "$s"
    }
    
    glob_filter() {
      local pat="${1:-*}"
      for k in "${!_GLOBAL[@]}"; do
        [[ "$pat" == "*" || "$k" == $pat ]] && printf "%s=%q\n" "$k" "${_GLOBAL[$k]}"
      done
    }
    
    # --- copy key=value lines into a given assoc array by nameref ---
    glob_copy_to() {
      local line k v
      local -n dest="$1"
      while IFS='=' read -r k v; do
        [[ -n $k ]] && dest["$k"]="${v//\"/}"
      done
    }
    
    # --- save a given assoc array to file ---
    glob_save_map() {
      local -n src="$1"
      local file="$2"
      [[ -z $file ]] && return 1
      mkdir -p "$(dirname "$file")"
      : > "$file"
      for k in "${!src[@]}"; do
        printf '%s=%q\n' "$k" "${src[$k]}" >> "$file"
      done
    }
        
    # --- load a .env-style file into _GLOBAL (optionally filtered) ---
    glob_load_env_file() {
      local file="$1" pat="${2:-*}"
      [[ -f $file ]] || return 1
      while IFS='=' read -r k v; do
        [[ -z $k ]] && continue
        [[ "$pat" == "*" || "$k" == $pat ]] && _GLOBAL["$k"]="${v//\"/}"
      done < "$file"
    }
  
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


        
    glob(){
      local cmd="${1:-}" key="${2:-}" val="${3:-}" file;
      local ssid="${_GLOBAL[_SSID_]}"; 
      local uptime="$(glob_uptime)";
      case "$cmd" in
        (set)  _GLOBAL["$key"]="$val"; ;;
        (get)  echo "${_GLOBAL[$key]}"; ;;
        (init) date -d "@${_GLOBAL[_INIT_]}"; ;;
        (uptime)  echo "$uptime";
        (ls)   for k in "${!_GLOBAL[@]}"; [[ $k == "$key"* ]] && echo "$k"; ;;
        (sufx) for k in "${!_GLOBAL[@]}"; [[ $k == *"$key" ]] && echo "$k"; ;;
        (rm)   for k in "${!_GLOBAL[@]}"; [[ $k == "$key"* ]] && unset "_GLOBAL[$k]"; ;;
        (dump) for k in "${!_GLOBAL[@]}"; echo "$k=${_GLOBAL[$k]}" | sort; ;;
        (zap)   unset _GLOBAL; declare -gA _GLOBAL; ;;
        (reset) unset _GLOBAL; mv "$GLOBAL_RC_FILE" "${GLOBAL_RC_FILE}.${ssid:-$key}.bak" || return 1; ;;
        (save)
          file=${key:-$GLOBAL_RC_FILE};
          : > "$file"
          for k in "${!_GLOBAL[@]}"; do
            printf '%s=%q\n' "$k" "${_GLOBAL[$k]}" >> "$file";
          done
          echo "Saved to $file";
          ;;
        (import)
          file=${key:-$GLOBAL_RC_FILE};
          [[ -f "$file" ]] || return 1
          while IFS='=' read -r k v; do
            [[ -n $k ]] && _GLOBAL["$k"]="${v//\"/}";
          done < "$file"
          stdprint "Loaded from $file" "blue";
          ;;
        (*) stdprint "Usage: glob {set|get|ls|sufx|age|rm|dump|zap|reset|save|import} [key] [val]"; ;;
      esac
      _GLOBAL[_LAST_]=$(date +%s);
    }
    
 else
    gssid="${_GLOBAL[_SSID_]}";
    gtime="${_GLOBAL[_INIT_]}";
    glast="${_GLOBAL[_LAST_]}";
    gbak="${GLOBAL_RC_FILE}.${gssid}.bak";
    guptime=$(glob_uptime);
    glob reset;
    stdprint "GLOBAL $(guptime)"
    stdprint "GLOBAL is now being cleaned up."
    [ -f "$gbak" ] && stdprint "Backup left at ($gbak)";
    unset -f "set_glob" &> /dev/null;
    unset -f "rem_global" &> /dev/null;
    unset -f "get_global" &> /dev/null;
    unset -f "glob" &> /dev/null;
    unset -f "glob_uptime"  &> /dev/null;
    unset gssid gtime glast gbak guptime;
 fi
