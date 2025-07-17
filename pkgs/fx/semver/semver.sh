#!/usr/bin/env bash


#-------------------------------------------------------------------------------
#=====================================code!=====================================
#-------------------------------------------------------------------------------

  readonly SEMV_PATH="${BASH_SOURCE[0]}";

#-------------------------------------------------------------------------------
# Boot
#-------------------------------------------------------------------------------

  _is_dir(){
    [ -n "$1" ] && [ -d "$1" ] && return 0;
    return 1;
  }

  if _is_dir "$FX_INC_DIR"; then
    _inc="$FX_INC_DIR";
    _app="$FX_APP_DIR";
  elif _is_dir "$FXI_INC_DIR"; then
    _inc="$FXI_INC_DIR";
    _app="$FXI_APP_DIR";
  else 
    printf "[ENV]. Cant locate [include] ($_inc). Fatal.\n";
    exit 1;
  fi

#-------------------------------------------------------------------------------
# Core Libraries
#-------------------------------------------------------------------------------

  source "$_inc/base.sh"; 

  if is_base_ready; then
    fx_smart_source stdfx    || exit 1;
    fx_smart_source stdutils || exit 1;
    fx_smart_source stdfx    || exit 1;
    fx_smart_source stderr   || exit 1;
  else
    error "Problem loading core libaries";
    exit 1;
  fi

  KNIFE="$(map_core_app knife)";
  
  _using( GIT FIND GREP AWK DATE SED );
  
#-------------------------------------------------------------------------------
# State Vars
#-------------------------------------------------------------------------------




  export TERM=xterm-256color;
  
  SEMV_EXEC="$0" #self reference


  SEMV_MAJ_LABEL="brk"
  SEMV_FEAT_LABEL="feat"
  SEMV_FIX_LABEL="fix"
  SEMV_DEV_LABEL="dev"
  SEMV_MIN_BUILD=1000

  opt_dev_note=1
  opt_build_dir=1
  opt_debug=0 #no reason to have this off
  opt_trace=1
  opt_yes=1
#-------------------------------------------------------------------------------
# Term
#-------------------------------------------------------------------------------

  #replace with stderr. 


  red=$(tput setaf 202)
  green=$(tput setaf 2)
  blue=$(tput setaf 12)
  orange=$(tput setaf 214)
  grey=$(tput setaf 247)
  purple=$(tput setaf 213)
  yellow=$(tput setaf 11)
  x=$(tput sgr0)
  inv="$(tput rev)"
  delta="\xE2\x96\xB3"
  pass="\xE2\x9C\x93"
  fail="${red}\xE2\x9C\x97"
  star="\xE2\x98\x85"
  lambda="\xCE\xBB"
  idots="\xE2\x80\xA6"
  bolt="\xE2\x86\xAF"
  spark="\xe2\x9f\xa1"
#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------

  #replace with stderr. 

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
    #echo "$val"
    __printf "\n"
    return $ret
  }

  __prompt(){
    local msg="$1" default="$2"
    if [ $opt_yes -eq 1 ]; then
      read -p "$msg --> " answer
      [ -n "$answer" ] && echo "$answer" || echo "$default"
    else 
      echo "$default"
    fi
  }

  warn(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$delta $text$x\n" "orange"; }
  okay(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$pass $text$x\n" "green"; }
  info(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] && __printf "$spark $text\n" "blue"; }

  trace(){ local text=${1:-}; [ $opt_trace -eq 0 ] && __printf "$idots $text\n" "grey"; }
  error(){ local text=${1:-}; __printf " $text\n" "fail"; }
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }


#-------------------------------------------------------------------------------
# Options maybe one day
#-------------------------------------------------------------------------------


  options(){
    local this next opts=("${@}");
    for ((i=0; i<${#opts[@]}; i++)); do
      this=${opts[i]}
      next=${opts[i+1]}
      case "$this" in
        --debug|-d)
          opt_debug=0
          opt_quiet=1
          ;;
        --dev|-N)
          opt_dev_note=0
          ;;
        --yes|-y)
          opt_yes=0
          ;;
        --build|-B)
          opt_build_dir=0
          ;;
        --tra*|-t)
          opt_trace=0
          opt_debug=0
          #opt_quiet=1
          ;;
        *)    
          :
          ;;
      esac
    done
  }


