#!/usr/bin/env bash
#
# countx - A simple file-based counter script.
# Manages local counters, supports custom names, formatting, and a central manifest.
#

# --- Configuration ---
DEFAULT_COUNTER_NAME=".counter";
MANIFEST_FILE="${COUNTX_FILE:-$HOME/.countx_log}";
DEFAULT_FORMAT="000";

# --- Argument & Flag State ---
declare -a pos_args=();
COUNTER_NAME="$DEFAULT_COUNTER_NAME";
FORMAT_STRING="";
SHOW_DATE=false;

# --- Helper Functions ---

usage() {
  cat << EOF
Usage: countx [command] [value] [flags]

A simple file-based counter.

Commands:
  init <n>      Create a new counter with initial value <n>.
  <number>      Increment or decrement the counter by the given number (e.g., 1, -5).
  rm            Remove the local counter and its manifest entry.
  ls            List all tracked counters from the manifest.
  help          Show this help message.
  (no command)  Print the current value of the local counter.

Flags:
  --name <file>   Specify a custom counter file name (default: .counter).
  --fmt <format>  On 'init', set a printf-style format for leading zeros (e.g., 00000).
  --date          When printing the count, also show the last modification date.

Manifest File:
  The script keeps a log of all created counters in: ${MANIFEST_FILE}
EOF
}

# ---
# ** THE DEFINITIVE FIX IS HERE **
# ---
# Reads and parses a counter file, correctly handling the multi-character '::' delimiter.
read_counter() {
  local file="$1";
  if [[ ! -f "$file" ]]; then
    echo "Error: Counter file '$file' not found in this directory." >&2;
    echo "       Use 'countx init <value>' to create it." >&2;
    return 1;
  fi

  # Read the entire line from the file.
  local line;
  if ! read -r line < "$file"; then
      # This will only fail if the file is completely empty.
      echo "Error: Counter file '$file' is empty or unreadable." >&2;
      return 1;
  fi

  # Manually parse the line using Bash parameter expansion, which correctly handles '::'.
  C_FORMAT="${line%%::*}";        # Get part before the first '::'
  local remainder="${line#*::}";   # Get part after the first '::'
  C_COUNT="${remainder%%::*}";    # Get the middle part
  C_TIMESTAMP="${remainder#*::}"; # Get the last part

  # Validate that all parts were found.
  if [[ -z "$C_FORMAT" || -z "$C_COUNT" || -z "$C_TIMESTAMP" ]]; then
      echo "Error: Corrupted data in '$file'. Expected format 'format::count::timestamp'." >&2;
      return 1;
  fi

  # Validate that the count is a number.
  if ! [[ "$C_COUNT" =~ ^-?[0-9]+$ ]]; then
    echo "Error: Corrupted data in counter file '$file'. Count ('$C_COUNT') is not a valid integer." >&2;
    return 1;
  fi
  return 0;
}

write_counter() {
  local file="$1";
  local format="$2";
  local count="$3";
  local new_timestamp;
  new_timestamp=$(date +%s);
  echo "${format}::${count}::${new_timestamp}" > "$file";
}

print_formatted() {
  local count="$1";
  local format_spec="$2";
  if [[ "$format_spec" =~ ^0+$ ]]; then
    printf "%0${#format_spec}d" "$count";
  else
    printf "%d" "$count";
  fi
}

default_action() {
  if ! read_counter "$COUNTER_NAME"; then
    exit 1;
  fi

  print_formatted "$C_COUNT" "$C_FORMAT";

  if [[ "$SHOW_DATE" == true ]]; then
    pretty_date=$(date -d "@$C_TIMESTAMP" '+%a %b %d, %Y %I:%M:%S %p');
    printf "\nLast updated: %s\n" "$pretty_date";
  else
    echo "";
  fi
}


