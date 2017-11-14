#!/usr/bin/env bash
#set -x
# shellcheck disable=1090,1091
#set -u #o pipefail							# unofficial bash strict mode
#IFS=$'\n\t'

# -----------------------------------------------------------------------------
# I've used a frightening & bewildering variety of *nix distros since the early
# 1980s. One thing all of them had in common was this "run-commands" file; it's
# that important to have machine-specific resources and commands configured and
# aliased appropriately. Rather than have 40 different versions ~ yes, really:
# there was BSD, System V, Sun OS, Solaris, GNU, AIX, Linux, and Darwin (macOS);
# on PDP-8|10, MIPS, ARM, MC68000, SPARC; from Sun, H-P, Apple ~ crafting one
# file to be synced to all my working computers was integral to keeping me sane.
#
# Originally this only tested for hostname. Because I worked on many a *nix farm
# I added machine architecture (chipset) and operating system testing, avoiding
# the need to specify each hostname I moved to. DNS (network identification) was
# next, to switch between home and various client set-ups.
#
# Once computing became portable & mobile, I had to add tests to check for WiFi,
# and finally location by time-of-day, in case all else failed.
#
# TO-DO: see if I can detect a VPN connection.
#
# +-------------------+-------------------------------------------------------+
# |     FUNCTION      | Customises your computer's environment based upon:    |
# +-------------------+-------------------------------------------------------+
# | doLocByDNS()      | DNS name ~ our_computer.your_cable_company.com        |
# | doLocByWifi()     | Wi-Fi name ~ "My Home Network"                        |
# | doLocByDateTime() | time of day, weekday or weekend                       |
# | doArchSpecifics() | machine chipset architecture ~ x86, arm               |
# | doOsSpecifics()   | operating system ~ darwin (macOS), linux, windows     |
# | doHostThings()    | hostname ~ "My MacBook Pro"                           |
# +-------------------+-------------------------------------------------------+
#
# Additionally, this script runs:
#
# +-------------------+-------------------------------------------------------+
# | setTermColors()   | use color terminal capabilities                       |
# | setTermPrompt()   | sets the terminal prompt                              |
# +-------------------+-------------------------------------------------------+
#
# Then, at the bottom, is a section with all the "universal" customizations,
# including a long list of command aliases, grouped by software package. These
# make working at the command-line much faster and easier.
#
# Lastly, tweaks to the command search path are done.
#
# I'll explain the configuration options in each of the sections below. Feel
# free to use this as a jumping-off point in tweaking your own *nix machines.
#
# Find me at ~ https://github.com/mickeys/dotfiles/blob/master/.bash_profile
# -----------------------------------------------------------------------------
# QA NOTE: if $BASH_VERSION < v4 parts of this script will silently not execute.
# This is a feature, not a bug. Update your bash to a modern one. This has been
# tested mostly on macOS 10.12 (Sierra), with side-trips to several Linuxes.
# UPDATE: Things were breaking badly, so now >= 4 now required. Progress :-/
# -----------------------------------------------------------------------------
if ((BASH_VERSINFO[0] < 4)); then echo "Error: bash 4.0 or later needed; quitting." >&2; exit 1; fi

PROFILING=0									# TO-DO: document profiling
if (( PROFILING )) ; then					#
#	PS4='+\t '
#	PS4='$(date "+%s.%N ($LINENO) + ")'
#	PS4='$(date "+%3N ($LINENO) + ")'		# 6N=microseconds
	PS4='$(date "+_%S_%6N_ ($LINENO) + ")'	# secs & 9=nano, 6=milli, 3=micro
	exec 3>&2 2>"${HOME}/bashstart.$$.log"	#
	set -xT									#
else
	PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
fi

# -----------------------------------------------------------------------------
# If $TEST_YOKE is *anything*, meaning we're being called by a test yoke, then
# we honor the environment variables set for us. Otherwise set defaults for this
# script's behavior.
# -----------------------------------------------------------------------------
if [[ ! $TEST_YOKE ]] ; then				# we being invoked from outside?
	DEBUG='' # 'YES'						# default: no debugging output
	RUN_TESTS='' # 'YES'					# default: production, not QA tests
	declare -g SILENT='YES' # ''			# default: silent running
#else
	# anything to be done before being run from an outside test yoke
	# echo "$(basename -- "$0")[${LINENO}]: DEBUG \"$DEBUG\" RUN_TESTS \"$RUN_TESTS\" SILENT ${#SILENT} TEST_YOKE \"$TEST_YOKE\""
fi

# if $SILENT is non-null, then give it a string that'll silence output
if [[ $SILENT ]] ; then SILENT='>& /dev/null'	; fi # overloading

# -----------------------------------------------------------------------------
# Constants:
# -----------------------------------------------------------------------------
SUCCESS=0									# standard *nix return code
FAILURE=1									# standard *nix return code
isNumber='^[0-9]+$'							# regexp ~ [[ $var =~ $isNumber ]]
# shellcheck disable=SC2034
myDomain=''									# initialize empty before use
mon=0										# $(date +'%u') returns [0..7]
fri=5										# $(date +'%u') returns [0..7]
sat=6										# $(date +'%u') returns [0..7]
sun=7										# $(date +'%u') returns [0..7]
# -----------------------------------------------------------------------------
#set -o xtrace								# debugging stuff
#set -o nounset								# debugging stuff

# -----------------------------------------------------------------------------
# General settings
#
# Location calculations continue until a method succeeds, so order your choices
# in tryLocationMethods from most (DNS & WIFI) to least accurate (DATE).
# -----------------------------------------------------------------------------
tryLocationMethods=( DNS WIFI DATE )		# choose from DNS WIFI DATE
where=''									# final answer stored here
skipCheckOnThese=( 'my_office.apple.com' )	# skip any self-evident location(s)
dayStarts=9									# time of day 0..23 ~ work starts
dayEnds=17									# time of day 0..23 ~ work ends

