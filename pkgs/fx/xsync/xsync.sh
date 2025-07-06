#!/usr/bin/env bash
#===============================================================================
#      ___ _   _ _ __   _____  __
#     / __| | | | '_ \ / __\ \/ /
#     \__ \ |_| | | | | (__ >  < 
#     |___/\__, |_| |_|\___/_/\_\
#           __/ |                
#          |___/                 
#
#===============================================================================

#note: rsync requires asbolute path
#note: make sure remote rsync bin is known by local rsync
#note: any errors will cause rsync to fail
#note: fswatch must be installed on mac
#note: debug with -vv --rsync-path=/usr/bin/rsync

  SYNCX_CONFIG="${SYNCX_CONFIG:-$SYNCX_HOME/config}";
  # can we add a way to look for a local syncx.rc file?

  SYNCX_RC="$SYNCX_HOME/syncx.rc"
  SYNCX_CACHE="$SYNCX_HOME/syncx.cache"

  SYNCX_LOG="$MY_LOG/syncx-change.log"
  SYNCX_ACTIVE_ID=-999;


# sync@devnull fun1:on
# --local /my/path
# --remote /other/path
# --include '*.log'
# --exclude '*'
# --flags -avi



  touch $SYNCX_LOG
  chmod u+w "$SYNCX_LOG"

  logo=$(sed -n '3,9 p' $BASH_SOURCE)
  hosts=()
  pids=()
  keys=()

  inactives=()
  local_paths=()
  host_paths=()

  delete_flag=

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
  idots="\xE2\x80\xA6"


#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------
  
  # __debug_mode(){ [ -z "$opt_debug" ] && return 1; [ $opt_debug -eq 0 ] && return 0 || return 1; }
  # __quiet_mode(){ [ -z "$opt_quiet" ] && return 1; [ $opt_quiet -eq 0 ] && return 0 || return 1; }


#-------------------------------------------------------------------------------
# Printers
#-------------------------------------------------------------------------------

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

  __confirm(){
    local ret;ret=1
    __printf "${1}? > " "white2" #:-Are you sure ?
    [ $opt_yes -eq 0 ] && __printf "${bld}${green}auto yes${x}\n" && return 0;
    [[ -f ${BASH_SOURCE} ]] && src='/dev/stdin' || src='/dev/tty'

    while read -r -n 1 -s answer < $src; do
      [ $? -eq 1 ] && exit 1;
      if [[ $answer = [YyNn10tf+\-q] ]]; then
        [[ $answer = [Yyt1+] ]] && __printf "${bld}${green}yes${x}" && ret=0 || :
        [[ $answer = [Nnf0\-] ]] && __printf "${bld}${red}no${x}" && ret=1 || :
        [[ $answer = [q] ]] && __printf "${bld}${purple}quit${x}\n" && exit 1 || :
        break
      fi
    done
    __printf "\n"
    return $ret
  }


  __confirm2() {
    local ret=1 answer src
    __printf "${1}? > " "white2"
    [ $opt_yes -eq 0 ] && { __printf "${bld}${green}auto yes${x}\n"; return 0; }
    src=${BASH_SOURCE:+/dev/stdin} || src='/dev/tty'

    while read -r -n 1 -s answer < $src; do
      [[ $? -eq 1 ]] && exit 1
      [[ $answer = [YyNn10tf+\-q] ]] || continue
      case $answer in
        [Yyt1+]) __printf "${bld}${green}yes${x}"; ret=0 ;;
        [Nnf0\-]) __printf "${bld}${red}no${x}"; ret=1 ;;
        [q]) __printf "${bld}${purple}quit${x}\n"; exit 1 ;;
      esac
      break
    done
    __printf "\n"
    return $ret
  }

  warn(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$delta $text$x\n" "orange"; }
  okay(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] &&__printf "$pass $text$x\n" "green"; }
  info(){ local text=${1:-} force=${2:-1}; [ $force -eq 0 ] || [ $opt_debug -eq 0 ] && __printf "$lambda $text\n" "blue"; }

  trace(){ local text=${1:-}; [ $opt_trace -eq 0 ] && __printf "$idots $text\n" "grey"; }
  error(){ local text=${1:-}; __printf " $text\n" "fail"; }
  fatal(){ trap - EXIT; __printf "\n$red$fail $1 $2 \n"; exit 1; }


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
  #trap 'echo "An unhandled error occurred!"; exit 1' ERR


