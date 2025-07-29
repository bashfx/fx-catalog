#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name:colorx
#$ autobuild: 00005
#$ author:qodeninja
#$ updated: Wed 2019-07-31 10:40 PM

#TODO: cleanup and bring into fx style

#-------------------------------------------------------
# Color X thing!
#-------------------------------------------------------
  #shopt -s lastpipe
  set -o pipefail
  shopt -s xpg_echo
  shopt -s expand_aliases

  trap fatal EXIT


#> infocmp screen
#>  {ESC}[{attr};{bg};{256colors};{fg}m
#----------------------------------------------------
# ENV OPTIONS
#----------------------------------------------------

  OPT_COLOR_DISABLE=false
  OPT_DATA_DIR=

#----------------------------------------------------
# STREAMS
#----------------------------------------------------


  [ -p /dev/stdin ] && term=0
  [ ! -t 0 -a ! -p /dev/stdin ] && term=0
  [ -t 0 ] && term=1


#----------------------------------------------------
# TERM
#----------------------------------------------------

  x=$(tput sgr0) #el wasnt working
  red=$(tput setaf 1)
  green=$(tput setaf 2)
  blue=$(tput setaf 12)
  yellow=$(tput setaf 11)
  fail="${red}\xE2\x9C\x97${x}"
  pass="${green}\xE2\x9C\x93${x}"

#----------------------------------------------------
# DIRECTORY AWARE
#----------------------------------------------------

  dir=""
  fg="▒"
  bg=" "

  _fx=( grid grid2 near256 to_hex to_rgb block blocks to_dec help \? )


#-------------------------------------------------------
# parse opts
#-------------------------------------------------------

  in_array(){
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
  }

      
  # command_exists(){ type "$1" &> /dev/null; }
  
  cmd_exists(){
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "I require $1 but it's not installed.  Aborting."; exit 1; }
  }

  cmd_fail() {
    trap - EXIT
    msg="${@}"
    echo -e "$fail ${msg} $x" && exit 1
  }

  fatal(){
    exit 1
  }

  usage(){
    local data
    data+=""
    data="$(cat <<-EOF

      Legacy Script, no guards!

      grid [n]      - 1 to n
      grid2         - generate 256 colors

      block   [n]   - (0-255) num to color grid
      blocks [seq]  - block for each seq number

      near256       - convert > hhhhhh -> bbb
      to_hex        - convert > rr gg bb -> hhhhhh
      to_rgb        - convert > hhhhhh -> rr gg bb
      to_dec        - convert > hh -> d

      help    - this.

EOF
    )";
    echo "$data"
  }


#-------------------------------------------------------
# parse opts
#-------------------------------------------------------
  args=("${@}")

  # help
  if [[ $@ =~ "?" || $@ =~ "help" ]]; then
    usage;
    exit 0;
  fi


  for i in ${!args[@]}; do
    this="${args[$i]:-}"
    if [[ "$this" =~ ^-.* ]]; then
      echo "thats an option"
    else
      if [ -z $cmd ]; then
        in_array "${this}" "${_fx[@]}";
        [ $? = 1 ] && arg_err="Unregistered command ($blue$this$x)" || cmd="$this";
      else
        cmd_args+=($this)
      fi
    fi
  done

  [ -n "$arg_err" ] && cmd_fail $arg_err || [ "$opt_dev_debug" = true ] && echo "$yellow$cmd ${cmd_args[@]}$x"

#-------------------------------------------------------
# Bash Color Stuff
#-------------------------------------------------------



  grid() {
    def=$(tput colors)
    len=${1:-$def}
    if cmd_exists tput && [ ! -z $len ]; then
      for i in $(seq 1 $len); do tput setab $i; echo -n "  $i "; done; tput setab 0; echo
    else
      echo "Error - <tput> command not found"
    fi
  }


  #----------------------------------------------------
  #2-bit (0-255) num to color grid
  #
  block(){
    new=$((10#$1)) #strip leading 0
    #echo $new
    printf '\e[48;5;%dm%03d' $new $new
    printf '\e[0m \n'
  }

  blocks(){
    for c; do
      c=$((10#$c))
      printf '\e[48;5;%dm%03d %d' $c $c $n
    done
    printf '\e[0m \n'
  }

  grid2() {
    IFS=$' \t\n'
    blocks {0..15}
    for ((i=0;i<6;i++)); do
        blocks $(seq $((i*36+16)) $((i*36+51)))
    done
    blocks {232..255}
  }

  #----------------------------------------------------



  #----------------------------------------------------

  #-------------------
  # ~ hhhhhh -> bbb
  #-------------------
  near256(){
    hex=${1#"#"}
    r=$(printf '0x%0.2s' "$hex")
    g=$(printf '0x%0.2s' ${hex#??})
    b=$(printf '0x%0.2s' ${hex#????})
    printf '%03d\n' "$(( (r<75?0:(r-35)/40)*6*6 + \
                         (g<75?0:(g-35)/40)*6   + \
                         (b<75?0:(b-35)/40)     + 16 ))"
  }

  #-------------------
  # rr gg bb -> hhhhhh
  #-------------------
  to_hex() {
    local a b c=({0..9} {a..f}) d=''
    for b;do
        for a in / % ;do
          d+=${c[$b$a 0x10]}
        done
    done
    echo $d
  }

  #-------------------
  # hh -> d
  #-------------------
  to_dec(){
    printf "%d\n" "0x${1}"
    #$((0x${hexNum}))
  }

  #progression  00 5F 87 AF D7 FF

  #-------------------
  # hhhhhh -> rr gg bb
  #-------------------
  to_rgb() {
    str="${1//[\#]/}" #remove hash
    [ -n "$str" ] && printf "%d %d %d\n" 0x${str:0:2} 0x${str:2:2} 0x${str:4:2} \
    || cmd_fail "Invalid input, try without leading hash 'FFFFFF' vs '#FFFFFF''"
  }

  #----------------------------------------------------

   pipe() {
    echo 1
  }

  

# echo 12345-1234 | printf 'Zip: %s\n' $(</dev/stdin) Zip: 12345-1234 # echo 1 2 3 4 | printf 'Number: %d\n' $(</dev/stdin) Number: 1 Number: 2 Number: 3 Number: 4

#----------------------------------------------------
# DRIVER
#----------------------------------------------------
  #echo $0 $1 $2 $3 $4
  #echo $cmd

  if [ $term -eq 0 ]; then
    while IFS=" " read -r line; do
      $cmd $line
    done #<<< "$(</dev/stdin)"
  else
    eval $@
  fi
