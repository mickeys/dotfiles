#!/usr/bin/env bash					# search PATH for bash ~ portable technique
#set -u #o pipefail					# unofficial bash strict mode
#IFS=$'\n\t'
# -----------------------------------------------------------------------------
# My customizations I've made to my UN*X shell, a project that started sometime
# in the 1980s and has followed me around since. I use the computer as a
# technical writer, programmer, engineering manager, and family guy. My working
# environment needs to help me out in all these areas.
#
# This script lets you customize your computer through the following functions:
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
# Find this at ~ https://github.com/mickeys/dotfiles/blob/master/.bash_profile
# -----------------------------------------------------------------------------
DEBUG="YES"									# if [[ "$DEBUG" ]] ...
SUCCESS=0
FAILURE=1
RUN_TESTS='YES'								# QA switch ~ never for production
isNumber='^[0-9]+$'							# regexp ~ [[ $var =~ $isNumber ]]
t=(	[0]=fail [1]=pass )						# (need BASH_VERSION >= 4)
mon=0										# $(date +'%u') returns [0..7]
fri=5										# $(date +'%u') returns [0..7]
sat=6										# $(date +'%u') returns [0..7]
sun=7										# $(date +'%u') returns [0..7]

# -----------------------------------------------------------------------------
# General settings
# -----------------------------------------------------------------------------
# Location calculations continue until a method succeeds, so order the methods
# from most (DNS & WIFI) to least accurate (DATE); choose wisely.
# -----------------------------------------------------------------------------
tryLocationMethods=( DNS WIFI DATE )		# choose from DNS WIFI DATE
where=''									# final answer stored here
skipCheckOnThese=( 'workserver' )			# self-evident location
dayStarts=9									# time of day 0..23 ~ work starts
dayEnds=17									# time of day 0..23 ~ work ends
AIRPORT='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
WIFI=`$AIRPORT -I | grep "\bSSID" | sed -e 's/^.*SSID: //'`

# -----------------------------------------------------------------------------
# DNS settings ~ used if specified in tryLocationMethods() above
# -----------------------------------------------------------------------------
# myWifis[Coffee]=cafe						# how-to: add element in code
typeset -A myDNSs							# associative array
myDNSs=(									# (need BASH_VERSION >= 4)
	[apple.com]=work						# compound assignment
	[zipcar.com]=work						# left-hand side must be unique
	[comcast.net]=home
	[shaw.net]=home
)

# -----------------------------------------------------------------------------
# Wi-Fi settings ~ used if specified in tryLocationMethods() above
# -----------------------------------------------------------------------------
typeset -A myWifis							# associative array
myWifis=(									# (need BASH_VERSION >= 4)
	[Apple]=work							# compound assignment
	[Zipcar]=work							# left-hand side must be unique
	[bbhome]=home
	[Winter Home]=home
)