#-------------------------------------------------------------------------------
# Dump
#-------------------------------------------------------------------------------
  dump_pids(){
    for ((i=0; i<${#hosts[@]}; i++)); do
      echo "${pids[i]}";
    done
  }

  dump_cat(){
    local arg="$1"
    if [ -n "$arg" -a -f "$arg" ]; then
      cat "$arg"
    fi    
  }

  dump_rc(){
    if [ -n "$syncx_rc" -a -f "$syncx_rc" ]; then
      cat "$SYNCX_RC"
    fi
  }

  dump_config(){
    if [ -n "$SYNCX_CONFIG" -a -f "$SYNCX_CONFIG" ]; then
      cat "$SYNCX_CONFIG";
    fi
  }

  dump_curr(){
    trace "Current info"

    for ((i=0; i<${#hosts[@]}; i++)); do

      pid=${pids[i]};

      if ! is_running "${pid}" "$i"; then 
        res="${red}not running${x}"
        #pause_sync $pid $i;
      else
        res="${green}running${x}" 
      fi

      info "[$i] ${res} | $pid ${hosts[i]} ${inactives[i]} | ${local_paths[i]} => ${host_paths[i]} "

    done
  }
 
  dump_var(){
    local arg="$1"
    echo "${!arg}"
  }

#-------------------------------------------------------------------------------
# Utils
#-------------------------------------------------------------------------------

  is_running(){
    trace "is_running pid $1 $2"
    local target_pid="${1:-1}" index="$2"
    if [ -n "$target_pid" ] && [ "$target_pid" -ge 0 ]; then
      if ps -p "$target_pid" > /dev/null; then
        inactives[i]=$SYNCX_ACTIVE_ID
        return 0;
      else
        inactives[i]=$i;
      fi
    fi
    return 1;
  }


  find_pid_index(){
    trace "find pid $1"
    local ret=0 target_pid="$1"
    for ((i=0; i<${#pids[@]}; i++)); do
      if [ "${pids[i]}" = "$target_pid" ]; then
        echo $i;
        return 0;
      fi
    done
    echo -1;
    return 1;
  }

  find_host_index(){
    local ret=0 target_host"$1"
    for ((i=0; i<${#hosts[@]}; i++)); do
      if [ "${hosts[i]}" = "$target_host" ]; then
        echo $i;
        break;
      fi
    done
    echo -1;
  }


  ls_active(){
    for ((i=0; i<${#hosts[@]}; i++)); do
      if [ "${actives[i]}" != "$SYNCX_ACTIVE_ID" ]; then
        echo "[$i] ${pids[i]} ${hosts[i]}:${local_paths[i]} (key:${keys[i]})"
      fi
    done
  }


  ls_inactive(){
    for ((i=0; i<${#hosts[@]}; i++)); do
      if [ "${inactives[i]}" == "$SYNCX_ACTIVE_ID" ]; then
       echo "[$i] ${keys[i]} ${hosts[i]}:${local_paths[i]}"
      fi
    done
  }


  print_row(){
    local i;
    echo "${keys[i]} ${hosts[i]} ${pids[i]} ${inactives[i]}" 
  }
 

  pseudo_key(){
    rand=$RANDOM$RANDOM
    rand=${rand: -5}
    echo $rand
  }

#-------------------------------------------------------------------------------
# Config
#-------------------------------------------------------------------------------
  
   config_load(){
    trace "loading config at ($opt_config)"

    if [ -z "$SYNCX_HOME" ] || [ ! -d "$SYNCX_HOME" ]; then
      fatal "Syncx Prefix (SYNCX_HOME) missing or invalid (val:$SYNCX_HOME). Please add to profile."
    fi

    if [ -z "$opt_config" ] || [ ! -f "$opt_config" ]; then
      fatal "Config file not found ($opt_config)"
    fi

    while read -r host l_path h_path; do
      trace "config $host"
      hosts+=("$host")
      local_paths+=("$l_path")
      [ -z "$h_path" ] && h_path=$l_path; #use local path for host path if none provided
      host_paths+=("$h_path")
    done < $opt_config
  }


  rc_load(){
    if [ -n "$SYNCX_RC" -a -f "$SYNCX_RC" ]; then
      while read -r key host pid inactive; do
        keys+=("$key")
        #not updating hosts here because it adds duplicate entries
        pids+=("$pid")
        inactives+=("$inactive")
      done < $SYNCX_RC
    else
      trace "$fail rc file not found... no loads"
      :
    fi
  }


  rc_write(){
    # Write the updated host-PID pairs to the .syncxrc file
    [ -n "$SYNCX_RC" -a ! -f "$SYNCX_RC" ] && touch "$SYNCX_RC";

    if [ -n "$SYNCX_RC" -a -f "$SYNCX_RC" ]; then
      > $SYNCX_RC
      #echo "#Note: Use trailing slash on local path to sync files " > $SYNCX_RC;
      #echo "# \t HOST \t LOCAL_PATH \t HOST_PATH " > $SYNCX_RC;
      for ((i=0; i<${#hosts[@]}; i++)); do
        if [ -n "$host" ]; then
          trace "writing line $i $host to rc"
          echo "${keys[i]} ${hosts[i]} ${pids[i]} ${inactives[i]}" >> $SYNCX_RC
        fi
      done 
    fi
    info "Writing Rc File..."
  }



#-------------------------------------------------------------------------------
# Rsync
#-------------------------------------------------------------------------------
  
  fake_syncx(){
    trace "execute fake"
    local i="$1" host="$2" local_dir="$3" host_dir="$4" pid ret; 

    
    if [ -d "$local_dir" -o  -f "$local_dir" ]; then
      info "fake sync > $local_dir (log at $SYNCX_LOG)"
      fswatch -o -L "$local_dir" | while read file; do
        echo "$(date) - fakesync change detected" >> "$SYNCX_LOG"
        #sleep $(( RANDOM % 100 + 1 ))
      done &
        
      pid=$!
      pids[i]="$pid"
      #echo $pid;
      return 0;
    else
      fatal "Path ($local_dir) doesnt exist cannot rsync!!"
      return 1;
    fi

  }

  do_syncx(){
    trace "execute rsync ($1 $2 $3)"
    local i="$1" host="$2" local_dir="$3" host_dir="$4" pid ret; 

    if [ -d "$local_dir" -o  -f "$local_dir" ]; then

      run_date=$(date "%m%d%Y");
      echo "date $run_date"
      host_log="$MY_LOG/${host}-host.log"

      fswatch -o -L "$local_dir" | while read file; do
        echo "$(date) - syncx change detected" >> "$SYNCX_LOG"
        rsync -avz --rsync-path=/usr/bin/rsync $delete_flag --exclude='.DS_Store' --exclude='.git' --exclude="*bak*" --exclude="*.zip" "$local_dir" "$host:$host_dir" >> "$host_log"
      done &

      pid=$! # Store the PID of the subshell
      echo "fswatch PID: $pid" >> "$SYNCX_LOG"

      pids[i]="$pid"

      info "Watching $host... ($pid) [connection:$i]";
      info "$local_dir -> $host_dir";


      #ret=$?;
      return 0;
    else
      fatal "Path ($local_dir) doesnt exist cannot rsync!!"
      return 1;
    fi
  }


#-------------------------------------------------------------------------------
# Pause
#-------------------------------------------------------------------------------

  do_pause_sync(){
    trace "execute pause ($1 $2 $3)"
    local ret=1 target_pid="${1:--1}"
    if [ "$target_pid" -ge 0 ]; then
      trace "Killing $target_pid => $((target_pid-1))"
      kill -9 "$target_pid"; ret=$?;
      kill -9 $((target_pid-1)); ret=$?; #child kill this is hacky
      #pkill -P "$target_pid"; ret=$?;
      [ $ret -eq 0 ] && echo "Process ${target_pid} terminated.";
      [ $ret -eq 1 ] && err="Failed to kill process ${target_pid}.";
    fi
    return $ret;
  }
 

  pause_sync_id(){
    if [ -n "$1" ]; then
      local ret=0 i="$1" 
      target_pid=${pids[i]};
      pause_sync $target_pid;
    fi
  }


  pause_sync(){
    trace "pause sync (pid:$1)..."
    local ret=0 target_pid="$1" index;

    if is_running "$target_pid"; then

      do_pause_sync $target_pid; 

      # Find the index of the PID to kill in the array and unset it
      if [ -z "$2" ]; then 
        index=$(find_pid_index $target_pid)
      else
        index=$2;
      fi

      if [ "$index" != "-1" ]; then
        inactives[i]=$i;
      else
        warn "PID $target_pid not found ($index) in array.";
        inactives[i]=$SYNCX_ACTIVE_ID;
      fi

      
    else
      warn "PID not running ($target_pid)"
    fi

    rc_write;
    return $ret;
  }  



  kill_sync(){
    trace "Kill all..."
    # Loop over the PIDs
    for ((i=0; i<${#pids[@]}; i++)); do
      target_pid=${pids[i]};

      # Skip if PID is -1 (indicating a previously killed process)
      if [ "$target_pid" != "-1" ]; then
        # Kill the process and handle any errors
        res=$(pause_sync $target_pid $i); ret=$?;
      else
        warn "Watcher for ${hosts[i]} was inactive. Skipping ($target_pid)"
      fi

    done
  }



#-------------------------------------------------------------------------------
# Run
#-------------------------------------------------------------------------------

  re_sync(){
    trace "Resync run... ($1)"
    local res ret i="$1";
    target_pid="${pids[i]}";

    # If the host at the specified index is inactive, run rsync for it
    if ! is_running $target_pid; then

      key="${keys[i]}"
      host="${hosts[i]}"
      local_dir="${local_paths[i]}"
      host_dir="${host_paths[i]}"

      info "Restarting [$i] sync for $host:$host_dir..."
      info "\t $local_dir to $host_dir";
      do_syncx "$i" "$host" "$local_dir" "$host_dir"; ret=$?;
     
      if [ $ret -eq 0 ]; then
        pid=${pids[i]};
        inactives[i]=$SYNCX_ACTIVE_ID;
        rc_write;
      else
        err="An error occurred trying to resync ($host)"
      fi
    else
      warn "Appears to not be running (pid:$target_pid -> ${inactives[i]})"
      inactives[i]=$i;
    fi

    return $ret;
  }



  main_sync(){
    #trace "Sync run..."
    local host host_dir local_dir first_load=1

    for ((i=0; i<${#hosts[@]}; i++)); do
      
      host="${hosts[i]}"
      local_dir="${local_paths[i]}"
      host_dir="${host_paths[i]}"

      if [ -n $host ] && [ -d "$local_dir" ]; then

        if [ -z "${pids[i]}" ] || ! is_running "${pids[i]}" ]; then

          trace "Sync run... on (host:$host) "

          do_syncx "$i" "$host" "$local_dir" "$host_dir"; ret=$?;
          pid=${pids[i]};
          actives[i]=$SYNCX_ACTIVE_ID
          keys[i]=$(pseudo_key)

        else   
          warn "Already watching $local_dir for $host. Skipping Sync..."
        fi

      fi

    done

    rc_write;

  }


  main_fake_sync(){
    trace "Sync run..."
    local host host_dir local_dir first_load=1

    for ((i=0; i<${#hosts[@]}; i++)); do
      
      host="${hosts[i]}"
      local_dir="${local_paths[i]}"
      host_dir="${host_paths[i]}"

      info "! $host $local_dir "

      if [ -n $host ] && [ -d "$local_dir" ]; then

        if [ -z "${pids[i]}" ] || ! is_running "${pids[i]}" ]; then

          trace "Sync run... on (host:$host) "

          fake_syncx "$i" "$host" "$local_dir" "$host_dir"; ret=$?;
          pid=${pids[i]};
          inactives[i]=$SYNCX_ACTIVE_ID
          keys[i]=$(pseudo_key)

        else   
          warn "Already watching $local_dir for $host. Skipping Sync..."
        fi

      fi

    done

    rc_write;

  }



  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")

    while IFS= read -r line; do
      echo "$line"
    done <<< "$_content"

 }


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

  usage(){
    if command_exists 'docx'; then
      docx "$BASH_SOURCE" "doc:help"; 
    fi
  }



  options(){
    local this next opts=("${@}");
    
    opt_mirror=1
    opt_debug=1
    opt_quiet=1
    opt_trace=1
    opt_config="$SYNCX_CONFIG"

    for ((i=0; i<${#opts[@]}; i++)); do

      this=${opts[i]}
      next=${opts[i+1]}
      

      case "$this" in
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
        --mirror|-m)
          opt_mirror=0;
          delete_flag="--delete";
          ;;
        --config|-c)
          if [ -f $next ]; then
            opt_config="$next";
          else
            fatal "Missing valid path to custom config file --config <path>"
          fi
          ;;
      esac
    done


  }


  #todo: add host log tail

  dispatch(){

    local call="$1" arg="$2" cmd= ret;
    case $call in
      run)      cmd='main_sync';; #doesnt work on mac
      pa*)      cmd='pause_sync_id';;
      re*)      cmd='re_sync';;
      ki*|stop) cmd='kill_sync';;
      ls)       cmd='ls_active';;
      lsi)      cmd='ls_inactive';;
      pids)     cmd='dump_pids';;
      insp*)    cmd="do_inspect";;
      fake*)    cmd='main_fake_sync';;
      xrc)      cmd='dump_var'; arg="SYNCX_RC";;
      xhome)    cmd='dump_var'; arg="SYNCX_HOME";;
      xconf)    cmd='dump_var'; arg="SYNCX_CONFIG";;
      conf*)    cmd='dump_cat'; arg="$SYNCX_CONFIG";;
      rc)       cmd='dump_cat'; arg="$SYNCX_RC";;
      curr|stat) cmd='dump_curr';;
      key)      cmd='pseudo_key';; #int generator
      help)     cmd='usage';;
      *)
        if [ ! -z "$call" ]; then
          err="Invalid command => $call";
        else
          err="Missing command!";
        fi
      ;;
    esac


    if [ -n "$cmd" ]; then
      trace "< $call | $cmd $arg >";
      $cmd "$arg";ret=$?;
    fi

    [ -n "$err" ] && fatal "$err";
    return $ret;

  }


  main(){
    config_load;
    rc_load;
    __logo
    dispatch "${args[@]}";ret=$?

  }


#-------------------------------------------------------------------------------


  if [ "$0" = "-bash" ]; then
    :
  else
    

    #command_exists fswatch
    orig_args=("${@}")
    options "${orig_args[@]}";
    args=( "${orig_args[@]/\-*}" ); #delete anything that looks like an option
    main "${args[@]}";ret=$?
  fi

#====================================doc:help!==================================
#  \n\t${b}syncx <cmd> [arg]${x}
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

