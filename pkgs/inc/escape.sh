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


  echo "loaded escape.sh";
  
#MORE_GLYPHS="☾☀︎⚁⚂⚅⚀☉✙✚✜♱⚙︎☩⚝☘︎⚑⚐☸︎🀸∇∞÷×∑∬≋&⊛⋈⊛⋒⋓⋐⋑⨂⨹⨺⨻⩏⩛⩚⩓⟡⨳⩩⫷⫏⟐⟑⫶⟡⧊⧇⧈⧗⧖𝒆𝚫𝚲𝜟𝜳𝜰Ω℉℃₵¢€$▽△★☆✕✖︎✓✔︎❁✿✘✰✣☑︎☒◉⦿⇒➲⟿⇪⇧↩︎⟳↻⤬⥰⥼☻☺︎✍︎✌︎♈︎♂︎⚔︎⚉"
#MORE_GLYPHS2="⟿⟼☈☇☁︎⛵︎⚾︎✄♒︎♌︎♋︎♇⚕︎⚚§₽⨏⨍⨘⨜∏∽∾∿≈⋇⧚⧛⧍⧋⧌⧨⧪⅀𝞹𝝿𝝨𝝱𝝰𝝲𝝳𝝷𝝵𝝺𝞃𝞇𝞅𝞈𝚲𝕭⦼⦼⦻⦜⦛⦝⦨⫎⫐☈♜♛♚☕︎♌︎"
##☾⚯⚮⚭⚬☌⚲☉☍⚭∘∷∴⊚◎◉⦿◦✱❈※❆✻߷⚿⟐⮧

#߷⚿⟐⮧
#⎌ undo U+238C
#⟲ ⟳ redo U+27F2  ↩
# ↲” (U+21B2)
# “↯” (U+21AF)
# ↶ (U+21B6)

#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------
  
  #still reviewing this, ignore color/term stuff for now
  # if command_exists tput && [ "${TERM:-}" != "dumb" ]; then
  #   :
  # else
  #   :
  # fi

  red2=$(tput setaf 197);
  red=$(tput setaf 9);
  orange=$(tput setaf 214);
  yellow=$(tput setaf 3);

  green=$(tput setaf 2);
  blue=$(tput setaf 6);
  blue2=$(tput setaf 39);
  cyan=$(tput setaf 14);

  purple=$(tput setaf 213);
  purple2=$(tput setaf 141);
  white=$(tput setaf 248);
  white2=$(tput setaf 15);
  grey=$(tput setaf 244);
  grey2=$(tput setaf 240);


  revc=$(tput rev);

  #we need to stop using $x here, but cannot until we clean them all up.
  x=$(tput sgr0); #deprec this

  #slighter newer x may rename this still
  xx=$(tput sgr0);
  
  eol="$(tput el)";
  eos="$(tput ed)";
  cll="$(tput cuu 1 && tput el)";
  bld="$(tput bold)";
  


  line="##---------------$nl";
  tab=$'\\t';
  nl=$'\\n';
  sp='\x20';

  snek='\xe2\x99\x8b';
  itime='\xe2\xa7\x97';
  spark='\xe2\x9f\xa1';
  flag_off="\xe2\x9a\x90"; 
  flag_on="\xe2\x9a\x91"; 
  diamond='\xE1\x9B\x9C';
  arrup='\xE2\x86\x91';
  arrdn='\xE2\x86\x93';
  darr="\u21B3";
  uarr="\u21B0";
  delim='\x01';
  delta="\xE2\x96\xB3";
  #pass="\xE2\x9C\x93";
  #fail="\xE2\x9C\x97";
  fail=$'\u2715';
  pass=$'\u2713';
  recv=$'\u27F2';

  star="\xE2\x98\x85";
  lambda="\xCE\xBB";
  idots="\xE2\x80\xA6";
  bolt="\xE2\x86\xAF";
  spark="\xe2\x9f\xa1";
  redo="\xE2\x86\xBB";
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
