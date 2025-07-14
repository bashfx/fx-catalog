#!/usr/bin/env bash

# KNIFE: Modular file utility for structured file introspection and manipulation

# --- Globals ---
KNOWN_FILES_FILE="$HOME/.knife_known"
HISTORY_FILE="$HOME/.knife_history"
BACKUP_SUFFIX=".bak"

# Safety and Development Modes
# Set to any non-empty value to disable interactive prompts for destructive ops.
DANGER_MODE="" # Example: DANGER_MODE="1"
# Set to any non-empty value to bypass initial DANGER_MODE warning prompt and enable recursive search anywhere.
DEV_MODE=""    # Example: DEV_MODE="1"

# Directories to exclude from recursive searches (case-sensitive)
KNIFE_EXCLUDES=(
  ".git"
  "node_modules"
  "target"
  "dist"
  "build"
  "vendor"
)

# --- Color Definitions ---
red=$'\x1B[31m';
orange=$'\x1B[38;5;214m';
green=$'\x1B[32m';
blue=$'\x1B[36m';
RESET=$'\x1B[0m';

# --- Utility Functions (Internal & External) ---

# Global variables to store paths to external commands once checked
REALPATH_CMD=""
MD5_CMD="" # Will be md5sum or md5
COLUMN_CMD=""
DATE_CMD="" # Will be date (GNU or BSD)

# Logs messages to stderr
stderr() { printf "%s\n" "$@" >&2; }

# Standardized return codes
knife_success() { return 0; }
knife_fail() { return 1; }

# Colorized logging functions (messages to stderr)
error() { stderr "${red}$1${RESET}"; knife_fail; } # Note: knife_fail does not exit, sets return code
warn()  { stderr "${orange}$1${RESET}"; }
okay()  { stderr "${green}$1${RESET}"; }
info()  { stderr "${blue}$1${RESET}"; }

# Checks if a command exists and stores its path in a global variable
__check_utility() {
  local cmd_name="$1"
  local global_var_name="$2"
  local cmd_path=""

  if command -v "$cmd_name" >/dev/null 2>&1; then
    cmd_path=$(command -v "$cmd_name")
  fi
  eval "$global_var_name=\"$cmd_path\"" # Set the global variable
}

# Checks for all required external dependencies at startup
__check_all_dependencies() {
  local missing_critical=0

  # Check for md5sum/md5
  __check_utility "md5sum" "MD5_CMD"
  if [[ -z "$MD5_CMD" ]]; then
    __check_utility "md5" "MD5_CMD" # Try macOS md5
  fi
  if [[ -z "$MD5_CMD" ]]; then
    error "Missing critical utility: md5sum or md5 (for hashing). Please install one."
    missing_critical=1
  fi

  # Check for realpath/greadlink/readlink -f
  __check_utility "realpath" "REALPATH_CMD"
  if [[ -z "$REALPATH_CMD" ]]; then
    __check_utility "greadlink" "REALPATH_CMD" # macOS GNU readlink
  fi
  # Fallback for readlink -f (standard readlink might not have -f)
  if [[ -z "$REALPATH_CMD" ]]; then
      if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then
          REALPATH_CMD=$(command -v readlink)
      fi
  fi
  if [[ -z "$REALPATH_CMD" ]]; then
    error "Missing critical utility: realpath or readlink -f (for canonical paths). Please install one."
    missing_critical=1
  fi

  # Check for date (for history formatting)
  __check_utility "date" "DATE_CMD"
  if [[ -z "$DATE_CMD" ]]; then
    error "Missing critical utility: date (for history timestamps). Please install."
    missing_critical=1
  fi

  # Check for column (non-critical, for history formatting)
  __check_utility "column" "COLUMN_CMD"
  if [[ -z "$COLUMN_CMD" ]]; then
    warn "Optional utility 'column' not found. History output may not be aligned."
  fi

  if [[ "$missing_critical" -eq 1 ]]; then
    exit 1 # Exit if critical dependencies are missing
  fi
  knife_success
}

# Helper to check if a file exists and report error if not
__check_file_exists_or_fail() {
  local file="$1"
  if [[ -f "$file" ]]; then
    knife_success
  else
    error "File not found: $file"
    knife_fail
  fi
}

# Checks if a file exists and is a shell script or .rc file
_is_shell_or_rc() {
  local file="$1"
  __check_file_exists_or_fail "$file" || return 1
  # Check for shebang OR common RC file extensions/names
  grep -qE '^#!.*sh' "$file" || [[ "$(basename "$file")" =~ (\.rc|\.profile|\.bashrc|\.zshrc)$ ]] || [[ "$(basename "$file")" =~ ^\.rc[a-zA-Z0-9_]*$ ]]
}

