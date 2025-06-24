#!/usr/bin/env bash
#===============================================================================
#              _ _
#   __  ____ _(_) |_
#   \ \/ / _` | | __|
#    >  < (_| | | |_
#   /_/\_\__, |_|\__|
#        |___/
# 
#-------------------------------------------------------------------------------
#$ name:xgit|gitx
#$ author:qodeninja
#$ autobuild: 00002
#$ date:

#-------------------------------------------------------------------------------
#=====================================code!=====================================
#-------------------------------------------------------------------------------


  #legacy delete these
  user='__user'
  email='1111+__user'

  opt_debug=0
  opt_default=1
  opt_yes=1

  FX_GITX_HOME="$MY_FX/gitx"
  FX_GITX_CONFIG="$FX_GITX_HOME/config"
  FX_GITX_RC="$FX_GITX_HOME/gitx.rc"

  GITX_USER=
  GITX_REPO=
  GITX_BRANCH=
  GITX_TAG=
  GITX_VERS=
  GITX_EMAIL=
  GITX_HOST=

#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------

  red=$(tput setaf 1)
  green=$(tput setaf 2)
  blue=$(tput setaf 39)
  blue2=$(tput setaf 27)
  cyan=$(tput setaf 14)
  orange=$(tput setaf 214)
  yellow=$(tput setaf 226)
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

  delta="\xE2\x96\xB3"
  pass="\xE2\x9C\x93"
  fail="${red}\xE2\x9C\x97"
  star="\xE2\x98\x85"
  lambda="\xCE\xBB"
  

#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------
  stderr(){ printf "${@}${x}\n" 1>&2; }

  __logo(){
    if [ -z "$opt_quiet" ] || [ $opt_quiet -eq 1 ]; then
      local logo=$(sed -n '3,9 p' $BASH_SOURCE)
      printf "\n$blue${logo//#/ }$x\n" 1>&2;
    fi
  }

  __printf(){
    local text color prefix
    text=${1:-}; color=${2:-white2}; prefix=${!3:-};
    [ -n "$text" ] && printf "${prefix}${!color}%b${x}" "${text}" 1>&2 || :
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
    echo "$val"
    __printf "\n"
    return $ret
  }

