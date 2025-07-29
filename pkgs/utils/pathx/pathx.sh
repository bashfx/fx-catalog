#!/usr/bin/env bash
#===============================================================================

# docx now with bolt!
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
  zap="\xE2\x86\xAF"
  #redo='\xE2\x9F\xB3'
  space='\x20'
  eol="$(tput el)"
  eos="$(tput ed)"
  cll="$(tput cuu 1 && tput el)"
  bld="$(tput bold)"
  rvm="$(tput rev)"

#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  stderr(){ printf "${@}${x}\n" 1>&2; }
  
#-------------------------------------------------------------------------------
# SED Utils
#-------------------------------------------------------------------------------
  
  #sed block parses self to find meta data
  sed_block(){
    local id="$1" filepath="$2" pre="^[#]+[=]+" post=".*" str end;
    str="${pre}${id}[:]?[^\!=\-]*\!${post}";
    end="${pre}\!${id}[:]?[^\!=\-]*${post}";
    sed -rn "1,/${str}/d;/${end}/q;p" $filepath | tr -d '#' | replace_escape_codes;
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
    # Replace the color codes in the input 
    echo "$input" |  sed "s/\${x}/$x/g; s/\${rev}/$revc/g; s/\${r}/$red/g; s/\${o}/$orange/g;  s/\${c}/$cyan/g;  s/\${g}/$green/g; s/\${isnek}/$snek/g; s/\${it}/$itime/g; s/\${id}/$delta/g; s/\${il}/$lambda/g; s/\${isp}/$spark/g;  \
    s/\${spark}/$spark/g; s/\${star}/$star/g; s/\${bolt}/$bolt/g; \
    s/\${b2}/$blue2/g; s/\${w2}/$white2/g; s/\${p}/$purple/g;  s/\${u}/$grey/g; \
    s/\${y}/$yellow/g; s/\${b}/$blue/g; s/\${w}/$white/g;  s/\${u2}/$grey2/g; \
    s/\${bld}/$bold/g; s/\${line}/$line/g; s/\${iz}/$zap/g; s/\${LINE}/$LINE/g; ";
  }

  #prints content between sed block
  block_print(){
    local lbl="$1" filepath="$2" IFS res ret;
    res=$(sed_block $lbl $filepath);ret=$?;
    if [ ${#res} -gt 0 ]; then
      while IFS= read -r line; do
        [[ $lbl =~ doc.*|inf.* ]] && line=$(printf '%b\n' "$line") || line=$(printf '%s\n' "$line");
        echo -e "$line"
      done <<< "$res"
    else
      return 1;
    fi
  }



#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------


  main(){
    local filepath=$1 lbl=$2
    if [ -n "$filepath" -a -n "$lbl" ]; then
      block_print "$lbl" "$filepath"
    else
      echo "error"
      exit 1;
    fi
  }


#-------------------------------------------------------------------------------

  main "$@";
