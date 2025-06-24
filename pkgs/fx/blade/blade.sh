#!/usr/bin/env bash
#-----------------------------><-----------------------------#
# -> Author: qodeninja
# -> Date: 11/18
# -> Id: fx-blade
# -> Autobuild: 8007f1
# -> Desc: DESCRIPTION
#-----------------------------><-----------------------------#
##
##     __    __          __
##    / /_  / /___ _____/ /__
##   / __ \/ / __ `/ __  / _ \
##  / /_/ / / /_/ / /_/ /  __/
## /_.___/_/\__,_/\__,_/\___/
##
##          ▟▙
##  ▟▒░░░░░░░▜▙▜████████████████████████████████▛
##  ▜▒░░░░░░░▟▛▟▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▛
##          ▜▛
##
##  ▬▬ι═════════-
#-------------------------------------------------------------------------------
# Settings
#-------------------------------------------------------------------------------

	red=$(tput setaf 9)
	yellow=$(tput setaf 11)
	orange=$(tput setaf 214)
	green=$(tput setaf 2)
	blue=$(tput setaf 12)
  blue2=$(tput setaf 4)
	purple=$(tput setaf 213)
	grey=$(tput setaf 239)
	w=$(tput setaf 15)
	wz=$(tput setaf 248)
	dash="\xE2\x80\x95"
	x=$(tput sgr0)
	eol="$(tput el)"
	eos="$(tput ed)"
	cll="$(tput cuu 1 && tput el)"
	bld="$(tput bold)"
	inv="$(tput rev)"
  bolt="\xE2\x86\xAF"
	pass='\xE2\x9C\x93'
	fail='\xE2\x9C\x97'
	delta='\xE2\x96\xB3'
	hook='\xE2\x94\x94'
	dots='\xE2\x80\xA6'
	flecha='\xC2\xBB'
	flecha2='\xC2\xAB'
  arrup='\xE2\x86\x91'
  arrdn='\xE2\x86\x93'
	space='\x20'
	diamond='\xE1\x9B\x9C'
  spark=$'\xe2\x9f\xa1'
  redo=$'\xE2\x9F\xB3'
	logo=$(sed -n '9,15 p' $BASH_SOURCE)
	sword=$(sed -n '16,19 p' $BASH_SOURCE)
	dline=$(sed -n '22,22 p' $BASH_SOURCE)
	tab=$'\t'
	ESCAPE_SEQ=$'\033'
	UP=$'A'
	DOWN=$'B'
	LEFT=$'C'
	RIGHT=$'D'
	SPACER=$'\x20'
	RETKEY=$'\x0a'



#-------------------------------------------------------------------------------
# Blade Vars
#-------------------------------------------------------------------------------
   CPID="$$"

	BLADE_RC="$HOME/.bladerc"
	BLADE_SRC="$HOME/.dx/dev" #path roots very delicate
	BLADE_SAFE_MODE=0

	BLD_REPO_1=
	BLD_RDIR_1=
	BLD_GRP_1=
	BLD_GDIR_1=
	BLD_ALIAS_1=


#-------------------------------------------------------------------------------
# Settings
#-------------------------------------------------------------------------------
	#:+ Known repos R* REPO_1
	__repo_list=( )

	#:+ Loaded git folders
	__known_list=()

	#:+ Available groups G* GROUP_1 GROUP_2
	__group_list=( )

	#:+ Available aliases A* ALIAS_1 ALIAS_2
	__alias_list=()

  __jump_name=()

  __semver_list=()

	#:+ Which repo R does alias A map to? REPO_1 REPO_2
	__alias_map=()

	#:+ Which dir D maps to repo R?  DIR_1 DIR_2
	__rdir_map=()

	#:+ Which group G does repo R belong to? GDIR_1 GDIR_2
	__group_map=()

	#:+ Which dir D maps to group G? GROUP_1 GROUP_2
	__gdir_map=()



	__owner=()
	__res=
	__buf_list=1
	__buf_msg=
	__buf=()
	__filt=()
	__stat=()

  __keep_index=()
  __keep=""

