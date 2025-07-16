#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

  echo "loaded stdfx.sh" >&2;

  # question: do functions that dont explict return value auto return 0? 
  # answer: No. A Bash function implicitly returns the exit status of the *last command* that was executed. If that last command succeeds, its exit status is 0, which becomes the function's return value. If it fails, a non-zero exit status is returned.

  # question: when a function calls a subfunc or command, does the return value propogate?
  # answer: Yes, the exit status of the sub-function or command will become the return value of the calling function, *if and only if* it is the last command executed. If you run another command after the sub-function, the return value of that second command will be the one that propagates. To capture an earlier exit code, you must explicitly use `return $?` or save `$?` to a variable.

  # question: for debug-like functions, how do I get the name of the parent function that called me?
  # answer: The built-in `${FUNCNAME[@]}` array holds the entire call stack. `${FUNCNAME[0]}` is the current function, `${FUNCNAME[1]}` is the caller (parent), `${FUNCNAME[2]}` is the grandparent, and so on. You can use this to create powerful debug traces.

  # question: what is a regex that matches a valid UNIX/POSIX path (filename)?
  # answer: This is famously tricky because a POSIX filename can contain any character except NUL (`\0`) and forward-slash (`/`). A simple regex for a single path component (a filename) would be `^[^/]+$`. However, for validation, it is almost always better to use `test -e` to see if a path actually exists, rather than trying to validate its characters with a complex regex.

  # question: what is a regex that matches a valid UNIX/BASH/POSIX variable name?
  # answer: The standard regex for a POSIX-compliant variable/function name is `^[a-zA-Z_][a-zA-Z0-9_]*$`. It must start with a letter or underscore, followed by zero or more letters, numbers, or underscores. This is correctly implemented in the `is_name` function.

  #followup: Ive seen function names like prefix::function, which I suppose is not POSIX compliant. Are there are variations like this that are supported by Bash not nec POSIX-compliant?
  #answer: You're right, `prefix::function` is not POSIX compliant. POSIX requires identifiers to start with a letter or underscore and contain only alphanumeric characters and underscores. However, Bash allows a broader range of characters in function names, including colons, especially when using "nameref" or other advanced features. While these names might work in Bash, they are not portable to other POSIX-compliant shells.


  # question: what is a regex that matches a valid UNIX/BASH/POSIX command name?
  # answer: For shell functions, aliases, and built-ins, the regex is the same as for a variable name: `^[a-zA-Z_][a-zA-Z0-9_]*$`. For external commands on the filesystem, the filename can contain other characters (like `-` or `.`), but must not contain a `/` to be callable without a path.

  # question: what are the sub commands used in this file (grep, find, etc) that might differ across OS?
  # answer: The primary external commands in this file that can have significant portability issues between GNU/Linux and BSD/macOS are:
  #   - `find`: GNU `find` has many more options (like `-print0`, `-quit`, `-printf`) than its BSD counterpart. The use of `-print0` with `xargs -0` is generally a safe and portable pattern.
  #   - `realpath`: This is a standard GNU coreutil but is often not installed by default on macOS. Scripts should check for its existence or have a fallback.
  #   - `grep`: GNU `grep` is more powerful (e.g., `-P` for PCRE). Using basic regex and POSIX character classes like `[[:space:]]` is generally safe.
  #   - `file`: The exact text output of the `file` command can vary slightly between systems, which might affect the `is_script` function if the patterns are too strict.