# -----------------------------------------------------------------------------
# How do we, in your *nix, find the Wi-Fi network to which we're connected?
# -----------------------------------------------------------------------------
os=${OSTYPE//[0-9.]/}						# get text part of the OS name and
os=${os,,}									# lowercase normalize it then
case "$os" in								# do OS-appropriate things
	# ---------------------------------------------------------------------
	darwin)									# Mac OS X

		AIRPORT='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
		WIFI=$( $AIRPORT -I | grep "\bSSID" | sed -e 's/^.*SSID: //' )
		alias lcd='for f in *; do mv "$f" "$f.tmp"; mv "$f.tmp" "`echo $f | tr "[:upper:]" "[:lower:]"`"; done'
		;; # end darwin
	# ---------------------------------------------------------------------
	linux)
		;; # end linux

	# ---------------------------------------------------------------------
	linux-gnu)								# Fedora
		;; # end linux-gnu

	# ---------------------------------------------------------------------
	*) echo "NOTE: Unknown operating system \"os\", can't find Wi-Fi!"
	;;
esac

# -----------------------------------------------------------------------------
# DNS settings ~ used if specified in tryLocationMethods() above
# -----------------------------------------------------------------------------
# shellcheck disable=SC2034
declare -A myDNSs=(							# (needs BASH_VERSION >= 4)
	[comcastbusiness.net]=work				# compound assignment
	[credenceid.com]=work					# left-hand side must be unique
	[comcast.net]=home
	[shaw.net]=home
)

# -----------------------------------------------------------------------------
# Wi-Fi settings ~ used if specified in tryLocationMethods() above
# -----------------------------------------------------------------------------
# shellcheck disable=SC2034
declare -A myWifis=(						# (needs BASH_VERSION >= 4)
	[Apple]=work							# compound assignment
	[Squirrel]=work							# left-hand side must be unique
	[Credence Air]=work
	[bbhome]=home
	[Winter Home]=home
)

