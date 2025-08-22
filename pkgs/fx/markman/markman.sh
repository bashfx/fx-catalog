#!/usr/bin/env bash
#===============================================================================
##                            __         
##                           /\ \        
##   ___ ___      __     _ __\ \ \/'\    
## /' __` __`\  /'__`\  /\`'__\ \ , <    
## /\ \/\ \/\ \/\ \L\.\_\ \ \/ \ \ \\`\  
## \ \_\ \_\ \_\ \__/.\_\\ \_\  \ \_\ \_\
##  \/_/\/_/\/_/\/__/\/_/ \/_/   \/_/\/_/
##                                                                          
#-------------------------------------------------------------------------------
#$ name:markman|mark
#$ author:qodeninja
#$ autobuild: 00009
#$ date:
# TODO: backup and restore key=>value pairs 
# TODO: use special chars for commands to allow for flag options
#-------------------------------------------------------------------------------
#=====================================code!=====================================
#-------------------------------------------------------------------------------

  
  readonly MARK_PATH="${BASH_SOURCE[0]}";


#-------------------------------------------------------------------------------
# Boot
#-------------------------------------------------------------------------------

  _is_dir(){
    [ -n "$1" ] && [ -d "$1" ] && return 0;
    return 1;
  }

  # if _is_dir "$FX_INC_DIR"; then
  #   _inc="$FX_INC_DIR";
  #   _app="$FX_APP_DIR";
  # elif _is_dir "$FXI_INC_DIR"; then
  #   _inc="$FXI_INC_DIR";
  #   _app="$FXI_APP_DIR";
  # else 
  #   printf "[ENV]. Cant locate [include] ($_inc). Fatal.\n";
  #   exit 1;
  # fi

#-------------------------------------------------------------------------------
# Core Libraries
#-------------------------------------------------------------------------------

  # source "$_inc/base.sh"; 

  # if is_base_ready; then
  #   fx_smart_source stdfx    || exit 1;
  #   fx_smart_source stdutils || exit 1;
  #   fx_smart_source stdfx    || exit 1;
  #   fx_smart_source stderr   || exit 1;
  # else
  #   error "Problem loading core libaries";
  #   exit 1;
  # fi

#-------------------------------------------------------------------------------
# State Vars
#-------------------------------------------------------------------------------





#----------------------------------------------------
# VARS
#----------------------------------------------------

  #note physical (-P) vs logical (-L) links e.g. cd -L pwd -L
  #we are using logical now

  err=
  out=

  do_unmark=1;
  do_edit=1;

  red=$(tput setaf 202)
  green=$(tput setaf 2)
  blue=$(tput setaf 12)
  orange=$(tput setaf 214)
  grey=$(tput setaf 247)
  purple=$(tput setaf 213)
  x=$(tput sgr0)

  imark='🔖 '; #\xEF\x91\xA1';
  ipath='⚡️';


  #   /Uf461
  # ◇ /U25C7
  # ※ /U203B

  #====================================
  #install location
  MY_BIN="$HOME/.my/bin"
  #bookmark data location       
  MY_MARK="$HOME/.my/etc/fx/markman";
  #mark bin
  MY_MARK_BIN="$MY_BIN/mark"

  #====================================

  REGEX_MARK_ID="^([@\_\.]{0,1}[[:alnum:]]+[-\_\.]{0,1}[[:alnum:]]*)+$";

  [ -f "$HOME/.profile" ] && BASH_PROFILE="$HOME/.profile" || BASH_PROFILE="$HOME/.bash_profile"
  [ -L "$BASH_PROFILE"  ] && LAST_BASH_PROFILE="$BASH_PROFILE" && BASH_PROFILE=$(realpath --logical $BASH_PROFILE) || :

  # Create this dir if it doesnt exist please
  [ ! -d "$MY_MARK" ] && mkdir -p "$MY_MARK";

