#!/usr/bin/env bash
#===============================================================================

# docx now with bolt!
# err and out added, not sure if it will fail yet lol

#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------

  red=$(tput setaf 9)
  green=$(tput setaf 40)
  blue=$(tput setaf 39)
  blue2=$(tput setaf 27)
  cyan=$(tput setaf 14)
  yellow=$(tput setaf 226)
  orange=$(tput setaf 214)
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
  
  LINE="$(printf '%.0s-' {1..54})";
  LINE2="$(printf '%.0s-' {1..80})";
  LINE3="$(printf '%.0s-' {1..30})";

  delta="\xE2\x96\xB3"
  pass="\xE2\x9C\x93"
  fail="${red}\xE2\x9C\x97"
  star="\xE2\x98\x85"
  lambda="\xCE\xBB"
  idots="\xE2\x80\xA6"
  spark="\xe2\x9f\xa1"
  star="\xE2\x98\x85"
  bolt="\xE2\x86\xAF"
  
  snek='\xe2\x99\x8b'
  itime='\xe2\xa7\x97'
  spark='\xe2\x9f\xa1' 
  flag_on="\xe2\x9a\x90" 
  flag_off="\xe2\x9a\x91" 

  diamond='\xE1\x9B\x9C'
  #delim='\x01'
  delta='\xE2\x96\xB3'
  pass='\xE2\x9C\x93'
  fail='\xE2\x9C\x97'
  dots='\xE2\x80\xA6'

  #redo='\xE2\x9F\xB3'
  space='\x20'
  eol="$(tput el)"
  eos="$(tput ed)"
  cll="$(tput cuu 1 && tput el)"
  bld="$(tput bold)"
  rvm="$(tput rev)"

  shebang="#!/usr/bin/env bash";

#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  stderr(){ printf "${@}${x}\n" 1>&2; }
  
#-------------------------------------------------------------------------------
# SED Utils
#-------------------------------------------------------------------------------
  
  #sed block parses self to find meta data
  sed_block(){
    local id="$1" target="$2" pre="^[#]+[=]+" post=".*" str end;
    if [[ -f $target ]]; then
      str="${pre}${id}[:]?[^\!=\-]*\!${post}";
      end="${pre}\!${id}[:]?[^\!=\-]*${post}";
      sed -rn "1,/${str}/d;/${end}/q;p" "$target" | strip_leading_comment | replace_escape_codes;
      return 0;
    fi
    err="File ($target) not found";
    return 1;
  }

  strip_leading_comment() {
    sed 's/^[[:space:]]*#\ ?//'
  }

  escape_sed_replacement() {
    printf '%s\n' "$1" | sed 's/[\/&\\]/\\&/g'
  }


  expand_vars() {
    local raw="$1" output="" varname value
    local prefix rest matched=1  # default to no match
    while [[ "$raw" == *'$'* ]]; do
      prefix="${raw%%\$*}"
      rest="${raw#*\$}"
      varname=$(expr "$rest" : '\([a-zA-Z_][a-zA-Z0-9_]*\)')
      # If no valid varname, break
      [ -z "$varname" ] && break
      value="${!varname}"
      rest="${rest#$varname}"
      output+="$prefix$value"
      raw="$rest"
      matched=0
    done
    output+="$raw"
    printf '%s\n' "$output"
    return $matched;
  }


  replace_escape_codes() {
    local input
    if [ -p /dev/stdin ]; then
      while IFS= read -r line || [[ -n $line ]]; do
        input+=$line$'\n'
      done
    elif [ -n "$1" ]; then
      input="$1"
    else
      echo "Error: No input provided" >&2
      return 1
    fi 

    #shebang needs special babysitting for sed
    shebang="#!/usr/bin/env bash";
    esc_shebang=$(escape_sed_replacement "$shebang");
    
    #replace data
    input="${input//%date%/$(date +'%Y-%m-%d %H:%M:%S')}";

    #expand variables to their string values
    input=$(expand_env_vars "$input");

    # Replace the color codes in the input 
    # bash3 doenst support assoc arrays, escapes are not 1:1 mapped
    echo "$input" |  sed "s/\${x}/$x/g; s/\${rev}/$revc/g; s/\${r}/$red/g; s/\${o}/$orange/g;  s/\${c}/$cyan/g;  s/\${g}/$green/g; s/\${isnek}/$snek/g; s/\${it}/$itime/g; s/\${id}/$delta/g; s/\${il}/$lambda/g; s/\${isp}/$spark/g;  \
    s/\${spark}/$spark/g; s/\${star}/$star/g; s/\${bolt}/$bolt/g; \
    s/\${b2}/$blue2/g; s/\${w2}/$white2/g; s/\${p}/$purple/g;  s/\${u}/$grey/g; \
    s/\${y}/$yellow/g; s/\${b}/$blue/g; s/\${w}/$white/g;  s/\${u2}/$grey2/g; \
    s/\${bld}/$bold/g; s/\${line}/$line/g; s/\${LINE}/$LINE/g; s/\${shebang}/$esc_shebang/g";
  }

  #prints content between sed block

  block_print(){
    local lbl="$1" filepath="$2" IFS res ret;

    res=$(sed_block $lbl $filepath);ret=$?;
    if [ ${#res} -gt 0 ]; then
      while IFS= read -r line; do
        if [[ $lbl =~ ^(doc|inf|rc).* ]]; then
          printf '%b\n' "$line"
        else
          printf '%s\n' "$line"
        fi
      done <<< "$res"
      return 0;
    else
      err="Unexpected empty file ($filepath)";
      return 1;
    fi
  }







#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------


  main(){
    local filepath=$1 lbl=$2 ret err;
    if [ -n "$filepath" -a -n "$lbl" ]; then
      block_print "$lbl" "$filepath"

      [ -n "$err" ] && stderr "$err" || stderr "$out";
      unset out err;
      return $ret

    else
      echo "error"
      exit 1;
    fi
  }


#-------------------------------------------------------------------------------

  main "$@";