# -----------------------------------------------------------------------------
# Housekeeping helper functions ~ miscellaneous necessary stuff
# -----------------------------------------------------------------------------
# remove duplicate $PATH entries
# -----------------------------------------------------------------------------
cleanPath() {
	if [ -n "$PATH" ]; then					# if the system PATH exists
	  oldPath=$PATH:; newPath=				# make a copy & new working space
	  while [ -n "$oldPath" ]; do			# while there's still something left
		x=${oldPath%%:*}					# get the first remaining entry
		case $newPath: in
		  *:"$x":*) ;;						# already there, do nothing
		  *) newPath=$newPath:$x;;    		# not there yet; add
		esac
		oldPath=${oldPath#*:}
	  done
	  PATH=${newPath#:}						# set system PATH to uniq'd version
	  unset oldPath newPath x				# clean up after ourselves
	fi
}

# -----------------------------------------------------------------------------
# if $debug show calling function and error message
# -----------------------------------------------------------------------------
debug() { if  [[ $DEBUG ]] ; then echo "${FUNCNAME[1]}(${LINENO}): $1" ; fi }

# -----------------------------------------------------------------------------
# pad out $1 with $2 number of digits (for XXX of YYY: ...). This is magic.
# -----------------------------------------------------------------------------
function pad {
	local n=$1 ; local w=$2 ; local s=$3
	expo=$((10 ** w))
	[ "$n" -gt "$expo" ] && { echo "$n"; return; }
	fmt=$(( n + expo ))
	echo "$s" ${fmt:1}
}

# -----------------------------------------------------------------------------
# All machines would have a FQDN (fully-qualified domain name) set in a perfect
# world. Sadly, many companies / locations / even operating systems don't. This
# function assembles an array of domainnames with all the techniques we know.
# -----------------------------------------------------------------------------
declare -a d=()								# array to hold domainnames we get

getDomainnames() {
	if [[ ${BASH_VERSINFO[0]} -lt 4 ]] ; then return ; fi

	# -------------------------------------------------------------------------
	# Method 1: take last two items from $HOSTNAME
	# -------------------------------------------------------------------------
	if [ -n "$HOSTNAME" ] ; then
		d[${#d[@]}]=$( echo "$HOSTNAME" | rev | cut -d. -f1,2 | rev )
	fi

	# -------------------------------------------------------------------------
	# Method 2: get domain from your ISP
	# -------------------------------------------------------------------------
	vpn=$( netstat -rn | grep utun1 | wc -l ) # check for any tunnels in action
	if [[ $vpn -eq 0 ]] ; then
		target='www.google.com'				# the machine we're trying to ping
		lookup='o-o.myaddr.l.google.com'
		dns='8.8.8.8'						# the DNS nameserver being used
	else									# Ah, the Great Firewall of China
		target='baidu.com'
		lookup='baidu.com'
		dns='61.139.2.69'					# DNS for Chengdu, Sichuan, China
	fi

	debug "nc -z -w 1 $target 80"
	if eval nc -z -w 1 "$target" 80 "$SILENT" ; then # only if network is up
		debug "the network is up, continuing..."

		#external_ip="$( dig +short myip.opendns.com @resolver1.opendns.com )"
		debug "host -t txt $lookup $dns"
		external_ip=$( host -t txt "$target" "$dns" | grep -oP "client-subnet \K(\d{1,3}\.){3}\d{1,3}" )
		if [[ ${#external_ip} -eq 0 ]] ; then
			debug "external_ip is empty, giving up..."
		else
			debug "external_ip is \"$external_ip\""
			# --> like 1.2.3.4
			fqdn=$( host "$external_ip" )
			debug "fqdn is $fqdn"
			# --> 1.2.3.4.in-addr.arpa domain name pointer c-73.hsd1.ca.comcast.net.
			fqdn=${fqdn:0:${#fqdn}-1}			# strip dot from end
			# --> 1.2.3.4.in-addr.arpa domain name pointer c-73.hsd1.ca.comcast.net
			d[${#d[@]}]=$(echo "$fqdn" | rev | cut -d. -f1,2 | rev)
			# --> comcast.net
		fi
	else
		debug "network is down, giving up..."
	fi
	# shellcheck disable=SC2128
	debug "fqdn parsing results in \"$d[${#d[@]}]\""
}

# -----------------------------------------------------------------------------
# location by the DNS services name
# -----------------------------------------------------------------------------
doLocByDNS() {
	if [[ ${BASH_VERSINFO[0]} -lt 4 ]] ; then return ; fi
	if [[ ! $DEBUG ]] && [ -z "$where" ] ; then return ; fi	# if already set, punt
	# $2 must be an associatve array
	if ( ! (( ${#2} )) && [[ "$(declare -p $2)" =~ "declare -a" ]] ) ; then return $FAILURE ; fi
	# process arguments passed into the function
# TO-DO: figure out how to properly deal with error SC2125 below; it bugs me
# shellcheck disable=SC2125
	local domainArrayReference=$1[@]
	local domainArray=("${!domainArrayReference}")
	declare -n dnss=$2						# how one passes associative arrays

	# sanity-check inputs before moving on
	if [ "${#dnss[@]}" -eq 0 ] || [ "${#domainArray[@]}" -eq 0 ] ; then return $FAILURE ; fi

	for i in "${!dnss[@]}"; do				# iterate over the array of DNSs
		for j in "${domainArray[@]}" ; do	# iterate over domainnames found
			if [[ "$i" == "$j"* ]]; then	# if there's a match
				where="$i"					# remember the associated location
				return "$SUCCESS"
			fi
		done
	done
	return "$FAILURE"
} # end of doLocByDNS

# -----------------------------------------------------------------------------
# use airport command to get Access Point name
# -----------------------------------------------------------------------------
doLocByWifi() {
	if [[ ${BASH_VERSINFO[0]} -lt 4 ]] ; then return ; fi
	if [[ ! $DEBUG ]] && [ -z "$where" ] ; then return ; fi	# if set, punt

	# $2 must be an associatve array
	if ( ! (( ${#2} )) && [[ "$(declare -p $2)" =~ "declare -a" ]] ) ; then return ; fi

	# process arguments passed into the function
	local active="$1"						# active Wi-Fi name, passed in
	declare -n wifis=$2						# how one passes associative arrays

	# sanity-check inputs before moving on
	if [ -z "$active" ] ; then return $FAILURE ; fi

	for i in "${!wifis[@]}"; do				# iterate over the array of wifis
		if [ "$i" == "$active" ] ; then		# if we found a match
			where="${wifis[$i]}"			# remember the associated location
			debug "$where"					# report back
			return							# match found; stop working
		fi
	done
} # end of doLocByWifi

# -----------------------------------------------------------------------------
# guessing location by time-of-day (at work during daytime)
# -----------------------------------------------------------------------------
doLocByDateTime() {
	if [[ ! "$DEBUG" ]] && [ -z "$where" ] ; then return ; fi	# leave if set

	# process arguments passed into the function
	hour=$1									# 00..24 hour of day
	hour=${hour#0}							# strip leading zero, if present
	day=$2									# 0..7 day of week

	local returnCode="$SUCCESS"				# all get a medal unless noted...

	# sanity-check inputs before moving on
	if  [[ $hour =~ $isNumber ]] &&
		( ! ( (( hour >= 0 )) && (( hour <= 24 )) ) ) ;
	then
		returnCode="$FAILURE"				# this is a fail
	# -------------------------------------------------------------------------
	elif (( ( day >= mon && day <= fri ) &&
		( hour >= dayStarts && hour <= dayEnds ) )) ;
	then
		debug "work (daytime weekday)"		# tell the debugging human
		where='work'						# remember the location
		echo "HI HERE WORK"
	# -------------------------------------------------------------------------
	elif (( ( day >= mon && day <= fri ) &&
		( hour < dayStarts || hour > dayEnds ) )) ;
	then
		debug "home (weekday outside of working hours)"	# tell
		where='home'						# remember the location
	# -------------------------------------------------------------------------
	elif (( day == sat || day == sun ))
	then
		debug "home (weekend)"				# tell the debugging human
		where='home'						# remember the location
	# -------------------------------------------------------------------------
	else
		debug "someplace unknown"			# no idea where we are
		returnCode="$FAILURE"				# this is a fail
	fi

	return "$returnCode"
} # end of doLocByDateTime

# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸,
# Test the major functions with a variety of inputs
# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸,

# shellcheck disable=SC2034
t=(	[0]=pass [1]=fail )						# array pairs codes to readable text
# if what you expected == what actually happened, be happy
passFail() { if (( $1 == $2 )) ; then echo -n "success" ; else echo -n "failure" ; fi }

# -----------------------------------------------------------------------------
# Every function to test (with arguments) and the expected result.
# -----------------------------------------------------------------------------
# shellcheck disable=SC2016,SC2034
declare -A allTheTests=(					# (needs BASH_VERSION >= 4)

	# -----|  doLocByDateTime  |-----------------------------------------------
	['doLocByDateTime 11 5']="$SUCCESS"
	['doLocByDateTime 25 8']="$FAILURE"
	['doLocByDateTime "dog" 8']="$FAILURE"

	# -----|  doLocByDNS  |----------------------------------------------------
	['doLocByDNS d myDNSs']="$SUCCESS"
	['doLocByDNS "" ""']="$FAILURE"

	# -----|  doLocByWifi  |---------------------------------------------------
	['doLocByWifi "$WIFI" myWifis']="$SUCCESS"
	['doLocByWifi "" myWifis']="$FAILURE"

	# -----|  miscellaneous  |-------------------------------------------------
	['doArchSpecifics']="$SUCCESS"
	['doOsSpecifics']="$SUCCESS"
	['doHostThings']="$SUCCESS"
)

# -----------------------------------------------------------------------------
# Run over the array of tests, report return codes.
# -----------------------------------------------------------------------------
doAllTheTests() {
	if [[ ${BASH_VERSINFO[0]} -lt 4 ]] ; then return ; fi
	# sanity-check inputs before moving on
	if ( ! (( ${#1} )) && [[ "$(declare -p $2)" =~ "declare -a" ]] ) ; then return ; fi

	declare -n tests=$1						# how one passes associative arrays

	# ----- iterate over array of tests ---------------------------------------
# shellcheck disable=SC2034
	__i__=1									# just a simple counter
# shellcheck disable=SC2034
	__l__=${#tests[@]}						# total number of tests
	for c in "${!tests[@]}" ; do			# iterate over the array of tests
		# run test
		eval "$c $SILENT"					# evaluate the test command line
#		r=$?								# save the test return value

		# generate output
#xyzzy		pad "$__i__" "${#__l__}" -n		# output number of this test
#		i="((__i__++))						# on to next in the array
#		echo -n "/$__l__ ~ "				# output total number of tests
#		passFail "$r" "${tests[$c]}"		# output human-readable pass or fail
		echo " ~ $c"						# output the test command line
     done
}

# -----------------------------------------------------------------------------
# Iterate over the methods chosen above & try to figure our location with them.
# -----------------------------------------------------------------------------
determineLocation() {
	for method in "${tryLocationMethods[@]}"
	do
		case "$method" in
			DNS) doLocByDNS d myDNSs ;;
			WIFI) doLocByWifi "$WIFI" myWifis ;;
			DATE) doLocByDateTime "$(date +'%H')" "$(date +'%u')" ;;
			*) echo "WARNING! Unknown determination method \"$fqdn\"." ;;
		esac
	done
	# TO-DO: echo "where \"$where\" -- make a doHomeStuff(), doWorkStuff() ??"
} # end determineLocation

# -----------------------------------------------------------------------------
# Do location-specific things if machine not on exclusion list.
# -----------------------------------------------------------------------------
determineLocationIfNotExcluded() {
	debug "hostname \"$HOSTNAME\""
	determineLocation=true					# default is to do check
	for fqdn in "${skipCheckOnThese[@]}"	# iterate over hostnames
	do
		if [[ "$HOSTNAME" =~ $fqdn ]]; then	# if this hostname found then
			determineLocation=false			# turn off location check
		fi
	done

	if $determineLocation ; then			# check hostname result
		determineLocation					# do location things
	fi
} # end determineLocationIfNotExcluded

# -----------------------------------------------------------------------------
# Do architecture-specific things.
#
# also: i386, i486, i586, i686, alpha, sparc, m68k, mips, ppc...
# -----------------------------------------------------------------------------
doArchSpecifics() {
	debug "machine architecture is \"$HOSTTYPE\", trimmed to \"${HOSTTYPE%_*}\""
	case "${HOSTTYPE%_*}" in				# get "x86" from "x86_64"
		# ---------------------------------------------------------------------
		x86)								# Macs, Intel running Linux
		;;

		# ---------------------------------------------------------------------
		arm)								# including iPhone/i$ad
		;;
	esac # end $HOSTTYPE
} # end doArchSpecifics()

# -----------------------------------------------------------------------------
# Do OS-specific things.
# -----------------------------------------------------------------------------
# shellcheck disable=2034
doOsSpecifics() {
	local os=${OSTYPE//[0-9.]/}				# get text part of the OS name and
	os=${os,,}								# lowercase normalize it then
	debug "machine operating system is \"$os\""
	case "$os" in							# do OS-appropriate things
		# ---------------------------------------------------------------------
		darwin)								# Mac OS X

			alias brewski='brew update && brew upgrade && brew cleanup; brew doctor'
			alias ftfix='sudo killall VDCAssistant ; sudo killall AppleCameraAssistant'
			alias lastmaint="ls -al /var/log/*.out"		# when did we last tidy up?
			alias ll='gls -FGlAhp'						# ls w kb, mb, gb
 			alias ls='gls -F --time-style=iso'			# ls special chars
			alias lock='open /System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app'
			alias maint="sudo periodic daily weekly monthly"	# tidy up :-)
			alias p='gnuplot'
			alias resizesb='sudo hdiutil resize -size '	# 6g BUNDLENAME'
			alias swap='swaps ; sudo dynamic_pager -L 1073741824 ; swaps' # force swap garbage collection
			alias swaps='ls -alh /var/vm/swapfile* | wc -l'	# how many swap files?
			trash() { mv "$@" ~/.Trash; }		# move to trash (vs deleting asap)
			#tw() { open -a /Applications/TextWrangler.app/ "$1" }	# my GUI editor

			# -----------------------------------------------------------------
			# Volume
			# -----------------------------------------------------------------
			alias fixvol='sudo killall -9 coreaudiod'	# when volume buttons don't

			alias min='osascript -e "set volume output volume 0"'
			alias off='osascript -e "set volume output volume 5"'
			alias max='osascript -e "set volume output volume 100"'

			# -----------------------------------------------------------------
			# Display Wi-Fi network password for one previously connected...
			# Usage: wifipass "some wifi network name"
			# -----------------------------------------------------------------
			alias wifipass="security find-generic-password -g -D \"AirPort network password\" -a"

			# -----------------------------------------------------------------
			# Display Wi-Fi signal strength
			# -----------------------------------------------------------------
			alias wifipow="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s"

			# -----------------------------------------------------------------
			# cd (pushd) to the macOS's foremost Finder window
			# -----------------------------------------------------------------
			cdf () {
				currFolderPath=$( /usr/bin/osascript <<EOT
					tell application "Finder"
						try
					set currFolder to (folder of the front window as alias)
						on error
					set currFolder to (path to desktop folder as alias)
						end try
						POSIX path of currFolder
					end tell
EOT
				)
				pushd "$currFolderPath"		# use 'cd' if it makes you happier
			}

			# -----------------------------------------------------------------
			# setup for flushing the macOS DNS cache
			# https://support.apple.com/en-us/HT202516
			# -----------------------------------------------------------------
			f=''
			kilmdn='sudo killall -HUP mDNSResponder'	# 10.12, 10.11, 10.10.4+
			discov='sudo discoveryutil mdnsflushcache'	# 10.10.{1-3}
			# udnsfl='sudo mdnsfutil udnsflushcaches'	# alleged 10.4 ~ undocumented
			dscache='sudo dscacheutil -flushcache'		# 10.6
			lookupd='sudo lookupd -flushcache'			# 10.5
			# mdnsfl='sudo mdnsfutil mdnsflushcache'	# alleged unknown os ver

			# -----------------------------------------------------------------
			# do things in darwin, by os version
			# -----------------------------------------------------------------
			v=$( sw_vers -productVersion )			# get version no (eg 10.10.3)
			vparts=( ${v//./ } )					# split apart into parts

			case "${vparts[0]}.${vparts[1]}" in

				10.12) # -------------------------- # Sierra
					f="$kilmdn"
					;;
				10.11) # -------------------------- # El Capitan
					f="$kilmdn"
					;;
				10.10) # -------------------------- # Yosemite
					if (( ( vparts[2] >= 1 ) && ( vparts[2] <= 3 ) )) ; then
						f="$discov"
					else
						f="$kilmdn"
					fi
					;;
				10.9) # --------------------------- # Mavericks
					;& # fall through to next clause
				10.8) # --------------------------- # Mountain Lion
					;& # fall through to next clause
				10.7) # --------------------------- # Lion
					f="$kilmdn"
					;;
				10.6) # --------------------------- # Snow Leopard
					f="$dscache"
					;;
				10.5) # --------------------------- # Leopard
					f="$lookupd"
					;;
				10.4) # --------------------------- # Tiger
					;;
				10.3) # --------------------------- # Panther
					;;
				10.2) # --------------------------- # Jaguar
					;;
				10.1) # --------------------------- # Puma
					;;
				10.0) # --------------------------- # Cheetah
					;;
				*) # ------------------------------ # Kodiak (Public Beta)
					;;
			esac

			# -----------------------------------------------------------------
			# iPhone simulator is hidden for some strange reason
			#alias simu='open /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app'

			# enable git completion
			# shellcheck source=/usr/local/opt/git/etc/bash_completion.d/git-completion.bash
			source "$( brew --prefix git )"/etc/bash_completion.d/git-completion.bash
			source "$( brew --prefix git )"/etc/bash_completion.d/git-prompt.sh
		    export BLOCKSIZE=1k				# default blocksize for ls, df, du

			;;	# end darwin
		# ---------------------------------------------------------------------
		linux)
			alias ls='ls --color --classify' # make ls colorful
> 			alias ll='ls -lh --time-style long-iso'
			today=$(date "+%Y%m%d")			# needed for logs
# shellcheck disable=SC2139
			alias ta="tail /etc/httpd/logs/${today}/error_log"
			;; # end linux

		# ---------------------------------------------------------------------
		linux-gnu)							# Fedora
			;; # end linux-gnu

		# ---------------------------------------------------------------------
		*) echo "NOTE: Unknown operating system \"os\"!"
		;;
	esac
} # end doOsSpecifics

# -----------------------------------------------------------------------------
# hostname-specific things
# -----------------------------------------------------------------------------
doHostThings() {
	# -------------------------------------------------------------------------
	case "$HOSTNAME" in						# do hostname-specific things

		# ---------------------------------------------------------------------
		michael.local)						# home machine
			# home-grown duplicate file deletion scheme ; ignore if you're not me :-)
			#alias ldups='ls | wc -l ; rm -f ../filelist ; cksum *.jpg | sort -n > ../filelist ; ../rmdups ; ls | wc -l'
			alias mdups='ls | wc -l ; rm -f ../filelist ; cksum *.jpg | sort -n > ../filelist ; rmdups ; ls | wc -l'
#
			# to use alias add hostnames and users to your ~/.ssh/config
			#alias 11="ssh u76141767@s513372989.onlinehome.us" 	# 1and1.com

		;; # end (michael.local) case
	esac; # end $HOSTNAME case

	# -------------------------------------------------------------------------
	# Do more complicated tests to customize one way for multiple machines.
	# -------------------------------------------------------------------------
	# work machine, on-line and off-line names
	if [ "$HOSTNAME" = 'michael.local' ] || [ "$HOSTNAME" = 'michael.at_work.com' ] ;
	then
                true # unused stub

		# ---------------------------------------------------------------------

	fi # end (michael.local)

	# -------------------------------------------------------------------------
} # end doHostThings

# -----------------------------------------------------------------------------
# Run (exceedingly optional) add-on scripts
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# All-*NIX do everywhere command aliasing. Works on all bash.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# less ~ the enhanced version of the 'more' page viewer
# -----------------------------------------------------------------------------
alias more='less'							# alias to use less
export LC_ALL=en_US.UTF-8					# language variable to rule them all
export LANG=en_us.UTF-8						# char set
export PAGER=less							# tell the system to use less
export LESSCHARSET='utf-8'					# was 'latin1'
export LESSOPEN='|/usr/bin/lesspipe.sh %s 2>&-' # Use if lesspipe.sh exists
#export LESS='-i -N -w  -z-4 -g -e -M -X -F -R -P%t?f%f :stdin .?pb%pb\%:?lbLine %lb:?bbByte %bb:-...'

# LESS man page colors (makes Man pages more readable).
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# -----------------------------------------------------------------------------
# *nix command history
# -----------------------------------------------------------------------------
alias h='history'							# see what happened before
HISTCONTROL=ignoredups:erasedups:ignorespace # no dups;
HISTFILE=~/.bash_eternal_history			# "eternal" ~ don't get truncated
# was eternal (empty); now set at 999 (three digits easier to grok)
HISTFILESIZE=999							# "eternal" ~ no max size
HISTSIZE=999								# "eternal" ~ no max size
HISTTIMEFORMAT="[%m-%d %H:%M] "				# add 24-hour timestamp to history
shopt -s checkwinsize						# after each command check window size...
shopt -q -s histappend >/dev/null 2>&1		# append, don't overwrite, history file
export PROMPT_COMMAND='history -a' >/dev/null 2>&1

# -----------------------------------------------------------------------------
# other environment settings
# -----------------------------------------------------------------------------
#export EDITOR=/usr/bin/vim					# graphic text editor of choice
export EDITOR=/usr/bin/vi					# graphic text editor of choice
# http://www.thegeekstuff.com/2013/12/bash-completion-complete/
# shellcheck source=/usr/local/etc/bash_completion
if [ -f "$(brew --prefix)/etc/bash_completion" ] ; then . "$(brew --prefix)/etc/bash_completion" ; fi	# hey, check out .inputrc

# -----------------------------------------------------------------------------
# generally things for all the *nix, alphabetically
# -----------------------------------------------------------------------------
alias c="clear"								# clear the terminal screen
alias ~="cd ~"                              # Go to the home directory
alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels

#alias cpbash='scp ~/.bash_profile USERNAME_OVER_THERE@hostname:'
alias ccze='ccze -A -o nolookups'			# log colorize more quickly
alias d='echo -en "\033[31;1;31m**********************************************************************************************************************\033[0m\n"'
alias dirs='dirs -v'						# show dir stack vertically
alias df='df -h'							# show human-readable sizes
alias e="exit"								# end this shell
alias grepc='grep --color=auto'				# grep shows matched in color
alias kb='bind -p | grep -F "\C"'			# see key bindings (see .inputrc)
alias kurl='curl -#O'						# download and save w orig filename
alias ll='gls -lAhF'							# ls w kb, mb, gb
alias lr='gls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | $PAGER' # lr ~ fully-recursive directory listing
alias ls='gls -FG --time-style=iso'
alias mydate='date +%Y%m%d_%H%M%S'			# more useful for sorting
alias netspeed='time curl -o /dev/null http://wwwns.akamai.com/media_resources/NOCC_CU17.jpg'
alias path='echo -e ${PATH//:/\\n}'         # show all executable Paths

# -------------------------------------------
# Test net connection to local machines...
# -------------------------------------------
alias net='nc -dzw1 google.com 80'			# most lightweight way to test net & DNS
png () { i='' ; h="$1" ; n="$2" ;
	if [[ $n && ${n-_} ]] ; then i="-i $n" ; fi ;
	c="ping -A $i $h | grep -oP 'time=\K(\d*)\.\d*'" ; # cut -d '=' -f4 ;
	echo $c
	eval $c
}
alias pch='png 61.139.2.69'					# Chengdu DNS
alias pcn='png 123.125.114.144 3'			# cn ~ baidu.com
alias pgg='png 8.8.8.8 3'					# Google DNS nameserver
alias pvt='png vantrontech.com.cn 3'

alias pd='pushd'							# see also 'popd'
alias psall='ps -afx'
alias pstop='ps -creo command,pid,%cpu | head -10'
#alias python="python3"						# p3 libs incompat with p2
alias rmempty='find . -name .DS_Store -delete ; find . -type d -empty -delete'
alias sc='shellcheck -x'					# follow paths to other scripts
alias sink='sync;sync;sync'					# write filesystem changes
alias sp='source ~/.bash_profile'			# re-load this file
alias tca='echo `TZ=America/Los_Angeles date "+%H:%M %d/%m" ; echo $TZ`'
#alias vi='vim'								# colored vi editor
alias vi='/usr/bin/vi' # high sierra breakage
alias which='type -all'                     # find executables

###remove### path() { echo "${PATH//:/$'\n'}" ; }

mcd () { mkdir -p "$1" && cd "$1" || exit ; }        # makes new dir and jump inside
#goog { open "https://google.com/search?q=$*" } # google from command-line
xv() { case $- in *[xv]*) set +xv;; *) set -xv ;; esac } # toggle debugging
#####mans () { man $1 | grep -iC2 --color=always $2 | $PAGER } # search man $1 for text $2

