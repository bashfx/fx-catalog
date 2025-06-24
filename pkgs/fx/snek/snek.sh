#!/usr/bin/env bash
#===============================================================================
#
#                   _
#    ___ _ __   ___| | __
#   / __| '_ \ / _ \ |/ /
#   \__ \ | | |  __/   <
#   |___/_| |_|\___|_|\_\
#
#
#-------------------------------------------------------------------------------
#$ name:fx-snek (--> snek)
#$ author:qodeninja
#$ date:
#$ semver:
#$ autobuild: 00004
#
#
# Note
# - very alpha version!
# - turned a janky script file into a full on fx
# - dumped a bunch of funcs, some redundant or unused -- cleanup
# - renamed from pyx -> snek more fun
# - dont clean from $HOME, find is super recursive!
# - dispatcher commands using the do_echo proxy are not fully tested
#   use the --yes flag to override the confirm bumper
# - just want to print snek? now you can > snek hi
# - 
#-------------------------------------------------------------------------------
#=====================================code!=====================================

#!!! embedded usage needs docx or .docfile output
#?   use readline for checking symlinks fqn ?
#?   support add from any path with python file?

#-------------------------------------------------------------------------------
# Vars and Paths
#-------------------------------------------------------------------------------

  #====================================

    PYX_PYTHONPATH=

    PYX_RC="$HOME/.pyxrc"
    PYX_HOME="$HOME/.my/etc/fx/pyx";
    PYX_PATH_FILE="$PYX_HOME/pythonpath";
    
    profile_src="$HOME/.profile"

    PYX_AUTO_INIT=
    PYX_SPY_MODE=

    #ERR_NO_PATH=1
  #====================================

  opt_dev=1
  opt_debug=1
  opt_quiet=1
  opt_trace=1 #TODO:remove trace
  opt_byte=1
  opt_spy=1;
  opt_clean=1;
  opt_init=1;
  opt_yes=1;  
  opt_here=1;  
  opt_boring=1;

#-------------------------------------------------------------------------------
# Std Term
#-------------------------------------------------------------------------------

  red=$(tput setaf 197)
  green=$(tput setaf 41)
  blue=$(tput setaf 39)
  orange=$(tput setaf 214)
  purple=$(tput setaf 213)
  white=$(tput setaf 248)
  white2=$(tput setaf 15)
  grey=$(tput setaf 244)
  grey2=$(tput setaf 245)
  revc=$(tput rev)
  bld=$(tput bold)
  x=$(tput sgr0)
  LINE="$(printf '%.0s-' {1..54})";
  delta="\xE2\x96\xB3"
  pass="\xE2\x9C\x93"
  fail="\xE2\x9C\x97"
  lambda="\xCE\xBB"
  idots="\xE2\x80\xA6"
  bolt="\xE2\x86\xAF"
  redo="\xE2\x86\xBB"
  gly_py="\u264B︎" #♋︎
  gly_on="\u2691" #⚐
  gly_off="\u2690" #⚐

#----------------------------------------------------
# PYX  GLYPHS              
#----------------------------------------------------

  export GLYPH_PY=" ${green}${gly_py}SNEK ${x}"
  export GLYPH_PY_ERR=" ${red}${gly_py}SNEK ${x}"
  export GLYPH_PY_WARN=" ${orange}${gly_py}SNEK ${x}"
  export GLYPH_SPY=""
  export SNEK="${green}._._|⧖|⧖|\|\|\8)${red}~${x}"