#-------------------------------------------------------------------------------
# Sig / Flow
#-------------------------------------------------------------------------------

	function __fullscreen() {
		tput smcup
		printf "\e[?25l" #hide
		#stty -echo
	}

	function __exitscreen() {
		tput rmcup
		#stty echo
		printf "\e[?25h" #show
		return 0
	}

	function handle_sigint() {
		__exitscreen
		S="$?"
		kill 0
		exit $S
	}

	function handle_sigtstp() {
		__exitscreen
		kill -s SIGSTOP $$
	}

	function handle_input(){
		[ -t 0 ] && stty -echo -icanon time 0 min 0
	}

	function cleanup(){
		[ -t 0 ] && stty sane
	}

	function fin(){
		local E="$?"
		cleanup
		# if [ -z "$opt_readonly_mode" ]; then
		# 	[ $E -eq 0 ] && printf "${green}${pass} ${1:-Done}." \
		# 							 || printf "$red$fail ${1:-${err:-Cancelled}}."
		# fi
	}


#-------------------------------------------------------------------------------
# Traps
#-------------------------------------------------------------------------------


	trap handle_sigint INT
	trap handle_sigtstp SIGTSTP
	trap handle_input CONT
	trap fin EXIT

#-------------------------------------------------------------------------------
# Util
#-------------------------------------------------------------------------------


	function __print(){
		local text color prefix
		text=${1:-}; color=${2:-grey}; prefix=${!3:-}
		# %b in format to get \n \t
		[ -n "$text" ] && printf "${prefix}${!color}%b${x}\n" "${text}" 1>&2
	}


	function __joinby(){
		local IFS="$1"; shift;
		echo "$*";
	}


	function __confirm() {
		local ret;ret=1
		printf "${1:-Are you sure ?}"
		while read -r -n 1 -s answer; do
			if [[ $answer = [YyNn10tf+\-q] ]]; then
				[[ $answer = [Yyt1+] ]] && printf "${bld}${green}yes${x}" && ret=0 || :
				[[ $answer = [Nnf0\-] ]] && printf "${bld}${red}no${x}" && ret=1 || :
				[[ $answer = [q] ]] && printf "\n" && exit 1 || :
				break
			fi
		done
		printf "\n"
		return $ret
	}

	opt_yes=1
  if [[ "${@}" =~ "--yes" ]]; then
    opt_yes=0
    shift;
  fi

  __prompt(){
    local msg="$1" default="$2"
    if [ $opt_yes -eq 1 ]; then
      read -p "$msg --> " answer
      [ -n "$answer" ] && echo "$answer" || echo "$default"
    else 
      echo "$default"
    fi
  }

	function __dump_ez(){
		local len arr i this 
		arr=("${@}"); len=${#arr[@]}
		if [ $len -gt 0 ]; then
			for i in ${!arr[@]}; do
				this="${arr[$i]}"
				[ -n "$this" ] && __print "-> $this $x"
			done
		fi
	}

	function __dump(){
		local len arr i this flag newl
		arr=("${@}"); len=${#arr[@]}
		[ $__buf_list -eq 0 ] && flag="\r" &&  newl="$eol" || newl="\n"
		if [ $len -gt 0 ]; then
			handle_input
			for i in ${!arr[@]}; do
				this="${arr[$i]}"
				[ -n "$this" ] && printf "$flag$orange$dots(%02d of %02d) $this $x$newl" "$i" "$len"
				sleep 0.1
			done
			cleanup
			printf "$flag$green$pass (%02d of %02d) Read. $x$eol\n" "$len" "$len"
		fi
	}

	function __wait(){
		local n l m=${1:-"Press Enter."};n=0
    printf "\r${m}$eol\n"
		while test $n -lt 1; do
			read l
			sleep 0.2
			echo -n " "
			n=$[n+1]
		done
		printf "$x"
		printf "\r$green$pass Done. $x$eol\n"
		clear
	}

  function indexof(){
    local elem args i j list; elem=$1; shift; list=("${@}")
    i=-1;
    for ((j=0;j<${#list[@]};j++)); do
      [ "${list[$j]}" = "$elem" ] && { i=$j; break; }
    done;
    echo $i;
    [[ "$i" == "-1" ]] && return 1 || return 0
  }



#-------------------------------------------------------------------------------
# API
#-------------------------------------------------------------------------------

	function __find_dirs(){
		__print "${purple}Finding project folders... $2 $x"
		find_cmd="find ${2:-.} -mindepth 1"
		[[ $1 =~ "1"   ]] && find_cmd+=" -maxdepth 2" || :
		[[ $1 =~ git ]] && find_cmd+=" -name .git"  || :
		find_cmd+=" -type d ! -path ."
		awk_cmd="awk -F'.git' '{ sub (\"^./\", \"\", \$1); print \$1 }'"
		cmd="$find_cmd | $awk_cmd"
		eval "$cmd"
	}


#-------------------------------------------------------------------------------
# Util
#-------------------------------------------------------------------------------


	__filter_buffer(){
		local IFS i
    local ig=("${@}");
    local match
		IFS=$' '

    for i in ${!__buf[@]}; do
      this="${__buf[$i]}"
			match=1
			for that in ${ig[@]}; do
        if [[ "$this" =~ ^"$that".* ]]; then
          match=0
          break
        fi
			done

      if [ $match -eq 1 ]; then
        __keep_index+=("$i") #only local so we have to pass 
      else
        __filt+=("$this")
      fi
		done

	  echo "${__keep_index[@]}" #<-- here
	}


	function __print_buffer(){
		local i j buf len sel act ttl pre

		sel="$1"
		act=${2:-0};
		buf=("${__buf[@]}")
		len=${#buf[@]}

		if [ $len -gt 0 ]; then
			((j=sel+1))
			printf "\n\n\n$tab${__buf_msg} (sel:$j)\n\n"
			for i in ${!buf[@]}; do
				((j=i+1))
				pre=
				this="${buf[$i]}"
				this_st="${__stat[$i]}"
				if [ $act -eq 0 ]; then
					case "$this_st" in
						"sel")  pre="$green[$pass]$x";;
						"del")  pre="$red[$fail]$x";;
						"none") pre="[$spark]";;
						*);;
					esac
				else
					[[ "$i" = "$sel" ]] && pre="$purple[$spark]" || pre="[$spark]"
				fi

				[[ "$i" = "$sel" ]] && delim="$purple$flecha$x" || delim="$space"
				printf "$tab $delim $pre %-2d $this$x\n" "$j"
			done

		fi
	}



	function __selection_buffer(){
		local buf len idx tmp act go key IFS


		idx=0
		act=${2:-0};go=0
		buf=("${__buf[@]}")
		len=${#buf[@]}; [ $len -eq 0 ] && return 1;
		((len-=1))

		__buf_msg="\n\n$blue${logo//#/ }$x\n\n\t$1"
		__fullscreen

		for i in ${buf[@]}; do
			__stat+=('none')
		done

		clear

		OLDIFS="$IFS"
		IFS=''
		cleanup


		while true; do

			__print_buffer $idx "$act"

			read -rsn 1 key
			case "$key" in
				$ESCAPE_SEQ)
					read -rsn 1 -t 1 tmp
					if  [[ "$tmp" == "[" ]]; then
						read -rsn 1 -t 1 arrow
						case "$arrow" in
							$UP)
							  [ $idx -ne 0 ] && ((idx-=1)) || :
								;;
							$DOWN)
								[ $idx -lt $len ] && ((idx+=1)) || :
								;;
							$LEFT)
								[[ ${__stat[$idx]} = 'del' ]] && __stat[$idx]='none' || __stat[$idx]='sel'
								;;
							$RIGHT)
								clear
								[[ ${__stat[$idx]} = 'sel' ]] && __stat[$idx]='none' || __stat[$idx]='del'
								go=1
								;;
						esac
					else
						printf "what?"
					fi
					;;
			$ESCAPE_SEQ)

			;;
			"+"|"_"|".")
				case "$key" in
					"+") tmp="sel";;
					"_") tmp="del";;
					*)   tmp="none";;
				esac
				for i in ${!buf[@]}; do
					__stat[$i]="$tmp"
				done
				;;
			"*"|"=")
				__stat[$idx]='sel'
				;;
			"-")
				__stat[$idx]='del'
				;;
			"q")
				__exitscreen
        __print "Exiting..."
				return 1
				;;
			"$SPACER")
				case "${__stat[$idx]}" in
					"sel") tmp="none";;
					"del") tmp="none";;
					"none")tmp="sel";;
					*);;
				esac
				__stat[$idx]=$tmp
				go=1
				;;
			"")
				go=1
				act=1
				;;
			esac

			clear

			if [ $act -eq 1 -a $go -eq 1 ]; then

				__res="${buf[$idx]}" #return value
				__exitscreen
				return 0
			fi

		done
	}

	# split global buffer into accepted stacked and rejected buckets
	function __sort_buffer(){
		local ret i stack keep skip buf len this this_st
		buf=("${__buf[@]}")
		len=${#buf[@]}
		if [ $len -gt 0 ]; then
			for i in ${!buf[@]}; do
				pre=
				this="${buf[$i]}"
				this_st="${__stat[$i]}"
				case "$this_st" in
					"sel")  keep+=("$this");;
					"del")  skip+=("$this");;
					"none") stack+=("$this");;
					*);;
				esac
			done
			__res="${keep[*]};${stack[*]};${skip[*]};${__stat[*]}"
			__buf=()
			__stat=()
		fi
	}