force=1
  warn(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$delta $text$x\n" "orange"; }
  okay(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$pass $text$x\n" "green"; }
  info(){ 
    local text=${1:-} force=${2:-1}; 
    [ $force -eq 0 ] || 
    [ $opt_debug -eq 0 ] && 
    __printf "$lambda $text\n" "blue"; 
  }

  trace(){ local text=${1:-}; [ $opt_trace -eq 0 ] && __printf "$idots $text\n" "grey"; }
  error(){ local text=${1:-}; __printf " $text\n" "fail"; }
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }

#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------
    
  command_exists(){ type "$1" &> /dev/null; }

  handle_interupt(){ E="$?"; printf "Interrupted!"; kill 0; exit $E; }
  handle_stop(){ kill -s SIGSTOP $$; }
  handle_input(){ [ -t 0 ] && stty -echo -icanon time 0 min 0; }
  cleanup(){ [ -t 0 ] && stty sane; }

  fin(){
    local E="$?"; cleanup
    if [ $opt_quiet -eq 1 ]; then
       [ $E -eq 0 ] && __printf "${green}${pass} ${1:-Done}." \
                    || __printf "$red$fail ${1:-${err:-Cancelled}}."
    fi
    return $E
  }

  trap handle_interupt INT
  trap handle_stop SIGTSTP
  trap handle_input CONT
  trap fin EXIT
  #trap 'echo "An unhandled error occurred!"; exit 1' ERR

  __options(){
    local this next opts=("${@}");
    #opt_debug=1
    opt_quiet=1
    opt_trace=1

    for ((i=0; i<${#opts[@]}; i++)); do
      this=${opts[i]}
      next=${opts[i+1]}
      case "$this" in
        --yes|-y)
          opt_yes=0
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
        --debug|-v)
          opt_debug=0
          opt_quiet=1
          ;;
        --default|-m)
          opt_default=0
          ;;
        #-*) err="Invalid flag [$this].";;
      esac
    done
    [ -n "$err" ] && fatal "$err";
  }


#-------------------------------------------------------------------------------
# Old Dispatch
#-------------------------------------------------------------------------------


  old_dispatch(){


    if [[ $@ =~ "--remote" ]]; then

      if [ -z "$2" ]; then
        read -p "GitHub repository (e.g. username/repo): " repo
      else
        repo="$2"
      fi

      if [ -z "$3" ]; then
        read -p "Branch name (default: local-master): " branch
        branch=${branch:-local-main}
      else
        branch="$3"
      fi

      echo "Initializing local git repository for $user..."
      git init
      echo "Adding files to git..."
      git add .
      echo "Creating initial commit..."
      git commit -m "Initial local commit"
      echo "Adding remote origin: git@$user:$repo.git..."
      git remote add origin "git@$user:$repo.git"
      echo "Fetching from origin..."
      git fetch origin
      echo "Creating new branch $branch..."
      git checkout -b "$branch"
      echo "Pushing branch $branch to origin..."
      git push -u origin "$branch"
      echo "Done."

    fi

    # fix upstream prob > git push --set-upstream origin master
    if [[ $@ =~ "--global" ]]; then
      #git config --global user.name "xxx"
      #git config --global user.email "1111043235+xxx@users.noreply.github.com"
      git config --global core.editor nano
      git config --global color.ui auto
      #git config --global excludesfile ~/.gitignore
      #git config --global autocrlf input
    elif [[ $@ =~ "--local" ]]; then
      git config user.name xxx
      git config user.email 111+xxx@users.noreply.github.com
    fi

    if [[ $@ =~ "--test" ]]; then
      ssh -T git@$user

    fi

    if [[ $@ =~ "--author" ]]; then
     git commit --amend --author="$user <$email@users.noreply.github.com>"
    fi

  }


#-------------------------------------------------------------------------------
# API
#-------------------------------------------------------------------------------
  
  get_meta(){
    local query="$1" this="$2" ret=1 this;

    case $query in
      user)    q='provide username';   ref=GITX_USER; alt=${user};;
      email)   q='provide [email] for user ';   ref=GITX_EMAIL; alt=${email};;
      branch)  q='provide [branch] name'; ref=GITX_BRANCH; alt="main";;
      repo)    q='provide [repo] name'; ref=GITX_REPO;;
      tag)     q='provide [tag] id'; ref=GITX_TAG;;
      vers)    q='provide version'; ref=GITX_VERS;;
      host)    q='provide host url or ssh host'; ref=GIT_HOST;;
      *)
        fatal "invalid inquery"
      ;;
    esac

    alt="${alt:-${!ref}}" #check defaults
    # [ -n "$alt" ] && info "default is ${alt}";

    while [ -z "$this" ]; do

      warn "---> Loop start for ($query)"

      # if still not this, check then prompt for it
      if [ -z "$this" ]; then


        if [ $opt_yes -eq 1 ]; then

          #read/confirm loop
          if [ -z "$this" ]; then 
            #use default
            if [ -n "$alt" ]; then
              val=$(__confirm "${blue}${delta} Use default value for ($alt) for ($query), y/n/q")
              [  -z "$val" ] && return 1;
              if [ "$val" == 'yes' ]; then
                this="$alt"
                ret=0
              fi
            fi
            #no default
            if [ -z "$this" ]; then
              read -p "-> $q (${alt:-none}) ? " this 
            fi
          fi

          if [ -n "$this" ] && [ "$this" != "$alt" ]; then 
            #confirm
            val=$(__confirm "${orange}${delta} Property ($query) will be set to ($this), y/n/q")
            err=$?
            [  -z "$val" ] && return 1;
            if [ "$val" == "yes" ]; then
              #okay "User confirmed ($query=>$this)"
              ret=0
            else
              #error "Ok user said no! ($? $val)"
              this=
            fi

          fi

        else
          if [ -z "$alt" ]; then
            fatal "Error: all arguments required for yes mode ($query). "
            return 1
          else
            this="$alt"
            continue
          fi
        fi
      fi
      val=
    done

    if [ -n "$this" ]; then
      ret=0
    fi

    #finally this
    #info "Get Meta decided on ($this) ($ret)"
    if [ -n "${!ref}"]; then
      eval "$ref=\"$this\""
      info "set $ref => ${!ref}"
      echo $this;
    fi

    return $ret
  }


  do_x(){
   echo "doing x..."
  }

  do_clone(){
    local ret=1 i=1
    __ask=('host'  'user'  'repo')
    for key in "${__ask[@]}"; do
      this_var="this_$key"
      res=$(get_meta "$key" "${!i}")
      ret=$?
      if [ $ret -eq 0 ]; then 
        eval "${this_var}=\"$res\""
      else
        #warn "Oops ret is $ret ($this_var)"
        return 1
      fi
      ((i++))
    done
    if [ $ret -eq 0 ]; then
      git clone git@${this_host}:${this_user}/${this_repo}.git
    fi
    return $ret
  }


  # this_host=$(get_meta "host" $1)
  # this_user=$(get_meta "user" $2)
  # this_repo=$(get_meta "repo" $3)



  do_vers(){
   echo "doing version..."
   ret=$(get_meta "vers" $1)
   [ $? -eq 0 ] && echo "user set to $ret"
  }

  do_user(){
   echo "doing user..."
   ret=$(get_meta "user" $1)
   [ $? -eq 0 ] && echo "user set to $ret"
  }

  do_config_global(){
    git config --global core.editor nano
    git config --global color.ui auto
  }

  do_config_local(){
    #ret=$(get_meta "user")
    info "Setting default $user and $email in git config"
    git config user.name "${user} "
    git config user.email "${email}@users.noreply.github.com"
  }

  do_author(){
    echo "doing author..."
    this=$(get_meta "user")
    this1=$(get_meta "email")
    if __confirm "${blue}${lambda} Ready! [$this] [$this1]. Commit changes [y/n]?"; then
      git commit --amend --author="${this} <${this1}@users.noreply.github.com>"
    fi
  }


  do_config(){
   git config --list | cat
  }

  do_tag(){
   echo "doing tag..."
  }


  #branch master, tag stable

  do_retag(){
    branch=${1:main}
    tagname=${2:dev}
    warn "Retag is ${branch} -> ${tagname}"
    #warn "Deleting local tag ${tagname}"
    #git tag -d ${tagname} 
    git add .; 
    git commit -m "dev: auto tag"; 
    git push origin $branch; 
    git tag -f -a ${tagname} -m "auto update"; 
    git push --tags --force
    #git push origin ${tagname} --tags --force
  }



  do_shorts(){
   echo "doing shorts..."
  }

  do_init(){
   echo "doing local init..."

    if [ -z "$2" ]; then
      read -p "GitHub repository (e.g. username/repo): " repo
    else
      repo="$2"
    fi

    if [ -z "$3" ]; then
      read -p "Branch name (default: local-master): " branch
      branch=${branch:-local-main}
    else
      branch="$3"
    fi

    echo "Initializing local git repository for $user..."
    git init
    echo "Adding files to git..."
    git add .
    echo "Creating initial commit..."
    git commit -m "Initial local commit"
    echo "Adding remote origin: git@$user:$repo.git..."
    git remote add origin "git@$user:$repo.git"
    echo "Fetching from origin..."
    git fetch origin
    echo "Creating new branch $branch..."
    git checkout -b "$branch"
    echo "Pushing branch $branch to origin..."
    git push -u origin "$branch"
    echo "Done."


  }

  do_test(){
    info "[host] -> map to ssh user"
    this=$(get_meta "user" $1)
    info "[$this] selected"
    ssh -T git@${this}
  }

  do_sshls(){
    awk '/^Host / && !/^#/ {for (i=2; i<=NF; i++) print $i}' "$HOME/.ssh/config"
  }

  do_remote_init(){
   echo "doing remote init..."
  }

  do_branch_ls(){
    git branch -a | cat  
  }

  do_pretty_log(){
    git log --pretty=oneline
  }

	# do_gen_vers(){
	# 	src="$1"
	# 	dest="$src/build.inf"
	# 	echo "Generating build information from Git... ($src)"
	# 	bvers="$(cd $src;git describe --abbrev=0 --tags)"
	# 	binc="$(cd $src;git rev-list HEAD --count)"
	# 	branch="$(cd $src;git rev-parse --abbrev-ref HEAD)"
	# 	printf "DEV_VERS=%s\\n" "$bvers" > $dest
	# 	printf "DEV_BUILD=%s\\n" "$binc" >> $dest
	# 	printf "DEV_BRANCH=%s\\n" "$branch" >> $dest
	# 	printf "DEV_DATE=%s\\n" "$(date +%y)" >> $dest
  #   cat $dest
  #   #git describe --tags --long --dirty --always
	# }


  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")
    echo ""
    while IFS= read -r line; do
      info "$line"
    done <<< "$_content"
 }



