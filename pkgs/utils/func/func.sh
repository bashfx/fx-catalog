#!/usr/bin/env bash
#
# func - A utility for safely extracting and managing shell functions
#        as part of the Function Isolation & Integration Protocol (FIIP).
#
# Version: 2.0 - Refactored for modularity and a more intuitive command set.
#

VERSION='2.0'

# --- Main Usage function ---
usage() {
  cat << EOF >&2

func v${VERSION}
Usage: func <command> [args...]

A powerful utility for the Function Isolation & Integration Protocol (FIIP).

Commands:
  spy <func_name> <src>
    Prints the body of <func_name> from <src> directly to stdout.

  extract <func_name> <src>
    Extracts <func_name> from <src> and saves it to a non-insertable
    file: ./func/<func_name>.extracted.sh.

  copy <func_name> <new_func_name> <src>
    Creates a new, versioned working file for development. Extracts
    <func_name>, renames it to <new_func_name>, and saves it to
    ./func/<new_func_name>.func.sh.

  flag <func_name> <new_func_name> <src>
    Inserts a clean, spaced-out FIIP marker comment above <func_name>
    in <src> for later integration.

  point <new_func_name> <src>
    Finds the FIIP marker for <new_func_name> in <src> and prints
    its line number.

  where <func_name> <src>
    Finds the definition of <func_name> in <src> and prints its
    starting line number, or -1 if not found.

  ls <src>
    Lists all functions detected in the <src> file.

  find <pattern> <src>
    Lists all functions in <src> whose names contain <pattern>.

  -h, --help
    Displays this help message.
EOF
  exit 1
}

# --- Low-Ordinal Helper Functions (The Primitives) ---

# Finds the starting line number of a function definition.
# Args: $1: function name, $2: file path
# Output: Line number to stdout, or empty string if not found.
__find_function_line() {
  local func_name="$1"
  local src_path="$2"
  # Robust regex for finding the function definition line.
  grep -n -E "^[[:space:]]*${func_name}[[:space:]]*\([[:space:]]*\)[[:space:]]*\{" "${src_path}" | cut -d: -f1
}

# Extracts the full body of a function using a robust, brace-counting awk script.
# Args: $1: function name, $2: file path
# Output: The full, multi-line function body to stdout.
__extract_function_body() {
  local func_name="$1"
  local file_path="$2"
  # This awk script correctly handles nested braces and avoids over-globbing.
  awk -v target_func="$func_name" '
    BEGIN { in_func = 0; brace_level = 0; }
    $0 ~ "^[[:space:]]*" target_func "[[:space:]]*\\([[:space:]]*\\)[[:space:]]*\\{" {
      if (in_func == 0) {
        in_func = 1;
        for (i = 1; i <= length($0); ++i) { if (substr($0, i, 1) == "{") brace_level++; }
        print $0; next;
      }
    }
    in_func == 1 {
      print $0;
      for (i = 1; i <= length($0); ++i) {
        if (substr($0, i, 1) == "{") brace_level++;
        else if (substr($0, i, 1) == "}") brace_level--;
      }
      if (brace_level == 0) in_func = 0;
    }
  ' "${file_path}"
}

# Finds the line number of an FIIP insertion flag.
# Args: $1: new function name, $2: file path
# Output: Line number to stdout, or empty string if not found.
__find_flag_line() {
  local new_func_name="$1"
  local src_path="$2"
  local marker_pattern="# FIIP_INSERT ./func/${new_func_name}.func.sh"
  grep -n -m 1 "${marker_pattern}" "${src_path}" | cut -d: -f1
}


# --- High-Ordinal Command Implementations ---

do_spy() {
  [ "$#" -ne 2 ] && usage
  __extract_function_body "$1" "$2"
}

do_extract() {
  [ "$#" -ne 2 ] && usage
  local func_name="$1"
  local src_path="$2"
  local func_body
  func_body=$(__extract_function_body "$func_name" "$src_path")
  [ -z "$func_body" ] && { echo "Error: Function '${func_name}' not found." >&2; exit 1; }

  mkdir -p "./func"
  local dest_file="./func/${func_name}.extracted.sh"
  printf "%s\n" "$func_body" > "$dest_file"
  echo "Extracted function to '${dest_file}'" >&2
}

do_copy() {
  [ "$#" -ne 3 ] && usage
  local func_name="$1"
  local new_func_name="$2"
  local src_path="$3"
  local func_body
  func_body=$(__extract_function_body "$func_name" "$src_path")
  [ -z "$func_body" ] && { echo "Error: Function '${func_name}' not found." >&2; exit 1; }

  local new_body
  new_body=$(echo "$func_body" | sed "1s/${func_name}/${new_func_name}/")
  mkdir -p "./func"
  local dest_file="./func/${new_func_name}.func.sh"
  printf "%s\n" "$new_body" > "$dest_file"
  echo "Copied and versioned function to '${dest_file}'" >&2
}

do_flag() {
  [ "$#" -ne 3 ] && usage
  local func_name="$1"
  local new_func_name="$2"
  local src_path="$3"

  local line_num
  line_num=$(__find_function_line "$func_name" "$src_path")
  [ -z "$line_num" ] && { echo "Error: Function '${func_name}' not found." >&2; exit 1; }

  # Creates a clean insertion zone with 4 newlines above the marker.
  local marker_text="# FIIP_INSERT ./func/${new_func_name}.func.sh"
  printf -v marker_block '\n\n\n\n%s' "${marker_text}"
  
  # Use a temporary file for safe in-place editing.
  sed "${line_num}i\\${marker_block}" "${src_path}" > "${src_path}.tmp" && mv "${src_path}.tmp" "${src_path}"

  [ $? -eq 0 ] && echo "Flag for '${new_func_name}' inserted into '${src_path}'." >&2 || { echo "Error writing flag to '${src_path}'." >&2; exit 1; }
}

do_point() {
  [ "$#" -ne 2 ] && usage
  __find_flag_line "$1" "$2"
}

do_where() {
  [ "$#" -ne 2 ] && usage
  local line_num
  line_num=$(__find_function_line "$1" "$2")
  if [ -z "$line_num" ]; then
    echo "-1"
  else
    echo "$line_num"
  fi
}

do_ls() {
  [ "$#" -ne 1 ] && usage
  grep -E '^[[:space:]]*[a-zA-Z0-9_]+\s*\(\s*\)\s*\{' "$1" | sed -E 's/^[[:space:]]*//;s/\s*\(.*//'
}

do_find() {
  [ "$#" -ne 2 ] && usage
  # Reuse `do_ls` and pipe its output to grep for the pattern.
  do_ls "$2" | grep "$1"
}


# --- Main Dispatcher ---
if [ "$#" -eq 0 ]; then usage; fi
COMMAND="$1"; shift

case "$COMMAND" in
  spy|extract|copy|flag|point|where|ls|find)
    "do_${COMMAND}" "$@"
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "Error: Unknown command '$COMMAND'" >&2
    usage
    ;;
esac