#-------------------------------------------------------------------------------
## setup
#-------------------------------------------------------------------------------


	function auto_setup(){

		local i j k this len buf arr kg ndir rdir nd ig
		kg=();nd=();ig=();
		this="$1"
		handle_input

		clear
		__fullscreen
		printf "\n\n\n\n\n$blue${logo//#/ }\n${sword}$x\n\n\t"

		buf=($(__find_dirs "git" "$this")); ret=$?
    sleep 4
		__wait
		__known_list=("${buf[@]}")
		len=${#buf[@]}

		if [ $len -gt 0 ]; then
			for this in ${buf[@]}; do

				arr=(${this//\// })
				len=${#arr[@]}
				ndir=${arr[((len-1))]}
				rdir=("${arr[@]:0:((len-1))}")

				nd+=( "$ndir" )

				this="$(__joinby \/ ${rdir[@]})"
				printf "$this -> $ndir ($len)\n"
				kg+=( $this )

			done
		fi


		#use global buffer and sort uniqs
		__buf=( $(printf "%s\n" "${kg[@]}" | sort -u) )
		__selection_buffer "Select Paths to add to Groups [${arrup}${arrdn}/spacebar]:"; ret=$?
		[ $ret -eq 1 ] && return 1

		__sort_buffer
		__buf=()

		OIFS="$IFS"
		IFS=';' read -ra this <<< "$__res"
		kg=(${this[0]})
		ig=(${this[1]}) #<------------------------------------------- why was this 2 ???

		__group_list=(${this[0]})
    
		__print "$red Building exclude list... $x"

		for this in ${__group_list[@]}; do
			__gdir_map+=( "$this" ) #$BLADE_SRC/
		done

		__buf=(${__known_list[@]})
		__buf=( $(__filter_buffer "${ig[@]}" | sort -u) ) #keeper values

    #__dump "${__buf[@]}"
    
    #buffer rematch to keep index
    for i in ${!__buf[@]}; do
      this="${__buf[$i]}"
      keep="${__known_list[$this]}" #index swap
      __buf[$i]=$keep
      __keep_index+=($this)
    done


		__buf_list=0

		__selection_buffer "Select Projects to track [${arrup}${arrdn}/spacebar]:"; ret=$?
		[ $ret -eq 1 ] && return 1
		__sort_buffer

		OIFS="$IFS"
		IFS=';' read -ra this <<< "$__res"
		kg=(${this[0]})

    __exitscreen

    SEMVER=$(which semv)
    clear

    if [ -x "$SEMVER" ]; then
      __print "\n\n\n\n$blue\t${bolt} Blade found semver tool.${x}"
      if __confirm "[ ${green}SEMVER ready${x} ] Load versions (y/n/q) ? "; then
        __print "\n\n"
        for i in ${!kg[@]}; do
          this="${kg[$i]}"
          this="$BLADE_SRC/$this"
          vers="$(semv auto $this)"
          [ -z "$vers" ] && {
            vers='missing'
            _vp="${red}${vers}${x}"   
           } || _vp="${green}${vers}${x}${grey}" 
          __semver_list+=($vers)
          __print "[$_vp] ${purple}${this}${x}"
        done
      else
        __print "${red}Skipping Semver..${x}"
      fi
    fi

    __print "\n\n"

		for i in ${!kg[@]}; do
      __keep="${__keep_index[$i]}"
			this="${kg[$i]}"
			rthis="${nd[$__keep]}"  #full index is from another place so need keeper mathc
			athis=${rthis//-/_}
			for j in ${!__group_list[@]}; do
				that="${__group_list[$j]}"
				case $this in
					$that/*)
						__group_map+=($j)
						__alias_map+=($i) #even though i thought you were not you are in fact I
						__alias_list+=($athis)
						__repo_list+=($rthis) #?? even you are wrong!
						__rdir_map+=( "$BLADE_SRC/$this" )
					;;
					*) : ;;
				esac
			done
		done
		__buf_list=0
		__dump "${__rdir_map[@]}"
		save_rc_file

    __print "\n\n$blue\t${bolt} Blade indexing complete. \n\n${x}"
	}


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
	function find_repos(){

		local i j k this len buf arr kg ndir rdir nd ig
		kg=();nd=();ig=();
		this="$1"

		#because of how I named some repos have to buff out ./proj/<=repos/
		buf=($(__find_dirs "git" ".")); ret=$?

		__buf_list=1
		__dump "${buf[@]}"

	}

	function save_rc_file(){
		rm $BLADE_RC
		[ -n ${BLADE_RC} ] && echo "$(file_rc_str)" > ${BLADE_RC}
		__print $dline
		cat $BLADE_RC
		__print $dline
	}



	function file_rc_str(){
		local size
		size=${#__repo_list[@]};
		size=$((size-1))
		local str="$(cat <<-EOF
			#!/usr/bin/env bash
			BLADE_SRC="$BLADE_SRC"
			BLADE_JUMP="$BLADE_JUMP"
			BLADE_SIZE=$size
			if [[ "\$1" =~ "--blade-vars" ]]; then
				__group_list=(${__group_list[*]})
				__group_map=(${__group_map[*]})
				__gdir_map=(${__gdir_map[*]})
				__repo_list=(${__repo_list[*]})
				__rdir_map=(${__rdir_map[*]})
				__alias_list=(${__alias_list[*]})
				__alias_map=(${__alias_map[*]})
        __jump_name=(${__jump_name[*]})
				__semver_list=(${__semver_list[*]})
			fi
			BLADE_LOAD=1
		EOF
		)";
		echo "$str"
	}


	function reset_user_data(){
		__group_list=()
		__group_map=()
		__gdir_map=()
		__alias_map=()
		__alias_list=()
		__repo_list=()
		__rdir_map=()
    __semver_list=()
	}

	function list_deep_repos(){
		local ret i buf len this group
		buf=("${__repo_list[@]}"); len=${#buf[@]}
 		# repo group path status
		if [ $len -gt 0 ]; then
			printf "%-20.20s | %-12s | %-40s\n" "repo" "group" "rdir"
			__print $dline
			for i in ${!buf[@]}; do
				group="${__group_map[$i]}"
				group="${__group_list[$group]}"
				repo="${__repo_list[$i]}"
				rdir="${__rdir_map[$i]}"
				rdir="${rdir/$BLADE_SRC\//}"
				(( ${#repo}  > 20 )) && repo="${repo:0:17}..."
				(( ${#group} > 12 )) && group="${group:0:9}..."
				#(( ${#rdir}  > 30 )) && rdir="${rdirc:0:27}..."
				#this="${__repo_list[$i]}:$group:${__rdir_map[$i]}"
				printf "%-20.20s | %-12s | %-40s\n" "$repo" "$group" "$rdir"

			done
		fi
	}


	function jump_repos(){
		local goto i buf len this this_dir

		this_dir="${1:-$BLADE_JUMP}"

		if [ -d "$this_dir" ]; then
      sed -i.bak "s|^BLADE_JUMP\=.*$|BLADE_JUMP=\"$this_dir\"|" ${BLADE_RC}
      rm "${BLADE_RC}.bak"
      clear
      if [ -z "$opt_readonly_mode" ]; then
	      __print "\n\n\n\n$blue$dline"
	      __print "$blue${logo//#/ }$x"
	      __print "\t[$this_dir]\n" "blue"
	      cd $this_dir; ls -la
	      __print $blue$dline
	     fi
    fi
    echo "$this_dir"

	}


	function list_repos(){
		local goto i buf len this_dir group

		__buf=( $(printf "%s\n" "${__repo_list[@]}") ); len=${#__buf[@]}; goto="${1:-1}"

		if [ $len -gt 0 ]; then
			if [ $goto -eq 1 ]; then
				__selection_buffer "Select a Repo:" 1
				#printf " $__res"
				idx=$(indexof $__res "${__repo_list[@]}")
				this_dir="${__rdir_map[$idx]}"

				jump_repos "$this_dir"

			else
				for i in ${__buf[@]}; do printf "$i\n"; done
			fi
		else
			err="No Repos Found"
			return 1
		fi
	}


	do_mark_up(){

    MARKFX=$(which mark)
    if [ -x "$MARKFX" ]; then

      __buf=( $(printf "%s\n" "${__rdir_map[@]}") ); 
      len=${#__buf[@]}; 
      __print "${blue}Setting up repo bookmarks...${len} ${x}"
      __jump_name=()

      for i in ${!__buf[@]}; do

        __buf_msg="$blue${logo//#/ }\n\n"
        j=$(($i+1))

        this="${__buf[$i]}"
        pretty="${__alias_list[$i]}"
        nick="${__jump_name[$i]}" 


        #if [ -z "$nick" ]; then
        this="${this%/}"  
        __print "path -> [$this]"
        #mark --fm $this
        this_mark=$(mark --fm $this)
        __print "mark -> [$this_mark]"
        
        __print "[$this_mark] is mark -> [$pretty] [$this]"

        if [ -n "$this_mark" ]; then

          if __confirm "\r${orange}${bolt} Mark exists [$this_mark] for [$pretty], change? (y/n/q) "; then
            __print "$this_mark is found!"
            $(mark --rm "$this_mark")
          else
            continue
            #err=$?
          fi

        fi
        if __confirm "\r${blue}${bolt} ${green}Add${blue} a jumpname for [$pretty]? (y/n/q) "; then
          nick=$(__prompt "${blue}Enter a jumpname${yellow}..." "$pretty")
          __jump_name+=("$nick")
          #sed -i.bak "s|^__jump_name\[$i\]\=.*$|__jump_name\[$i\]\=\"$nick\"|" ${BLADE_RC}
          #rm "${BLADE_RC}.bak"
          $(cd $this;mark --add $nick)
        else
          __jump_name+=("none")
        fi


        __print "${grey} ${j} ${pretty} -> ${nick} ${x}"
      done
      #save_rc_file

    fi
  }


	sweep_info(){

    local len this name SEMVER fwd chg vers __buf force=${1:-1}

    __buf=( $(printf "%s\n" "${__rdir_map[@]}") ); 
    len=${#__buf[@]}; 
    SEMVER=$(which semv)

    if [ -x "$SEMVER" ]; then

      __buf_msg="$blue${logo//#/ }\n\n"
      
      printf "$__buf_msg"
      printf "%-5s | %-20s | %-5s | %12s | %12s \n" "idx" "name" "stat" "vers" "fwd" 
      printf "$dline\n${x}"

      __ttl=0
      __chg=()

      for i in ${!__buf[@]}; do
        ret=
        this="${__buf[$i]}"
        name="${__alias_list[$i]}"
        j=$(($i+1))

        cd $this;
        if [ $? -eq 0 ]; then

          fwd="$(semv auto $this 'fwd')" #TODO: more granular version bumps
          chg="$(semv auto $this 'st')"
          vers="$(semv auto $this)"
          vers_o="${__semver_list[$i]}"

          __commits+=( $this ) #  needs a commit

          if [ $chg -gt 0 ]; then
	          __ttl=$(($__ttl + $chg))
	          __chg+=($this)
	          __keep_index+=($i) # reusing keep index buffer
	        fi

          [ $chg -gt 0 ] && { _nc="${blue}${spark}${x}"; _sc="${orange}";  } || { _nc=" ";_sc="${grey}";chg='.'; }
          [ -z "$vers" ] && { _vc="${grey}"; vers="missing"; } || _vc="";
          [ -z "$fwd"  ] && {  _fc="${grey}"; fwd="none";    } || _fc="${green}";

          printf "%-5s | %-20s${_nc} | ${_sc}%-5s${x} | ${_vc}%12s${x} | ${_fc}%12s${x} \n" "${j}" "${name}" "${chg}" "${vers}" "${fwd}" 
        fi



      done
      printf "$blue$dline\n${x}"
    else
      __print "${red} Sadly no semver.${x}"
    fi

    if [ $__ttl -gt 0 ]; then

    	# Save the cursor position
			


    	if [ $force -eq 0 ]; then 
		    if __confirm "\rThere are ${orange}${__ttl}${x} changes. Do you want to sweep commit on curr branch? (y/n/q) "; then
		        
	        if __confirm "One commit message for all? (y/n/q)"; then
	        	msg=$(__prompt "${blue}Enter a commit message${yellow}..." "woop")
	        fi
		      
		    	for i in ${!__keep_index[@]}; do
		    		clear

		        this="${__keep_index[$i]}"
		        name="${__alias_list[$this]}"
		        repo="${__buf[$this]}"

		        cd $repo
		        branch=$(git rev-parse --abbrev-ref HEAD)

		        if [ -n "$branch" ]; then

			        __print "\r${blue}${bolt} Checking [$name]--> ${repo} ${x}"
			        
			        git status
			        __print "$blue$dline\n${x}"


			        if [ -z "$msg" ]; then
			        	note=$(__prompt "${blue}Enter a commit message${yellow}..." "woop")
			        fi
			        printf "$x"
			        note=${msg:-$note}
			        git add . --all
			        git commit -m "$note :sweep:"
			        git push origin "${branch}"

			        semv
			      else

			      	__print "${red}Error finding repo branch.${x}"
			      fi


		    	done

		    	
		    fi
		  else
		  	__print "${blue}There are ${spark} ${orange}${__ttl}${x}${blue} changes.${x}"
		  fi


	  fi
    #note=$(__prompt "${blue}Add a note for the tag${yellow}" "auto tag bump")
		# url
		# user
		# service
		# branch
		# status
	}



	# function __dump(){
	# 	local len arr i this flag newl
	# 	arr=("${@}"); len=${#arr[@]}
	# 	[ $__buf_list -eq 0 ] && flag="\r" &&  newl="$eol" || newl="\n"
	# 	if [ $len -gt 0 ]; then
	# 		handle_input
	# 		for i in ${!arr[@]}; do
	# 			this="${arr[$i]}"
	# 			[ -n "$this" ] && printf "$flag$orange$dots(%02d of %02d) $this $x$newl" "$i" "$len"
	# 			sleep 0.1
	# 		done
	# 		cleanup
	# 		printf "$flag$green$pass (%02d of %02d) Read. $x$eol\n" "$len" "$len"
	# 	fi
	# }




	function load_rc_file(){
		[ ! -f $BLADE_RC ] && err="Missing BLADE_RC file" && return 1;
		source $BLADE_RC --blade-vars
	}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
  function __dispatch(){
    #log_debug "[fx:$FUNCNAME] args:$#"
    local call ret

    call=$1; shift

		case $call in
			ls)  list_repos 0; ret=$?;;
			go)  list_repos 1; ret=$?;;
			jump) jump_repos $BLADE_JUMP; ret=$?;;
      sweep) sweep_info; ret=$?;;
			fix) sweep_info 0; ret=$?;;
			rc)  cat $BLADE_RC; ret=$?;;
			find) find_repos; ret=$?;;
      clean) do_clean; ret=$?;;
      mu) do_mark_up; ret=$?;;
			setup)
        clear
				if __confirm "\n\n\n\n[ ${green}BLADERC LOADED${x} ] Do you want to run autosetup (y/n/q) > "; then
					reset_user_data
					sleep 0.5
					auto_setup
				fi
				;;
			*) ret=1;;
		esac

    return $ret
  }



	function main(){
		load_rc_file
		if [ -z "$BLADE_LOAD" ]; then
			__print "Missing BLADE_RC, trying to install $BLADE_LOAD"
			sleep 1
			auto_setup
		else
			cd $BLADE_SRC
			__dispatch "$@"
		fi
	}

#TODO: list_deep_repos ??

#-------------------------------------------------------------------------------
# Driver
#-------------------------------------------------------------------------------

  #read only handshake means function agrees to consume output to change the PWD
  if [[ "${@}" =~ "--read-only" ]]; then
    opt_readonly_mode=0
    shift;
  fi



  #running in subshell
  if [[ "$0" != "-bash" ]]; then
    if [ -n "$opt_readonly_mode" ]; then
      main "$@";ret=$?
    else
      if [ $CPID -ne $PPID ]; then
      	#__print "$BASH_SOURCE curr($$) caller($PPID) origin($SPID)" "yellow"
        #__print "${delta}Warning. BLADEX(1) cannot be called from subshell without --exec flag set." "red"
        :
      fi
      main "$@";ret=$?
    fi
  else
    main "$@";ret=$?
  fi
