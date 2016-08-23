#!/usr/bin/env bash
#set -u #o pipefail							# unofficial bash strict mode
#IFS=$'\n\t'

# -----------------------------------------------------------------------------
# I've used a frightening & bewildering variety of UN*X distros since the early
# 1980s. One thing all of them had in common was this "run-commands" file; it's
# that important to have machine-specific resources and commands configured and
# aliased appropriately. Rather than have 40 different versions ~ yes, really:
# there was BSD, System V, Sun OS, Solaris, GNU, AIX, Linux, and Darwin (macOS);
# on PDP-8|10, MIPS, ARM, MC68000, SPARC; from Sun, H-P, Apple ~ crafting one
# file to be synced to all my working computers was integral to keeping me sane.
#
# Originally this only tested for hostname. Because I worked on many a UN*X farm
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
# free to use this as a jumping-off point in tweaking your own UN*X machines.
# 
# Find me at ~ https://github.com/mickeys/dotfiles/blob/master/.bash_profile
# -----------------------------------------------------------------------------
# QA NOTE: if $BASH_VERSION < v4 parts of this script will silently not execute.
# This is a feature, not a bug. Update your bash to a modern one. This has been
# tested mostly on macOS 10.12 (Sierra), with side-trips to several Linuxes.
# -----------------------------------------------------------------------------

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
SUCCESS=0									# standard UN*X return code
FAILURE=1									# standard UN*X return code
isNumber='^[0-9]+$'							# regexp ~ [[ $var =~ $isNumber ]]
# shellcheck disable=SC2034					# appears unused
myDomain=''									# initialize empty before use
mon=0										# $(date +'%u') returns [0..7]
fri=5										# $(date +'%u') returns [0..7]
sat=6										# $(date +'%u') returns [0..7]
sun=7										# $(date +'%u') returns [0..7]
# -----------------------------------------------------------------------------
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
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
skipCheckOnThese=( 'pippin.apple.com' )		# self-evident location
dayStarts=9									# time of day 0..23 ~ work starts
dayEnds=17									# time of day 0..23 ~ work ends
AIRPORT='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
WIFI=$( $AIRPORT -I | grep "\bSSID" | sed -e 's/^.*SSID: //' )

# -----------------------------------------------------------------------------
# DNS settings ~ used if specified in tryLocationMethods() above
# -----------------------------------------------------------------------------
# shellcheck disable=SC2034					# appears unused
declare -A myDNSs=(							# (needs BASH_VERSION >= 4)
	[comcastbusiness.net]=work				# compound assignment
	[zipcar.com]=work						# left-hand side must be unique
	[comcast.net]=home
	[shaw.net]=home
)