# =============================================================================
# Housekeeping helper functions ~ start
# =============================================================================
cleanPath() {								# remove duplicate $PATH entries
	if [ -n "$PATH" ]; then
	  old_PATH=$PATH:; PATH=
	  while [ -n "$old_PATH" ]; do
		x=${old_PATH%%:*}					# the first remaining entry
		case $PATH: in
		  *:"$x":*) ;;						# already there
		  *) PATH=$PATH:$x;;    			# not there yet
		esac
		old_PATH=${old_PATH#*:}
	  done
	  PATH=${PATH#:}
	  unset old_PATH x						# clean up after ourselves
	fi
}

# if $debug show calling function and error message
debug() { if  [[ "$DEBUG" ]] ; then echo "${FUNCNAME[1]}: $1" ; fi }

# =============================================================================
# Housekeeping helper functions ~ end
# =============================================================================

# -----------------------------------------------------------------------------
# Here's the mundane $PATH changes; further additions are pushed in front of
# the path, to be found first.
# -----------------------------------------------------------------------------
# Ask Python to help in finding the binaries directory; then double-check. This
# should work in environments which have multiple versions installed, as the
# active python is queried.
# -----------------------------------------------------------------------------
PY_BIN=`python -c 'import sys; print sys.prefix'`'/bin'	# ask Python right spot
if [[ -d "$PY_BIN" ]] ; then PATH="$PATH:$PY_BIN" ; fi	# double-check
PATH=/opt/ImageMagick:$PATH					# ImageMagick
PATH=/usr/local/bin:/usr/local/sbin:$PATH	# Homebrew
PATH=/opt/local/bin:/opt/local/sbin:$PATH	# MacPorts

# -----------------------------------------------------------------------------
# Below you'll find functions which determine and do customization based upon
# your machine's "location" (by time of day & week), its operating system, and
# its domain and host name. Set are the terminal colors (for readability), the
# terminal prompt, and the PATH and MANPATH environmental variables.
# -----------------------------------------------------------------------------
myDomain=''									# initialize empty before use

# =============================================================================
# location by the DNS services name
# =============================================================================
doLocByDNS() {
	if [[ ! "$DEBUG" ]] && [ -z "$where" ] ; then return ; fi	# if already set, punt

	# $2 must be an associatve array
	if ( ! (( ${#2} )) && [[ "$(declare -p $2)" =~ "declare -a" ]] ) ; then return ; fi

	# process arguments passed into the function
	local active="$1"						# active Wi-Fi name, passed in
	declare -n dnss=$2						# how one passes associative arrays

	# sanity-check inputs before moving on
	if [ -z "$active" ] || [ "${#dnss[@]}" -le 0 ] ; then return $FAILURE ; fi

	if (( $BASH_VERSINFO < 4 )) ; then return ; fi # associative arrays needed

	for i in "${!dnss[@]}"; do				# iterate over the array of wifis
		if [[ "$active" == *"$i"* ]]; then
			where="${dnss[$i]}"				# remember the associated location
			debug "$where"					# report back
			return							# match found; stop working
		fi
     done
} # end of doLocByDNS

# =============================================================================
# use airport command to get access point name
# =============================================================================
doLocByWifi() {
	if [[ ! "$DEBUG" ]] && [ -z "$where" ] ; then return ; fi	# if already set, punt

	# $2 must be an associatve array
	if ( ! (( ${#2} )) && [[ "$(declare -p $2)" =~ "declare -a" ]] ) ; then return ; fi

	# process arguments passed into the function
	local active="$1"						# active Wi-Fi name, passed in
	declare -n wifis=$2						# how one passes associative arrays

	# sanity-check inputs before moving on
	if [ -z "$active" ] ; then return $FAILURE ; fi

	if (( $BASH_VERSINFO < 4 )) ; then return ; fi # associative arrays needed

	for i in "${!wifis[@]}"; do				# iterate over the array of wifis
		if [ "$i" == "$active" ] ; then		# if we found a match
			where="${wifis[$i]}"			# remember the associated location
			debug "$where"					# report back
			return							# match found; stop working
		fi
	done
} # end of doLocByWifi

# =============================================================================
# guessing location by time-of-day (at work during daytime)
# =============================================================================
doLocByDateTime() {
	if [[ ! "$DEBUG" ]] && [ -z "$where" ] ; then return ; fi	# if already set, punt

	# process arguments passed into the function
	hour=$1									# 00..24 hour of day
	hour=${hour#0}							# strip leading zero, if present
	day=$2									# 0..7 day of week

	# sanity-check inputs before moving on
	if  [[ $hour =~ $isNumber ]] &&
		( ! ((( $hour >= 0 )) && (( $hour <= 24 ))) ) ; then return $FAILURE ; fi

	# -------------------------------------------------------------------------
	if (( ( $day >= $mon && $day <= $fri ) &&
		( $hour >= $dayStarts && $hour <= $dayEnds ) )) ;
	then
		debug "work (daytime weekday)"		# tell the debugging human
		where='work'						# remember the location
	# -------------------------------------------------------------------------
	elif (( ( $day >= $mon && $day <= $fri ) &&
		( $hour < $dayStarts || $hour > $dayEnds ) )) ;
	then
		debug "home (weekday outside of working hours)"	# tell
		where='home'						# remember the location
	# -------------------------------------------------------------------------
	elif (( $day == sat || $day == sun ))
	then
		debug "home (weekend)"				# tell the debugging human
		where='home'						# remember the location
	# -------------------------------------------------------------------------
	else
		debug "someplace unknown"
	fi
} # end of doLocByDateTime

# =============================================================================
# Location-specific things
#
# Note: Darwin (locally) and many workplaces don't properly set the
# domainname, so I have to use this work-around to see what network
# to which you're currently using. If you're working at a cafe or train
# and have no work WiFi via VPN (which I've not tested) this may not be
# a good way of doing things. I'm still checking alternatives.
#
# If a FQDN is properly set the following command will work, but I've
# seen that many companies / locations don't properly set either the
# hostname to FQDN or the domainname at all.
#
# MYDOMAIN="`echo $HOSTNAME | rev | cut -d. -f1,2 | rev`
#
# The following is designed to be extensible to multiple work and other
# locations.
# =============================================================================

# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸,
# Test the major functions with a variety of inputs
# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸,
test_doLocByDateTime() {
	doLocByDateTime 11 5
	if ! doLocByDateTime 25 8 ; then echo "test should have failed" ; fi
	if ! doLocByDateTime "dog" 8 ; then echo "test should have failed" ; fi
}

test_doLocByDNS() {
	doLocByDNS "`scutil --dns`" myDNSs
	if ! doLocByDNS '' '' ; then echo "test should have failed" ; fi
}

test_doLocByWifi() {
	doLocByWifi "$WIFI" myWifis
	if ! doLocByWifi '' myWifis ; then echo "test should have failed" ; fi
}

# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸,
# Run all the tests
# °º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸,
if [[ "$RUN_TESTS" ]] ; then
	echo "$(date +'%H:%M:%S') ~ tests begin"
	test_doLocByDateTime
# TO-DO: check that we're passing these arguments down to the actual functions
	test_doLocByDNS "`scutil --dns`" myDNSs
	test_doLocByWifi "$WIFI" myWifis
	echo "$(date +'%H:%M:%S') ~ tests end"
fi

# =============================================================================
# Iterate over the methods chosen above & try to figure our location with them.
# =============================================================================
determineLocation() {
	for method in "${tryLocationMethods[@]}"
	do
		case "$method" in
			DNS) doLocByDNS "`scutil --dns`" myDNSs ;;
			WIFI) doLocByWifi "$WIFI" myWifis ;;
			DATE) doLocByDateTime $(date +'%H') $(date +'%u') ;;
			*) echo "WARNING! Unknown determination method \"$fqdn\"!" ;;
		esac
	done
	# TO-DO: echo "where \"$where\" -- make a doHomeStuff(), doWorkStuff() ??"
} # end determineLocation

# =============================================================================
# Do location-specific things if machine not on exclusion list.
# =============================================================================
determineLocationIfNotExcluded() {
	debug "hostname \"$HOSTNAME\""
	determineLocation=true					# default is to do check
	for fqdn in "${skipCheckOnThese[@]}"	# iterate over hostnames
	do
		if [[ "$HOSTNAME" =~ "$fqdn" ]]; then	# if this hostname found then
			determineLocation=false			# turn off location check
		fi
	done

	if $determineLocation ; then			# check hostname result
		determineLocation					# do location things
	fi
} # end determineLocationIfNotExcluded

# =============================================================================
# Do architecture-specific things.
# =============================================================================
doArchSpecifics() {
	archStr=$(arch)							# get machine architecture
	debug "machine architecture is \"$archStr\""
	case "archStr" in						# do architecture-specifics
		# =====================================================================
		i386)								# including Mac
		;;

		# =====================================================================
		arm)								# including iPhone/i$ad
		;;
	esac # end archStr
}

# =============================================================================
# Do OS-specific things.
# =============================================================================
doOsSpecifics() {
	unameStr=${OSTYPE//[0-9.]/}				# get OS name and
	debug "operating system is \"$unameStr\""
	case "$unameStr" in						# do OS-appropriate things
		# =====================================================================
		darwin)								# Mac OS X

			alias dnsflush='sudo discoveryutil mdnsflushcache ; sudo discoveryutil udnsflushcaches'

			# iPhone simulator is hidden for some strange reason
			#alias simu='open /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app'

			# use powerline and gitstatus-powerline for prompts & status lines
			POWERLINE_PATH=$(/usr/bin/python -c 'import pkgutil; print pkgutil.get_loader("powerline").filename' 2>/dev/null)
			if [[ "$POWERLINE_PATH" != "" ]]; then
				source ${POWERLINE_PATH}/bindings/bash/powerline.sh
			else
				setTermPrompt				# else use old-school prompt
			fi
  			;;

		# =====================================================================
		Linux)
			alias ls='ls --color --classify' # make ls colorful
			today=`date "+%Y%m%d"`			# needed for logs
			alias ta="tail /etc/httpd/logs/${today}/error_log"
			;;

		# =====================================================================
		*) echo "NOTE: Unknown operating system \"$unameStr\"!" ;;
	esac
} # end doOsSpecifics

# =============================================================================
# hostname-specific things
# =============================================================================
doHostThings() {
	# =========================================================================
	case "$HOSTNAME" in						# do hostname-specific things

		# =====================================================================
		michael.local)						# home machine
			# home-grown duplicate file deletion scheme ; ignore if you're not me :-)
			alias ldups='ls | wc -l ; rm -f ../filelist ; cksum *.jpg | sort -n > ../filelist ; ../rmdups ; ls | wc -l'
			alias mdups='ls | wc -l ; rm -f ../filelist ; cksum *.jpg | sort -n > ../filelist ; rmdups ; ls | wc -l'

			# to use alias add hostnames and users to your ~/.ssh/config
			alias 11="ssh u76141767@s513372989.onlinehome.us" 	# 1and1.com

		;; # end (michael.local) case
	esac; # end $HOSTNAME case

	# =========================================================================
	# Do more complicated tests to customize one way for multiple machines.
	# =========================================================================
	# work machine, on-line and off-line names
	if [ "$HOSTNAME" = 'this.machine.example.com' \
		-o "$HOSTNAME" = 'msattler.local' ] ;
	then
		S_CERTS='/Users/me/employer/.chef'	# where I keep Chef certs

		# =====================================================================
	fi # end (michael.local)

	# =========================================================================
} # end doHostThings

# =============================================================================
# Run add-on scripts
# =============================================================================
dir="${BASH_SOURCE%/*}"						# pointer to this script's location
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi	# if doesn't exist use current PWD
. "$dir/.set_prompt.sh"						# pre-powerline, set shell prompt

# <<---+----+----+----+----+----+----+----+----+----+----+----+----+----+---->>
# <<---|  The end of the defined functions. Following is the main body. |---->>
# <<---+----+----+----+----+----+----+----+----+----+----+----+----+----+---->>
doHostThings								# do host-specifics
doArchSpecifics								# do architecture-specifics
doOsSpecifics								# do OS-specifics
determineLocationIfNotExcluded				# do location-specifics
setTermColors								# set terminal colors
setTermPrompt								# set the shell prompt

# -----------------------------------------------------------------------------
# UN*X command history
# -----------------------------------------------------------------------------
alias h='history'							# see what happened before
HISTCONTROL=ignoreboth						# bash(1) don't add dups, etc.
HISTSIZE=1000								# bash(1) history command length
HISTFILESIZE=2000							# bash(1) history file size max
shopt -s histappend							# append, don't overwrite, history file
shopt -s checkwinsize						# after each command check window size...

# -----------------------------------------------------------------------------
# general things, alphabetically
# -----------------------------------------------------------------------------
alias ..="cd .."							# absent-minded sys-admin :-)
alias c="clear"								# clear the terminal screen
alias cd..="cd .."							# I typo this all the time :-/
alias cpbash='scp .bash_profile USERNAME_OVER_THERE@hostname:'
alias e="exit"								# end this shell
alias fixvol='sudo killall -9 coreaudiod'	# when volume buttons don't
alias kurl='curl -#O'						# download and save w orig filename
alias lastmaint="ls -al /var/log/*.out"		# when did we last tidy up?
alias ll='ls -lAhF'							# ls w kb, mb, gb
alias lock="open '/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app'"
alias ls="ls -F"							# ls special chars
alias maint="sudo periodic daily weekly monthly"	# tidy up :-)
alias mydate='date +%Y%m%d_%H%M%S'			# more useful for sorting
alias netspeed='time curl -o /dev/null http://wwwns.akamai.com/media_resources/NOCC_CU17.jpg'
alias pd='pushd'							# see also 'popd'
alias ps='ps -creo command,pid,%cpu | head -10'
#alias python="python3"						# p3 libs incompat with p2
alias resizesb='sudo hdiutil resize -size '	# 6g BUNDLENAME'
alias rmempty='find . -name .DS_Store -delete ; find . -type d -empty -delete'
alias sink='sync;sync;sync'					# write filesystem changes
alias swap='swaps ; sudo dynamic_pager -L 1073741824 ; swaps' # force swap garbage collection
alias swaps='ls -alh /var/vm/swapfile* | wc -l'	# how many swap files?
alias ta='tail /usr/local/var/log/apache2/error_log'	# apache error log
alias tca='echo `TZ=America/Los_Angeles date "+%H:%M %d/%m" ; echo $TZ`'
alias vi='vim'								# colored vi editor
function xv() { case $- in *[xv]*) set +xv;; *) set -xv ;; esac }
function trash() { mv $@ ~/.Trash; }		# move to trash (vs deleting asap)