#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------

  __logo(){
    if [ $opt_boring -eq 1 ]; then
      if [ -z "$opt_quiet" ] || [ $opt_quiet -eq 1 ] ; then
        local logo=$(sed -n '3,9 p' $BASH_SOURCE)
        printf "\n    $green$gly_py$(python --version)${logo//#/ }\n$x\n" 1>&2;
      fi
    fi
  }

  # __printf(){
  #   local text color prefix
  #   text=${1:-}; color=${2:-white2}; prefix=${!3:-};
  #   [ -n "$text" ] && printf "${prefix}${!color}%b${x}" "${text}" 1>&2 || :
  # }

  __printf(){
    local text color prefix revc
    text=${1:-}; color=${2:-grey}; prefix=${!3:-}; revc=${4:-}
    [ -n "$revc" ] && revc=$rvm ||:
    [ -n "$text" ] && printf "${!color}${prefix} ${revc}%b${x}\n" "${text}" 1>&2 || :
  }


  __confirm() {
    local ret=1 answer src
    opt_yes=${opt_yes:-1}
    __printf "${1}? > " "white2"
    [ $opt_yes -eq 0 ] && { __printf "${bld}${green}auto yes${x}\n"; return 0; }
    src=${BASH_SOURCE:+/dev/stdin} || src='/dev/tty'

    while read -r -n 1 -s answer < $src; do
      [[ $? -eq 1 ]] && exit 1
      [[ $answer = [YyNn10tf+\-q] ]] || continue
      case $answer in
        [Yyt1+]) __printf "${bld}${green}yes${x}"; val='yes'; ret=0 ;;
        [Nnf0\-]) __printf "${bld}${red}no${x}"; val='no'; ret=1 ;;
        [q]) __printf "${bld}${purple}quit${x}\n"; val='quit'; ret=1; exit 1;;
      esac
      break
    done
    #echo "$val"
    __printf "\n"
    return $ret
  }


  stderr(){ printf "${@}${x}\n" 1>&2; }

  warn(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf " $delta $text$x\n" "orange"; }
  okay(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf " $pass $text$x\n" "green"; }
  info(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] && __printf " $lambda $text\n" "blue"; }

  #\trace(){ local text=${1:-}; [ $opt_trace -eq 0 ] && __printf "$idots $text\n" "grey"; }
  error(){ local text=${1:-}; __printf " $text\n" "fail"; }
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }

  xline(){ stderr "${blue}${LINE}↯\n${x}"; }

  printx(){
    local text=${1:-} color=${2:-white2} glyph=${3:-}
    __printf "$text" "$color" "$glyph"
  }

#----------------------------------------------------
#  Py Term
#----------------------------------------------------
# hmm 

  pyout(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$gly_py $text$x" "green"; }
  stdpy(){ printf "${GLYPH_SPY}${GLYPH_PY}${@}${x}\n" 1>&2; }
  stdpyerr(){ printf "${GLYPH_SPY}${GLYPH_PY_ERR}${red}${@}${x}\n" 1>&2; }
  stdpywarn(){ printf "${GLYPH_SPY}${GLYPH_PY_WARN}${orange}${@}${x}\n" 1>&2; }

#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------
# probably dont need traps we'll see

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

  trap handle_interupt INT # trap ctrl_c_handler SIGINT ?
  trap handle_stop SIGTSTP # Ctrl-Z 
  trap handle_input CONT
  trap fin EXIT


#----------------------------------------------------
#            
#----------------------------------------------------


  options(){
    local this next opts=("${@}");
    for ((i=0; i<${#opts[@]}; i++)); do
      this=${opts[i]}
      next=${opts[i+1]}
      case "$this" in
        --spy|-s)
          opt_spy=0;
          opt_init=0;
          ;;
        --clean)
          opt_clean=0;
          ;;
        --init)
          opt_init=0;
          ;;
        --boring)
          opt_boring=0;
          ;;
        --yes)
          opt_yes=0;
          ;;
        --here)
          opt_here=0;
          ;;
        --byte|-b)
          opt_byte=0
          ;;
        --quiet|-q)
          opt_quiet=0
          opt_debug=1
          opt_trace=1
          ;;
        --tra*|-t)
          opt_trace=0
          opt_debug=0
          opt_quiet=1
          ;;
        --dev|-D)
          opt_dev=0
          opt_debug=0
          opt_quiet=1
          ;;
        --debug|-v)
          opt_debug=0
          opt_quiet=1
          ;;
        *)
          shift 
          ;;
      esac
    done


  }



#----------------------------------------------------
#            
#----------------------------------------------------


  do_spy_mode(){
    if [ $opt_spy -eq 0 ];  then
      if [ -n "$PYTHONPATH" ]; then
        export PYX_DEBUG=0
        export GLYPH_SPY=" ${purple}⨳${x}"
        stdpy "${blue}-> ${gly_on} site-customize enabled."
      else
        stdpyerr "Spy mode cant run without an active PYTHONPATH."
      fi
    else
      export PYX_DEBUG=1
      GLYPH_SPY=
      stdpy "${orange}-> ${gly_off} site-customize disabled."
    fi
  }