# showa: to remind yourself of an alias (given some part of it)
showa () { /usr/bin/grep --color=always -i -a1 "$@" ~/.bash_profile | grep -v '^\s*$' | less -FSRXc ; }
zipf () { zip -r "$1".zip "$1" ; }          # create zip archive of a folder

# -----------------------------------------------------------------------------
# terminal color
# -----------------------------------------------------------------------------
#export LS_OPTIONS='--color=auto'			# make ls colorful
export CLICOLOR=1							# make ls colorful
export LSCOLORS='BxGxfxfxCxdxdxhbadbxbx'	# was 'Bxgxfxfxcxdxdxhbadbxbx'
export TERM=xterm-color						# use color-capable termcap

# -----------------------------------------------------------------------------
# WordPress local hosting development
# -----------------------------------------------------------------------------
alias cdwp='cd /Library/WebServer/Documents/s/wp-content/themes/m_and_c/'

# -----------------------------------------------------------------------------
# Exiftool: rename image files by embedded EXIF data. Can operate in existing
# directory (in-line) or move recursively into a dated directory hierarchy.
#
# NOTE: exiftool was using 'CreateDate' but 'FileModifyDate' actually works.
# -----------------------------------------------------------------------------
# er ~ rename by modify date & move into dated folder hierarchy
alias er="exiftool -r '-FileName<FileModifyDate' -d %Y/%m/%Y%m%d/%Y%m%d_%H%M%S%%-c.%%le"
# erc ~ rename inline with creation date
alias erc="exiftool -r '-FileName<DateTimeOriginal' -d %Y%m%d_%H%M%S%%-c.%%le"
# eri - rename inline with modification date
alias eri="exiftool -r '-FileName<FileModifyDate' -d %Y%m%d_%H%M%S%%-c.%%le"
alias era="exiftool -a -G1 -s "				# show all tags
alias ert="exiftool -time:all -a -G0:1 -s "	# show time tags
# show tabular compilation of the GPS locations (-n in decimal) arg="*.JPG"
alias erg="exiftool -gpslatitude -gpslongitude -T -n"
alias en="exiftool -all="
# pix without EXIF data (but with MF5 filenames) can be moved:
alias mvmd5='mv ????????????????????????????????.* /Volumes/foobar/pix/'
# my whole exiftool work-flow
GRAPHICS='IMG* *.jpeg *.jpg *.gif *.png'
# shellcheck disable=2139
alias eee="pushd ~/Pictures/family/ ; er $GRAPHICS ; md5.bash $GRAPHICS ; mvmd5"

