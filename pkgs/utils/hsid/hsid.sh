#!/usr/bin/env bash
#===============================================================================
#-------------------------------------------------------------------------------
#$ name:x-hsid
#$ autobuild: 00003
#$ author:qodeninja
# TODO: md5sum needs OSX compat
# TODO: try to use global GLYPHS[n]
# TODO: simplify - bunch of fx not needed here
# TODO: split up generator functions
# TODO: make HSID file harder to delete (deleting may cause issues)
# TODO: change HSID to note how it was generated (by)
# TODO: consider util to change machine-id for vms (/bin/systemd-machine-id-setup)
# TODO: introduce friendly machine name
# NOTE: also /var/lib/dbus/machine-id also in Debian ( dbus-uuidgen --ensure=/etc/machine-id )
# NOTE: changing machine-id may require immediate reboot
# NOTE: alternative: uuidgen -or- mktemp -u XXXXXXXXXXXXXXXX
# UPDATE: md5cmd and uuidgen for MACOSX support
# UPDATE: add OSX support ioreg call
# TODO: enable random mode independent of type
#-------------------------------------------------------------------------------
# CONFIG PARAMS
#-------------------------------------------------------------------------------

#----------------------------------------------------
# VARS
#----------------------------------------------------

	args=("${@}");readonly T=0 F=1;

	red=$(tput setaf 202)
	green=$(tput setaf 2)
	blue=$(tput setaf 12)
	orange=$(tput setaf 214)
	grey=$(tput setaf 247)
	x=$(tput sgr0)

	delta="\xE2\x96\xB3";
	pass="\xE2\x9C\x93";
	fail="\xE2\x9C\x97";
	lambda="\xCE\xBB";
	tab=$'\t'
	nl=$'\n'
	sp="  "

	opt_quiet=1;
	opt_debug=1;
	opt_dev=1;
	opt_reset=1;

#----------------------------------------------------
# KEY VARS
#----------------------------------------------------

	HSID_FILE="$HOME/.handshake-id"
	HSID=""

	DEV_UUID_FILE="$HOME/.dev-uuid"
	UUID=""

	md5cmd="$(which md5sum || which md5)" #OSX compat

#-------------------------------------------------------------------------------
#  TERM UTILS
#-------------------------------------------------------------------------------

	stderr(){
		[ $opt_quiet -eq 1 ] && printf "${@}${x}\n" 1>&2;
	}

	__printf(){
		local text color prefix
		text=${1:-}; color=${2:-white2}; prefix=${!3:-};
		[ $opt_quiet -eq 1 ] && [ -n "$text" ] && printf "${prefix}${!color}%b${x}" "${text}" 1>&2 || :
	}

	function pass(){ local text=${1:-}; __printf "$pass $text\n" "green"; }
	function error(){ local text=${1:-}; __printf "$fail $text\n" "red"; }
	function warn(){ local text=${1:-}; __printf "$delta $text$x\n" "orange";  }
	function info(){ local text=${1:-}; [ $opt_debug -eq 0 ] && __printf "$lambda$text\n" "blue"; }
	function ninfo(){ local text=${1:-}; [ $opt_debug -eq 0 ] && __printf "$lambda$text\n" "orange"; }
	function die(){ __printf "$red$fail $1$x$nl"; exit 1; }

	function quiet(){ [ -t 1 ] && opt_quiet=${1:-1} || opt_quiet=1; }



	confirm(){
		local answer src ret default=${2:-0};ret=1
		__printf "(?) ${1}? > " "white2" #:-Are you sure ?
		#[ $opt_yes -eq 0 -a $default -eq 1 ] && __printf "${bld}${red}auto no${x}\n" && return 1;
		#[ $opt_yes -eq 0 ] && __printf "${bld}${green}auto yes${x}\n" && return 0;

		[[ -f ${BASH_SOURCE} ]] && src='/dev/stdin' || src='/dev/tty' #how does this work for pipe

		while read -r -n 1 -s answer < $src; do
			[ $? -eq 1 ] && exit 1;
			if [[ $answer = [YyNn10tf+\-q] ]]; then
				[[ $answer = [Yyt1+] ]] && __printf "${bld}${green}yes${x}" && ret=0 || :
				[[ $answer = [Nnf0\-] ]] && __printf "${bld}${red}no${x}" && ret=1 || :
				[[ $answer = [q] ]] && __printf "\n" && exit 1 || :
				break
			fi
		done
		__printf "\n"
		return $ret
	}


	prompt(){
		local res ret next __VALUE prompt="$1" default="$2"
		#[ $opt_yes -eq 0 -a ! -n "$default" ] && die "Missing default value specified for auto-yes prompt";
		#[ $opt_yes -eq 0 ] && __printf "${bld}${green}auto default:[${default}]${x}\n" && echo "$default" && return 0;
		[[ -f ${BASH_SOURCE} ]] && src='/dev/stdin' || src='/dev/tty' #how does this work for pipe
		while [[ -z "$next" ]]; do
			read -p "${x}(?) $prompt? > ${bld}${green}" __VALUE;
			next=1
			printf "$x"
		done
		[ -n "$default" -a ! -n "$__VALUE" ] && __VALUE="$default";
		echo $__VALUE
	}

