#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name: 
#$ author: 
#$ semver: 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

  readonly LIB_STDUTILS="${BASH_SOURCE[0]}";


  _index=

#-------------------------------------------------------------------------------
# Load Guard
#-------------------------------------------------------------------------------

if ! _index=$(is_lib_registered "LIB_STDUTILS"); then 

  register_lib LIB_STDUTILS;



#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

# width=$(tput cols 2>/dev/null || echo 80);



  deref_var() {
    local __varname="$1"
    [[ "$__varname" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1;
    eval "printf '%s' \"\$${__varname}\"";
  }

  #update to take prefix as a paramter isntead of do_
  # do_inspect(){
  #   declare -F | grep 'do_' | awk '{print $3}'
  #   _content=$(sed -n -E "s/[[:space:]]+([^#)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")
  #   __printf "$LINE\n"
  #   while IFS= read -r row; do
  #     info "$row"
  #   done <<< "$_content"
  # }


################################################################################
#
#  __print_in_columns (Low-Ordinal Helper)
#
################################################################################
# Description: Reads a list from stdin and formats it into fixed-width columns.
# Arguments:
#   1: num_cols (integer) - The number of columns to print.
#   2: col_width (integer) - The width of each individual column.
# Returns: 0.
__print_in_columns() {
    local num_cols="$1";
    local col_width="$2";
    local -a items=();
    
    mapfile -t items

    local count=${#items[@]};
    if [[ $count -eq 0 ]]; then return 0; fi

    # THE FIX: Remove the explicit `\n` from the format string.
    # The `printf` in the loop will now only print the formatted row,
    # and the calling context (or the implicit newline from the command
    # substitution ending) will handle the line break.
    local format_string="";
    for ((i=0; i<num_cols; i++)); do
        format_string+="%-*s ";
    done;

    for ((i=0; i<count; i+=num_cols)); do
        local -a row_args=();
        for ((j=0; j<num_cols; j++)); do
            row_args+=("$col_width" "${items[i+j]:-}");
        done;
        # We add the newline here, outside the format string, for clarity and control.
        printf -- "${format_string}\n" "${row_args[@]}";
    done;
    return 0;
}




do_inspect(){
  info "Available Commands (from dispatch):";
  
  # The sed command here is a simplified version to extract just the command.
  # The final pipe to `pr` does the column formatting.
  sed -n '/dispatch()/,/esac/p' "$0" \
    | grep -oE '^\s*\(([^)]+)\)' \
    | sed 's/[()]/ /g' \
    | tr '|' '\n' \
    | awk '{$1=$1;print "  "$0}' \
    | sort -u \
    | __print_in_columns 4 20;

  line;
  
  info "Available Functions (by prefix):";
  declare -F \
    | awk '{print $3}' \
    | grep -E '^(do_|dev_|is_)' \
    | sed 's/^/  /' \
    | sort \
    | __print_in_columns 4 20;

  return 0;
}


  # Removes leading and trailing whitespace from a string and prints the result.
  trim_string() {
    local var="$*"
    # Remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
  }

  # in_array moved to base.sh
  
  is_empty_file(){
    local this=$1;
    trace "Checking for empty file ($this)";
    if [[ -s "$this" ]]; then
      if grep -q '[^[:space:]]' "$this"; then
        return 1;
      else
        return 0;
      fi
    fi
    return 0;
  }


  #ex  list2="$(join_by \| ${list[@]})"
  join_by(){
    local IFS="$1"; shift;
    echo "$*";
  }

  split_by(){
    local this on;
    this="$1";
    on="$2";
    array=(${this//$on/ })
    echo "${array[@]}"
  }

  has_subdirs(){
    local dir="$1"
    for d in "$dir"/*; do
      [ -d "$d" ] && return 0
    done
    return 1
  }

  # @note uses portable find
  sub_dirs(){
    local path=$1
    res=($($cmd_find "$path" -type d -printf '%P\n' ))
    echo "${res[*]}"
  }


  pop_array(){
    local match="$1"; shift
    local temp=()
    local array=($@)
    for val in "${array[@]}"; do
        [[ ! "$val" =~ "$match" ]] && temp+=($val)
    done
    array=("${temp[@]}")
    unset temp
    echo "${array[*]}"
  }

   requote(){
    whitespace="[[:space:]]"
    for i in "$@"; do
      if [[ $i =~ $whitespace ]]; then
        i=\"$i\"
      fi
      echo "$i"
    done
  }

   argsify(){
    local IFS ret key arg var prev
    prev="$IFS"; IFS='|'
    args=$(auto_escape "$*"); ret=$?

    case "${@}" in
      *\ * ) ret=0;;
      * ) arg="$1";;
    esac

    [ $ret -eq 0 ] && arg="'$*'" && trace "Args needs special love <3"

    trace "ARG is $arg"

    IFS=$prev
    echo "$arg"
  }

   auto_escape(){
    local str="$1"
    printf -v q_str '%q' "$str"
    if [[ "$str" != "$q_str" ]]; then
      ret=0
    else
      ret=1
    fi
    echo "$q_str"
    return $ret
  }



  # Compares two semantic version strings.
  # Usage: compare_versions "1.2.3" ">=" "1.2.0"
  # Handles standard operators: =, ==, !=, <, <=, >, >=
  compare_versions() {
      # Easy case: versions are identical
      if [[ "$1" == "$3" ]]; then
          case "$2" in
              '='|'=='|'>='|'<=') return 0 ;;
              *) return 1 ;;
          esac
      fi

      # Split versions into arrays using '.' as a delimiter
      local OLD_IFS="$IFS"
      IFS='.'
      local -a v1=($1) v2=($3)
      IFS="$OLD_IFS"

      # Find the longest version array to iterate through
      local i
      local len1=${#v1[@]}
      local len2=${#v2[@]}
      local max_len=$(( len1 > len2 ? len1 : len2 ))

      # Compare each component numerically
      for ((i = 0; i < max_len; i++)); do
          # Pad missing components with 0
          local c1=${v1[i]:-0}
          local c2=${v2[i]:-0}

          if (( c1 > c2 )); then
              case "$2" in '>'|'>='|'!=') return 0 ;; *) return 1 ;; esac
          fi
          if (( c1 < c2 )); then
              case "$2" in '<'|'<='|'!=') return 0 ;; *) return 1 ;; esac
          fi
      done

      # If we get here, they are equal component-by-component
      case "$2" in '='|'=='|'>='|'<=') return 0 ;; *) return 1 ;; esac
  }


  find_repos(){
    think "Finding repo folders..."
    warn "This may take a few seconds..."
    this="$cmd_find ${2:-.} -mindepth 1"
    [[ $1 =~ "1" ]] && this+=" -maxdepth 2" || :
    [[ $1 =~ git ]] && this+=" -name .git"  || :
    this+=" -type d ! -path ."
    awk_cmd="awk -F'.git' '{ sub (\"^./\", \"\", \$1); print \$1 }'"
    cmd="$this | $awk_cmd"
    __print "$cmd"
    eval "$cmd" #TODO:check if theres a better way to do this
  }


#-------------------------------------------------------------------------------
# Load Guard Error
#-------------------------------------------------------------------------------

else
  error "Library LIB_STDUTILS found at index [$_index]";
  return 1;
fi