# -----------------------------------------------------------------------------
# web development
# -----------------------------------------------------------------------------
alias acheck='ps aux | grep httpd'
alias arestart='sudo apachectl restart'
alias astart='sudo apachectl start'
alias astop='sudo apachectl stop'
alias atest='apachectl configtest'
#
alias aedit='sudo edit /etc/httpd/httpd.conf'	# edit Apache httpd.conf
alias alogs="less +F /var/log/apache2/error_log" # show apache error logs
alias hostfile='sudo edit /etc/hosts'		# edit /etc/hosts file
httpdebug () { /usr/bin/curl "$@" -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n" ; }

# -----------------------------------------------------------------------------
# seriously miscellaneous stuff that was necessary at some time :-)
# -----------------------------------------------------------------------------
alias synctarot='rsync -avz "${HOME}/Documents/Burning Man/2015/tarot/" "/Volumes/LaCie 500GB/tarot-backups"'
alias syncpix='rsync -azP root@192.168.1.195:/var/mobile/Media/DCIM ${HOME}/Pictures/family/iph'

# -----------------------------------------------------------------------------
# cd to frontmost macOS Finder window
# -----------------------------------------------------------------------------
cdf () {
	currFolderPath=$( /usr/bin/osascript <<EOT
		tell application "Finder"
			try
		set currFolder to (folder of the front window as alias)
			on error
		set currFolder to (path to desktop folder as alias)
			end try
			POSIX path of currFolder
		end tell
EOT
	)
	echo "cd to \"$currFolderPath\""
	cd "$currFolderPath" || exit
}

function tit { echo -ne "\033]0;${*}\007" ; }	# iTerm set title bar

# -----------------------------------------------------------------------------
# extract best-known archives with one command
# -----------------------------------------------------------------------------
extract () {
	if [ -f "$1" ] ; then
	  case "$1" in
		*.tar.bz2)   tar xjf "$1"     ;;	# tar ~ bzip2
		*.tar.gz)    tar xzf "$1"     ;;	# tar ~ gzip
		*.bz2)       bunzip2 "$1"     ;;	# bzip2
		*.rar)       unrar e "$1"     ;;	# Roshal Archive (win.rar)
		*.gz)        gunzip "$1"      ;;	# gzip
		*.tar)       tar xf "$1"      ;;	# tar
		*.tbz2)      tar xjf "$1"     ;;	# bzip2-compressed tar archive
		*.tgz)       tar xzf "$1"     ;;	# really tar.gz
		*.zip)       unzip "$1"       ;;	# zip (pkware)
		*.Z)         uncompress "$1"  ;;	# compress
		*.7z)        7z x "$1"        ;;	# 7-Zip
		*)     echo "'$1' cannot be extracted via extract()" ;;
		 esac
	 else
		 echo "'$1' is not a valid file"
	 fi
}