#-------------------------------------------------------------------------------
#  FX Utils
#-------------------------------------------------------------------------------

	fx_can_sudo(){
		local ret prompt=$(sudo -nv 2>&1);ret=$?
    if [ $ret -eq 0 ]; then
   	 	echo "has_sudo_ready"
    elif echo $prompt | grep -q '^sudo:'; then
    	echo "has_sudo_needs_pass"
    	ret=0;
    else
    	echo "no_sudo"
    fi
    return $ret;
	}


	fx_normalize_uuid(){
		echo $(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d - );
	}

#-------------------------------------------------------------------------------
#  API
#-------------------------------------------------------------------------------
	usage(){
		local count data b=$blue g=$green o=$orange w=$grey hsid="$(api_get_id)"
		data+=""
		data="$(cat <<-EOF
			\n\t${b}hsid --option${x}

			\t${o}FILE: $HSID_FILE${x}
			\t${o}HSID: $hsid${x}

			\t${w}Edit:${x}

			\t  -l --ls   <?n>    ${b}List hsid value to stdout${x}

			\t  -R --reset        ${b}Reset HSID files ${x}
			\t  -D --dev          ${b}Use Dev Mode logic${x}
			\t  -V --verbose      ${b}Print extra status info${x}

			\t${w}Meta:${x}

			\t? -h --help

		EOF
		)";
		printf "$data";
		return 0;
	}

	api_get_id(){
		[ -f "$HSID_FILE" ] && cat "$HSID_FILE";
	}

	api_set_id(){
		local by doc this_id hashed_id;

		if [ -f "$HSID_FILE" -a $opt_reset -eq 1 ]; then
			info "HSID already generated. Skipping...";
			stderr "${green}$(api_get_id)$x";
			return $T;
		fi

		if [ ! -f "/etc/machine-id" -o $opt_dev -eq 0 ]; then

			if [[ "$OSTYPE" == "darwin"* ]]; then

				this_id=$(ioreg -rd1 -c IOPlatformExpertDevice | grep IOPlatformUUID); ret=$?;
				if [ $ret -eq 0 ]; then
					UUID=$(fx_normalize_uuid "$this_id")
					by="ios_reg"
				else
					die "Cannot find UUID from ios_reg."
				fi

			elif fx_can_sudo 2>&1 >/dev/null; then
				doc="$(cat <<-EOF
					WARNING: ${nl}${line}${sp}A persistent UUID is required but the /etc/machine-id entry was not found (or was ignored).
					${sp}Alternative methods of finding a UUI require temporary sudo access.
					${line}${x}
				EOF
				)";
				warn "$doc"
				if confirm "Try to find another UUID with sudo (y/n)" 1; then
					this_id=$(sudo cat /sys/class/dmi/id/product_uuid)
					UUID=$(fx_normalize_uuid "$this_id")
					by="product_id"
					#info $this_id;
				else
					ninfo "Skipped UUID discovery";
				fi
			else
				die "User ($USER) does not have sufficient sudo access to request system UUID info."
			fi

		else
			by="machine_id"
			UUID=$(cat "/etc/machine-id")
		fi

		[ ! -n "$UUID" -a $opt_dev -eq 0 ] && this_id=$(prompt "Enter a 32-bit UUID or <enter> for random" "R");

		if [[ "$this_id" =~ "R" ]]; then
			this_id=$(cat /proc/sys/kernel/random/uuid);
			[ -z "$this_id" ] && this_id=$(/usr/bin/uuidgen) #OSX compat
			UUID=$(fx_normalize_uuid "$this_id");
			by="random_id"
			info "Saving random UUID dev-uuid";
			touch "$DEV_UUID_FILE"
			echo "$UUID" > "$DEV_UUID_FILE";
		fi

		[ ! -n "$UUID" ] && die "Persistent UUID required; Try <hsid> again with --R flag or set UUID in env";
		[ ${#UUID} -lt 32 ] && die "Invalid DEVICE_ID ($UUID)";
		#[ -t 1 ] && clear;

		HSID=$(echo "$UUID$USER" | $md5cmd | cut -d ' ' -f 1 )
		touch "$HSID_FILE"
		echo "$HSID" > "$HSID_FILE";
		pass "Found (by:$by) UUID: $UUID. HSID:$HSID"

		return $T;
	}

#-------------------------------------------------------------------------------


	dispatch(){
    local call="$1" arg= cmd_str= ret;
    call="$1";
    #[ $# -gt 3 ] && err="Too many arguments." && return 1;

    for i; do
			case "$i" in
				--help|-h|\?) cmd="usage";;
				--rm|-r)    cmd="api_rm_id";;
				--ls|-l)    cmd="api_get_id";;
				--quiet|-q) opt_quiet=$T;;
				--verb*|-V) opt_debug=$T;;
				--dev|-D)   opt_dev=$T;;
				--reset|-R) opt_reset=$T;;
				-*) 				err="Invalid flag [$i].";;
			esac
		done

		[ ${#cmd} -eq 0 ] && cmd="api_set_id";

		cmd_str+="$cmd";
		[ $opt_dev -eq 0 ] && stderr "fx=> $cmd_str ($call q:$opt_quiet V:$opt_debug D:$opt_dev R:$opt_reset) ";

		[ -n "$err" ] && return 1;
		$cmd_str;ret=$?;
		return $ret;
	}

	main(){
		local ret;
		dispatch "$@";ret=$?
		[ -n "$err" ] && stderr "${red}$err" || stderr "$out";
		unset out err edit;
		return $ret
	}

#-------------------------------------------------------------------------------

	main "$@";

#===============================================================================