# -----------------------------------------------------------------------------
# Wi-Fi settings ~ used if specified in tryLocationMethods() above
# -----------------------------------------------------------------------------
# shellcheck disable=SC2034					# appears unused
declare -A myWifis=(						# (needs BASH_VERSION >= 4)
	[Apple]=work							# compound assignment
	[Zipcar]=work							# left-hand side must be unique
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
debug() { if  [[ $DEBUG ]] ; then echo "${FUNCNAME[1]}: $1" ; fi }

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
	if eval nc -z -w 1 google.com 80 "$SILENT" ; then # only if network up
		external_ip="$( dig +short myip.opendns.com @resolver1.opendns.com )"
		# --> like 1.2.3.4
		fqdn=$( host "$external_ip" )
		# --> 1.2.3.4.in-addr.arpa domain name pointer c-73.hsd1.ca.comcast.net.
		fqdn=${fqdn:0:${#fqdn}-1}			# strip dot from end
		# --> 1.2.3.4.in-addr.arpa domain name pointer c-73.hsd1.ca.comcast.net
		d[${#d[@]}]=$(echo "$fqdn" | rev | cut -d. -f1,2 | rev)
		# --> comcast.net
	fi
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
# use airport command to get access point name
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

# shellcheck disable=SC2034					# appears unused
t=(	[0]=pass [1]=fail )						# array pairs codes to readable text
# if what you expected == what actually happened, be happy
passFail() { if (( $1 == $2 )) ; then echo -n "success" ; else echo -n "failure" ; fi }

# -----------------------------------------------------------------------------
# Every function to test (with arguments) and the expected result.
# -----------------------------------------------------------------------------
# shellcheck disable=SC2034					# appears unused
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
# shellcheck disable=SC2034					# appears unused
	__i__=1									# just a simple counter
# shellcheck disable=SC2034					# appears unused
	__l__=${#tests[@]}						# total number of tests
	for c in "${!tests[@]}" ; do				# iterate over the array of tests
		# run test
		eval "$c $SILENT"					# evaluate the test command line
#		r=$?								# save the test return value

		# generate output
#xyzzy		pad "$__i__" "${#__l__}" -n				# output number of this test
#		i="((__i__++))						# on to next in the array
#		echo -n "/$__l__ ~ "				# output total number of tests
#		passFail "$r" "${tests[$c]}"			# output human-readable pass or fail
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
doOsSpecifics() {
	local os=${OSTYPE//[0-9.]/}				# get text part of the OS name and
	os=${os,,}								# lowercase normalize it then
	debug "machine operating system is \"$os\""
	case "$os" in							# do OS-appropriate things
		# ---------------------------------------------------------------------
		darwin)								# Mac OS X
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
			v=$( sw_vers -productVersion )				# get version no (eg 10.10.3)
			vparts=(${v//./ })							# split apart into parts

			case "${vparts[0]}.${vparts[1]}" in

				10.12) # -------------------------- # Sierra
					f="$kilmdn"
					;;
				10.11) # -------------------------- # El Capitan
					f="$kilmdn"
					;;
				10.10) # -------------------------- # Yosemite
					if (( ( ${vparts[2]} >= 1 ) && ( ${vparts[2]} <= 3 ) )) ; then
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
					f="dscache"
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
			source $( brew --prefix git)/etc/bash_completion.d/git-completion.bash
			;;	# end darwin
		# ---------------------------------------------------------------------
		linux)
			alias ls='ls --color --classify' # make ls colorful
			today=$(date "+%Y%m%d")			# needed for logs
			alias ta="tail /etc/httpd/logs/${today}/error_log"
			;;

		# ---------------------------------------------------------------------
		linux-gnu)							# Fedora
			;;

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
	if [ "$HOSTNAME" = 'michael.local' \
		-o "$HOSTNAME" = 'michael.at_]work.com' ] ;
	then
# shellcheck disable=SC2034					# appears unused
                unused='needed a placeholder in this clause'

		# ---------------------------------------------------------------------

	fi # end (michael.local)

	# -------------------------------------------------------------------------
} # end doHostThings

# -----------------------------------------------------------------------------
# Run (exceedingly optional) add-on scripts
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# use powerline and gitstatus-powerline for prompts & status lines (or go
# old-school on systems without it installed)
# -----------------------------------------------------------------------------
POWERLINE_PATH=$(/usr/bin/python -c 'import pkgutil; print pkgutil.get_loader("powerline").filename' 2>/dev/null)
if [[ "$POWERLINE_PATH" != "" ]]; then
	source "${POWERLINE_PATH}/bindings/bash/powerline.sh"
else
	dir="${BASH_SOURCE%/*}"					# point to this script's location
	if [[ ! -d "$dir" ]]; then dir="$PWD"; fi	# if doesn't exist use PWD
	. "$dir/.set_colors.sh"					# pre-powerline, set prompt colors
	. "$dir/.set_prompt.sh"					# pre-powerline, set prompt
	setTermPrompt							# use old-school prompt
fi

# -----------------------------------------------------------------------------
# Do command aliasing. Works on any bash version.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# UN*X command history
# -----------------------------------------------------------------------------
alias h='history'							# see what happened before
HISTCONTROL=ignoreboth						# don't add duplicates, etc.
HISTFILE=~/.bash_eternal_history			# "eternal" ~ don't get truncated
HISTFILESIZE=								# "eternal" ~ no max size
HISTSIZE=									# "eternal" ~ no max size
HISTTIMEFORMAT="[%m-%d %H:%M] "				# add 24-hour timestamp to history
shopt -s checkwinsize						# after each command check window size...
shopt -s histappend							# append, don't overwrite, history file

# -----------------------------------------------------------------------------
# other environment settings
# -----------------------------------------------------------------------------
export EDITOR=/usr/bin/vim					# graphic text editor of choice
# http://www.thegeekstuff.com/2013/12/bash-completion-complete/
if [ -f "$(brew --prefix)/etc/bash_completion" ] ;	# if bash completion exists
then . "$(brew --prefix)/etc/bash_completion" ; fi	# hey, check out .inputrc

# -----------------------------------------------------------------------------
# general things, alphabetically
# -----------------------------------------------------------------------------
alias c="clear"								# clear the terminal screen
alias ~="cd ~"                              # Go to the home directory
alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias .3='cd ../../../'                     # Go back 3 directory levels
alias .4='cd ../../../../'                  # Go back 4 directory levels
alias .5='cd ../../../../../'               # Go back 5 directory levels
alias .6='cd ../../../../../../'            # Go back 6 directory levels
#alias diffc="diff --old-group-format=$'\e[0;31m%<\e[0m' \
#     --new-group-format=$'\e[0;31m%>\e[0m' \
#     --unchanged-group-format=$'\e[0;32m%=\e[0m'"
     
#alias cpbash='scp ~/.bash_profile USERNAME_OVER_THERE@hostname:'
alias e="exit"								# end this shell
alias fixvol='sudo killall -9 coreaudiod'	# when volume buttons don't
alias grepc='grep --color=auto'				# grep shows matched in color
alias kb='bind -p | grep -F "\C"'			# see key bindings (see .inputrc)
alias kurl='curl -#O'						# download and save w orig filename
alias lastmaint="ls -al /var/log/*.out"		# when did we last tidy up?
alias ll='ls -lAhF'							# ls w kb, mb, gb
alias lock="open '/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app'"
#alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less' # lr ~ fully-recursive directory listing
alias ls="ls -F"							# ls special chars
alias maint="sudo periodic daily weekly monthly"	# tidy up :-)
alias mydate='date +%Y%m%d_%H%M%S'			# more useful for sorting
alias netspeed='time curl -o /dev/null http://wwwns.akamai.com/media_resources/NOCC_CU17.jpg'
alias path='echo -e ${PATH//:/\\n}'         # show all executable Paths
alias pd='pushd'							# see also 'popd'
alias ps='ps -creo command,pid,%cpu | head -10'
#alias python="python3"						# p3 libs incompat with p2
alias resizesb='sudo hdiutil resize -size '	# 6g BUNDLENAME'
alias rmempty='find . -name .DS_Store -delete ; find . -type d -empty -delete'
alias sink='sync;sync;sync'					# write filesystem changes
alias sp='source ~/.bash_profile'
alias swap='swaps ; sudo dynamic_pager -L 1073741824 ; swaps' # force swap garbage collection
alias swaps='ls -alh /var/vm/swapfile* | wc -l'	# how many swap files?
alias ta='tail /usr/local/var/log/apache2/error_log'	# apache error log
alias tca='echo `TZ=America/Los_Angeles date "+%H:%M %d/%m" ; echo $TZ`'
alias vi='vim'								# colored vi editor
alias which='type -all'                     # find executables
mcd () { mkdir -p "$1" && cd "$1" || exit ; }        # makes new dir and jump inside
#goog { open "https://google.com/search?q=$*" } # google from command-line
trash() { mv "$@" ~/.Trash; }		# move to trash (vs deleting asap)
#tw() { open -a /Applications/TextWrangler.app/ "$1" }	# my GUI editor
xv() { case $- in *[xv]*) set +xv;; *) set -xv ;; esac } # toggle debugging

# -----------------------------------------------------------------------------
# terminal color
# -----------------------------------------------------------------------------
#export LS_OPTIONS='--color=auto'			# make ls colorful
export CLICOLOR=1							# make ls colorful
export LSCOLORS='BxGxfxfxCxdxdxhbadbxbx'	# was 'Bxgxfxfxcxdxdxhbadbxbx'
export TERM=xterm-color						# use color-capable termcap

# -----------------------------------------------------------------------------
# git
#
# see also: http://nuclearsquid.com/writings/git-tricks-tips-workflows/
# http://durdn.com/blog/2012/11/22/must-have-git-aliases-advanced-examples/
# -----------------------------------------------------------------------------
alias g='git'								# save 66% of typing
complete -o default -o nospace -F _git g	# autocomplete for 'g' as well
function ga() { git add "$1"\ ; }			# add files to be tracked
function gc() { git commit -m "$@" ; }		# commit changes locally
alias gd='git diff'							# see what happened
alias gi='git check-ignore -v *'			# see what's being ignored
alias gl='git log --pretty=format:" ~ %s (%cr)" --no-merges'	# see what happened
alias gs='git status --short'				# see what's going on
alias gp='git push -u origin master'		# send changes upstream
alias gsl='git stash list'					# git-stash(1)
alias gsp='git stash pop'					# git-stash(1)
alias gss='git stash save'					# git-stash(1)

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
alias eee="pushd ~/Pictures/family/ ; er $GRAPHICS ; md5.bash $GRAPHICS ; mvmd5"

# -----------------------------------------------------------------------------
# less ~ the enhanced version of the 'more' page viewer
# -----------------------------------------------------------------------------
alias more='less'							# alias to use less
export LC_ALL=en_US.UTF-8					# language variable to rule them all
export LANG=en_us.UTF-8						# char set
export PAGER=less							# tell the system to use less
export LESSCHARSET='utf-8'					# was 'latin1'
export LESSOPEN='|/usr/bin/lesspipe.sh %s 2>&-' # Use if lesspipe.sh exists
export LESS='-i -N -w  -z-4 -g -e -M -X -F -R -P%t?f%f :stdin .?pb%pb\%:?lbLine %lb:?bbByte %bb:-...'

# LESS man page colors (makes Man pages more readable).
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# -----------------------------------------------------------------------------
# web development
# -----------------------------------------------------------------------------
alias aedit='sudo edit /etc/httpd/httpd.conf'	# edit Apache httpd.conf
alias alogs="less +F /var/log/apache2/error_log" # show apache error logs
alias arestart='sudo apachectl graceful'	# restart Apache
alias hostfile='sudo edit /etc/hosts'		# edit /etc/hosts file
alias hlogs='tail /var/log/httpd/error_log'	# tail HTTP error logs
httpdebug () { /usr/bin/curl "$@" -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n" ; }

# -----------------------------------------------------------------------------
# seriously miscellaneous stuff that was necessary at some time :-)
# -----------------------------------------------------------------------------
alias synctarot='rsync -avz "/Users/michael/Documents/Burning Man/2015/tarot/" "/Volumes/LaCie 500GB/tarot-backups"'
alias syncpix='rsync -azP root@192.168.1.195:/var/mobile/Media/DCIM /Users/michael/Pictures/family/iph'

# -----------------------------------------------------------------------------
# extract best-known archives with one command
# -----------------------------------------------------------------------------
extract () {
	if [ -f "$1" ] ; then
	  case "$1" in
		*.tar.bz2)   tar xjf "$1"     ;;
		*.tar.gz)    tar xzf "$1"     ;;
		*.bz2)       bunzip2 "$1"     ;;
		*.rar)       unrar e "$1"     ;;
		*.gz)        gunzip "$1"      ;;
		*.tar)       tar xf "$1"      ;;
		*.tbz2)      tar xjf "$1"     ;;
		*.tgz)       tar xzf "$1"     ;;
		*.zip)       unzip "$1"       ;;
		*.Z)         uncompress "$1"  ;;
		*.7z)        7z x "$1"        ;;
		*)     echo "'$1' cannot be extracted via extract()" ;;
		 esac
	 else
		 echo "'$1' is not a valid file"
	 fi
}