#-------------------------------------------------------------------------------
# Support FX
#-------------------------------------------------------------------------------

  split_vers(){
    local vers_str=$1
    if [[ $vers_str =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        patch=${BASH_REMATCH[3]}
        extra=${BASH_REMATCH[4]}
        echo "$major $minor $patch $extra"
        return 0
    else
        return 1
        exit 1
    fi
  }

  #git log --grep="feat:" --pretty=format:"%h - %s"  #v0.1.0

  since_last(){
    local tag=$1 label=$2

    if is_repo; then
      #local count1=$(git log "${tag}"..HEAD --grep="^${label}:" --pretty=format:"%s")
      local count=$(git log --pretty=format:"%s" ${tag}..HEAD | grep -cE "^${label}:")
      echo $count
      trace "[$count] [$label] changes since [$tag]"
    else
      error "Error. current dir not a git repo."
    fi

  }


#-------------------------------------------------------------------------------
# Is/Has Checks
#-------------------------------------------------------------------------------

  is_repo_hard(){
    local count=$(find . -maxdepth 1 -type d -name ".git" | wc -l | awk '{print $1}')
    [ $count -gt 0 ] && return 0
    return 1
  }


  is_repo(){
    git rev-parse --is-inside-work-tree > /dev/null 2>&1
  }

  is_main(){
    local b=$(this_branch)
    [ -n "$b" ] && [ "$b" == "main" ] || [ "$b" == "master" ] && return 0
    return 1
  }

  has_commits(){
    is_repo && git rev-parse HEAD > /dev/null 2>&1
  }

  is_not_staged(){
    #git status --porcelain
    git diff --exit-code > /dev/null 2>&1
  }

  #semver check requires official v1.1.1 format not suffixes
  has_semver(){
    git tag --list | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+$'
  }


#-------------------------------------------------------------------------------
# Simple Info
#-------------------------------------------------------------------------------

  this_branch(){
    git branch --show-current
    #git rev-parse --abbrev-ref HEAD
  }

  this_user(){
    git config user.name|tr -d ' '
  }

  this_project(){
    basename $(git rev-parse --show-toplevel)
  }

#-------------------------------------------------------------------------------
# Simple FX
#-------------------------------------------------------------------------------

  ls_tags(){
    git show-ref --tags | cut -d '/' -f 3-
  }

  top_tag(){
    git describe --tags --abbrev=0
  }



  which_main_hard(){
    branches=$(git branch)
    if [[ "$branches" =~ main|master ]]; then
      echo "$BASH_REMATCH"
    fi
  }

  which_main(){
    if has_commits; then
      git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
    fi
  }


  last_commit(){
    #git log -1 --pretty=format:%cd --date=iso
    if has_commits; then
      if git rev-parse HEAD >/dev/null 2>&1; then
        git show -s --format=%ct HEAD
        return 0
      fi
    fi
    echo "0"
    return 1
  }
 

  do_latest_tag(){
    if is_repo; then
      latest=$(git tag | sort -V | tail -n1)
      echo "$latest"
      [ -n "$latest" ] && return 0 || :
    fi
    return 1
  }


  do_latest_semver(){
    if has_semver; then
      latest=$(git tag --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
      echo "$latest"
      [ -n "$latest" ] && return 0 || :
    else
      error "Error. No semver tags found."
      return 1
    fi
  }


  do_find_rev(){
    local ref=$1
    git rev-parse "$ref" >/dev/null 2>&1
  }


  do_all_count(){
    git rev-list --all --count
  }

  do_build_count(){
    local count=$(git rev-list HEAD --count)
    count=$((count+$SEMV_MIN_BUILD)) #build floor
    echo $count
  }

  do_remote_build_count(){
    local count
    count=$(git rev-list origin/main --count 2>/dev/null || echo 0)
    count=$((count+$SEMV_MIN_BUILD)) #build floor
    echo $count
  }



  do_days_ago(){
    local last=$(last_commit)
    local now=$(date +%s)
    local diff=$((now-last))
    local days=$((diff/86400))
    echo $days
  }

  do_since_pretty(){
    local last=$(last_commit)
    #local last_date=($1)
    local now=$(date +%s)

    # Get the timestamp for midnight
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        local midnight=$(date -v0H -v0M -v0S +%s)
    else
        # Linux
        local midnight=$(date --date="today 00:00:00" +%s)
    fi

    local diff=$((now-last))
    local days=$((diff/86400))
    local hours=$(((diff/3600)%24))
    local minutes=$(((diff/60)%60))
    local seconds=$((diff%60))
    if [ $days -eq 0 ]; then
      if [ $last -lt $midnight ]; then
        daystr="Yesterday"
      else
        daystr="Today"
      fi
    elif [ $days -eq 1 ]; then
      daystr="$days day"
    else
      daystr="$days days"
    fi

    if [ $hours -ne 0 ]; then
      daystr="$daystr $hours hrs"
    fi

    if [ $minutes -ne 0 ]; then
      daystr="$daystr $minutes min"
    fi

    if [ $seconds -ne 0 ]; then
      daystr="$daystr $seconds sec"
    fi

    if [ $days -eq 0 ] && [ $hours -eq 0 ] && [ $minutes -eq 0 ] && [ $seconds -lt 30 ]; then
      daystr="Just now"
    fi

    echo "$daystr"
  }


#-------------------------------------------------------------------------------
# FX
#-------------------------------------------------------------------------------
  do_print_semver(){
    local ret=1
    if [ -n "$1" ]; then
      echo "-> $1"
      res=$(split_vers $1)
      ret=$?
      if [ $ret -eq 0 ]; then
        local _i=($res)
        info "Major: ${_i[0]} Minor: ${_i[1]} Patch: ${_i[2]}  Extra: ${_i[3]} "
      fi
      return $ret
    else
      return $ret
    fi
  }




  make_vers_file(){
    local dest=$1 
    touch "$dest"
    if [ -w $dest ]; then
      
      info "Generating build information from Git..."
      bvers="$(do_latest_tag)"
      binc="$(do_build_count)"
      branch="$(this_branch)"
      printf "DEV_VERS=%s\\n" "$bvers" > $dest
      printf "DEV_BUILD=%s\\n" "$binc" >> $dest
      printf "DEV_BRANCH=%s\\n" "$branch" >> $dest
      printf "DEV_DATE=%s\\n" "$(date +%D)" >> $dest
      printf "DEV_SEMVER=%s\\n" "$($SEMV_EXEC)" >> $dest #configure this top of script
      cat "$dest"
    else
      error "Error. could not write to dest ($dest)"
    fi
  }


  do_change_count(){
    local tag=${1:-$(do_latest_tag)}
    #info "Tag is $tag"

    b_major=0
    b_minor=0
    b_patch=0
    break_s=$(since_last "$tag" "$SEMV_MAJ_LABEL")
    feature_s=$(since_last "$tag" "$SEMV_FEAT_LABEL")
    patch_s=$(since_last "$tag" "$SEMV_FIX_LABEL")
    note_s=$(since_last "$tag" "$SEMV_DEV_LABEL")
    build_s=$(do_build_count)
    trace "f[$feature_s] b[$patch_s] p[$note_s] $build_s"
    #if updates sincelast, then bump
    if [ $break_s -ne 0 ]; then
      #warn 'found break'
      b_major=1
      b_minor=0
      b_patch=0
    elif [ $feature_s -ne 0 ]; then
      #warn 'found feature'
      b_minor=1
      b_patch=0
    elif [ "$patch_s" -ne 0 ]; then
      #warn 'found patch'
      b_patch=1
    elif [ "$note_s" -ne 0 ]; then
      #warn 'found note'
      #no semver bumps
      :
    else
      return 1 # no changes
    fi
    #echo "$major $minor $patch $build_s $note_s"
    return 0
  }


  do_next_semver(){
    local _i tag ret major minor patch build ret opt_force=${1:-1}
    
    tag=$(do_latest_tag) #latest not top
    ret=$?
    if [ $ret -eq 1 ]; then
      #error "Error. could not find a version tag to bump from"
      exit 1
    fi

    res=$(split_vers $tag)
    ret=$?

    if [ $ret -eq 0 ]; then
      _i=($res)
      #trace "latest tag -> $tag"
      major=${_i[0]}
      minor=${_i[1]}
      patch=${_i[2]}
      build=${_i[3]} #not really used as a basis

      # Count commits for each type and increment version accordingly
      do_change_count "$tag" #sets b_major, b_minor, b_patch build_s note_s

      ret=$?
      if [ $ret -eq 1 ]; then
        if [ $opt_dev_note -eq 0 ]; then
          error "Error. no changes since last tag ($tag)"
          exit 1
        fi
      else 
        major=$((major+$b_major))
        minor=$((minor+$b_minor))
        patch=$((patch+$b_patch))
      fi

      new_version="v$major.$minor.$patch"

      if [ $opt_dev_note -eq 0 ]; then

        if [ "$note_s" -ne 0 ]; then
          trace "dev notes since last build ($tag)"
          tail_s="-dev_$note_s"
        else
          trace "clean build"
          tail_s="-build_$build_s"
        fi
        new_version="${new_version}${tail_s}"

      fi

      trace "maj -> $major"
      trace "feat -> $minor"
      trace "fix -> $patch"
      trace "build -> $build_s" #vs build
      #trace "$new_version"

      if [ $opt_force -ne 0 ]; then
        if [ "$note_s" -ne 0 ] && [ $opt_dev_note -eq 1 ]; then
          if __confirm "${red}There are ${inv}[$note_s]$dev notes${x}${red} on the current version and ${inv}[--dev] flag${x}${red} is disabled!\n
          $tag ->  $new_version
          \n${orange}You should only bump versions if the dev notes have been resolved.\nOtherwise you can cancel and run again with --dev enabled.\nContinue (y/n/q)"; then
            info '~~~> Bumping anyway'
          else
            error 'Cancelled.'
            return 1
          fi
        elif [ "$note_s" -ne 0 ]; then
          info "${inv}[--dev enabled] --> (${tail_s/-/})"
        else
        :
        fi
      fi

      echo -e "$new_version"	 
      return 0

    else
      error "invalid format."
      exit 1
    fi
 
  }


  do_build_file(){
    local name="${1:-build.inf}"

    if [ $opt_build_dir -eq 0 ]; then
      [ ! -d "./build" ] && mkdir -p "./build"
      dest="./build/${name}"  
    else
      dest="./${name}"  
    fi

    make_vers_file $dest

    if [ $opt_trace -eq 0 ]; then
      cat $dest
    fi

  } 


#-------------------------------------------------------------------------------
# CMDS
#-------------------------------------------------------------------------------
  do_pending(){
    local latest=$(do_latest_tag)
    local label=${1:-'dev'}
    if [ -n "$latest" ]; then
      if [ $label != "any" ]; then
        res=$(git log "${latest}"..HEAD --grep="^${label}:" --pretty=format:"%h - %s")
        ret=$?
      else
        res=$(git log "${latest}"..HEAD  --pretty=format:"%h - %s")
        ret=$?
      fi
      if [ -n "$res" ]; then
        warn "Found changes ($label)=>\n$res"
        return 0
      else
        okay "No labeled (${label}:) commits after $latest." && return 0
        return 1
      fi
    else
      error "Error. No semver version tag found. try semv new?"
      return 1
    fi

  }

  do_can_semver(){
    if is_repo; then
      local last=$(do_latest_tag)
      local branch=$(this_branch)
      if [ -z "$last" ]; then
        okay "Can semver here. Repo found. Use <semv new> to set new 0.0.1 version."
      else
        info "Semver found ($last). Use ${inv}semv bump${x}${blue} to update."
      fi
    else
      error "Error. Not in a git repo."
    fi
  }

  do_test_semver(){
    if ! do_print_semver "$1"; then
      error "Error. Input not valid semver format (vM.m.p-bXXX)"
    fi
  }


  do_mark_1(){
    local last=$(do_latest_tag)
    if is_repo; then
      if ! has_semver; then
        if is_main; then
          warn "Mark 1 will setup an initial semver at v0.0.1"
          touch README.md
          git add README.md
          git commit -m "auto: Update README for repository setup :robot:"
          git tag -f -a v0.0.1 -m "auto update"; 
          if __confirm "Push mark 1 tag (v0.0.1) to origin?"; then
            git push origin v0.0.1 # --force
            git push origin main
          fi
        else
          warn "Not in main branch."
        fi
      else
        warn "Repo already has semver $last. Cannot init to v.0.0.1"
      fi
    else
      error "Error. Not in a git repo." 
    fi
  }


  do_is_greater(){ # B > A
    local B=$1 A=$2
    if [ -z "$A" ] || [ -z "$B" ]; then
      error "Error. Invalid comparison" 
      exit 1
    fi
    trace "$B : $A ?"

    if [ "$B" == "$A" ]; then #sanity check sort didnt work on mac for some reason
      return 1;
    elif [ "$(printf '%s\n%s' "$A" "$B" | sort -V | tail -n1)" = "$B" ]; then
      trace "$B > $A ?"
      return 0
    else
      trace "$B <= $A ?"
      return 1
    fi
    # if do_is_greater "$val" "$latest" ; then
    #   warn "$val is greater than $latest"
    # else
    #   error "hmm..."
    #fi
  }

  do_retag(){ 

    local tag=$1
    local last_tag=$2

    [ -z "$tag" ] && { error "Error. missing tag"; return 1; } || :
        
    if has_semver && is_main; then

        #hopefully this works lol
        if do_is_greater "$tag" "$last_tag"; then
          info "Change detected: $last_tag => $tag"
        else 
          error "Latest tag [$last_tag] already applied. Bumping would move tag to a new commit."
          exit 1
        fi

        if ! is_not_staged; then
          if __confirm "${orange}${inv}Warning: You have uncommited changes.${x}${orange}\nIf you commit now, these changes will be added to the tag.\nCheckin with the retag (y/n/q)"; then
            echo -ne "${grey}"
            git add --all
            git commit -m "auto: adding all changes for retag @${tag}"
            echo -ne "${x}"
          else
            error "Cancelled retag."
            exit 1
          fi
        fi

        note=$(__prompt "${blue}Add a note for the tag${yellow}" "auto tag bump")
        echo -ne "${grey}"
        git tag -f -a "${tag}" -m "$note";
        git push --tags --force;
        echo -ne "${x}"
        if __confirm "${blue}Push commits for ${tag} and main to origin (y/n/q)"; then
          echo -ne "${grey}"
          git push origin "${tag}"  #--force
          git push origin main
          
        fi
        echo -ne "${x}"
        return 0
    else
      error "Error. Cant retag. Current branch must be main semver."
      return 1
    fi


    return 1
  }


  do_bump(){
    local ret force_bump=${1:-1}
    local latest=$(do_latest_tag)
    local val=$(do_next_semver)
    ret=$?
    if [ $ret -eq 0 ] && [ -n "$val" ]; then
      trace "bump latest[ $latest ] -> new[ $val ] (run:${force_bump})"
      if [ "$force_bump" == "0" ]; then
        do_retag "$val" "$latest"
      else
        echo "$val"
      fi
    fi
  }

  do_tags(){
    local tags=$(git tag)
    info "tags\n$tags"
  }

  # this does almost the same thing as retag check but specific versions
  # can be used externally
  do_has_forward(){
    local ret v1 v2
    v1="$(do_latest_tag)"
    v2="$(do_next_semver 0)"
    #warn "$v1 : $v2"
    
    #TODO: get granular forward info
    # do_change_count "$v1"    
    # $b_major
    # $b_minor
    # $b_major

    if [ -z "$v1" ] || [ -z "$v2" ]; then
     return 1
    fi
    if [[ "$v2" != "$v1" ]] &&  do_is_greater "$v2" "$v1" ; then
      #okay "Yay future change! $v1 -> $v2"
      echo -e "$v2"
      ret=0
    else
      # -> version is same or less??
      ret=1
    fi
    return $ret
  }


#-------------------------------------------------------------------------------
# FX
#-------------------------------------------------------------------------------



  do_info(){

    # 1> can repo
    if is_repo; then

      user=$(git config user.name|tr -d ' ')

      if [ -z "$user" ]; then
        user="${red}-unset-${x}"
      fi
      branch=$(this_branch)
      main=$(which_main)  
      project=$(this_project)

      if has_commits; then
        # 2> repo info
        build=$(do_build_count)
        rbuild=$(do_remote_build_count)

        changes=$(do_status)
        since=$(do_since_pretty)
        days=$(do_days_ago)

        if [ $changes -gt 0 ]; then
          changes="${green}Edits +$changes${x}"
        else
          changes="${grey}none${x}"
        fi

        if [ $rbuild -gt $build ]; then
          rbuild="${green}${rbuild}${x}"
        elif [ $rbuild -eq $build ]; then
          :
        else
          build="${green}${build}${x}"
        fi

        msg+="~~ About this repo ~~ \n${spark} User --> [${user}]\n"
        msg+="${spark} Repo --> [${project}] [${branch}] [${main}]\n"
        msg+="${spark} Stat --> [${changes}]  \n"
        msg+="${spark} Bld  --> [${build}:${rbuild}] \n"
        msg+="${spark} Last --> [${days} days] ${since}\n"
        if has_semver; then
          semver=$(do_latest_semver)
          next=$(do_next_semver 0)
          if [ -z "$next" ]; then
            next="${red}-none-${x}"
          elif do_is_greater "$next" "$semver"; then
            next="${green} -next-> ${next}${x}"
          elif [ "$next" == "$semver" ]; then
            next="<-same-> ${next}"
          fi
          msg+="${spark} Vers --> [${semver} ${next}]"
        else
          semver="${red}-unset-${x}"
          msg+="${spark} Vers --> [${semver}]"
        fi

        __printf "$msg"

        # 3> semver info
        # 4> next semver
        
      else
        warn "Repo --> [${user}${orange}] [${project}] [${branch}] [${red}no commits found${orange}]"
      fi

    else
      error "Error. Not in a git repo."
    fi

  }

  do_last(){
    if is_repo; then
      days=$(do_days_ago)
      since=$(do_since_pretty) 
      semver=$(do_latest_tag)
      text='Last commit was'
      if [ $days -lt 7 ]; then
        okay "$text $since"
      elif [ $days -lt 30 ]; then
        warn "$text $since"
      else
        error "$text $since"
      fi
    else
      error "Error. Not in a git repo."
    fi
  }

  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^#)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")
    __printf "$LINE\n"
    while IFS= read -r row; do
      info "$row"
    done <<< "$_content"
  }

  do_auto(){
    local path=$1 call=$2 ret arg

    #try to get the version of a files parent dir
    if [ -f "$path" ]; then
      parent_dir=$(dirname "$path")
      if [ -d "$parent_dir" ]; then
        arg="$parent_dir"
      fi
    fi

    if [ -d "$path" ]; then
      cd "$path"
      if is_repo; then
        #info "call is $call"

        case $call in
          chg) cmd='do_pending';arg='any'; ;;
          st) cmd='do_status';;
          fwd) cmd='do_has_forward';;
          *)
            cmd='do_latest_tag'
          ;;
        esac

        if [ -n "$cmd" ]; then
          $cmd "${arg}";ret=$?;
          #[ $ret -eq 0 ] && okay "... $cmd good."
        fi

        return $ret

      else
        return 1
      fi      
    else
     :
    fi

    return 1

  }

  do_status(){
    local count=$(git status --porcelain | wc -l | awk '{print $1}')
    echo -e "$count"
    [ $count -gt 0 ] && return 0
    return 1
  }

  do_label_help(){
        msg+="~~ Semv Commit labels ~~ \n"
        msg+="${spark} ${green}brk:${x}\t --> Use for breaking changes \t[Major] \n"
        msg+="${spark} ${green}feat:${x}\t --> Use for new features added\t[Minor] \n"
        msg+="${spark} ${green}fix:${x}\t --> Use for fixing bugs \t[Patch] \n"
        msg+="${spark} ${green}dev:${x}\t --> Use for dev note locks \t[Dev]\n"
    __printf "$msg"

  }

  usage(){
    if command_exists 'docx'; then
      docx "$BASH_SOURCE" "doc:help"; 
    fi
  }



  do_fetch_tags(){
    before_fetch=$(git tag)
    output=$(git fetch --tags 2>&1)
    ret=$?
    after_fetch=$(git tag)
    if [ "$before_fetch" != "$after_fetch" ]; then
      okay "New tag changes found."
    else
      error "No tag changes."
    fi
    return $ret;
  }

  do_latest_remote(){
    do_fetch_tags > /dev/null 2>&1
    fetch_status=$?
    git describe --tags $(git rev-list --tags --max-count=1);
  }

  do_fetch(){
    if is_repo; then
      git fetch --all > /dev/null 2>&1
    fi;
  }

  do_remote_compare(){
    do_fetch;
    local tag=$(git describe --tags --abbrev=0);
    local remote_tag=$(do_latest_remote);
    if do_is_greater "$remote_tag" "$tag"; then
      info "Local version outdated [$tag] => $remote_tag."
      echo 1;
      return 1
    fi 
    okay "Version [$remote_tag] up to date."
    echo 0;
    return 0;
  }

  

  do_rbuild_compare(){
    do_fetch;
    local build=$(do_build_count);
    local rbuild=$(do_remote_build_count);
    if do_is_greater "$rbuild" "$build"; then
      warn "Local version outdated [$build] => $rbuild."
      echo 1;
      return 1
    fi 
    okay "Version Build [$build] up to date."
    echo 0;
    return 0;
  }


  do_snip_majors(){
    git tag | grep -vE 'v[0-9]+\.[0]+\.[0]+$' | xargs -n 1 git tag -d
  }

  do_snip_majors_remote(){
    git tag | grep -vE 'v[0-9]+\.[0]+\.[0]+$' | xargs -n 1 -I {} git push origin --delete {}
  }

  do_snip_minors(){
    git tag | grep -vE 'v[0-9]+\.[1-9][0-9]*\.0$' | xargs -n 1 git tag -d
    #regex='v[0-9]+\.[1-9][0-9]*\.0$'
    # test> git tag | grep -vE 'v[0-9]+\.[1-9][0-9]*\.0$' | xargs -n 1 echo
  }

  do_snip_minors_remote(){
    git tag | grep -vE 'v[0-9]+\.[1-9][0-9]*\.0$'  | xargs -n 1 -I {} git push origin --delete {}
  }

  do_snip(){
    #todo: fix when there is nothing to snip
    warn "Snip command will snip the following minor tags..."
    git tag | grep -vE 'v[0-9]+\.[1-9][0-9]*\.0$' | xargs -n 1 echo
    if __confirm "Are you sure you want to snip these minors"; then
      do_snip_minors
      do_snip_minors_remote
      okay "Snips are done! no returning now"
    else
      error "Snip cancelled."
    fi

  }