#----------------------------------------------------
#            
#----------------------------------------------------

  # [ -L "$ref" ] && {
  #   err="Mark ($lbl) already exists.\n";
  #   err+="${imark}$lbl => $(readlink $ref)"; ret=1;
  # }


  add_path_file(){

    local this_path=$1 ret=1

    if [ -d $this_path ]; then

      if [ -f $PYX_PATH_FILE ]; then
        if ! grep -q "$this_path" $PYX_PATH_FILE; then
          echo "$this_path" >> $PYX_PATH_FILE
          ret=$?

          #auto_generate
          if is_linked; then
            info "Profile is linked with pyxrc file. Regen?"
          else
            error "Profile missing pyxrc! Wont autoload"
          fi

        else
          stdpywarn "Path already in pathfile! ($this_path)"
        fi
      else
        stdpyerr "cant add path without a pathfile. try --init flag"
      fi

    else
      stdpyerr "File [$this_path] does not exist. Not added to PYTHONPATH"
    fi

    return $ret

  }

  rem_path_file(){
    local this_path=$1 ret
    if grep -q "$this_path" $PYX_PATH_FILE; then
      sed -i.bak "$this_path" "$PYX_PATH_FILE"
    fi
  }

  clear_path_file(){
    if [ -f "$PYX_PATH_FILE" ]; then
      rm "$PYX_PATH_FILE" 
    fi
  }

  load_ppath_file(){
    local THIS_PATH line

    info "pathfile is $PYX_PATH_FILE"

    if [ -f "$PYX_PATH_FILE" ]; then

      while IFS= read -r row; do
        if [[ -n "$row" ]]; then
          if [ -d "$row" ]; then
            if [[ -z "$THIS_PATH" ]]; then
              THIS_PATH="$row"
            else
              THIS_PATH="$THIS_PATH:$row"
            fi
          else
            stderr "Skipping $row. Dir not found."
          fi
        fi
      done < "$PYX_PATH_FILE"


    else
      stdpyerr "Cannot build PYTHONPATH missing path file."
    fi
    echo -ne "$THIS_PATH"
  }


  rc_file_str(){
    local data
    data+=""
    data="$(cat <<-EOF
      #!/usr/bin/env bash

      ### pyx rc file ###
      # do not edit
      # created: $(date)

        PYX_PYTHONPATH="$PYX_PYTHONPATH"
        n="\$PYX_PYTHONPATH"
        p="\$PYTHONPATH"; 
        case ":\$p:" in
          *":\$n:"*) 
            echo -ne "$grey$pass--> [pypath] unchanged$x";
          ;;
          *)  
            export PYTHONPATH=\$p:\$n;
            printx "--> [pypath] changed" "green" "bolt";
          ;;
        esac
        if [ -z "\$PYTHONPATH" ]; then
          printx "--> [pypath] not set" "red" "redo";
        fi

EOF
    )";
    echo "$data"
  }




  is_linked(){
    grep -q "source ${PYX_RC}" $profile_src; 
  }


  unlink_profile(){
    local src="$PYX_RC"
    if grep -q "source ${src}" $profile_src; then
      sed -i.bak '/source .*\.pyxrc/d' "$HOME/.profile"
    else
      warn "Nothing to unlink..."
    fi
  }


  link_profile(){
    local msg src="$PYX_RC"

    if [ -z "$PYX_PYTHONPATH" ]; then
      msg="PYX_PYTHONPATH was empty trying to create rc file." 
      if [ $opt_here -eq 1 ]; then
          stdpyerr "$msg Exiting."
          exit
        else
          stdpywarn "$msg"
      fi
    fi



    #dump rc file
    data="$(rc_file_str)"
    echo -e "$data" > $src

    #link rc file
    if [ -f "${src}" ]; then
      if ! grep -q "source ${src}" $profile_src; then
        echo "source ${src}" >> $profile_src
        ret=$?

        if [ $opt_debug -eq 0 ]; then 
          info "Dumping generated pyxrc file"
          cat "$src"
        fi

      else
        #echo "source line already added"
        ret=0
      fi
    else
      ret=1 
    fi
  
  }

  dump_rc(){
    if [ -n $PYX_RC ]; then
      cat "$PYX_RC"
    else
      stdpyerr "Sas snek, no rc file. Try -> snek update"
    fi
  }

  make_ppath_rc(){
    local src data ret=1 THIS_PATH
    src="$PYX_RC"
    if [ -n $src ]; then
      #build path 
      THIS_PATH=$(load_ppath_file)
      if [ -n "$THIS_PATH" ]; then
        export PYX_PYTHONPATH=$THIS_PATH
        link_profile
      else
        stdpyerr "Pathfile was empty." 
      fi
    fi
    return $ret
  }


  do_update_ppath(){
    if make_ppath_rc; then
      stdpy "Linking ${PYX_RC} to profile."         
    else
      stdpyerr "Oops. couldnt make rc file!"
    fi
  }