# Creates a backup of a file
_backup_file() {
  local file="$1"
  if __check_file_exists_or_fail "$file"; then
    cp "$file" "$file$BACKUP_SUFFIX"
    okay "Backup created: ${file}${BACKUP_SUFFIX}"
    knife_success
  else
    warn "No file to backup: $file"
    knife_fail # Returns failure if no file to backup
  fi
}

# Returns the canonical path of a file
_canonical_path_of() {
  local file="$1"
  if [[ -n "$REALPATH_CMD" ]]; then
    "$REALPATH_CMD" "$file" 2>/dev/null || echo "$file"
  else
    # Fallback if REALPATH_CMD is not set (should not happen after __check_all_dependencies)
    echo "$file"
  fi
}

# Returns MD5 hash of file content
_file_md5() {
  local file="$1"
  if __check_file_exists_or_fail "$file"; then
    if [[ -n "$MD5_CMD" ]]; then
      if [[ "$MD5_CMD" =~ "md5sum" ]]; then
        "$MD5_CMD" "$file" | cut -d ' ' -f 1
      else # Likely 'md5' (macOS)
        "$MD5_CMD" -q "$file"
      fi
    else
      # Should be caught by __check_all_dependencies, but just in case
      error "Hashing utility (md5sum/md5) not available."
      echo "" # Return empty string on failure
    fi
  else
    echo "" # Return empty string if file doesn't exist
  fi
}

# Returns MD5 hash of a string
_string_md5() {
  local str="$1"
  if [[ -n "$MD5_CMD" ]]; then
    if [[ "$MD5_CMD" =~ "md5sum" ]]; then
      echo -n "$str" | "$MD5_CMD" | cut -d ' ' -f 1
    else # Likely 'md5' (macOS)
      echo -n "$str" | "$MD5_CMD" -q
    fi
  else
    # Should be caught by __check_all_dependencies
    error "Hashing utility (md5sum/md5) not available."
    echo "" # Return empty string on failure
  fi
}

# Formats a Unix timestamp into a human-readable date string
__format_timestamp() {
  local timestamp="$1"
  if [[ -n "$DATE_CMD" ]]; then
    # Check for GNU date vs BSD/macOS date syntax
    if "$DATE_CMD" --version >/dev/null 2>&1; then # GNU date
      "$DATE_CMD" -d "@${timestamp}" "+%Y-%m-%d %H:%M:%S"
    else # BSD/macOS date
      "$DATE_CMD" -r "${timestamp}" "+%Y-%m-%d %H:%M:%S"
    fi
  else
    echo "${timestamp} (Date utility missing)"
  fi
}

