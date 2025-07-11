#!/usr/bin/env bash
#===============================================================================
#   __ _             _
#  / _| | __ _  __ _| |__   __ _ ___  ___
# | |_| |/ _` |/ _` | '_ \ / _` / __|/ _ \
# |  _| | (_| | (_| | |_) | (_| \__ \  __/
# |_| |_|\__,_|\__, |_.__/ \__,_|___/\___|
#              |___/
#
#-------------------------------------------------------------------------------
#$ name:fx-flagbase (kvfb)
#$ author:qodeninja
#$ date:
#$ semver:
#$ autobuild: 00008
#
#
# Note
# - very alpha version!
# - mac systems with bash 4+ support, not tested on general *nix
# - not fully tested/cleanedup may not be suitable 
#   for systems that have low error tolerance (e.g. critical)
# - some general testing for primary use case, edges cases likely to fail
# - forcing paths for "safety", if you want to override paths have to
#   manually do it.
#
#
#=====================================code!=====================================
#-------------------------------------------------------------------------------
# Version
#-------------------------------------------------------------------------------
# The script has been updated to support Bash 3.2+ (e.g., default macOS bash)
# if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
#   echo "Bash version 4.0 or higher is required"
#   exit 1
# fi

#-------------------------------------------------------------------------------
# Customizable Vars (change in your .profile not here)
#-------------------------------------------------------------------------------

FLAGX_HOME=${FLAGX_HOME:-"$HOME/.my/etc/fx/flags"}
FLAGX_CURSOR_HOME=${FLAGX_CURSOR_HOME:-"$HOME/.flagx"}
FLAGX_EXPORT_PATH=${FLAGX_EXPORT_PATH:-"$HOME/exports"}

#-------------------------------------------------------------------------------
# System Vars
#-------------------------------------------------------------------------------

SESSION_DIR="$FLAGX_HOME/session.d"
KEYFILE_DIR="$FLAGX_HOME/keyfile.d"
PRIVATE_DIR="$FLAGX_HOME/private.d"
ACTIVE_SESSION_FILE="$FLAGX_CURSOR_HOME"

session_id=
opt_debug=0

#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------

  red=$(tput setaf 1)
  green=$(tput setaf 2)
  blue=$(tput setaf 39)
  blue2=$(tput setaf 27)
  cyan=$(tput setaf 14)
  orange=$(tput setaf 214)
  yellow=$(tput setaf 226)
  purple=$(tput setaf 213)
  white=$(tput setaf 248)
  white2=$(tput setaf 15)
  grey=$(tput setaf 244)
  grey2=$(tput setaf 245)
  revc=$(tput rev)
  x=$(tput sgr0)
  eol="$(tput el)"
  bld="$(tput bold)"
  line="##---------------$nl"
  tab=$'\\t'
  nl=$'\\n'

  delta="\xE2\x96\xB3"
  pass="\xE2\x9C\x93"
  fail="${red}\xE2\x9C\x97"
  star="\xE2\x98\x85"
  lambda="\xCE\xBB"
  idots="\xE2\x80\xA6"


  __logo(){
    if [ -z "$opt_quiet" ] || [ $opt_quiet -eq 1 ]; then
      local logo=$(sed -n '3,9 p' "$BASH_SOURCE")
      printf "\n$blue${logo//#/ }$x\n" 1>&2;
    fi
  }

  __printf(){
    local text color prefix
    text=${1:-}; color=${2:-white2}; prefix=${!3:-};
    [ -n "$text" ] && printf "${prefix}${!color}%b${x}" "${text}" 1>&2 || :
  }


  warn(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$delta $text$x\n" "orange"; }
  okay(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$pass $text$x\n" "green"; }
  info(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] && __printf "$lambda $text\n" "blue"; }

  trace(){ local text=${1:-}; [ $opt_trace -eq 0 ] && __printf "$idots $text\n" "grey"; }
  error(){ local text=${1:-}; __printf " $text\n" "fail"; }
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }


  options(){
    # Set defaults
    opt_admin=1; opt_quiet=1; opt_trace=1; opt_env=1

    # Use a while loop to consume flags, leaving only commands/args
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --admin|-A)
          opt_admin=0
          shift
          ;;
        --envfile|-E)
          opt_env=0
          shift
          ;;
        --quiet|-q)
          opt_quiet=0
          shift
          ;;
        --tra*|-t)
          opt_trace=0
          shift
          ;;
        --debug|-d)
          opt_debug=0
          shift
          ;;
        *)
          # Not an option, break the loop
          break
          ;;
      esac
    done
  }