#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  # Returns 0 (true) if the string is null or contains only whitespace.
  is_empty(){
    # This parameter expansion removes all characters in the `[:space:]` class
    # and then checks if the resulting string has zero length.
    [[ -z "${1//[[:space:]]/}" ]]
  }



  # Returns 0 (true) if the string contains at least one non-whitespace character.
  is_defined(){
    # This is a more readable alias for has_value, the direct inverse of is_empty.
    [[ -n "${1//[[:space:]]/}" ]]
  }


  # must be "defined" and cannot be . or / or .. or // or : or  null, none, empty, undefined, or other values that might indicate an error in parsing
  # should support one or more input, if one fails it all fails
  is_super_defined(){
    for arg in "$@"; do
      if [[ -z "$arg" || "$arg" == "." || "$arg" == "/" || "$arg" == ".." || "$arg" == "//" || "$arg" == ":" || "$arg" == "null" || "$arg" == "none" || "$arg" == "empty" || "$arg" == "undefined" ]]; then
        return 1
      fi
    done
    [[ -n "${1//[[:space:]]/}" ]]
  }




  # Returns 0 (true) if string $2 contains substring $1.
  in_string(){
    # The original implementation was flawed.
    # The [[ ... ]] construct is the modern, robust, and readable way to check for substrings.
    # The right-hand side is a glob-style pattern, not a literal string.
    [[ "$2" == *"$1"* ]]
  }
  

  # Returns 0 (true) if two strings are identical.
  strings_are_equal(){
    [[ "$1" == "$2" ]]
  }

  # Alias for strings_are_equal for brevity.
  a_eq_b(){
    strings_are_equal "$1" "$2"
  }

  # Alias for in_string for brevity.
  a_in_b(){
    in_string "$1" "$2"
  }

  # Returns 0 (true) if the string is a valid integer or floating-point number.
  is_num(){
    # This regex handles: an optional sign, integers, and various float formats (e.g., 1.23, .23, 1.).
    # It's a robust, single-line check without forking to an external command like awk.
    [[ "$1" =~ ^[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$ ]]
  }

  # Returns 0 (true) if the string consists of one or more alphanumeric characters.
  is_alnum(){
    # Fails for an empty string, then removes all alphanumeric chars and checks if nothing is left.
    # This is a fast, pure-bash alternative to regex.
    [[ -n "$1" && -z "${1//[[:alnum:]]/}" ]]
  }
  # Returns 0 (true) if the string consists of one or more alphabetic characters.
  is_alpha(){
    [[ -n "$1" && -z "${1//[[:alpha:]]/}" ]]
  }

  # Returns 0 (true) if the string is a valid shell identifier (e.g., a variable name).
  is_name(){
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
  }

  # Returns 0 (true) if string $2 starts with prefix $1.
  starts_with(){
    [[ "$2" == "$1"* ]]
  }

  # Returns 0 (true) if string $2 ends with suffix $1.
  ends_with(){
    [[ "$2" == *"$1" ]]
  }


#-------------------------------------------------------------------------------
# Path Support
#-------------------------------------------------------------------------------

  # all path tests imply that the var holding a path is non-empty and the var is a valid path

  # Returns 0 (true) if the string is a valid path name (per Unix) and is not empty
  is_path_name(){
    [ -n "$1" ] && [[ "$1" != "" ]] && [[ "$1" != /* ]]
  }




  # Returns 0 (true) if the string is a valid path (file or directory).
  is_path() {
    [ -n "$1" ] && test -e "$1"
  }


  # Returns 0 (true) if the given path is in the user's PATH environment variable.
  in_path() {
    is_path "$1" || return 1
    local path=$1 IFS=':'; set -- $PATH; [[ " $* " =~ " $path " ]]
  }

  # Lists executable commands or scripts in the specified directory.
  ls_bin(){
    is_path "$1" || return 1
    local dir="$1"
    find "$dir" -maxdepth 1 -type f -executable -print0 | xargs -0 -n 1 basename
  }

#-------------------------------------------------------------------------------
# Dir/Tree Support
#-------------------------------------------------------------------------------

  # Returns 0 (true) if the string is a valid directory.
  is_dir() {
    [ -n "$1" ] && test -d "$1"
  }

  # Returns 0 (true) if the string is a valid directory and is both readable and writable.
  is_rw_dir() {
    [ -n "$1" ] && test -d "$1" -a -r "$1" -a -w "$1"
  }

  # Lists all subdirectories in the specified directory.
  ls_dirs(){
    is_dir "$1" || return 1
    find "$1" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -n 1 basename
  }

  # Lists all files in the specified directory.
  ls_files() {
    is_dir "$1" || return 1;
    local dir="$1";
    local files=();
    while IFS= read -r -d '' file; do
      files+=( "$(basename "$file")" );
    done < <(find "$dir" -maxdepth 1 -type f -print0);

    local result="";
    local i;
    for (( i=0; i<${#files[@]}; i++ )); do
      result+="${files[i]}";
      if (( i < ${#files[@]} - 1 )); then
        result+="\n";
      fi;
    done;
    printf "%s" "${result}";
  }

  self_base() {
    realpath "$(dirname "${BASH_SOURCE[0]}")"
  }


#-------------------------------------------------------------------------------
# File Support
#-------------------------------------------------------------------------------

  # valid path var, checks for type file
  # Returns 0 (true) if the string is a valid file path.
  is_file() {
    [ -n "$1" ] && test -f "$1"
  }

  # Returns 0 (true) if the string is a valid file path and is both readable and writable.
  is_rw_file() {
    [ -n "$1" ] && test -f "$1" -a -r "$1" -a -w "$1"
  }

  # Returns 0 (true) if the file at the given path is empty or contains only whitespace.
  is_empty_file(){
    is_file "$1" || return 1
    [ ! -s "$1" ] || ! grep -q '[^[:space:]]' "$1"
  }

  # Return 0 if file is "active"
  is_active_file(){
    is_rw_file "$1" && [ -s "$1" ]
  }


 # Returns 0 (true) if the file has a shebang (indicating it's likely a script, though not necessarily executable).
  is_script(){
    file "$1" | grep -q -E 'text executable|script text'
  }

  # Returns 0 (true) if the file is executable.
  is_executable(){
    is_file "$1" || return 1
    [ -n "$1" ] && test -x "$1"
  }

  # Returns 0 (true) if path 'a' is a subpath of directory 'b'.
  a_sub_path_b() {
    is_path "$1" || return 1
    is_path "$2" || return 1
    [[ "$1" == "$2"/* ]]
  }

  # Returns 0 (true) if 'a' is a file within directory 'b'.
  a_file_in_b() {
    is_path "$2" || return 1
    [[ "$1" == "$2"/* ]] && is_file "$1"
  }

  canon_path(){
    is_path "$1" || return 1
    realpath "$1"
  }

  # Returns 0 (true) if path 'a' has the same canonical path as 'b'.
  a_canon_path_b() {
    is_path "$1" || return 1
    is_path "$2" || return 1
    [[ "$(canon_path "$1")" == "$(canon_path "$2")" ]]
  }


# Link and Misc Utilities
#-------------------------------------------------------------------------------

  # Returns 0 (true) if file 'a' is sourced by file 'b'.
  a_linked_b(){
    is_file "$1" || return 1
    is_file "$2" || return 1
    grep -q "source[[:space:]]\+\(.\+\/\|)$1" "$2"
  }

  # Lists all files sourced by the given file.
  ls_source(){
    is_file "$1" || return 1
    grep -o "source[[:space:]]\+\(.\+\/\|)[^[:space:]]\+" "$1" | cut -d ' ' -f 2
  }

  # Copies the target file to a backup file with a pid.bak extension and returns the backup path.
  copy_bak(){
    is_file "$1" || return 1
    local pid=$ file="$1" bak_file="$file.$pid.bak"
    cp "$file" "$bak_file" && echo "$bak_file"
  }


  # Makes a tmp file based on the current date in the xdg tmp 
  # e.g. ~/.cache/tmp/tmp_[DATE]_[PID]
  # and returns that path
  make_tmp(){
    local base
    base=$(xdg_path tmp)
    mkdir -p "$base"
    local date
    date=$(date +%Y%m%d)
    local pid=$
    echo "$base/tmp_${date}_${pid}"
  }
#-------------------------------------------------------------------------------
# XDG+ Support
#-------------------------------------------------------------------------------


  # get the full XDG-compliant path for the specified string
  # supports BashFX XDG+ convention (as specd in architecture.md)
  # e.g. xdg_path home -> $HOME/.local
  #      xdg_path lib  -> $HOME/.local/lib #xdg+ path
  #      xdg_path data -> $HOME/.local/data #xdg+ path
  # Returns the full XDG-compliant path for the specified string, following BashFX XDG+ conventions.
  xdg_path(){
    local type="$1"
    case "$type" in
      (home) echo "$HOME/.local" ;;
      (lib)  echo "$HOME/.local/lib" ;;
      (bin)  echo "$HOME/.local/bin" ;;
      (data) echo "$HOME/.local/data" ;;
      (config) echo "$HOME/.config" ;;  # Assuming a config type
      (cache)  echo "$HOME/.cache" ;;
      (state) echo "$HOME/.local/state" ;;
      (share) echo "$HOME/.local/share" ;;
      (tmp)  echo "$HOME/.cache/tmp" ;;
      (*)    echo ""; return 1;; 
    esac
  }

  # given the path, returns the string of the xdg+ compliant base path, and none if not xdg+ compliant
  # Returns the XDG+ compliant base path type (e.g., "home", "lib", "data") if the path is XDG+ compliant; otherwise, returns "none".
  xdg_type(){
    local path="$1"
    case "$path" in
      ($HOME/.local*) echo "home" ;;
      ($HOME/.local/lib*) echo "lib" ;;
      ($HOME/.local/bin*) echo "bin" ;;
      ($HOME/.local/data*) echo "data" ;;
      ($HOME/.config*) echo "config" ;;
      ($HOME/.cache*)  echo "cache" ;;
      ($HOME/.local/state*) echo "state" ;;
      ($HOME/.local/share*) echo "share" ;;
      ($HOME/.cache/tmp*) echo "tmp" ;;
      (*)            echo "none" ;;
    esac
  }
  

  # Returns 0 (true) if the given path is XDG+ compliant.
  is_xdg_path(){
    local path="$1"
    [[ "$(xdg_type "$path")" != "none" ]];
  }


#-------------------------------------------------------------------------------
# Source and Project Helpers
#-------------------------------------------------------------------------------

  # base implies the current script base path, some functions attempt to take the base path in question as an 'auto' parameter for a non-base function counterpart.

  # Returns 0 (true) if the given path is a sibling of the current script.
  is_sibling_file(){
    local path="$1";
    local base;
    base=$(self_base);
    local self_canonical_path;
    self_canonical_path=$(realpath "${BASH_SOURCE[0]}");

    # Check if the dirname of the provided path is the same as the script's base directory,
    # and ensure the provided path is not the script itself (using canonical paths for comparison).
    [[ "$(dirname "$path")" == "$base" && "$(realpath "$path")" != "$self_canonical_path" ]];
  }


  # find a file in the subtree of the given directory
  in_tree(){
    local dir="$1" file="$2" 
    if is_path "$dir"; then
      find "$dir" -name "$file" -print -quit;
    fi
  }





  # is the file in the current scripts base tree
  in_base_tree(){
    local base
    base=$(self_base)
    in_tree "$base" "$1"
  }



  base_source(){
    local file="$1" path
    path=$(in_base_tree "$file")
    if [ -n "$path" ]; then
      source "$path"
      return 0
    else
      return 1
    fi
  }

  # Finds and echoes the project root (git top-level) for a given path.
  # Returns 0 on success, 1 on failure (e.g., not in a git repo).
  project_base() {
    local this="$1"
    local search_dir

    # Determine the directory to start searching from.
    # Must be a real directory for `git -C` to work.
    if [ -d "$this" ]; then
      search_dir="$this"
    elif [ -f "$this" ]; then
      search_dir=$(dirname "$this")
    else
      # The path doesn't exist, so it can't be in a project.
      return 1
    fi

    if [ -e git ]; then
      # Use git rev-parse to find the top-level directory.
      # The -C option runs git as if it were started in <path>.
      # The command's exit code is passed through, and stderr is suppressed.
      command git -C "$search_dir" rev-parse --show-toplevel 2>/dev/null | realpath
    else
      #local markers=("package.json" "pyproject.toml" "composer.json" "pom.xml" ".git" ".hg" ".svn")
      local markers=(".git");

      # Traverse up the directory tree.
      while [ "$search_dir" != "/" ]; do
        for marker in "${markers[@]}"; do
          if [ -e "$search_dir/$marker" ]; then
            # Found a marker, assume this is the project root.
            echo "$search_dir"
            return 0
          fi
        done

        # Move up one level in the directory tree.
        search_dir=$(dirname "$search_dir")
      done

    fi
    # Reached the root without finding a marker.
    echo ""
    return 1
  }


  
  # Returns 0 (true) if the file is located within a git repository.
  is_project_file() {
    # The output is discarded, we only care about the exit code.
    project_base "$1" >/dev/null 2>&1
  }


  #todo incomplete. should source a file either from base tree or project tree.
  fuzzy_source(){
    local filer="$1" file="$2" path
    case "$filer" in
      project) 
        path=$(in_proj_base_tree "$file")
      ;;
      *)   
        path=$(in_base_tree "$file")
      ;; 
    esac
    if [ -n "$path" ]; then
      source "$path"
      return 0
    else
      return 1
    fi
  }


  # Returns 0 (true) if the specified directory is the root of a Git repository.
  # this implementation specifically checks for -n and -d 
  is_project_path(){
    local dir="$1"
    is_path "$dir" && [ -d "$dir/.git" ] && return 0
    return 1
  }

  # If the given directory is a project directory, checks if a file exists within its subdirectories and returns the path.
  # Returns 0 (true) and echoes the path if found.
  in_project_tree(){
    local dir="$1" file="$2"
    if is_project_path "$dir"; then
      local found_path
      found_path=$(in_tree "$dir" "$file")
      if [ -n "$found_path" ]; then
        realpath "$found_path"
      fi
    fi
  }


  # If the script's directory is a project directory, finds the specified file within its subdirectories.
  # Returns 0 (true) and echoes the path if found.
  in_proj_base_tree(){
    local base
    base=$(project_base "$(self_base)")
    if [ -n "$base" ]; then
      in_project_tree "$base" "$1"
    fi
  }



  # Sources the specified file based on its location within the project tree, relative to the script's directory.
  project_source(){
    local file="$1" path
    path=$(in_proj_base_tree "$file")
    if [ -n "$path" ]; then
      source "$path"
      return 0
    else
      return 1
    fi
  }
  
#-------------------------------------------------------------------------------
# Treehouse Functions - treehouse functions are simple functions run over an array
#-------------------------------------------------------------------------------


  # Returns 0 if every item in the list passes the specified test
  # a in b -> a in every b
  # a is x -> every a is x
  # a has b -> every a has b
  # 'super' implies an opinionated/special case
  #   super_equal -> all items equal eachother
  #   super_defined -> extra rules for "defined"
  # note: in some cases it may be more efficient to create an "all" versoin of a function
  #       instead of iterating with individual function calls (find comes to mind)
  is_each(){
    noimp;
    #empty
    #defined
    #super_defined
    #num
    #alnum
    #alpha
    #super_equal
    #name
    #starts_with
    #ends_with
    #has_substring
    #is_path
    #xdg_path
    #valid_path (general dir or file)
    #rw_path (general dir or file)
    #is_file
    #active_file
    #is_dir
    #in_path

  }

#-------------------------------------------------------------------------------
# Driver
#-------------------------------------------------------------------------------













