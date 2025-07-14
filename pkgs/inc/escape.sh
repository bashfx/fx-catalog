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


#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------
  

  # Use hardcoded ANSI escape sequences for performance and portability.
  # The $'\...' syntax tells Bash to interpret the escape codes.
  red2=$'\x1B[38;5;197m';
  red=$'\x1B[31m';
  orange=$'\x1B[38;5;214m';
  yellow=$'\x1B[33m';

  green=$'\x1B[32m';
  blue=$'\x1B[36m';
  blue2=$'\x1B[38;5;39m';
  cyan=$'\x1B[38;5;14m';
  magenta=$'\x1B[35m';

  purple=$'\x1B[38;5;213m';
  purple2=$'\x1B[38;5;141m';
  white=$'\x1B[38;5;248m';
  white2=$'\x1B[38;5;15m';
  grey=$'\x1B[38;5;244m';
  grey2=$'\x1B[38;5;240m';


  revc=$'\x1B[7m';   # Reverse video
  bld=$'\x1B[1m';    # Bold
  x=$'\x1B[0m';      # Reset all attributes
  xx=$'\x1B[0m';     # Alias for reset

  eol=$'\x1B[K';    # Erase to end of line
  eos=$'\x1B[J';    # Erase to end of display
  cll=$'\x1B[1A\x1B[K'; # Move cursor up one line and erase line

  tab=$'\t';
  nl=$'\n';
  sp=' ';

  snek=$'\xe2\x99\x8b';
  itime=$'\xe2\xa7\x97';
  spark=$'\xe2\x9f\xa1';
  flag_off=$'\xe2\x9a\x90';
  flag_on=$'\xe2\x9a\x91';
  diamond=$'\xE1\x9B\x9C';
  arrup=$'\xE2\x86\x91';
  arrdn=$'\xE2\x86\x93';
  darr=$'\u21B3';
  uarr=$'\u21B0';
  delim=$'\x01';
  delta=$'\xE2\x96\xB3';

  #matching icon set now
  fail=$'\u2715';
  pass=$'\u2713';
  recv=$'\u27F2';

  star=$'\xE2\x98\x85';
  lambda=$'\xCE\xBB';
  idots=$'\xE2\x80\xA6';
  bolt=$'\xE2\x86\xAF';
  redo=$'\xE2\x86\xBB';

  uage=$'\u2756';    # ❖
  cmdr=$'\u2318';    # ⌘
  boto=$'\u232C';    # ⌬ robot great
  gear=$'\u26ED'     # ⛭ gear
  rook=$'\u265C'     # ♜ rook
  pawn=$'\u265F'     # ♟ pawn
  king=$'\u26ED'     # ♕ queen/crown
  vtri=$'\u25BD'     # ▽ down triangle
  utri=$'\u25B3'     # △ up triangle <-- delta
  xmark=$'\u292C'    # ⤬ heavy cross
  sword=$'\u2694'    # ⚔︎ crossed swords
  moon=$'\u263E'     # ☾ crescent moon
  sun=$'\u2600'      # ☀︎ sun
  spark=$'\u273B'    # ✻ snowflake/star
  colon2=$'\u2237'   # ∷ double colon
  theref=$'\u2234'   # ∴ therefore
  bull=$'\u29BF'     # ⦿ circled bullet
  sect=$'\u00A7'     # § section symbol
  bowtie=$'\u22C8'   # ⋈ bowtie
  sum=$'\u2211'      # ∑ summation
  prod=$'\u220F'     # ∏ product
  dharm=$'\u2638'    # ☸︎ dharma wheel
  scroll=$'\u07F7'   # ߷ paragraphus / ornament
  note=$'\u266A'     # ♪ music note
  anchor=$'\u2693'   # ⚓ anchor
  unlock=$'\u26BF'   # ⚿ unlocked padlock
  spindle=$'\u27D0'  # ⟐ circled dash / orbital
  anote=$'\u260D'
  

  LINE="$(printf '%.0s-' {1..54})";
  LINE2="$(printf '%.0s-' {1..80})";
  LINE3="$(printf '%.0s-' {1..30})";

#-------------------------------------------------------------------------------
# Experiments
#-------------------------------------------------------------------------------


  #cursor_frames=( '∷'  '⁙' '⁛' '⁘' '·' '⁘' '∷' ) # ('≑' '≒' '≑' '∺'  '⁛' '⁘' '⁞' '⋱' '⋯')
  #cursor_frames=('⠁' '⠂' '⠄' '⡀' '⠄' '⠂')  
  #cursor_frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  cursor_frames=(⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓)
  animate_cursor(){
    while :; do
      for frame in "${cursor_frames[@]}"; do
        printf "${blue}\r%s${x} " "$frame"
        sleep 0.1
      done
    done
  }

  braille_cursor() {
    local msg="${1:-Working...}"
    local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    local i=0
    tput civis
    while :; do
      printf "\r%s %s" "${frames[i]}" "$msg"
      sleep 0.1
      i=$(( (i + 1) % ${#frames[@]} ))
    done
  }

  # braille_cursor "Compiling shaders..." & spinner_pid=$!
  # sleep 3
  # kill "$spinner_pid" && wait "$spinner_pid" 2>/dev/null
  # tput cnorm
  # printf "\r$purple$pass  Shaders compiled.\n"





  up_prompt(){
    local msg="$1"
    local i=0
    tput civis
    while :; do
      printf "${blue}"
      printf "\033[s"               # Save cursor position
      printf "\033[1A\r"            # Move cursor up one line
      printf "%s${x} %s\n" "${cursor_frames[i]}" "$msg"
      printf "\033[u"               # Restore cursor position
      sleep 0.1
      i=$(( (i + 1) % ${#cursor_frames[@]} ))
    done
  }

  test_up_prompt(){
    # Write blank line for spinner to occupy
    printf "\n"

    # Start spinner one line above prompt
    up_prompt "${x}Waiting for user input..." & spinner_pid=$!

    # Clean prompt input area
    read -rp "Enter your name: " user_input

    # Kill spinner, clean up
    kill "$spinner_pid" 2>/dev/null
    wait "$spinner_pid" 2>/dev/null
    tput cnorm

    # Replace spinner line with confirmation
    printf "\033[1A\r✔️  Input received: %s\n" "$user_input"
  }


