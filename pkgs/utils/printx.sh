#!/usr/bin/env bash




    #MORE_GLYPHS="☾☀︎⚁⚂⚅⚀☉✙✚✜♱⚙︎☩⚝☘︎⚑⚐☸︎🀸∇∞÷×∑∬≋&⊛⋈⊛⋒⋓⋐⋑⨂⨹⨺⨻⩏⩛⩚⩓⟡⨳⩩⫷⫏⟐⟑⫶⟡⧊⧇⧈⧗⧖𝒆𝚫𝚲𝜟𝜳𝜰Ω℉℃₵¢€$▽△★☆✕✖︎✓✔︎❁✿✘✰✣☑︎☒◉⦿⇒➲⟿⇪⇧↩︎⟳↻⤬⥰⥼☻☺︎✍︎✌︎♈︎♂︎⚔︎⚉"
    #MORE_GLYPHS2="⟿⟼☈☇☁︎⛵︎⚾︎✄♒︎♌︎♋︎♇⚕︎⚚§₽⨏⨍⨘⨜∏∽∾∿≈⋇⧚⧛⧍⧋⧌⧨⧪⅀𝞹𝝿𝝨𝝱𝝰𝝲𝝳𝝷𝝵𝝺𝞃𝞇𝞅𝞈𝚲𝕭⦼⦼⦻⦜⦛⦝⦨⫎⫐☈♜♛♚☕︎♌︎"
    ##☾⚯⚮⚭⚬☌⚲☉☍⚭∘∷∴⊚◎◉⦿◦✱❈※❆✻


    red2=$(tput setaf 1)
    red=$(tput setaf 9)
    yellow=$(tput setaf 11)
    orange=$(tput setaf 214)
    green=$(tput setaf 41)
    blue=$(tput setaf 39)
    blue2=$(tput setaf 12)
    cyan=$(tput setaf 123)
    purple=$(tput setaf 213)
    grey=$(tput setaf 244)
    grey2=$(tput setaf 240)
    white=$(tput setaf 15)
    white2=$(tput setaf 248)

    LINE="$(printf '%.0s-' {1..54})";
    LINE2="$(printf '%.0s-' {1..80})";
    LINE3="$(printf '%.0s-' {1..30})";

    lambda="\xCE\xBB"
    line="$(sed -n '2,2 p' $BASH_SOURCE)$nl"
    bline="$(sed -n '3,3 p' $BASH_SOURCE)$nl"
    x=$(tput sgr0)
    sp="   "
    tab=$'\t'
    nl=$'\n'
    snek='\xe2\x99\x8b'
    itime='\xe2\xa7\x97'
    spark='\xe2\x9f\xa1' 
    flag_on="\xe2\x9a\x90" 
    flag_off="\xe2\x9a\x91" 
    diamond='\xE1\x9B\x9C'
    arrup='\xE2\x86\x91'
    arrdn='\xE2\x86\x93'
    darr="\u21B3"
    uarr="\u21B0"
    delim='\x01'
    delta='\xE2\x96\xB3'
    pass='\xE2\x9C\x93'
    fail='\xE2\x9C\x97'
    dots='\xE2\x80\xA6'
    bolt="\xE2\x86\xAF"
    redo='\xE2\x9F\xB3'
    space='\x20'
    eol="$(tput el)"
    eos="$(tput ed)"
    cll="$(tput cuu 1 && tput el)"
    bld="$(tput bold)"
    rvm="$(tput rev)"

    #function stderr(){ printf "${@}${x}\n" 1>&2; }
    function main(){
      local text color prefix revc
      text=${1:-}; color=${2:-grey}; prefix=${!3:-}; revc=${4:-}
      [ -n "$revc" ] && revc=$rvm ||:
      [ -n "$text" ] && printf "${!color}${prefix} ${revc}%b${x}\n" "${text}" 1>&2 || :
    }



  #export GLYPH="\xE2\x9C\x93:\xE2\x9C\x97:\xE2\x96\xB3:\xCE\xBB:\xE2\x80\xA0:\xC2\xBB:\xE2\x94\x94:\xE2\x80\xA6:\xE2\x80\xBB"
  #export GLYPH=(${GLYPH//:/ })


  #dagger="\xE2\x80\xA0"
  #mark="\xE2\x80\xBB" #\xE2\x96\x88
  #dots="\xE2\x80\xA6"
  #dash="${bl2}\xE2\x80\x95"
  #delta="${orange}\xCE\x94"
  #flecha="\xC2\xBB "
  #square="\xE2\x95\x90" #\xE2\x96\xA1"
  #hook="\xE2\x94\x94"
  #flake="\xE2\x9D\x86"

  
#-------------------------------------------------------------------------------

  main "$@";