#-------------------------------------------------------------------------------
# FX
#-------------------------------------------------------------------------------


  dispatch(){
    local call="$1" arg="$2" arg2="$3" cmd= ret=0;
    case $call in
      #run)      cmd='do_echo';; #doesnt work on mac
      test)      cmd='do_test_semver';;
      bc)        cmd='do_build_count';;
      bcr)       cmd='do_remote_build_count';;
      can)       cmd='do_can_semver';;
      last|tag)  cmd='do_latest_semver';;
      lbl)       cmd='do_label_help';;
      mark1|new) cmd='do_mark_1';;
      fetch)     cmd='do_fetch_tags';;
      remote)    cmd='do_latest_remote';;
      upst*)     cmd='do_remote_compare';;
      rbc*)      cmd='do_rbuild_compare';;
      tags)      cmd='do_tags';;
      chg)       cmd='do_change_count';;
      auto)      cmd='do_auto';;
      st*)       cmd='do_status';;
      pend*)     cmd='do_pending';;
      fwd)       cmd='do_has_forward';;
      file)      cmd='do_build_file';;
      insp*)     cmd='do_inspect';;
      since)     cmd='do_last';;
      snip)      cmd='do_snip';;
      info)      cmd='do_info';;
      next|dry)  cmd='do_bump';;
      bump)      cmd='do_bump'; arg=0; ;;
      help)      cmd='usage';;
      *)
        if [ ! -z "$call" ]; then
      
          err="Invalid command => $call";
          usage
        else
          #err="Missing command!";
          do_latest_semver
        fi
      ;;
    esac


    if [ -n "$cmd" ]; then
      $cmd "$arg" "$arg2"; ret=$?;
      return $ret;
    fi

    [ -n "$err" ] && fatal "$err";
    return $ret;

  }


  main(){
    dispatch "${args[@]}";ret=$?
    return $ret;
  }