#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------
    
  command_exists(){ type "$1" >/dev/null 2>&1; }

  handle_interupt(){ E="$?";  kill 0; exit $E; }
  handle_stop(){ kill -s SIGSTOP $$; }
  handle_input(){ [ -t 0 ] && stty -echo -icanon time 0 min 0; }
  cleanup(){ [ -t 0 ] && stty sane; }

  fin(){
      local E="$?"; cleanup
      if [ -z "$opt_quiet" ]; then
         [ $E -eq 0 ] && __printf "${green}${pass} ${1:-Done}." \
                      || __printf "$red$fail ${1:-${err:-Cancelled}}."
      fi
  }

  trap handle_interupt INT
  trap handle_stop SIGTSTP
  trap handle_input CONT
  trap fin EXIT
  #trap 'echo "An unhandled error occurred!"; exit 1' ERR


#-------------------------------------------------------------------------------
# Helpers
#-------------------------------------------------------------------------------


stderr(){ printf "${@}${x}\n" 1>&2; }

generate_session_id() {
  # Using /dev/urandom for better portability than openssl
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1
}

# generate_session_id() {
#   openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1
# }

handle_error() {
  echo "Error: $1" >&2
  exit 1
}

is_locked() {
  [[ $1 =~ ^__.*__$ ]]
}

trim_locked(){
  local string="$1"
  trimmed="${string#__}"
  trimmed="${trimmed%%__}"
  echo "$trimmed"
}

is_valid_key() {
  [[ $1 =~ ^[a-zA-Z0-9_]+$ ]]
}

rm_active(){
  if [[ -f "$ACTIVE_SESSION_FILE" ]]; then
    rm -f "$ACTIVE_SESSION_FILE"
  fi
}