#TO-DO: put the following in a doHome() doWork() doElsewhere()
# -----------------------------------------------------------------------------
# Zipcar stuff
# -----------------------------------------------------------------------------
if /usr/bin/which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
# shellcheck source="/Users/msattler/"		# where to find the following file
source ~/.profile							# for rvm
#source $HOME/.bash_profile_zipcar			# zipcar-specific dev resources

export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools

# <<---+----+----+----+----+----+----+----+----+----+----+----+----+----+---->>
# <<---|  The end of the defined functions. Following is the main body. |---->>
# <<---+----+----+----+----+----+----+----+----+----+----+----+----+----+---->>

getDomainnames								# find all the domainnames we can
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
# Manage $PATH and $MANPATH. Put your customizations before $PATH to have them
# used instead of built-ins.
# -----------------------------------------------------------------------------
export MANPATH=/opt/local/share/man:$MANPATH	# MacPorts

# -----------------------------------------------------------------------------
# Ask Python to help in finding the binaries directory; then double-check. This
# should work in environments which have multiple versions installed, as the
# active python is queried.
# -----------------------------------------------------------------------------
PY_BIN=$(python -c 'import sys; print sys.prefix')'/bin'	# ask Python right spot
if [[ -d "$PY_BIN" ]] ; then PATH="$PATH:$PY_BIN" ; fi	# double-check
#PATH=/opt/ImageMagick:$PATH				# ImageMagick
PATH=/usr/local/bin:/usr/local/sbin:$PATH	# Homebrew
#PATH=/opt/local/bin:/opt/local/sbin:$PATH	# MacPorts
cleanPath									# remove duplicates from PATH
PATH=~/bin:$PATH							# my personal projects first :-)
export PATH									# share and enjoy!

# -----------------------------------------------------------------------------
# Housekeeping for regular use, debugging, and calling from a QA test yoke.
# -----------------------------------------------------------------------------
unset DEBUG ; unset RUN_TESTS ; unset SILENT ; unset TEST_YOKE # QA stuff
#set +uo