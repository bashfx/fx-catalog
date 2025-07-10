#!/usr/bin/env bash
#===============================================================================
#-----------------------------><-----------------------------#
#$ name:stderr
#$ author:qodeninja
#$ date:
#$ semver:
#$ autobuild: 00001
#-----------------------------><-----------------------------#
#=====================================code!=====================================
  
  echo "loaded stderr.sh";
  
  LOCAL_LIB_DIR="$(dirname ${BASH_SOURCE[0]})";
  source "${LOCAL_LIB_DIR}/escape.sh";

#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------
  
  # __debug_mode(){ [ -z "$opt_debug" ] && return 1; [ $opt_debug -eq 0 ] && return 0 || return 1; }
  # __quiet_mode(){ [ -z "$opt_quiet" ] && return 1; [ $opt_quiet -eq 0 ] && return 0 || return 1; }
  opt_silly=${opt_silly:-1};
  opt_trace=${opt_trace:-1};
  opt_debug=${opt_debug:-1};
  opt_yes=${opt_yes:-1};

#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------


  __logo(){
    local logo;
    local src=$1 r1=${2:-3} r2=${3:-9};
    warn 'trying logo';
    if [ -z "$opt_quiet" ] || [ $opt_quiet -eq 1 ]; then
      logo=$(sed -n "${r1},${r2} p" $src)
      printf "\n%b%s %s\n" "$blue" "${logo//#/ }" "$x" 1>&2;
    else
      warn "Logo was caught in quiet mode!";
    fi
  }



  __printx() {
    local text=$1 color=$2 prefix=$3 stream=${4:-2}
    local color_code=${!color:-$white2}
    [ -n "$text" ] && printf "%b" "${color_code}${prefix}${text}${x}" >&$stream
  }

  __log() {
    local type=$1 text=$2 force=$3 stream=2;
    case "$type" in
      dev)   [[ $opt_dev -eq 0 ]]                   && __printx "$text\n" "red2"   "$boto "   $stream ;;
      warn)  [[ $force -eq 0 || $opt_debug -eq 0 ]] && __printx "$text\n" "orange" "$delta "  $stream ;;
      okay)  [[ $force -eq 0 || $opt_debug -eq 0 ]] && __printx "$text\n" "green"  "$pass "   $stream ;;
      info)  [[ $force -eq 0 || $opt_debug -eq 0 ]] && __printx "$text\n" "blue"   "$lambda " $stream ;;
      note)  [[ $force -eq 0 || $opt_debug -eq 0 ]] && __printx "$text\n" "grey"   "$colon2 " $stream ;;
      silly) [[ $force -eq 0 || $opt_silly -eq 0 ]] && __printx "$text\n" "purple" "$idots "  $stream ;;
      recover) [[ $force -eq 0 || $opt_debug -eq 0 ]] && __printx "$text\n" "purple2" "$recv "  $stream ;;
      think) [[ $opt_trace -eq 0 ]]                 && __printx "$text\n" "white2"   "$idots "  $stream ;;
      trace) [[ $opt_trace -eq 0 ]]                 && __printx "$text\n" "grey"   "$darr "  $stream ;;
      error)                                           __printx "$text\n" "red"   "$fail "   $stream ;;
    esac
  }

  recover()  { __log recover  "$1" "${2:-1}"; }
  warn()    { __log warn  "$1" "${2:-1}"; }
  okay()  { __log okay  "$1" "${2:-1}"; }
  info()  { __log info  "$1" "${2:-1}"; }
  note()  { __log note  "$1" "${2:-1}"; }
  silly() { __log silly "$1" "${2:-1}"; }
  trace() { __log trace "$1"; }
  think() { __log think "$1"; }
  error() { __log error "$1"; }
  dev()   { __log dev "$1"; }


  __printf(){
    local text color prefix
    text=${1:-}; color=${2:-white2}; prefix=${!3:-};
    [ -n "$text" ] && printf "${prefix}${!color}%b${x}" "${text}" 1>&2 || :
  }

  stderr(){ printf "%b\n" "$@" 1>&2; }
  __nl(){ printf "\n" 1>&2; }
  __x(){ printf "${x}" 1>&2; };


  __printbox(){
    if [ $opt_quiet -ne 0 ];  then
      local text="${1:-}";         # multiline string or single line
      local color="${2:-white2}";  # color for text + border
      local prefix="${!3:-}";      # optional glyph/symbol
      local stream="${4:-2}";      # default to stderr
      local width=70;              # max width, tweak if needed
      local border_char="-";
      local color_val=${!color:-$white2};
      local none="";
      # Build border line
      local border=""
      while [ ${#border} -lt $width ]; do
        border="${border}${border_char}"
      done

      # Top border
      printf "\n%b\n" "${color_val}${border}${prefix}${x}${nl}" >&$stream

      printf '%s\n' "$text" | while IFS= read -r line || [[ -n "$line" ]]; do
        printf "%b\n" "${sp}${sp}${color_val}${line}${x}" >&$stream
      done

      # Bottom border
      printf "\n%b\n\n" "${color_val}${border}${prefix}${x}" >&$stream
    else
      printf "Refuse to print box! ($opt_quiet)";
    fi
  }

  __boltbox(){ __printbox "$1" "blue" "bolt"; }
  __docbox(){   __printbox "$1" "purple" "lambda"; }
  __errbox(){   __printbox "$1" "red" "none"; }

  # Robust confirmation prompt. Reads from the TTY to avoid consuming piped stdin.
  # Respects the --yes flag.
  __confirm() {
    local prompt="${1:-Are you sure?}" answer

    # If --yes is passed, auto-confirm and don't prompt.
    if [ "${opt_yes:-1}" -eq 0 ]; then
      __printf "${prompt} ${bld}${green}auto-yes${x}\n"
      return 0
    fi

    # Ensure we read from the terminal, not from stdin if it's being piped.
    local tty_dev="/dev/tty"
    if ! [ -t 0 ] && ! [ -c "$tty_dev" ]; then
      error "Cannot ask for confirmation without a terminal."
      return 1 # Fail confirmation
    fi

    while true; do
      # Prompt on stderr, read a single character from the TTY.
      __printf "${prompt} [y/n/q] > " "white2"
      read -r -n 1 answer < "$tty_dev"
      case "$answer" in
        [Yy]) __printf "${bld}${green}yes${x}\n"; return 0 ;;
        [Nn]) __printf "${bld}${red}no${x}\n"; return 1 ;;
        [Qq]) __printf "${bld}${purple}quit${x}\n"; exit 1 ;;
        *)    __printf "\n${yellow}Invalid input. Please try again.${x}\n" ;;
      esac
    done
  }


  __prompt(){
    local msg="$1" default="$2"
     if [ "${opt_yes:-1}" -eq 1 ]; then # Only prompt if opt_yes is NOT 0 (i.e., not auto-yes)
      read -p "$msg --> " answer
      [ -n "$answer" ] && echo "$answer" || echo "$default"
    else # If opt_yes is 0 (auto-yes), just return the default
      echo "$default"
    fi
  }


  xline(){ stderr "${blue}${LINE}↯\n${x}"; }

  #todo: refactor to use __log
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }


  toggle_quiet() {
    opt_quiet=$((1 - opt_quiet))
    return "$opt_quiet"
  }

  toggle_debug() {
    opt_debug=$((1 - opt_debug))
    return "$opt_debug"
  }

  debug_on(){ opt_debug=0; }
  
  quiet_off(){ opt_quiet=1; }

  require_dev(){
    [ "$opt_dev" -eq 0 ] && return 0;
    return 1;
  }

  __flag(){ 
    local flag=${1:-1} lbl=$2 color=;
    [ $flag -eq 0 ] && icon=$flag_on && color=$green;
    [ $flag -eq 1 ] && icon=$flag_off && color=$grey2;
    [ -n "$lbl"   ] && lbl=" ${lbl}"; 
    printf "%b%s%s%b" "$color" "$icon" "$lbl" $x;
  }


#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------
    
  command_exists(){ type "$1" &> /dev/null; }

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