# -----------------------------------------------------------------------------
# terminal color
# -----------------------------------------------------------------------------
#export LS_OPTIONS='--color=auto'			# make ls colorful
export CLICOLOR=1							# make ls colorful
export LSCOLORS='BxGxfxfxCxdxdxhbadbxbx'	# was 'Bxgxfxfxcxdxdxhbadbxbx'
export TERM=xterm-color						# use color-capable termcap

# -----------------------------------------------------------------------------
# git
# -----------------------------------------------------------------------------
function ga() { git add $1\ ; }				# add files to be tracked
function gc() { git commit -am $@ ; }		# commit changes locally
alias gi='git check-ignore -v *'			# see what's being ignored
alias gl='git log'							# see what happened
alias gs='git status'						# see what's going on
alias gp='git push -u origin master'		# send changes upstream

# -----------------------------------------------------------------------------
# Exiftool and the many ways I use it
# -----------------------------------------------------------------------------
# rename-by-date and move into dated folder hierarchy
GRAPHICS='IMG* *.jpeg *.jpg *.gif *.png'
# exiftool - was using CreateDate but FileModifyDate actually exists
## exiftool recursively rename files and place into nested directory structure
#
alias er="exiftool -r '-FileName<FileModifyDate' -d %Y/%m/%Y%m%d/%Y%m%d_%H%M%S%%-c.%%le"
#
## exiftool inline (replace filenames without sorting into nested directories)
#
# era - show all tags
# ert - show time tags
# erc - rename inline with creation date
# eri - rename inline with modification date
alias era="exiftool -a -G1 -s "
alias ert="exiftool -time:all -a -G0:1 -s "
alias erc="exiftool -r '-FileName<DateTimeOriginal' -d %Y%m%d_%H%M%S%%-c.%%le"
alias eri="exiftool -r '-FileName<FileModifyDate' -d %Y%m%d_%H%M%S%%-c.%%le"
## exiftool show tabular compilation of the GPS locations (-n in decimal)
alias erg="exiftool -n -filename -gpslatitude -gpslongitude -T"
alias en="exiftool -all="
alias mvmd5='mv ????????????????????????????????.* /Volumes/foobar/pix/'
alias eee="pushd ~/Pictures/family/ ; er $GRAPHICS ; md5.bash $GRAPHICS ; mvmd5"

# -----------------------------------------------------------------------------
# seriously miscellaneous stuff that was necessary at some time :-)
# -----------------------------------------------------------------------------
alias synctarot='rsync -avz "/Users/michael/Documents/Burning Man/2015/tarot/" "/Volumes/LaCie 500GB/tarot-backups"'
alias syncpix='rsync -azP root@192.168.1.195:/var/mobile/Media/DCIM /Users/michael/Pictures/family/iph'

# -----------------------------------------------------------------------------
# Zipcar stuff
# -----------------------------------------------------------------------------
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
source ~/.profile							# for rvm
#source $HOME/.bash_profile_zipcar			# zipcar-specific dev resources

export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools

# -----------------------------------------------------------------------------
# Set the MANPATH & the all-important PATH
# -----------------------------------------------------------------------------
export MANPATH=/opt/local/share/man:$MANPATH	# MacPorts MANPATH
cleanPath									# remove duplicates from PATH
PATH=~/bin:$PATH							# find my stuff first
export PATH									# share and enjoy!
#set +uo