# Checks if a path is within the user's home directory
_is_home_dir() {
  local path="$1"
  local abs_path=$(_canonical_path_of "$path")
  local home_abs=$(_canonical_path_of "$HOME")
  [[ "$abs_path" == "$home_abs" || "$abs_path" == "$home_abs"/* ]]
}

# Checks if a directory path is the root directory
_is_root_dir() {
  local path="$1"
  [[ "$path" == "/" ]]
}

# Checks if a command is destructive (modifies a file)
_is_destructive_command() {
  local cmd="$1"
  case "$cmd" in
    (setv|defv|link|inject|delete|unlink|metaset|metadel|cleanup) return 0 ;;
    (*) return 1 ;;
  esac
}

# --- Known Files Management ---

# Adds/updates a file's entry in .knife_known
_add_known_file() {
  local file="$1"
  if ! __check_file_exists_or_fail "$file"; then knife_fail; fi

  local canon_path=$(_canonical_path_of "$file")
  local path_hash=$(_string_md5 "$canon_path")
  local content_hash=$(_file_md5 "$file")
  local filename=$(basename "$file")

  if [[ -z "$path_hash" || -z "$content_hash" ]]; then
    error "Cannot generate hash for $file due to missing utility. Skipping known file entry."
    knife_fail
  fi

  # Check if an entry with the exact path AND content hash already exists
  if grep -qE "^${canon_path}:${path_hash}:${content_hash}:${filename}$" "$KNOWN_FILES_FILE" 2>/dev/null; then
    knife_success
  else
    # Remove old entry if path exists but content has changed (or different hash)
    sed -i "/^${canon_path}:/d" "$KNOWN_FILES_FILE" 2>/dev/null || true # `|| true` to suppress error if file doesn't exist
    echo "${canon_path}:${path_hash}:${content_hash}:${filename}" >> "$KNOWN_FILES_FILE"
    knife_success
  fi
}

# --- History Management ---

__get_next_history_id() {
  local last_id="0" # Default to 0
  if [[ -f "$HISTORY_FILE" && -s "$HISTORY_FILE" ]]; then # Check if file exists and is not empty
    # Try to extract the last ID. Use awk for robustness as it handles empty files better.
    last_id=$(awk -F: 'END {print $1}' "$HISTORY_FILE" 2>/dev/null)
    # Ensure it's numeric, otherwise fallback to 0
    if ! [[ "$last_id" =~ ^[0-9]+$ ]]; then
      last_id="0"
    fi
  fi
  printf "%04d" $((10#$last_id + 1)) # Convert to base 10, increment, then format back
}

# Logs a knife operation to .knife_history
__log_history() {
  local cmd_type="$1"
  local cmd_params="$2"
  local target_file="$3" # This is the file name as passed to knife, not canonical yet

  # Add to known files and get canonical details
  _add_known_file "$target_file" || return 1 # Ensure file is in known list and exists

  local id=$(__get_next_history_id)
  local timestamp=$(date +%s) # Using 'date' as it's checked by __check_all_dependencies
  local vanity_filename=$(basename "$target_file")
  local canon_path=$(_canonical_path_of "$target_file")
  local path_hash=$(_string_md5 "$canon_path")
  local content_hash=$(_file_md5 "$target_file") # Hash of the file *after* operation

  if [[ -z "$path_hash" || -z "$content_hash" ]]; then
    error "Cannot log history for $target_file: Hashing failed."
    knife_fail
  fi

  echo "${id}:${timestamp}:${cmd_type}:${cmd_params}:${vanity_filename}:${path_hash}:${content_hash}" >> "$HISTORY_FILE"
  knife_success
}

# --- Main Knife Commands ---


# knife line <line_num> <file>
knife_line() {
  local line_num="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  sed -n "${line_num}p" "$file"
  knife_success
}

# knife lines quick <file>
knife_lines_quick() {
  local file="$1"
  __check_file_exists_or_fail "$file" || return 1
  wc -l < "$file"
  knife_success
}

# knife banner <label> <file>
knife_banner() {
  local label="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  grep -nE "^###\\s*$label\\s*###" "$file" | cut -d: -f1 || { info "Banner '${label}' not found in $file"; echo -1; }
  knife_success
}

# knife block <label> <file>
knife_block() {
  local label="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  awk "/### open:$label/{flag=1; next} /### close:$label/{flag=0} flag" "$file"
  knife_success
}

# knife linked <fileA> <fileB>
knife_linked() {
  local fileA="$1" fileB="$2"
  __check_file_exists_or_fail "$fileA" || return 1
  __check_file_exists_or_fail "$fileB" || return 1
  # Match either canonical path or just basename for flexibility in existing source statements
  grep -qE "source +\"?($(_canonical_path_of "$fileA")|$(basename "$fileA"))\"?" "$fileB"
  if [[ $? -eq 0 ]]; then knife_success; else knife_fail; fi
}

# knife link <fileA> <fileB> (adds source statement)
knife_link() {
  local fileA="$1" fileB="$2"
  __check_file_exists_or_fail "$fileA" || return 1
  __check_file_exists_or_fail "$fileB" || return 1
  if ! _is_shell_or_rc "$fileB"; then
    error "Cannot link: $fileB is not a shell or .rc file."
    return 1 # Early exit on error
  fi
  if knife_linked "$fileA" "$fileB"; then # Use the new knife_linked
    warn "Already linked: ${fileA} in ${fileB}"
    knife_success
  else
    _backup_file "$fileB" || return 1
    echo "source \"$(_canonical_path_of "$fileA")\" # knife:link" >> "$fileB"
    __log_history "link" "$(basename "$fileA")" "$fileB"
    okay "Linked ${fileA} in ${fileB}"
    knife_success
  fi
}

# knife unlink <fileA> <fileB> (removes source statement)
knife_unlink() {
  local fileA="$1" fileB="$2"
  __check_file_exists_or_fail "$fileA" || return 1
  __check_file_exists_or_fail "$fileB" || return 1
  if ! _is_shell_or_rc "$fileB"; then
    error "Cannot unlink: $fileB is not a shell or .rc file."
    return 1 # Early exit on error
  fi
  if ! knife_linked "$fileA" "$fileB"; then # Use the new knife_linked
    warn "Not linked: ${fileA} not found in ${fileB}"
    knife_success
  else
    _backup_file "$fileB" || return 1
    # Use '|' as sed delimiter to safely match source statements with canonical or basename path
    local search_pattern="source +\"?($(_canonical_path_of "$fileA")|$(basename "$fileA"))\"?"
    sed -i "\|^${search_pattern}|d" "$fileB"
    __log_history "unlink" "$(basename "$fileA")" "$fileB"
    okay "Unlinked ${fileA} from ${fileB}"
    knife_success
  fi
}

# knife getv <key> <file>
knife_getv() {
  local key="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  grep -E "^\s*${key}\s*=" "$file" | tail -n1 | cut -d= -f2-
  knife_success
}

# knife keys <file>
knife_keys() {
  local file="$1"
  __check_file_exists_or_fail "$file" || return 1
  grep -E '^\s*[A-Za-z_][A-Za-z0-9_]*\s*=.*' "$file"
  knife_success
}

# knife val <value_pattern> <file>
knife_val() {
  local value_pattern="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  # Search for lines where VALUE part contains the pattern (after first '=')
  grep -E '^[A-Za-z_][A-Za-z0-9_]*\s*=[^=]*'"${value_pattern}"'.*' "$file"
  knife_success
}

# knife setv <key> <value> <file> (aliased by defv)
knife_setv() {
  local key="$1" value="$2" file="$3"
  __check_file_exists_or_fail "$file" || return 1
  _backup_file "$file" || return 1
  if grep -qE "^\s*${key}\s*=" "$file"; then
    sed -i "s|^\s*${key}\s*=.*|${key}=${value}|" "$file"
    okay "Updated key '${key}' in ${file}"
  else
    echo "${key}=${value}" >> "$file"
    okay "Added key '${key}' to ${file}"
  fi
  __log_history "setv" "${key}=${value}" "$file"
  knife_success
}

# knife split <line_num> <file>
knife_split() {
  local line="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  head -n "$line" "$file" > "${file}.part1"
  tail -n +$((line + 1)) "$file" > "${file}.part2"
  okay "Split ${file} into ${file}.part1 and ${file}.part2"
  echo "${file}.part1 ${file}.part2" # Output new filenames to stdout
  knife_success
}

# knife inject <src_file> <target_file>
knife_inject() {
  local src="$1" target="$2" name="$(basename "$src")"
  __check_file_exists_or_fail "$src" || return 1
  __check_file_exists_or_fail "$target" || return 1
  # Use grep -F for fixed string match of the marker
  if ! grep -Fq "### include:$name ###" "$target"; then
    error "Injection marker '### include:${name} ###' not found in ${target}."
    knife_fail
  fi
  _backup_file "$target" || return 1
  # Use '|' as sed delimiter to avoid issues with '/' in path
  sed -i "\|### include:${name} ###|r ${src}" "$target"
  __log_history "inject" "$name" "$target"
  okay "Injected ${src} into ${target}"
  knife_success
}

# knife delete <line_num> <file> (replaces with comment)
knife_delete_line() {
  local line_num="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  _backup_file "$file" || return 1
  # Replace content of line_num with a comment to preserve line count and mark deletion
  sed -i "${line_num}s/.*/#knife deleted line $(_format_timestamp "$(date +%s)")/" "$file"
  __log_history "delete" "$line_num" "$file"
  okay "Line ${line_num} in ${file} replaced with '#knife deleted line'."
  knife_success
}

# knife extract <label> <file> (alias for block)
knife_extract() {
  knife_block "$@"
}

# knife meta <file>
knife_meta() {
  local file="$1"
  __check_file_exists_or_fail "$file" || return 1
  grep -E '^#\s*[A-Za-z_]+\s*:' "$file"
  knife_success
}

# knife metaget <key> <file>
knife_metaget() {
  local key="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  # Match key, extract content after first colon, remove leading/trailing whitespace
  grep -E "^#\\s*${key}\\s*:" "$file" | head -n1 | cut -d: -f2- | sed -E 's/^\s*//;s/\s*$//'
  knife_success
}

# knife metaset <key> <value> <file>
knife_metaset() {
  local key="$1" value="$2" file="$3"
  __check_file_exists_or_fail "$file" || return 1
  _backup_file "$file" || return 1
  local marker_line_num=$(grep -nE "^#\\s*${key}\\s*:" "$file" | head -n1 | cut -d: -f1)
  if [[ -n "$marker_line_num" ]]; then
    sed -i "${marker_line_num}s|^#\\s*${key}\\s*:.*|# ${key}: ${value}|" "$file"
    okay "Updated meta key '${key}' in ${file}"
  else
    # Find the last # comment line to append meta to
    local last_comment_line=$(grep -nE '^\s*#' "$file" | tail -n1 | cut -d: -f1)
    if [[ -n "$last_comment_line" ]]; then
      sed -i "${last_comment_line}a\\# ${key}: ${value}" "$file" # Append after last comment
    else
      echo "# ${key}: ${value}" >> "$file" # Append to end if no comments
    fi
    okay "Added meta key '${key}' to ${file}"
  fi
  __log_history "metaset" "${key}=${value}" "$file"
  knife_success
}

# knife metadel <key> <file>
knife_metadel() {
  local key="$1" file="$2"
  __check_file_exists_or_fail "$file" || return 1
  local marker_line_num=$(grep -nE "^#\\s*${key}\\s*:" "$file" | head -n1 | cut -d: -f1)
  if [[ -n "$marker_line_num" ]]; then
    _backup_file "$file" || return 1
    sed -i "${marker_line_num}d" "$file"
    __log_history "metadel" "${key}" "$file"
    okay "Deleted meta key '${key}' from ${file}"
  else
    warn "Meta key '${key}' not found in ${file}."
    knife_success
  fi
}


# knife logo <file>
knife_logo() {
  local file="$1"
  __check_file_exists_or_fail "$file" || return 1

  # Look for a logo marker. Example: ### KNIFE_LOGO_START ###
  local start_marker="### KNIFE_LOGO_START ###"
  local end_marker="### KNIFE_LOGO_END ###"

  # Find line numbers of markers
  local start_line=$(grep -Fn "$start_marker" "$file" | cut -d: -f1 | head -n1)
  local end_line=$(grep -Fn "$end_marker" "$file" | cut -d: -f1 | head -n1)

  if [[ -n "$start_line" && -n "$end_line" && "$start_line" -lt "$end_line" ]]; then
    # Print lines between markers (exclusive of markers themselves)
    awk -v start="$start_line" -v end="$end_line" 'NR > start && NR < end {print}' "$file"
    knife_success
  else
    info "No logo block found (or markers malformed) in ${file}. Expected '${start_marker}' to '${end_marker}'."
    knife_fail
  fi
}

# knife copy <source_file> <num_lines> <output_file>
knife_copy_lines() {
  local file="$1" n="$2" out="$3"
  __check_file_exists_or_fail "$file" || return 1
  head -n "$n" "$file" > "$out"
  okay "Copied first ${n} lines of ${file} to ${out}"
  knife_success
}

# knife history [ :fields... | :all ] [file_query...]
knife_history() {
  local requested_fields=""
  local file_query_arg=""
  local field_map="id:0 time:1 cmd:2 params:3 vanity:4 path_hash:5 content_hash:6"
  local -A headers=(
    [id]="ID" [time]="Time" [cmd]="Command" [params]="Parameters"
    [vanity]="File" [path_hash]="PathHash" [content_hash]="ContentHash"
  )

  # Parse arguments: colon-prefixed fields followed by file_query
  local arg
  for arg in "$@"; do
    if [[ "$arg" == :* ]]; then # It's a field argument
      local field_name="${arg#:}" # Remove leading colon
      if [[ "$field_name" == "all" ]]; then
        requested_fields="id,time,cmd,params,vanity,path_hash,content_hash"
        break # :all means no further field parsing
      elif [[ "$field_map" =~ "${field_name}:" ]]; then
        requested_fields="${requested_fields}${field_name},"
      else
        warn "Unknown field: ${field_name}. Skipping."
      fi
    else # It's part of the file query
      if [[ -z "$file_query_arg" ]]; then
        file_query_arg="$arg"
      else
        file_query_arg="${file_query_arg} ${arg}"
      fi
    fi
  done

  # Default fields if no fields specified and no query
  if [[ -z "$requested_fields" && -z "$file_query_arg" ]]; then
    requested_fields="time,cmd,vanity,path_hash" # Default for last operation
  fi
  requested_fields="${requested_fields%,}" # Trim trailing comma

  local -a field_names=($(echo "$requested_fields" | tr ',' ' '))
  local -a field_indices=()
  local -a display_headers=()

  # Map field names to indices and build display headers
  local name index
  for name in "${field_names[@]}"; do
    index=$(echo "$field_map" | sed -E "s/.*${name}:([0-9]).*/\1/")
    if [[ -n "$index" ]]; then
      field_indices+=("$index")
      display_headers+=("${headers[$name]}")
    fi
  done

  if [[ ! -f "$HISTORY_FILE" || ! -s "$HISTORY_FILE" ]]; then
    info "No history found in ${HISTORY_FILE}."
    knife_fail
  fi

  local output_data=""
  local history_lines=""

  # Determine if only the last line or all lines are processed
  if [[ -z "$requested_fields" ]] && [[ -z "$file_query_arg" ]]; then
    # Default: Show only the very last operation, for history file tail
    history_lines=$(tail -n 1 "$HISTORY_FILE")
  else
    history_lines=$(cat "$HISTORY_FILE")
  fi

  local id_h time_h cmd_h params_h vanity_h path_hash_h content_hash_h
  while IFS=':' read -r id_h time_h cmd_h params_h vanity_h path_hash_h content_hash_h; do
    local keep_line=1

    if [[ -n "$file_query_arg" ]]; then
      # Filter by query (matches vanity filename or path hash)
      if [[ ! "$vanity_h" =~ "$file_query_arg" && ! "$path_hash_h" =~ "$file_query_arg" ]]; then
        keep_line=0
      fi
    fi

    if [[ "$keep_line" -eq 1 ]]; then
      local current_output=""
      for ((j=0; j<${#field_indices[@]}; j++)); do
        local field_idx="${field_indices[j]}"
        local field_val=""
        case "$field_idx" in
          (0) field_val="$id_h" ;;
          (1) field_val=$(__format_timestamp "$time_h") ;;
          (2) field_val="$cmd_h" ;;
          (3) field_val="$params_h" ;;
          (4) field_val="$vanity_h" ;;
          (5) field_val="$path_hash_h" ;;
          (6) field_val="$content_hash_h" ;;
        esac
        # Append with actual tab character
        current_output="${current_output}${field_val}"$'\t'
      done
      # Remove trailing tab, then add newline
      output_data="${output_data}${current_output%?}\n" # %? removes the last character (the tab)
    fi
  done <<< "$history_lines"

  if [[ -z "$output_data" ]]; then
    info "No history entries found matching your criteria."
    knife_fail
  else
    # Print headers
    printf "%s\t" "${display_headers[@]}" | sed 's/\t$//' # Trim last tab
    echo ""
    # Print data using column for formatting, if available
    if [[ -n "$COLUMN_CMD" ]]; then
      printf "%s" "$output_data" | "$COLUMN_CMD" -ts $'\t'
    else
      printf "%s" "$output_data" # Raw tab-separated if column is missing
    fi
    knife_success
  fi
}


# knife search <pattern>
knife_search_here() {
  local pattern="$1"
  local current_dir=$(pwd)

  if _is_root_dir "$current_dir"; then
    error "Searching in the root directory (/) is not allowed."
    knife_fail
  fi

  local find_args=("-type" "f") # Only search files
  local exclude_paths=()

  # Build exclude paths for find -not -path
  local exclude_item
  for exclude_item in "${KNIFE_EXCLUDES[@]}"; do
    exclude_paths+=("-o" "-path" "*/${exclude_item}/*")
  done
  # Remove the leading -o if there were exclusions, then group with NOT
  if [[ "${exclude_paths[0]}" == "-o" ]]; then
    unset 'exclude_paths[0]'
    exclude_paths=("!" "(" "${exclude_paths[@]}" ")")
  fi

  local search_depth=""
  if ! _is_home_dir "$current_dir" && [[ -z "$DEV_MODE" ]]; then
    search_depth="-maxdepth 1"
    warn "Restricting search to current directory only. Set DEV_MODE or run from \$HOME for recursive search."
  fi

  info "Searching for '${pattern}' in files from ${current_dir}..."

  # Build the find command arguments safely in an array
  local -a find_cmd_args=("$current_dir")
  if [[ -n "$search_depth" ]]; then
    find_cmd_args+=("$search_depth")
  fi
  find_cmd_args+=("${find_args[@]}")
  find_cmd_args+=("${exclude_paths[@]}")
  
  # Crucially, use -exec sh -c 'grep -l -E "$0" "$@"' to safely pass pattern
  # The first "$0" in sh -c's argument list becomes the value of "$0" in the executed script (the pattern)
  # The "sh" after the pattern is a dummy argument for "$0" inside the sh -c, as "$@" starts from $1
  find_cmd_args+=("-exec" "sh" "-c" 'grep -l -E "$0" "$@"' "$pattern" "sh" "{} +" )

  # Execute the find command directly using the command path
  local found_files
  # Capture stderr to suppress `grep: command not found` etc. if sh -c has issues
  found_files=$("$REALPATH_CMD" "${find_cmd_args[@]}" 2>/dev/null) # REALPATH_CMD stores the path to find

  if [[ -z "$found_files" ]]; then
    info "No files found containing '${pattern}'."
    knife_fail
  else
    echo "$found_files"
    okay "Search complete. Found files containing '${pattern}'."
    knife_success
  fi
}

# knife cleanup
knife_cleanup() {
  local num_removed=0
  local success=0

  if [[ -z "$DANGER_MODE" ]]; then
    info "This will remove all Knife-related backups (.bak), split parts (.part1, .part2), and Knife's history/known files."
    info "Are you sure you want to proceed? (y/N)"
    read -r -p "Confirm: " response
    if ! [[ "$response" =~ ^[Yy]$ ]]; then
      error "Cleanup cancelled by user."
      return 1
    fi
  fi

  # 1. Remove backup files based on known files list
  if [[ -f "$KNOWN_FILES_FILE" ]]; then
    info "Removing backup files (.bak)..."
    local canon_path filename
    while IFS=':' read -r _ _ _ canon_path filename; do
      local backup_file="${canon_path}${BACKUP_SUFFIX}"
      if [[ -f "$backup_file" ]]; then
        rm "$backup_file"
        if [[ $? -eq 0 ]]; then
          okay "Removed backup: ${backup_file}"
          num_removed=$((num_removed + 1))
        else
          warn "Failed to remove backup: ${backup_file}"
        fi
      fi
    done < "$KNOWN_FILES_FILE"
    success=1
  else
    info "No known files to check for backups."
  fi

  # 2. Remove split part files (*.part1, *.part2)
  info "Removing split part files (*.part1, *.part2)..."
  local part_file_count=$(find "$HOME" -maxdepth 5 -type f \( -name "*.part1" -o -name "*.part2" \) -print0 2>/dev/null | xargs -0 rm -f 2>/dev/null | wc -l)
  if [[ "$part_file_count" -gt 0 ]]; then
      okay "Removed ${part_file_count} split part files."
      num_removed=$((num_removed + part_file_count))
      success=1
  else
      info "No split part files found."
  fi
  
  # 3. Remove Knife's internal state files
  info "Removing Knife's internal state files..."
  if [[ -f "$KNOWN_FILES_FILE" ]]; then
    rm "$KNOWN_FILES_FILE"
    if [[ $? -eq 0 ]]; then okay "Removed ${KNOWN_FILES_FILE}"; num_removed=$((num_removed + 1)); success=1; else warn "Failed to remove ${KNOWN_FILES_FILE}"; fi
  else
    info "${KNOWN_FILES_FILE} not found."
  fi

  if [[ -f "$HISTORY_FILE" ]]; then
    rm "$HISTORY_FILE"
    if [[ $? -eq 0 ]]; then okay "Removed ${HISTORY_FILE}"; num_removed=$((num_removed + 1)); success=1; else warn "Failed to remove ${HISTORY_FILE}"; fi
  else
    info "${HISTORY_FILE} not found."
  fi

  if [[ "$num_removed" -gt 0 ]]; then
    okay "Cleanup complete. Total files removed: ${num_removed}."
    knife_success
  else
    info "Cleanup finished. No Knife-related files were found to remove."
    knife_success # Still success if nothing was there to remove
  fi
}


# --- Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then

  # Centralized command dispatch
  dispatch() {
    local cmd="$1"
    shift # Remove cmd from $@

    local arg1="$1" arg2="$2" arg3="$3" # Capture up to 3 arguments. History can take more, handled specifically.

    local target_file_for_prompt="" # Used only for safety prompt context

    # Determine target_file_for_prompt based on NEW argument order
    case "$cmd" in
      (line|delete|split|has|show) target_file_for_prompt="$arg2" ;; # <arg1> <file>
      (banner|block|meta|logo|lines|extract|keys|val) target_file_for_prompt="$arg1" ;; # <label> <file> or <file> for meta/logo/keys/val
      (find) # find <type> <file> or find <type> <key> <file>
          if [[ "$arg1" == "key" ]]; then target_file_for_prompt="$arg3"; # find key KEY FILE
          elif [[ "$arg1" == "values" ]]; then target_file_for_prompt="$arg2"; # find values FILE
          fi ;;
      (setv|defv) target_file_for_prompt="$arg3" ;; # <key> <value> <file>
      (getv) target_file_for_prompt="$arg2" ;; # <key> <file>
      (linked|link|unlink|inject) target_file_for_prompt="$arg2" ;; # <src_file> <target_file>
      (copy) target_file_for_prompt="$arg3" ;; # <source_file> <num_lines> <output_file> -> target is source file
      (metaget|metaset|metadel) target_file_for_prompt="$arg2" ;; # <key> <file> for get/del, <key> <value> <file> for set
      (cleanup) ;; # Cleanup has its own internal prompt
      (*) ;; # Other commands (history, search) don't have a direct target file for this prompt logic
    esac

    # Safety Guard for Destructive Operations
    # Check if command is destructive AND if a target file was identified (or if it's cleanup)
    if _is_destructive_command "$cmd" && [[ -n "$target_file_for_prompt" || "$cmd" == "cleanup" ]]; then
      local confirm_path="$target_file_for_prompt"
      if [[ "$cmd" == "cleanup" ]]; then confirm_path="$HOME"; fi # Use HOME as reference for cleanup safety prompt

      local canon_confirm_path=$(_canonical_path_of "$confirm_path")
      # Execute first conditional test, then chain with logical AND (&&)
      if [[ -z "$DANGER_MODE" ]] && ! _is_home_dir "$canon_confirm_path"; then
        warn "WARNING: You are attempting a destructive operation ('${cmd}') outside of your HOME directory:"
        warn "  Target: ${canon_confirm_path}"
        info "Are you sure you want to proceed? (y/N)"
        read -r -p "Confirm: " response
        if ! [[ "$response" =~ ^[Yy]$ ]]; then
          error "Operation cancelled by user."
          return 1 # Return failure to dispatch, which will propagate
        fi
      fi
    fi

    # Execute command with arguments reordered for the new function signatures
    case "$cmd" in
      (line) knife_line "$arg1" "$arg2" ;;
      (lines)
        if [[ "$arg1" == "quick" ]]; then knife_lines_quick "$arg2"; else error "Unknown 'lines' subcommand: $arg1"; return 1; fi ;;
      (banner) knife_banner "$arg1" "$arg2" ;;
      (block) knife_block "$arg1" "$arg2" ;;
      (linked) knife_linked "$arg1" "$arg2" ;;
      (link) knife_link "$arg1" "$arg2" ;;
      (unlink) knife_unlink "$arg1" "$arg2" ;;
      (getv) knife_getv "$arg1" "$arg2" ;; # getv KEY FILE
      (keys) knife_keys "$arg1" ;; # keys FILE
      (val) knife_val "$arg1" "$arg2" ;; # val VALUE_PATTERN FILE
      (setv|defv) knife_setv "$arg1" "$arg2" "$arg3" ;; # setv KEY VALUE FILE
      (split) knife_split "$arg1" "$arg2" ;;
      (inject) knife_inject "$arg1" "$arg2" ;;
      (delete) knife_delete_line "$arg1" "$arg2" ;;
      (extract) knife_extract "$arg1" "$arg2" ;;
      (meta) knife_meta "$arg1" ;;
      (metaget) knife_metaget "$arg1" "$arg2" ;;
      (metaset) knife_metaset "$arg1" "$arg2" "$arg3" ;;
      (metadel) knife_metadel "$arg1" "$arg2" ;;
      (logo) knife_logo "$arg1" ;;
      (copy) knife_copy_lines "$arg1" "$arg2" "$arg3" ;; # copy SOURCE_FILE NUM_LINES OUTPUT_FILE
      (has) knife_has "$arg1" "$arg2" ;;
      (show) knife_show "$arg1" "$arg2" ;;
      (history) knife_history "$@" ;; # Pass all remaining args directly for history
      (search) knife_search_here "$arg1" ;;
      (cleanup) knife_cleanup ;;
      (*) error "Unknown command: $cmd"; return 1 ;;
    esac
  }

  main() {
    # Check all critical external dependencies at startup
    __check_all_dependencies || exit 1

    # Initial DANGER_MODE warning and prompt
    if [[ -n "$DANGER_MODE" ]]; then
      warn "WARNING: Knife is running in DANGER_MODE! Destructive operations may proceed without confirmation."
      if [[ -z "$DEV_MODE" ]]; then
        info "Do you wish to continue? (y/N)"
        read -r -p "Confirm: " response
        if ! [[ "$response" =~ ^[Yy]$ ]]; then
          error "Knife exited due to DANGER_MODE. Rerun without DANGER_MODE or set DEV_MODE to bypass."
          exit 1
        fi
      fi
    fi

    if [[ "$#" -eq 0 ]]; then
      info "Usage: knife <command> [args...]"
      info "Examples:"
      info "  knife line 5 my_file.sh"
      info "  knife setv MY_VAR new_value config.ini"
      info "  knife history :time :vanity"
      info "  knife history :all my_script.sh"
      info "  knife search 'my_pattern'"
      info "  knife cleanup"
      exit 1
    fi

    dispatch "$@" # Dispatch the command and its arguments
    # The return code of dispatch (and thus the last command executed) will be the script's exit code
  }

  main "$@"
fi