has_sessions(){
  if [[ -d "$SESSION_DIR" ]]; then
    local session_files=("$SESSION_DIR"/*)
    # Check if the glob expanded to at least one existing file.
    if [[ ${#session_files[@]} -gt 0 && -e "${session_files[0]}" ]]; then
      return 0
    fi
  fi
  return 1
}

get_current_session() {
  if has_sessions; then
    if [[ -f $ACTIVE_SESSION_FILE ]]; then
      cat "$ACTIVE_SESSION_FILE"
      return 0
    fi
  fi
  return 1
}


update_session(){
  local this_id="$1"
  if [[ -n "$this_id" ]]; then
    info "session -> ${this_id}"
    session_id="$this_id"
    echo "$this_id" > "$ACTIVE_SESSION_FILE"
  else
    handle_error "Missing session id"
  fi
}


switch_session() {
  local next_id="$1"
  if [[ -f "$SESSION_DIR/$next_id" ]]; then
    #echo "$next_id" > "$ACTIVE_SESSION_FILE"
    if [[ ! -d "$KEYFILE_DIR/$next_id" ]]; then
      mkdir -p "$KEYFILE_DIR/$next_id"
    fi
    update_session "$next_id"
  else
    handle_error "Session $next_id does not exist"
  fi
}


new_session() {
  local alt_id=$(generate_session_id)
  local next_id=${1:-$alt_id}
  #info "New session id is $next_id"
  touch "$SESSION_DIR/$next_id" || handle_error "Failed to create session file"
  mkdir -p "$KEYFILE_DIR/$next_id" || handle_error "Failed to create session keyfile directory"
  #echo "$next_id" > "$ACTIVE_SESSION_FILE"
  update_session "$next_id" #<---this is the switch
}



initialize_environment() {
  mkdir -p "$FLAGX_HOME" "$SESSION_DIR" "$KEYFILE_DIR" "$PRIVATE_DIR" || handle_error "Failed to create required directories"
  local root_session='main'
  if ! has_sessions; then
    info "No sessions found. Creating initial session: '$root_session'"
  fi
  new_session "$root_session"
  # Auto clean temporary files in the current session
  handle_auto_clean
}

load_session(){
  local this_id=$(get_current_session)
  if [[  -z "$this_id" ]]; then
    initialize_environment
  else
    update_session "$this_id"
  fi
}

# @todo : handle exists review

handle_exists() {
  local key="$1"
  local key_type="$2" # 'normal' or 'locked'
  local keypath

  if [[ $key_type == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi

  if [[ -f "$keypath" ]]; then
    return 0 # Success, key exists
  fi
  return 1 # Failure, key does not exist
}

# @todo : handle_source review

handle_source() {
  local session_id=$(get_current_session)
  
  # Source session keys
  for file in "$KEYFILE_DIR/$session_id"/*; do
    if [[ -f "$file" ]]; then
      local key=$(basename "$file")
      # Ensure key is a valid shell variable name
      if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        local value=$(cat "$file")
        printf "export %s=\"%s\"\n" "$key" "$value"
      fi
    fi
  done

  # Source locked keys
  for file in "$PRIVATE_DIR"/*; do
    if [[ -f "$file" ]]; then
      local locked_key=$(basename "$file")
      local key=$(trim_locked "$locked_key")
      # Ensure key is a valid shell variable name
      if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        local value=$(cat "$file")
        printf "export %s=\"%s\"\n" "$key" "$value"
      fi
    fi
  done
}


# @todo : handle_help review

handle_help() {
  __logo
  cat << EOF
A file-system-based key-value store for shell scripts.

Usage:
  flagbase [options] <command> [arguments...]

Commands:
  help                            Show this help message
  source                          Print keys as 'export' statements for sourcing

  read|read_lock <key>            Read a key's value
  write|write_lock <key> <value>  Write a value to a key
  delete|delete_lock <key>        Delete a key
  exists|exists_lock <key>        Check if a key exists (uses exit code)
  ls|ls_lock                      List keys
  ... and many more. See the source for a full list of utility commands.
EOF
}




handle_list_sessions() {
  local active_session=$(get_current_session)
  local session_files=("$SESSION_DIR"/*)

  # Check if the glob failed to find any files
  if [[ ${#session_files[@]} -eq 1 && ! -e "${session_files[0]}" ]]; then
    echo "No sessions available."
    return
  fi


  echo "Available sessions:"
  local i=1
  for session_file in "${session_files[@]}"; do
    local session_id=$(basename "$session_file")
    if [[ "$session_id" == "$active_session" ]]; then
      echo -e "$i) \033[32m$session_id\033[0m (active)"  # Green color for active session
    elif [[ "$session_id" != "active" ]]; then
      echo "$i) $session_id"
    fi
    ((i++))
  done
}


handle_select_session_by_index() {

  local index="$1"
  local session_files=("$SESSION_DIR"/*)

  # Check if the glob found any files before proceeding
  if [[ ${#session_files[@]} -gt 0 && -e "${session_files[0]}" ]]; then

    if [[ -z "$index" ]]; then
      handle_list_sessions
      echo "Please select a session index:"
      read index
    fi


    if (( index < 1 || index > ${#session_files[@]} )); then
      handle_error "Invalid session index"
      return
    fi

    local selected_session_file=${session_files[$((index - 1))]}
    local this_id=$(basename "$selected_session_file")

    switch_session "$this_id"

  else
    error "No sessions available."
  fi
}



get_locked_keyfile_path() {
  local key="__${1}__"
  echo "$PRIVATE_DIR/$key"
}

get_keyfile_path() {
  local key="$1"
  local this_id=$(get_current_session)
  echo "$KEYFILE_DIR/$this_id/$key"
}

get_appropriate_keyfile_path() {
  local key="$1"
  if is_locked "$key"; then
    get_locked_keyfile_path "$key"
  else
    get_keyfile_path "$key"
  fi
}

handle_lock() {
  local normal_keypath=$(get_keyfile_path "$1")
  local locked_keypath=$(get_locked_keyfile_path "$1")

  if [[ -f "$normal_keypath" ]]; then
    mv "$normal_keypath" "$locked_keypath" || handle_error "Failed to lock key"
  else
    handle_error "Key to lock does not exist"
  fi
}

handle_unlock() {
  local locked_keypath=$(get_locked_keyfile_path "$1")
  local normal_keypath=$(get_keyfile_path "$1")

  if [[ -f "$locked_keypath" ]]; then
    mv "$locked_keypath" "$normal_keypath" || handle_error "Failed to unlock key"
  else
    handle_error "Locked key does not exist"
  fi
}









handle_toggle() {
  local key="$1"
  local keypath=$(get_appropriate_keyfile_path "$key")

  if [[ ! -f "$keypath" ]]; then
    handle_error "Key does not exist"
    return
  fi

  local value=$(cat "$keypath")
  case "$value" in
    "0")
      echo "1" > "$keypath"
      ;;
    "1")
      echo "0" > "$keypath"
      ;;
    "true")
      echo "false" > "$keypath"
      ;;
    "false")
      echo "true" > "$keypath"
      ;;
    *)
      handle_error "Key value is not toggleable"
      ;;
  esac
  val=$(cat "$keypath")
  okay "Key '$key' toggled to $val"
}


# Revised handle_write function
handle_write() {
  local key="$1"
  local value="$2"
  local key_type="$3"  # 'normal' or 'locked'
  local keypath
  if [[ $key_type == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi
  info "$key -> $value"
  echo "$value" > "$keypath" || handle_error "Failed to write key"
}


handle_read() {
  local key="$1"
  local key_type="$2"  # 'normal' or 'locked'

  local keypath
  if [[ $key_type == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi

  [[ -f "$keypath" ]] && cat "$keypath" || handle_error "Key does not exist"
}


handle_delete() {
  local key="$1"
  local key_type="$2"  # 'normal' or 'locked'

  local keypath
  if [[ $key_type == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi

  rm -f "$keypath" || handle_error "Failed to delete key"
}

handle_new() {
  local key="$1"
  local key_type="$2"  # 'normal' or 'locked'

  local keypath
  if [[ $key_type == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi

  [[ ! -f "$keypath" ]] && touch "$keypath" || handle_error "Key already exists"
}

handle_write_safe() {
  local key="$1"
  local value="$2"
  local key_type="$3"  # 'normal' or 'locked'

  local keypath
  if [[ $key_type == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi

  # Backup existing file, if it exists
  if [[ -f "$keypath" ]]; then
    local backup_path="${keypath}.old.$(date +%s)"
    mv "$keypath" "$backup_path" || handle_error "Failed to backup existing key"
  fi

  echo "$value" > "$keypath" || handle_error "Failed to write key safely"
}

handle_ls() {
  local key_type="$1"  # 'normal' or 'locked'
  local dir_path
  if [[ $key_type == "locked" ]]; then
    dir_path="$PRIVATE_DIR"
  else
    dir_path="$KEYFILE_DIR/$session_id"
  fi

  if [ ! "$(ls -A "$dir_path")" ]; then
     info "No keys found in this location."
     return
  fi

  ls "$dir_path" || handle_error "Failed to list keys"
}

handle_hist() {
  local key="$1"
  local key_type="$2"
  local keypath

  if [[ "$key_type" == "locked" ]]; then
    keypath=$(get_locked_keyfile_path "$key")
  else
    keypath=$(get_keyfile_path "$key")
  fi

  info "History for key '$key' (created by 'write_safe'):"
  local history_files=("$keypath.old."*)
  if [[ ! -e "${history_files[0]}" ]]; then
    warn "No history found for this key."
    return
  fi

  for file in "${history_files[@]}"; do
    local timestamp=$(echo "$file" | sed 's/.*\.old\.//')
    local formatted_date=$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S")
    local value=$(cat "$file")
    printf "  [%s] %s\n" "$formatted_date" "$value"
  done
}



handle_clean() {

  find "$KEYFILE_DIR/$session_id" -name '*old*' -delete || handle_error "Failed to clean old files"
  find "$KEYFILE_DIR/$session_id" -name '_*' -delete || handle_error "Failed to clean temporary files"
}

handle_reset() {
  rm -rf "$KEYFILE_DIR/$session_id"/* || handle_error "Failed to reset session"
}


handle_auto_clean() {
  find "$KEYFILE_DIR/$session_id" -name '_*' -delete || handle_error "Failed to auto clean temporary files"
}

handle_nuke() {
  rm -rf "$KEYFILE_DIR"/* || handle_error "Failed to nuke keyfile directory"
  rm -rf "$SESSION_DIR"/* || handle_error "Failed to nuke session directory"
  rm -rf "$PRIVATE_DIR"/* || handle_error "Failed to nuke private directory"
  rm_active
  if [[ $1 == "all" ]]; then
    rm -rf "$FLAGX_HOME"
  else
    # Reinitialize environment after nuking
    initialize_environment
  fi
}

handle_nuke_all(){
  error "Deleting all fx/flags data!"
  handle_nuke "all"
}

handle_export() {

  local session_id=$(get_current_session)
  local export_file="$FLAGX_EXPORT_PATH/flagfile.log"
  
  warn "Flagx export home -> [$FLAGX_EXPORT_PATH]"
  if [ ! -d "$FLAGX_EXPORT_PATH" ]; then
    mkdir -p "$FLAGX_EXPORT_PATH"
  fi

  if [ $opt_env -eq 0 ]; then 
    export_file="$FLAGX_EXPORT_PATH/flagfile.env"
  fi

  if [ -f $export_file ]; then
    rm "$export_file"
  fi
  warn "Flagx export file -> [$export_file]"

  # Export session keys
  if [ $opt_env -eq 1 ]; then 
    warn "Flagx running session export mode."
    for file in "$KEYFILE_DIR/$session_id"/*; do
      if [[ -f "$file" ]]; then
        local key=$(basename "$file")
        local value=$(cat "$file")
        echo "$key=$value" >> $export_file
      fi
    done
  else
    warn "Flagx running in ENV export mode."
  fi

  # Export locked keys
  for file in "$PRIVATE_DIR"/*; do
    if [[ -f "$file" ]]; then
      local locked_key=$(basename "$file")

      if [ $opt_env -eq 0 ]; then 
        locked_key=$(trim_locked "$locked_key" )
      fi

      local value=$(cat "$file")
      #echo "$locked_key=$(cat "$file")"
      echo "$locked_key=$value" >> "$export_file"
    fi
  done
}


handle_import() {
  local import_file="$1"

  while IFS= read -r line; do
    if [[ $line =~ ^([a-zA-Z0-9_]+)="([^\"]*)"$ ]]; then
      # Value in quotes
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
    elif [[ $line =~ ^([a-zA-Z0-9_]+)=([^[:space:]]+)$ ]]; then
      # Value without quotes (no whitespace allowed)
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
    else
      echo "Invalid line in import file: $line"
      # Optionally, halt the import or continue
      # return 1  # Uncomment to stop import on error
      continue
    fi

    if is_locked "$key"; then
      local keypath=$(get_locked_keyfile_path "$key")
    else
      local session_id=$(get_current_session)
      local keypath="$KEYFILE_DIR/$session_id/$key"
    fi

    echo "$val" > "$keypath"
  done < "$import_file"
}


dispatch(){

# Dispatcher
command=$1
keyfile="$2"

local op_type="normal"
local base_command="$command"

if [[ "$command" == *_lock ]]; then
  op_type="locked"
  base_command="${command%_lock}"
fi

case $base_command in
  # Core Operations
  write) handle_write "$keyfile" "$3" "$op_type" ;;
  read) handle_read "$keyfile" "$op_type" ;;
  delete) handle_delete "$keyfile" "$op_type" ;;
  new)
    if [[ -z "$keyfile" ]]; then
      new_session
    else
      handle_new "$keyfile" "$op_type"
    fi
    ;;
  exists) handle_exists "$keyfile" "$op_type" ;;
  ls) handle_ls "$op_type" ;;
  write_safe) handle_write_safe "$keyfile" "$3" "$op_type" ;;
  hist) handle_hist "$keyfile" "$op_type" ;;

  # Session Management
  switch) switch_session "$keyfile" ;;
  lss) handle_list_sessions ;;
  ids) handle_select_session_by_index "$keyfile" ;;

  # Utility Operations
  lock) handle_lock "$keyfile" ;;
  unlock) handle_unlock "$keyfile" ;;
  clean) handle_clean ;;
  reset) handle_reset ;;
  nuke) handle_nuke ;;
  nukeall) handle_nuke_all ;;
  export) handle_export "$keyfile" ;;
  import) handle_import "$keyfile" ;;
  toggle) handle_toggle "$keyfile" ;;

  # Meta
  help|--help|-h) handle_help ;;
  source) handle_source ;;

  *)
    echo "Invalid command: $command"
    handle_help
    return 1
    ;;
  esac

}

main(){
  __logo
  load_session
  dispatch "$@";ret=$?
}

#-------------------------------------------------------------------------------


  if [ "$0" = "-bash" ]; then
    :
  else
    
    # Process flags, which are shifted off the argument list by options()
    options "$@"

    # The remaining arguments are passed to main
    main "$@"; ret=$?
  fi