# -----------------------------------------------------------------------------
# make backups into a local directory before you're ready for a git commit.
# add a datestamp between the filename and extension so you can still open file.
# -----------------------------------------------------------------------------
bak () {
	bkdir='./bak'							# write backups in your dir
	dn="$( dirname "$1" )"					# /path/to/file --> /path/to
	bn="$( basename "$1" )"					# /path/to/file --> file
	fn="${bn%.*}"							# filename: a.b.c.xyz --> a.b.c
	ex="${bn##*.}"							# extension: a.b.c.xyz --> xyz

	if [ ! "$1" ] ; then					# did you pass me a anything to backup?
		echo "usage: $0 [ file | directory ]"
		return								# nope. get it right, you!
	elif [ ! -w "$dn" ] ; then				# can I put a backup here?
		echo "$0: fatal: \"$dn\" not writable; quitting."
		return								# nope. try again
	elif [ ! -e "$1" ] ; then				# does the source exist?
		echo "$0: '$1' doesn't exist; quitting."
		return								# what are you thinking of?
	fi

	if [ -d "$1" ] ; then r='/'	; l='-r' ; fi	# is dir? tweak syntax

	mkdir -p "$bkdir"						# in case it doesn't exist
	d=$( date +%Y%m%d_%H%M%S )				# allow breadcrumbing through time
	if ! cp $L "$1" "$bkdir/${fn}_${d}.${ex}$R" ; then echo "$bn: error occured!"; fi
}