#-------------------------------------------------------------------------------


  if [ "$0" = "-bash" ]; then
    :
  else
    orig_args=("${@}")
    options "${orig_args[@]}";
    args=( "${orig_args[@]/^-*}" ); #delete anything that looks like an option
    main "${args[@]}";ret=$?
  fi

#-------------------------------------------------------------------------------
#=====================================!code=====================================
#====================================doc:help!==================================
#
#  \n\t${b}semv [command] ${x}
#  
#  \t${o}insp${x} - shows funcs and dispatch keys (full help not done yet)
#  \t${o}info${x} - shows repo/branch info
#  \t${o}lbl${x}  - shows comit labels to use for versions (mini help)
#  \t${o}new${x}  - initializes the repo to use semv style tags with 0.0.1
#  \t${o}bump${x} - create the next version tag and commit
#  \t${o}pend${x} - check for new dev flags since last version
#  \t${o}upst${x} - check for new remote tags
#  \t${o}rbc${x}  - remote build compare
# 
#  \t${w2}Commit Labels:${x}
#  \t${w}Commit messages must be prefixed by one of the labels in order
#  \tfor auto version incrementer to work.${x}\n
#  \t${spark} ${o}brk:${x}\t --> Use for breaking changes \t[Major]
#  \t${spark} ${o}feat:${x}\t --> Use for new features added\t[Minor]
#  \t${spark} ${o}fix:${x}\t --> Use for fixing bugs \t[Patch]
#  \t${spark} ${o}dev:${x}\t --> Use for dev note locks \t[Dev]
# 
#  \t${r}Dev Build Mode: (ex:v1.0.0-build289)${x}
#  \t${w}The dev label prevents the version from bumping, instead 
#  \tappending a build number to the tag 
#  \tthis helps when you are iterating on fix/features
#  \twithout triggering a version bump. Switch off by using${x}
#  \t<bump> or <auto> commands.
# 
#=================================!doc:help=====================================