#----------------------------------------------------
# UTILS
#----------------------------------------------------

  command_exists(){ type "$1" &> /dev/null;  }

  stderr(){ printf "${@}${x}\n" 1>&2; }
  fatal(){ stderr "${red}Error:${1}${x}"; exit 1; }

  abs(){ printf '%s' "$(realpath -L "$1")"; }

  in_array(){
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
  }

  resolve() {
    cd "$(dirname "$1")" && echo "$(pwd -P)/$(basename "$1")" #this is using physical resolve
  }

  mark_time(){
    local ref this="$1"; [ ! -e "$this" ] && this="$MY_MARK/$1";
    [ -e "$this" ] && echo $(date -r $this +"%Y-%m-%d %H:%M:%S") && return 0 || return 1;
  }

  dir_info(){
    while [ $# -gt 0 ]; do
      ## time: $blue$(mark_time $1)
      printf "%-30s\t%-7s\t%s\n" "${orange}${imark}$(basename $1)" "${blue}==>" "$(read_mark $1 | pretty_path)"; shift;
    done
  }

  num_marks(){
    local count=($(list_mark_names));
    printf "${#count[@]}";
  }


  list_mark_names(){
    local names=$(find $MY_MARK -maxdepth 1 -type l -exec basename {} ';' | sort );
    if [ -z "$names" ]; then 
      stderr "No marks."; 
    else
      printf "$names";
    fi
  }


  list_marks(){
    dirs="$(find $MY_MARK -maxdepth 1 -type l | sort)";
    stderr "$(dir_info ${dirs[@]})";
  }

#----------------------------------------------------
# Dep Check
#----------------------------------------------------

  # todo: use resolve function instead here
  if ! command_exists "realpath"; then
    stderr "${red}Realpath utility is missing!${x}${nl}Install with '${blue}brew install coreutils${x}' $nl";
    exit 1;
  fi


#----------------------------------------------------
# API
#----------------------------------------------------


  usage(){
    local count data b=$blue g=$green o=$orange w=$grey
    count=$(num_marks);
    data+=""
    data="$(cat <<-EOF
      \n\t${b}mark --option [<n>ame] [<p>ath]${x}

      \t${o}home: $MY_MARK${x}
      \t${o}size: ($count)${x}

      \t${w}Edit:${x}

      \t+ -a --add  <n> <p> ${b}Add bookmark if it doesnt exist${x}
      \t- -r --rm   <n>     ${b}Remove bookmark${x}
      \t  -e --edit <n> <p> ${b}Force bookmark update${x}

      \t  -x --clr          ${b}Clear all bookmarks${x}

      \t${w}Find:${x}

      \t     --lp   <?>     ${b}List paths for all marks${x}
      \t     --fp   <p>     ${b}Find path <path>${x}
      \t     --fm   <p>     ${b}Find marks with path <path>${x}

      \t${w}Meta:${x}

      \t? -h --help
      \t       --ez         ${b}Ez Install <jump> function${x}
      \t       --reset      ${b}Nuke all mark/jump references${x}

      \t@ -l --ls   <?n>    ${b}List marks and info${x}
      \t  -s --link <n>     ${b}Get symlink${x}
      \t  -t --time <n>     ${b}Get change time${x}


      \t${w}Commands:${x}

      \t${b}mark | m
      \t${b}jump | j <name>
      \t${b}last
      \t${b}rem${x}
EOF
    )";
    printf "$data";
    return 0;
  }

  list_paths(){
    #showmark can only be 1 or 0
    local i showmark=${1:-1} list=($(list_mark_names));
    if [[ "$1" == "0" || "$1" == "1" ]]; then
      showmark="$1"
    else
      return 1;
    fi

    for i in "${list[@]}"; do
      [ $showmark -eq 1 ] &&  printf "%s\n" "$(read_mark $i)";
      [ $showmark -eq 0 ] &&  printf "%s:%s\n" "$i" "$(read_mark $i)";
    done
    return 0;
  }

  find_path(){
    local ret path=$1 list=($(list_paths));
    $(in_array $path "${list[@]}"); ret=$?;
    return $ret;
  }

  find_marks_by_path(){
    local i arr this next path=$1 list=($(list_paths 0));
    [ ! -n "$path" ] && return 1;
    for i in "${list[@]}"; do
      this="${i%%:*}" #everything before =
      next="${i##*:}"  #everything after =
      [[ $path == $next ]] && arr+=($this);
    done
    echo "${arr[*]}";
    [ ${#arr} -gt 0 ] && return 0 || return 1;
  }

  read_mark(){
    local ref this="$1"; [ ! -e "$this" ] && this="$MY_MARK/$1";
    [ -e "$this" ] && ref=$(readlink $this) || err="Link destination doesnt exist. ($this $1)"
    [ "$this" == "$1" ] && err="You're already here."
    printf "$ref"
  }

  prune(){
    : #TODO:cleanup any unlinked marks
  }

  unmark(){
    local ref this="$MY_MARK/$1";
    #ref=$(read_mark $1);
    #stderr "unmark: $this"
    [ -L "$this" ] && rm "$this" || err="Mark $1 not found";
    #[ -e "$this" ] && rm "$this" || err="Mark $1 not found"; ref doesnt exist
    out="${red}- Removing bookmark ( ${imark}$1 ) ...";
  }

  linker(){
    local lbl=$1 ref dest=$2;
    ref="$MY_MARK/$lbl";
    [ ! -L "$ref" ] && {
      ln -s "$dest" "$ref"; #using logical pwd
      out+="${green}+ Added bookmark ( ${imark}$lbl ) ...\n";
      #out+="$(dir_info $ref)"; ret=0;
    }
  }

  pretty_path() {
    sed -e "s|^$HOME|~|"
  }

  logical_pwd(){
    stderr $(pwd -L)
    pwd -L
  }

  mark_item(){
    local dest lbl="$1" sym ref res ret=0;


    if [ $# -gt 0 ]; then
      [ $# -eq 1 -a -n "$1" ] && dest=$(logical_pwd) || ret=1;
      [ $# -gt 1 -a -e "$2" ] && dest="$2"  || ret=1;

      ref="$MY_MARK/$lbl"

      [ $do_edit -eq 0 ] && do_unmark=0;
      [ ! -e "$ref" -a -L "$ref" ] && do_unmark=0 && stderr "${orange}Link doesnt exist... deleting mark (${imark}$lbl)";

      [ $do_unmark -eq 0 ] && $(unmark $lbl);

      [ -L "$ref" ] && {
        err="Mark ($lbl) already exists.\n";
        err+="${imark}$lbl => $(readlink $ref)"; ret=1;
      }

      if find_path "$dest" ; then

        : #find -L /dir/to/start -samefile /tmp/orig.file
        if [ "$lbl" != "last" ]; then
          res=("$(find_marks_by_path $dest)")
          err="Path ($dest) is already marked ( ${imark}${res[@]} )."
        else
          linker "$lbl" "$dest";
        fi

      else

        linker "$lbl" "$dest";

      fi

    else
      err="";
      list_mark_names;
    fi
    [ -z "$err" ] && ret=0
    return $ret;
  }

#-------------------------------------------------------------------------------

  clean_up(){
    rm -rf $MY_MARK;
    [ ! -f $MY_MARK ] && mkdir -p "$MY_MARK";
  }

  reset(){
    local src="$BASH_PROFILE" MARK_BAK="$HOME/markman.${RANDOM}.bak" 
    sed -i.bak "/#### markman ####/,/########/d" "$src";
    rm -f "${src}.bak";

    if [ -d $MY_MARK ]; then 
      mv "$MY_MARK" "${MARK_BAK}";
      rm -rf "$MY_MARK"
      stderr "${red}Backup file created at ${MARK_BAK}${x}";
    fi

    [ -f $MY_MARK_BIN ] && rm $MY_MARK_BIN;
    out="${red}- Markman MARK(1) has been uninstalled ...";
  }

  ez_update(){
    [ ! -z "$MY_MARK_BIN" ] && [ -f "./markman" ] && cp ./markman "$MY_MARK_BIN"
  }

  ez_install(){
    local localbin data res ret src="$BASH_PROFILE";

    #stderr "profile is $BASH_PROFILE"
    res=$(sed -n "/#### fx:markman ####/,/########/p" "$src");

    [ -z "$res" ] && ret=1 || ret=0;

    if [ $ret -eq 1 ]; then

      if [[ ! "$PATH" =~ "$MY_BIN" ]]; then
        stderr "${red}Local user bin directory is missing. Adding...${x}";

        mkdir -p "$MY_BIN"
        export PATH="$MY_BIN":$PATH
        localbin="$(cat <<-EOF
if [[ ! "$PATH" =~ "$MY_BIN" ]]; then
  export PATH=$MY_BIN:$PATH
fi
EOF
        )";
      fi

      data="$(cat <<-EOF
#### fx:markman ####
  #markman installed - do not edit this block
  $localbin
  if [ -n "\$(which mark)" ]; then
    jump(){
      local this=\$(mark -s \$1);
      [ -d "\$this" ] && { cd -L "\$this"; echo -e "\\\\n[${green}#\$1${x}] \$this\\\\n"; ls -la; }
    }
    alias marks='mark @';
    alias rem='mark -e last';
    alias lastuser=\$(which last); # /usr/bin/last last logged in user 
    alias last='clear; jump last';
    alias j='jump';
    alias m='mark';
  fi
########
EOF
      )";


      [ ! -z "$MY_MARK_BIN" ] && [ -f "./markman" ] && cp ./markman "$MY_MARK_BIN"

      if [ -f "$MY_MARK_BIN" ]; then
        printf "$data" >> "$src";
        stderr "${green}Jump/Rem/Last added to Profile. \nSource your profile to enable...${x}\n Markman installed use command ${blue}mark${x}";
      else
        err="Could not install MARK(1) to user bin folder ($MY_MARK_BIN).";
      fi

    else
      stderr "${red}Cannot run EZ INSTALL more than once!${x}";
    fi
  }


#-------------------------------------------------------------------------------

  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")

    while IFS= read -r line; do
      echo "$line"
    done <<< "$_content"

  }


  dispatch(){
    local call="$1" arg= path= cmd_str= ret;

    [ $# -gt 3 ] && err="Too many arguments." && return 1;

    case "$call" in
      --inspect)    cmd="do_inspect";;
      --reset)      cmd="reset";;
      --ez)         cmd="ez_install";;
      --help|-h|\?) cmd="usage";; #doesnt work on mac
      --clr|-x)     cmd="clean_up";; #still need to test this
      --link|-s)    cmd="read_mark";arg="$2";;
      --time|-t)    cmd="mark_time";arg="$2";;
      --edit|-e)    cmd="mark_item";arg="$2"; do_edit=0;;
      --rm|-r|-)    cmd="unmark";arg="$2";;
      --add|\+)     cmd="mark_item";arg="$2";path="$3";;
      --lp)
        cmd="list_paths";
        [ $# -eq 2 ] && arg="0";;
      --fp)         cmd="find_path";path="$2";;
      --fm)         cmd="find_marks_by_path";path="$2";;
      --ls|-l|\@)
        [ $# -eq 1 ] && cmd="list_marks";
        [ $# -eq 2 ] && cmd="dir_info" && path="$MY_MARK/$2";
        ;;
      -*) err="Invalid flag [$call].";;
      *)
        cmd="mark_item";
        [ $# -eq 1 ] && arg="$1" && path=$(logical_pwd) && stderr  "path is $path";
        [ $# -eq 0 ] && cmd="list_mark_names";
      ;;
    esac
    cmd_str+=$cmd;

    if [ -n "$arg" ]; then
      [[ "$arg" =~ $REGEX_MARK_ID ]] && cmd_str+=" $arg" || err="Error invalid mark id ($arg)";
    fi

    if [ -n "$path" ]; then
      [ -e "$path" -a -L "$path" -o -d "$path" ] && cmd_str+=" $path" || err="Error invalid path ($path)";
    fi

    # stderr "fx=> $cmd_str";

    [ -n "$err" ] && return 1;
    $cmd_str;ret=$?;
    return $ret;
  }

  main(){
    local ret;
    dispatch "$@";ret=$?
    [ -n "$err" ] && fatal "$err" || stderr "$out";
    unset out err do_edit do_unmark;
    return $ret
  }

#-------------------------------------------------------------------------------

  main "$@";

#-------------------------------------------------------------------------------
#=====================================!code=====================================
#====================================doc:help!==================================
#
#  \n\t${b}mark --option [<n>ame] [<p>ath]${x}
#
#  \t${o}home: $MY_MARK${x}
#  \t${o}size: ($count)${x}
#
#  \t${w}Edit:${x}
#
#  \t+ -a --add  <n> <p> ${b}Add bookmark if it doesnt exist${x}
#  \t- -r --rm   <n>     ${b}Remove bookmark${x}
#  \t  -e --edit <n> <p> ${b}Force bookmark update${x}
#
#  \t  -x --clr          ${b}Delete all bookmarks${x}
#
#  \t${w}Find:${x}
#
#  \t     --lp   <?>     ${b}List paths for all marks${x}
#  \t     --fp   <p>     ${b}Find path <path>${x}
#  \t     --fm   <p>     ${b}Find marks with path <path>${x}
#
#  \t${w}Meta:${x}
#
#  \t? -h --help
#  \t       --ez         ${b}Ez Install <jump> function${x}
#  \t       --reset      ${b}Nuke all mark/jump references${x}
#
#  \t@ -l --ls   <?n>    ${b}List marks and info${x}
#  \t  -s --link <n>     ${b}Get symlink${x}
#  \t  -t --time <n>     ${b}Get change time${x}
#
#
#  \t${w}Commands:${x}
#
#  \t${b}mark | m
#  \t${b}jump | j <name>
#  \t${b}last
#  \t${b}rem${x}
#
#=================================!doc:help=====================================
