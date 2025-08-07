#!/usr/bin/env bash



    ARGS=("${@}");
    #MORE_GLYPHS="☾☀︎⚁⚂⚅⚀☉✙✚✜♱⚙︎☩⚝☘︎⚑⚐☸︎🀸∇∞÷×∑∬≋&⊛⋈⊛⋒⋓⋐⋑⨂⨹⨺⨻⩏⩛⩚⩓⟡⨳⩩⫷⫏⟐⟑⫶⟡⧊⧇⧈⧗⧖𝒆𝚫𝚲𝜟𝜳𝜰Ω℉℃₵¢€$▽△★☆✕✖︎✓✔︎❁✿✘✰✣☑︎☒◉⦿⇒➲⟿⇪⇧↩︎⟳↻⤬⥰⥼☻☺︎✍︎✌︎♈︎♂︎⚔︎⚉"
    #MORE_GLYPHS2="⟿⟼☈☇☁︎⛵︎⚾︎✄♒︎♌︎♋︎♇⚕︎⚚§₽⨏⨍⨘⨜∏∽∾∿≈⋇⧚⧛⧍⧋⧌⧨⧪⅀𝞹𝝿𝝨𝝱𝝰𝝲𝝳𝝷𝝵𝝺𝞃𝞇𝞅𝞈𝚲𝕭⦼⦼⦻⦜⦛⦝⦨⫎⫐☈♜♛♚☕︎♌︎"
    ##☾⚯⚮⚭⚬☌⚲☉☍⚭∘∷∴⊚◎◉⦿◦✱❈※❆✻߷⚿⟐⮧


    invert='\e[7m';
    italic='\e[3m';


    deep=$'\x1B[38;5;61m';
    deep_green=$'\x1B[38;5;60m';

    red3=$'\x1B[38;5;197m';
    red2=$(tput setaf 1)
    red=$(tput setaf 9)
    yellow=$'\x1B[33m';
    orange=$'\x1B[38;5;214m';
    orange2=$'\x1B[38;5;221m';
    green3=$(tput setaf 41)
    green2=$'\x1B[38;5;156m';
    green=$'\x1B[38;5;10m';
    magenta=$'\x1B[35m';
    blue=$'\x1B[36m';
    blue2=$'\x1B[38;5;39m';
    cyan=$'\x1B[38;5;51m';
    purple=$'\x1B[38;5;213m';
    purple2=$'\x1B[38;5;141m';
    grey=$'\x1B[38;5;242m';
    grey2=$'\x1B[38;5;240m';
    grey3=$'\x1B[38;5;237m';
    white=$'\x1B[38;5;247m';
    white2=$'\x1B[38;5;15m';

    LINE="$(printf '%.0s-' {1..54})";
    LINE2="$(printf '%.0s-' {1..80})";
    LINE3="$(printf '%.0s-' {1..30})";

    fail=$'\u2715';
    pass=$'\u2713';
    recv=$'\u27F2';

    uclock=$'\u23F1'    # ⏱
    uclock2=$'\u23F2'   # ⏲
    uhour=$'\u29D6'     # ⧖ 
    udate=$'\u1F5D3'    # 🗓
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
    snow=$'\u273B'    # ✻ snowflake/star
    colon2=$'\u2237'   # ∷ double colon
    theref=$'\u2234'   # ∴ therefore
    bull=$'\u29BF'     # ⦿ circled bullet
    sect=$'\u00A7'     # § section symbol
    bowtie=$'\u22C8'   # ⋈ bowtie

    lambda="\xCE\xBB"
    line="$(sed -n '2,2 p' $BASH_SOURCE)$nl"
    bline="$(sed -n '3,3 p' $BASH_SOURCE)$nl"
    xx=$'\x1B[0m';
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
    ulock=$'\u26BF'
    boto=$'\u232C'
    delta='\xE2\x96\xB3'
    #pass='\xE2\x9C\x93'
    #fail='\xE2\x9C\x97'
    dots='\xE2\x80\xA6'
    bolt="\xE2\x86\xAF"
    redo='\xE2\x9F\xB3'
    space='\x20'
    eol="$(tput el)"
    eos="$(tput ed)"
    cll="$(tput cuu 1 && tput el)"
    bld="$(tput bold)"
    rvm="$(tput rev)"

    color_filter(){
      local color_name="${1:-grey}";
      local color_code=${!color_name};
      local reset_code=${xx};
      trap 'printf "%s" "${reset_code}"' EXIT;
      printf "%s" "${color_code}";
      cat
    }

    stream_array() {
      local array_name="$1";
      if [[ ! "$(declare -p "$array_name" 2>/dev/null)" =~ ^declare\ -[aA] ]]; then
        error "Error: stream_array expects the name of an array as its argument." >&2;
        return 1;
      fi
      local -n arr_ref="$array_name";
      printf "%s\n" "${arr_ref[@]}";
    }

    #function stderr(){ printf "${@}${x}\n" 1>&2; }
    main(){
      local text color prefix revc
      text=${1:-}; color=${2:-grey}; prefix=${!3:-}; styl=${4:-}
      [ -n "$styl" ] && styl=$rvm ||:
      [ -n "$text" ] && printf "${styl}${!color}${prefix} %b${xx}\n" "${text}" 1>&2 || :
    }

  #stream_array ARGS |  pr -4 -t -s'|' | column -t -s'|' | list_filter  >&2;


# --------------------------------------------------

  main "$@";