# --- Argument Parsing Loop ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    (--name)
      if [[ -z "$2" ]]; then echo "Error: --name requires a filename." >&2; exit 1; fi
      COUNTER_NAME="$2";
      shift 2;
      ;;
    (--fmt)
      if [[ -z "$2" ]]; then echo "Error: --fmt requires a format string." >&2; exit 1; fi
      if ! [[ "$2" =~ ^0+$ ]]; then echo "Error: --fmt string must be composed of only zeros (e.g., 0000)." >&2; exit 1; fi
      FORMAT_STRING="$2";
      shift 2;
      ;;
    (--date)
      SHOW_DATE=true;
      shift;
      ;;
    (-*)
      echo "Error: Unknown flag '$1'" >&2;
      usage;
      exit 1;
      ;;
    (*)
      pos_args+=("$1");
      shift;
      ;;
  esac
done

set -- "${pos_args[@]}";
COMMAND="$1";


# --- Main Logic ---
case "$COMMAND" in
  (help)
    usage;
    exit 0;
    ;;
  (init)
    if [[ -f "$COUNTER_NAME" ]]; then
      echo "Error: Counter file '$COUNTER_NAME' already exists here." >&2;
      exit 1;
    fi
    VALUE="$2";
    if ! [[ "$VALUE" =~ ^-?[0-9]+$ ]]; then
      echo "Error: 'init' requires an integer value. You provided: '$VALUE'" >&2;
      exit 1;
    fi
    
    final_format="${FORMAT_STRING:-$DEFAULT_FORMAT}";
    write_counter "$COUNTER_NAME" "$final_format" "$VALUE";
    
    echo -n "Counter '$COUNTER_NAME' created with initial value: ";
    print_formatted "$VALUE" "$final_format";
    echo "";

    touch "$MANIFEST_FILE";
    counter_path=$(realpath "$COUNTER_NAME");
    if ! grep -q -F "$counter_path" "$MANIFEST_FILE"; then
      echo "$counter_path" >> "$MANIFEST_FILE";
    fi
    ;;

  (rm)
    removed_file=false;
    removed_manifest=false;
    
    # Resolve the full, canonical path of the counter we intend to remove.
    # The `-s` flag for realpath resolves the path without requiring the file to exist.
    counter_path=$(realpath -s "$COUNTER_NAME");

    # Step 1: Remove the local file if it exists.
    if [[ -f "$COUNTER_NAME" ]]; then
      rm "$COUNTER_NAME";
      echo "Removed local file: $COUNTER_NAME";
      removed_file=true;
    fi

    # Step 2: Check the manifest for a matching entry and remove it.
    # This runs regardless of whether the local file was found.
    if [[ -f "$MANIFEST_FILE" ]]; then
      # Check if the path exists in the file before trying to remove it.
      if grep -q -F "$counter_path" "$MANIFEST_FILE"; then
        grep -v -F "$counter_path" "$MANIFEST_FILE" > "${MANIFEST_FILE}.tmp" && \
        mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE";
        echo "Removed entry from manifest: $counter_path";
        removed_manifest=true;
      fi
    fi

    # Step 3: If nothing was done, inform the user.
    if [[ "$removed_file" == false && "$removed_manifest" == false ]]; then
      echo "Nothing to remove. File '$COUNTER_NAME' not found locally or in manifest.";
    fi
    ;;

  (ls)
    if [[ ! -f "$MANIFEST_FILE" || ! -s "$MANIFEST_FILE" ]]; then
      echo "Manifest is empty. No counters tracked.";
      exit 0;
    fi
    echo "Tracked Counters (${MANIFEST_FILE})";
    cat "$MANIFEST_FILE";
   ;;

  ("") 
    default_action; 
    ;;
  (*)
    if [[ "$COMMAND" =~ ^\+$ ]]; then
      COMMAND=1;
    fi
    if [[ "$COMMAND" =~ ^-?[0-9]+$ ]]; then
      if ! read_counter "$COUNTER_NAME"; then
        exit 1;
      fi

      increment=$COMMAND;
      new_sum=$(( C_COUNT + increment ));
      
      write_counter "$COUNTER_NAME" "$C_FORMAT" "$new_sum";
      
      print_formatted "$new_sum" "$C_FORMAT";
      echo "";
    else
      echo "Error: Unknown command '$COMMAND'." >&2;
      usage;
      exit 1;
    fi
    ;;
esac