#----------------------------------------------------
#            
#----------------------------------------------------

  add_pythonpath() {
    for d; do
      d=$(cd -- "$d" && { pwd -P || pwd; }) 2>/dev/null  # canonicalize symbolic links
      if [ -z "$d" ]; then continue; fi  # skip nonexistent directory
      case ":$PYTHONPATH:" in
        *":$d:"*) :;;
        *) export PYTHONPATH=$PYTHONPATH:$d;;
      esac
    done
  }

#----------------------------------------------------
#            
#----------------------------------------------------

  run_and_check(){
    "$@"
    ret=$?
    if [ $ret -ne 0 ]; then
      stdpyerr "Error with '$*': Exited with status $status" 
      exit $status
    else
      stdpy "task '$*' done."
      return 0
    fi
  }

#----------------------------------------------------
#            
#----------------------------------------------------

  do_pythonable(){
    local this=
    if [ -d "./bin" ]; then
      this="${PWD}/bin" 
    fi 

    if [ -d "./src" ]; then
      this="${PWD}/src" 
    fi 

    if [ -f "./sitecustomize.py" ]; then
      this="${PWD}/sitecustomize.py"
    fi 

    if [ $opt_here -eq 0 ]; then
      this="${PWD}"
    fi

    for f in ./*.py; do
      if [ -f "$f" ]; then
        this="${PWD}" 
        break
      fi
    done

    if [ -z "$this" ]; then
      stdpyerr "did not find a pythonable path here."
    else
      echo $this
    fi
  }

  do_add_path(){
    local ret=1 this=$(do_pythonable)
    if [ -n "$this" ]; then
      add_path_file "${this}"
      ret=$?
      [ $ret -eq 0 ] && stdpy "added path to snek's pathfile. ($this)"
    fi
  }

  do_rm_path(){
    local ret=1 this=$(do_pythonable)
    if [ -n "$this" ]; then
      rem_path_file "${this}"
      ret=$?
      [ $ret -eq 0 ] && stdpy "removed path from snek's pathfile. ($this)"
    fi
  }

  do_path(){
    if [ -n "$PYTHONPATH" ]; then
      stdpy "PYTHONPATH:"
      echo -e ${PYTHONPATH//:/\\n}
    else
      stdpyerr "-> PYTHONPATH empty!"
    fi
  }

#----------------------------------------------------
#            
#----------------------------------------------------

  do_dev_dty(){
    #debug this yo
    local file=
    [ -f "./debug.py"  ] && file="debug"  || :
    [ -f "./driver.py" ] && file="driver" || :
    if [ -n "$file" ]; then
      stdpy "${blue}Running driver (-m) in current dir\n\n${x}"
      xline
      python3 -m ${file} 
    else
      stdpyerr "-> cant snek dev outside of dev folder." 
    fi
  }

  do_pip_pak(){
    :
    pip install -e .
  }
#----------------------------------------------------
#            
#----------------------------------------------------
  
  do_clean(){
    #remove pyc cache
    stdpy "${blue}-> scrubbing the sneks ${SNEK}${blue} ◦°⨀◦${x}" #◦⨀°◦ o◎0o0o.⊚◉◦✱.0o❈✻o0o0❆oO※oo⦿°⨀❍◦✱o..

    if [[ "$PWD" != "$HOME" ]]; then
      find . -type d -name "__pycache__"
      find . -type f -name "*.py[co]" -delete -or -type d -name "__pycache__" -delete;
    else
      stdpywarn "refused to clean your entire \$HOME.\n" 0
    fi

    [ -f ./dist ] && rm -rf ./dist;
    {
      rm -rf *.egg-info
      pip cache purge
      pyenv rehash
    } >> "$HOME/pyx-clean.log" 2>&1
    stdpy "done."
  }


  do_reset(){

    if __confirm "You sure you want to ${red}reset${x} snek's memories... (y/n/q)"; then

      if [ $(which funsnek) ]; then
        funsnek
      fi

      stdpy "${blue}-> forgot all the stuff! ${blue} ◦°⨀◦${x}" 
      #  {
        unlink_profile
        [ -d $PYX_HOME ] && rm -rf "$PYX_HOME" || : 
        [ -f $PYX_RC ] && rm "$PYX_RC" || : 
      #  } >> "$HOME/pyx-clean.log" 2>&1

      array=(PYX_PATH_FILE PYTHONPATH PYX_AUTO_INIT PYX_SPY_MODE)
      for var in "${array[@]}"; do
        unset "$var"
      done

      stdpy "Done.\n\n${purple}\t\tRestart terminal to complete."

    fi
  }


#----------------------------------------------------
#            
#----------------------------------------------------
  do_snek(){
    echo -ne "${SNEK}"
  }

  do_build(){
    if [[ $@ =~ "build" ]]; then
      python -m build
    fi
  }

  do_py_site(){
    if [[ $@ =~ "site" ]]; then
      python -c "import site; print(site.getsitepackages())"
      #python $HOME/.pyenv/versions/3.11.6/bin/hello-world
    fi
  }

  do_byte_code(){
    #toggle bytecode
    if [[ $@ =~ "--byte" ]]; then
      pbc=$PYTHONDONTWRITEBYTECODE 
      if [ -z $pbc ]; then
       export PYTHONDONTWRITEBYTECODE=1
      else
        unset PYTHONDONTWRITEBYTECODE
      fi
    fi
  }

  do_which(){
    echo $(which python3)
  }

  do_ez(){
    do_init
    do_add_path
    do_update_ppath
    if [ $(which mark) ]; then
      mark -e last &> /dev/null;
    fi
  }

  do_peekaboo(){
    stdpy "-> python -> $(which python)"
    stdpy "-> python3 -> $(which python3)"
    [ -f "$PYX_PATH_FILE" ] && stdpy "-> snekrc -> $PYX_PATH_FILE" || stdpywarn "-> snekrc -> No Pathfile!"
    [ -f "$PYX_RC" ] && stdpy "-> snekrc -> $PYX_RC" || stdpywarn "-> snekrc -> No Config File!"
    [ -n $(which funsnek) ] && stdpy "-> funsnek -> can doodle!" || stdpywarn "-> funsnek cant doodle..."
    do_path
    
  }


  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^#)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")
    pyout "$LINE\n"
    while IFS= read -r row; do
      info "$row"
    done <<< "$_content"
  }


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

  do_init(){

    #preload commands
    #clean
    #spy
    if [ $opt_init -eq 0 ]; then
      [ ! -d "$PYX_HOME" ] && mkdir -p "$PYX_HOME" || :
      [ ! -f "$PYX_PATH_FILE" ] && touch "$PYX_PATH_FILE"
      [ ! -f "$PYX_RC" ] && touch "$PYX_RC"
      do_spy_mode
    fi

  }

#----------------------------------------------------
#            
#----------------------------------------------------


  usage(){
    if command_exists 'docx'; then
      docx "$BASH_SOURCE" "doc:help"; 
    fi
  }


  do_echo(){
    local cmd

    cmd="${1#[[[}"
    cmd="${cmd%%]]]}"

    if [ $opt_dev -eq 0 ]; then

      echo -ne "\n\n$LINE\n\n"
      stderr "\t--> $1 $2 $3 $4 $5 $6 <--\n"
      stderr "\t$opt_debug opt_debug  \t$opt_trace opt_trace"
      stderr "\t$opt_quiet opt_quiet  \t$opt_byte opt_byte"
      stderr "\t$opt_clean opt_clean  \t$opt_init opt_init"
      stderr "\t$opt_spy   opt_spy  \t$opt_yes opt_yes"
      echo -ne "\n$LINE\n\n\n"

      if [ -n "$cmd" ]; then
        if __confirm "Execute requested command? ${purple}$cmd${x} (y/n/q)"; then
          echo -ne "\n\n"
          xline
          $cmd
        else
          stdpyerr "you didnt do it"
        fi
      fi

    else
      echo -ne "\n"
      #xline
      $cmd

    fi

  }



  dispatch(){
    local call="$1" arg="$2" exc cmd= ret;
    
    case $call in
      run)     cmd='do_echo';;
      init)    cmd='do_echo'; exc="do_init";;
      upd*)    cmd='do_echo'; exc="do_update_ppath";;
      relink)  cmd='do_echo'; exc="make_ppath_rc";;
      unlink)  cmd='do_echo'; exc="unlink_profile";;
      rc)      cmd='do_echo'; exc="";;
      clean)   cmd='do_echo'; exc="do_clean";;
      path)    cmd='do_echo'; exc="do_path";;
      dty|dev) cmd='do_echo'; exc="do_dev_dty";;
      add)     cmd='do_echo'; exc="do_add_path";;
      rm)      cmd='do_echo'; exc="do_rm_path";;
      reset)   cmd='do_echo'; exc="do_reset";;
      snek|hi) cmd='do_snek'; opt_boring=0;;
      peek)    cmd='do_peekaboo';;
      here)    cmd='do_pythonable';;
      ez)      cmd='do_ez';;
      insp*|i) cmd='do_inspect';;
      help|\?) cmd="usage";;
      *)
        if [ ! -z "$call" ]; then
          fatal "Invalid command => $call";
        fi
      ;;
    esac

    if [ -n "$cmd" ]; then

      #info "< $call | $cmd [$arg] [$*] >";
      __logo #<-- print the pretty
      #info "$cmd $exc"
      do_init
      if [[ $cmd == "do_echo" ]]; then
        "$cmd" "[[[$exc]]]" "$arg" $@   
      else
        "$cmd" "$arg" $@  "'$exc'" # Pass all extra arguments if cmd is defined
      fi
      ret=$?
    else
      echo -ne "\n\n\t"
      do_snek
      usage    
    fi

    [ -n "$err" ] && fatal "$err";
    echo -ne "\n\n"
    return $ret;

  }


  main(){
    dispatch "${args[@]}";ret=$?
  }


#-------------------------------------------------------------------------------


  if [ "$0" = "-bash" ]; then
    :
  else

    orig_args=("${@}")
    options "${orig_args[@]}";
    args=( "${orig_args[@]/\-*}" ); #delete anything that looks like an option
    main "${args[@]}";ret=$?
  fi








#-------------------------------------------------------------------------------
#
# these are not comments, its the documentation do not delete LOL
# TODO generate the snek.docfile
#
#====================================doc:help!==================================
#
#  
#  \n\t> ${g}snek <cmd> [arg] [--flags]${x}
#
#  \t${u}Flags:${x}
#
#  \t${u} ${b}--debug${x}${u}  \t[ enable verbose output ]
#  \t${u} ${b}--spy${x}${u}  \t[ enable sitecustomize hooks ]
#  \t${u} ${b}--yes${x}${u}  \t[ confirm all prompts ]
#
#  \t${u}Commands:${x}
#
#  \t${u} ${b}hi${x}${u}  \t[ show snek ]
#  \t${u} ${b}ez${x}${u}  \t[ from a bin/src add path, regen path and rc ]
#  \t${u} ${b}add${x}${u} \t[ from a bin/src, or sitecustomize dir]
#  \t${u} ${b}upd${x}${u} \t[ rebuild the path and rc files ]
#  \t${u} ${b}dev${x}${u} \t[ run debug.py or driver.py from current directory ]
#  \t${u} ${b}clean${x}${u} \t[ remove pycache and pip cache ]
#  \t${u} ${b}reset${x}${u} \t[ remove snek rc and pythonpath files ]
#
#
#
#
#
#
#${x}
#=================================!doc:help=====================================