# ------------------------------------------------------------------------------
# Enable a terminal window to communicate with a serial port. Disconnecting it
# occasionally leaves the terminal window wonky. Try:
#
# alias screenfix='reset; stty sane; tput rs1; clear; echo -e "\033c"'
#
# NOTE: you may have to type 'reset' in terminal after disconnect serial device.
# ------------------------------------------------------------------------------
# Thank you, Intel:
# https://software.intel.com/en-us/setting-up-serial-terminal-on-system-with-mac-os-x
# ------------------------------------------------------------------------------
serial() {
	ports=$( ls /dev/cu.usbserial-* )		# get the USB serial port(s)
	numPorts=$( echo "$ports" | wc -l )		# count the number of ports found

	if (( $(( numPorts )) != 1 )) ; then	# which one? we can't read your mind
		echo "$0: fatal: expected to find 1 usb serial port, found $((numPorts)); quitting."
		exit								# we give up
	else
		screen "$ports" 115200 -L			# unambiguous; do the serial thing
	fi
}

#TO-DO: put the following in a doHome() doWork() doElsewhere()

# -----------------------------------------------------------------------------
# WordPress
# -----------------------------------------------------------------------------
# 'localhost' doesn't work because sockets
alias mys='mysql --host=127.0.0.1 --port=65001 -u root -p --execute="show databases;"'

# -----------------------------------------------------------------------------
# Credence ID
# -----------------------------------------------------------------------------
# shellcheck source=/Users/michael/.bash_credenceid
source ~/.bash_credenceid				# use a common .bashrc file

alias getkenny='scp build:/home/kcrudup/src/t2r-test-repo/out/target/product/trident_2r/*.{img,zip} .'
#alias foo="x=\"$2\" ; echo \"$x thing_\${x}.png\""
alias uu="fastboot \$TARGET oem unlock B73AC261"
#alias ap='adb shell cat /mnt/sdcard/ektp/config.properties'

alias wbackup='wget --user brittonholland --password Credence#1 -r ftp://ftp.credenceid.com/'
alias fw='ftp ftp://brittonholland:Credence#1@ftp.credenceid.com'

# shellcheck source="${HOME}/"
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools
export JAVA_HOME						# SC2155: Declare and assign separately
JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

# --- my shortcuts to CID working directories ---
CREDENCEID="$HOME/Documents/cid"
alias cdapps="cd \$CREDENCEID/code/CredenceIDApps"
# shellcheck disable=SC2139
alias cdcid="cd \$CREDENCEID/"
alias cdd="cd \$CREDENCEID/devops"
alias cdt2r="cd \$CREDENCEID/devops/t2/nix"
alias cdc1="cd /Users/michael/Box\ Sync/official__releases__PUBLIC/os/credence-one"
alias cdbcat="cd \$CREDENCEID/devops/bcat"
alias cdqa="cd \$CREDENCEID/qa"