#-------------------------------------------------------------------------------
# New Dispatch
#-------------------------------------------------------------------------------


  wrap_dispatch(){
    local ret=1
    if [ $opt_default -eq 1 ]; then
      info "Running gitx in new mode $opt_debug"
      dispatch "${args[@]}";ret=$?
    else
      if __confirm "${orange}${delta} OOPS! Running in (default) mode! Continue"; then
        old_dispatch "${orig_args[@]}";ret=$?;
      fi
    fi
  }


  debug_run(){
   echo "running..."

  }

  dispatch(){
    local call="$1" arg="$2" cmd= ret;
    shift; shift; 
    case $call in
      run)    cmd='debug_run';;
      init)   cmd='do_init';;
      local)  cmd='do_config_local';;
      config) cmd='do_config';;
      author) cmd='do_author';;
      retag)  cmd='do_retag';;
      sshls)  cmd='do_sshls';;
      clone)  cmd='do_clone';;
      branch) cmd='do_branch';;
      brls)   cmd='do_branch_ls';;
      plog)   cmd='do_pretty_log';;
      tag)    cmd='do_tag';;
      vers)   cmd='do_vers';;
      user)   cmd='do_user';;
      test)   cmd='do_test';;
      inspect) cmd='do_inspect';;
      help|\?) cmd="usage";;
      *)
        if [ ! -z "$call" ]; then
          err="Invalid command => $call";
        else
          err="Missing command!";
        fi
      ;;
    esac
    

    if [ -n "$cmd" ]; then
      trace "< $call | $cmd [$arg] [$*] >";
      "$cmd" "$arg" $@  # Pass all extra arguments if cmd is defined
      ret=$?
    fi

    [ -n "$err" ] && fatal "$err";
    return $ret;
  }


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------


  usage(){
    if command_exists 'docx'; then
      docx "$BASH_SOURCE" "doc:help"; 
    fi
  }


  main(){
    __logo
    wrap_dispatch "${args[@]}";ret=$?
    [ -n "$err" ] && return 1;
  }

#-------------------------------------------------------------------------------


  if [ "$0" = "-bash" ]; then
    :
  else

    orig_args=("${@}")
    args=( "${orig_args[@]/\-*}" ); #delete anything that looks like an option
    __options "${orig_args[@]}";
    main "${args[@]}";ret=$?
    #[ -n "$err" ] && fatal "$err" || stderr "$out";

  fi


#-------------------------------------------------------------------------------
#=====================================!code=====================================
#====================================doc:help!==================================
#  \n\t${b}gitx <cmd> [arg]${x}
#
#  \t${rev}${y}Commands:${x}
#   
#  \t${u}start | stop
#  \t${u}curr  
#  \t${u}pause  <pid>
#  \t${u}resume <pid>
#  \t${u}ls   | lsi
#  \t${u}conf | rc
#
#${x}
#=================================!doc:help=====================================