# ---- one-offs useful for a short time ----
__DIST_DIR__="${HOME}/Box Sync"
# shellcheck disable=SC2034
__CANDIDAT__="${__DIST_DIR__}/official__candidates__private/1.12.12"
__RELEASED__="${__DIST_DIR__}/official__releases__public/__LATEST_SDK__/1.15.00"
# shellcheck disable=SC2034
__MARK__="${__DIST_DIR__}/staff_drop_boxes/mark.evans"
# shellcheck disable=SC2034
__LATEST_SDK__="${__RELEASED__}"
alias released="__LATEST_SDK__=\"\${__RELEASED__}\""
alias candidate="__LATEST_SDK__=\"\${__CANDIDAT__}\""
alias mark="__LATEST_SDK__=\"\${__MARK__}\""

# TO-DO: deal with the newline that screws up the following
alias usdk="a=\"\$( al | cut -d '=' -f 2 | tr -d '\r' )\" ; echo \$a"

alias obq="pushd ./__SPECIAL_STUFFS__ ; adb shell mkdir /sdcard/ ; adb \$TARGET push TWIZZLER_01_ROM-other.bq.fs /sdcard/ ; adb \$TARGET shell /data/bqtool -d 3 /sdcard/TWIZZLER_01_ROM-other.bq.fs ; popd"

alias doall="pushd \${HOME}/Documents/cid/devops/2r-trident/nix ; grc \${HOME}/Documents/cid/devops/bin/all-adb.sh minimal-adb.sh ; popd"

# -----------------------------------------------------------------------------
# wrapper is ~/bin/serial
#alias serial="screen `ls /dev/cu.usbserial-*` 115200 –L"
alias ptys="ls /dev/cu.usbserial-*"
alias fix='reset; stty sane; tput rs1; clear; echo -e "\033c"'

# <<---+----+----+----+----+----+----+----+----+----+----+----+----+----+---->>
# <<---|  The end of the defined functions. Following is the main body. |---->>
# <<---+----+----+----+----+----+----+----+----+----+----+----+----+----+---->>

getDomainnames								# find all the domainnames
if [[ $RUN_TESTS ]] ; then
	echo "$(date +'%H:%M:%S') ~ start"		# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º
	doAllTheTests allTheTests				# º Run all the tests             º
	echo "$(date +'%H:%M:%S') ~ end"		# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º
else
	doHostThings							# do host-specifics
	doArchSpecifics							# do architecture-specifics
	doOsSpecifics							# do OS-specifics
	determineLocationIfNotExcluded			# do location-specifics
fi

# -----------------------------------------------------------------------------
# Housekeeping for regular use, debugging, and calling from a QA test yoke.
# -----------------------------------------------------------------------------
unset DEBUG ; unset RUN_TESTS ; unset SILENT ; unset TEST_YOKE # QA stuff
#set +uo
if (( PROFILING )) ; then
	set +x
	exec 2>&3 3>&-
fi

# -----------------------------------------------------------------------------
# Manage $PATH and $MANPATH.
# -----------------------------------------------------------------------------
PATH="$(brew --prefix homebrew/php/php70)/bin:$PATH" # PHP 7.x
PATH="/usr/local/opt/python/libexec/bin:$PATH"	# homebrew python
MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"	# GNU
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"		# GNU
#PATH=/opt/ImageMagick:$PATH				# ImageMagick
PATH=/usr/local/bin:/usr/local/sbin:$PATH	# Homebrew
#MANPATH=/opt/local/share/man:$MANPATH		# MacPorts
#PATH=/opt/local/bin:/opt/local/sbin:$PATH	# MacPorts

# -----------------------------------------------------------------------------
# Ask Python to help in finding the binaries directory; then double-check. This
# should work in environments which have multiple versions installed, as the
# active python is queried.
# -----------------------------------------------------------------------------
PY_BIN=$(python -c 'import sys; print sys.prefix')'/bin'	# ask Python right spot
if [[ -d "$PY_BIN" ]] ; then PATH="$PATH:$PY_BIN" ; fi	# double-check

# -----------------------------------------------------------------------------
# use powerline and gitstatus-powerline for prompts & status lines (or go
# old-school on systems without it installed)
#
# FYI: configs in ${HOME}/.config/powerline/themes/shell/
# -----------------------------------------------------------------------------
#POWERLINE_PATH=$( /usr/bin/python -c 'import pkgutil; print pkgutil.get_loader("powerline").filename' 2>/dev/null )
POWERLINE_PATH=$( pip show powerline-status | grep Location | cut -d " " -f 2 )
if [[ "$POWERLINE_PATH" != "" && -e "${POWERLINE_PATH}/bindings/bash/powerline.sh" ]]; then
	PATH="$PATH:$POWERLINE_PATH/../scripts"	#
	powerline-daemon -q						#
	export POWERLINE_BASH_CONTINUATION=1	#
	export POWERLINE_BASH_SELECT=1			#
	# shellcheck source=/Users/michael/Library/Python/2.7/lib/python/site-packages/powerline/bindings/bash/powerline.sh
	source "${POWERLINE_PATH}/bindings/bash/powerline.sh"
else
	dir="${BASH_SOURCE%/*}"					# point to this script's location
	if [[ ! -d "$dir" ]]; then dir="$PWD"; fi	# if doesn't exist use PWD
	# shellcheck source=/Users/michael/.set_colors.sh
	. "$dir/.set_colors.sh"					# pre-powerline, set prompt colors
	# shellcheck source=/Users/michael/.set_prompt.sh
	. "$dir/.set_prompt.sh"					# pre-powerline, set prompt
	setTermPrompt							# use old-school prompt
fi

# -----------------------------------------------------------------------------
# Lastly, put my stuff at the front of PATH so it's found and used first.
# -----------------------------------------------------------------------------
__WORK_BIN="${CREDENCEID}/devops/bin:${CREDENCEID}/bin"	# work code
__PERS_BIN="$HOME/bin"						# personal executable binaries
PATH=.:${__PERS_BIN}:${__WORK_BIN}:$PATH	# cwd, my bin, work bin

PATH=~/Library/Android/sdk/platform-tools:$PATH

cleanPath									# remove duplicates from PATH
export PATH									# share and enjoy!
