# 1.1.35 michael
# -----------------------------------------------------------------------------
# This is my .bash_profile, a run-commands file, consumed by the bash shell at
# start-up. This class of file allows for storing customization for repeating.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CUSTOMIZATIONS ALL LOCATED UP HERE...
# -----------------------------------------------------------------------------
LOCATION_DETERMINATION=( )	# options: DNS DATE WIFI
SKIP_LOC_CHECK=( 'stormdev' )				# self-evident location
WORK_STARTS=9								# time of day work starts
WORK_ENDS=17								# time of day work ends
# -----------------------------------------------------------------------------
#MY_WORK_DNS='splunk.com'					# work domain(s)
## MY_HOME_DNS=''		# home domain(s) - currently comcast, too generic
## MY_CAFE_DNS='my.favorite.cafe'			# cafe domain(s)
## MY_OTHER_PLACE='my.other.place'			# misc domain(s)
#DNS_LOCATIONS=(								# DNS to look for
#	"$MY_WORK_DNS"							# look at work locations	
#	#"$MY_HOME_DNS"								# look at home locations
#)
## -----------------------------------------------------------------------------
#MY_WORK_WIFI='Splunk'						# work access point name
#MY_HOME_WIFI='Harmless Network Device'		# home access point name
## MY_CAFE_WIFI='my.favorite.cafe'			# cafe access point name
## MY_OTHER_PLACE='my.other.place'			# misc access point name
#WIFI_LOCATIONS=(							# WIFI to look for
#	"$MY_WORK_WIFI"							# look at work locations	
#	"$MY_HOME_WIFI"							# look at home locations
#)
## -----------------------------------------------------------------------------
AT_HOME='home'
AT_WORK='work'
#AT_CAFE='cafe'
H1=( $AT_HOME 'Harmless Network Device' )
H2=( $AT_HOME 'Mostly Harmless Network Device' )
W1=( $AT_WORK 'Splunk' )
W2=( $AT_WORK 'Splunk-Guest' )
WIFIS=( H1 H2 W1 W2 )

# -----------------------------------------------------------------------------
# Here's the mundane $PATH changes; further additions are pushed in front of
# the path, to be found first.
# -----------------------------------------------------------------------------
PATH="/Library/Frameworks/Python.framework/Versions/3.4/bin:${PATH}"
PATH=/opt/ImageMagick:$PATH					# ImageMagick
PATH=/usr/local/bin:/usr/local/sbin:$PATH	# Homebrew
PATH=/opt/local/bin:/opt/local/sbin:$PATH	# MacPorts PATH

# -----------------------------------------------------------------------------
# Below you'll find functions which determine and do customization based upon
# your machine's "location" (by time of day & week), its operating system, and
# its domain and host name. Set are the terminal colors (for readability), the
# terminal prompt, and the PATH and MANPATH environmental variables.
# -----------------------------------------------------------------------------
MY_DOMAIN=''								# initialize before use
my_loc=''									# initialize? scope?

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
# HOSTNAME to FQDN or the domainname at all.
#
# MYDOMAIN="`echo $HOSTNAME | rev | cut -d. -f1,2 | rev`
#
# The following is designed to be extensible to multiple work and other
# locations.
# =============================================================================

# =============================================================================
# * location by the DNS services name
# =============================================================================
doLocByDns() {
	DNS_RESULTS="`scutil --dns`"	# get DNS info
echo "doLocByDns(): DNS_RESULTS \"$DNS_RESULTS\""
	for element in "${DNS_LOCATIONS[@]}"
	do
		if [[ $element =~ "$DNS_RESULTS" ]]; then
# xyzzy - rewrite to use nested array
			MY_DOMAIN="$element"	# yay! found location via DNS
		fi
	done


	# =================================================================
	# Issue commands below based upon where you've been located.
	# =================================================================
	case "$MY_DOMAIN" in
		# =============================================================
		"DNS: $MY_HOME_DNS")
			echo "my home"			# do home stuff here
			;;
		# =============================================================
		"DNS: $MY_WORK_DNS")
			echo "my work"			# do work stuff here
			;;
		# =============================================================
		*)
			echo "DNS: someplace unknown (or off-network)"
			;;
		esac
} # end of doLocByDns

# =============================================================================
# * use airport command to get access point name
# =============================================================================
doLocByWifi() {
	# =========================================================================
	# sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/sbin/airport
	#
	# airport arguments:
	#	change channel (-c)
	#	disconnect (-z)
	#	get current connection info (-I)
	#	scan for Wi-Fi networks-s
	#
	# Also see networksetup :-)
	# =========================================================================
	AIRP=`airport -I | grep "\bSSID" | sed -e 's/^.*SSID: //'`
	for element in ${WIFIS[@]}				# go through nested array
	do
		the_loc="`eval echo \\\${$element[0]}`"
		the_net="`eval echo \\\${$element[1]}`"
		if [[ "$the_net" == "$AIRP" ]] ; then
			my_loc="$the_loc"				# remember our location for case
			echo "WIFI: $my_loc"
			break							# stop looping after a match
		fi
	done
} # end of doLocByWifi

# =============================================================================
# * guessing location by time-of-day (at work during daytime)
# =============================================================================
doLocByDateTime() {
	DHOUR=`date +'%H' | sed 's/0*//'`		# 00..24 (sed strip leading zero)
	# DHOUR=$((date +'%H')#0)				# fails to strip leading zero
	WDAY=$(date +'%u')						# 1..7 - see constants following:
		MONDAY=1
		FRIDAY=6
		SATURDAY=7
		SUNDAY=8

	# =================================================================
	if (( ( $WDAY >= $MONDAY && $WDAY <= $FRIDAY ) &&
		( $DHOUR >= $WORK_STARTS && $DHOUR <= $WORK_ENDS ) )) ;
	then
		echo "DATE: work (daytime weekday)"
		my_loc="$AT_WORK"

	# =================================================================
	elif (( ( $WDAY >= $MONDAY && $WDAY <= $FRIDAY ) &&
		( $DHOUR < $WORK_STARTS || $DHOUR > $WORK_ENDS ) )) ;
	then
		echo "DATE: home (weekday outside of working hours)"
		my_loc="$AT_HOME"

	# =================================================================
	elif (( $WDAY == SATURDAY || $WDAY == SUNDAY ))		# weekend
	then
		echo "DATE: home (weekend)"
		my_loc="$AT_HOME"

	# =================================================================
	else
		echo "DATE: someplace unknown"
	fi
} # end of doLocByDateTime

# =============================================================================
# =============================================================================
doLocationThings() {
	for element in "${LOCATION_DETERMINATION[@]}"
	do
		case "$element" in
			DNS) doLocByDns ;;
			WIFI) doLocByWifi ;;
			DATE) doLocByDateTime ;;
			*) echo "WARNING! Unknown determination method \"$element\"!" ;;
		esac
	done
	#############echo "my_loc \"$my_loc\" -- make a doHomeStuff(), doWorkStuff() ??"
} # end doLocationThings


# =============================================================================
# Do location-specific things if machine not on exclusion list.
# =============================================================================
doLocationThingsIfNotExcluded() {
		determineLocation=true						# default is to do check
		for element in "${SKIP_LOC_CHECK[@]}"		# iterate over HOSTNAMEs
		do
			if [[ $HOSTNAME =~ $element ]]; then	# if this HOSTNAME found
				determineLocation=false				# turn off location check
			fi
		done

		if $determineLocation ; then				# check HOSTNAME result
			doLocationThings						# do location things
		fi
} # end doLocationThings


# =============================================================================
# Do architecture-specific things.
# =============================================================================
doArchSpecifics() {
	archStr=$(arch)									# get machine architecture
	case "archStr" in								# do architecture-specifics
		# =====================================================================
		i386)										# including Mac
		;;

		# =====================================================================
		arm)										# including iPhone/i$ad
		;;
	esac # end archStr
}


# =============================================================================
# Do OS-specific things.
# =============================================================================
doOsSpecifics() {
	unameStr=$(uname)								# get OS name and
	case "$unameStr" in								# do OS-appropriate things
		# =====================================================================
		Darwin)										# Mac OS X

			alias dnsflush='sudo discoveryutil mdnsflushcache ; sudo discoveryutil udnsflushcaches'

			alias tca='echo `TZ=America/Los_Angeles date "+%H:%M %d/%m" ; echo $TZ`'

			# iPhone simulator is hidden for some strange reason
#			alias simu='open /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app'

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
			#
			## exiftool show tabular compilation of the GPS locations (-n in decimal)
			#
			alias erg="exiftool -n -filename -gpslatitude -gpslongitude -T"
			alias en="exiftool -all="
			alias mvmd5='mv ????????????????????????????????.* /Volumes/foobar/pix/'
			alias eee="pushd ~/Pictures/family/ ; er $GRAPHICS ; md5.bash $GRAPHICS ; mvmd5"

			# color
			#export LS_OPTIONS='--color=auto' # make ls colorful
			export CLICOLOR=1				# make ls colorful
			#export LSCOLORS='Bxgxfxfxcxdxdxhbadbxbx'	# use these colors
			export LSCOLORS='BxGxfxfxCxdxdxhbadbxbx'	# use these colors
			export TERM=xterm-color			# use color-capable termcap

			# general things, alphabetically
			alias ..="cd .."
			alias c="clear"
			alias cd..="cd .."
			alias e="exit"
			alias fixvol='sudo killall -9 coreaudiod'	# when volume buttons don't
			alias gs='git status'
			alias kurl='curl -#O'			# download and save w orig filename
			alias lastmaint="ls -al /var/log/*.out"	# when did we last tidy up?
			alias ll='ls -lAhF'				# ls w kb, mb, gb
			alias lock="open '/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app'"
			alias ls="ls -F"				# ls special chars
			alias maint="sudo periodic daily weekly monthly"	# tidy up :-)
			alias mydate='date +%Y%m%d_%H%M%S'		# more useful for sorting
			alias netspeed='time curl -o /dev/null http://wwwns.akamai.com/media_resources/NOCC_CU17.jpg'
			alias ps='ps -creo command,pid,%cpu | head -10'
			alias resizesb='sudo hdiutil resize -size '	# 6g BUNDLENAME'
			#alias ssh="ssh -X"				# enable X11 forwarding
			alias swap='swaps ; sudo dynamic_pager -L 1073741824 ; swaps' # force swap garbage collection
			alias swaps='ls -alh /var/vm/swapfile* | wc -l'	# how many swap files?

#			# Apache error logs
			alias ta='tail /usr/local/var/log/apache2/error_log'

			alias synctarot='rsync -avz "/Users/michael/Documents/Burning Man/2015/tarot/" "/Volumes/LaCie 500GB/tarot-backups"'
			alias syncpix='rsync -azP root@192.168.1.195:/var/mobile/Media/DCIM /Users/michael/Pictures/family/iph'

			POWERLINE_PATH=$(/usr/bin/python -c 'import pkgutil; print pkgutil.get_loader("powerline").filename' 2>/dev/null)
			if [[ "$POWERLINE_PATH" != "" ]]; then
				source ${POWERLINE_PATH}/bindings/bash/powerline.sh
			else
				setTermPrompt
			fi
  			;;

		# =====================================================================
		Linux)
			alias ls='ls --color --classify'	# make ls colorful
			today=`date "+%Y%m%d"`				# needed for logs
			alias ta="tail /etc/httpd/logs/${today}/error_log"
			;;

		# =====================================================================
		*) echo "NOTE: Unknown operating system \"unamestr\"!" ;;
	esac
} # end doOsSpecifics


# =============================================================================
# HOSTNAME-specific things
# =============================================================================
doHostThings() {
	# =========================================================================
	case "$HOSTNAME" in						# do HOSTNAME-specific things

		# =====================================================================
		michael.local)						# home machine
			# home-grown duplicate file deletion scheme ; ignore if you're not me :-)
			alias ldups='ls | wc -l ; rm -f ../filelist ; cksum *.jpg | sort -n > ../filelist ; ../rmdups ; ls | wc -l'
			alias mdups='ls | wc -l ; rm -f ../filelist ; cksum *.jpg | sort -n > ../filelist ; rmdups ; ls | wc -l'

			# to use alias add HOSTNAMEs and users to your ~/.ssh/config
			alias 11="ssh u76141767@s513372989.onlinehome.us" 	# 1and1.com

		;; # end michael.local case
	esac; # end HOSTNAME case

	# =========================================================================
	# Do more complicated tests to customize one way for multiple machines.
	# =========================================================================
	# work machine, on-line and off-line names
	if [ "$HOSTNAME" = 'msattler.sv.splunk.com' \
		-o "$HOSTNAME" = 'msattler.local' ] ;
	then
		S_CERTS='/Users/msattler/splunk/.chef'		# where I keep certs

		# =====================================================================
		# for GIT(hub)
		#export GIT_FULL_NAME='Michael Sattler'
		#export GIT_EMAIL='michael@sattlers.org'
		#export OPSCODE_USERNAME='msattler'
		#export OPSCODE_ORGANIZATION_NAME='msattler'

		# =====================================================================
	fi # end (michael.local)

	# =========================================================================
} # end doHostThings

# =============================================================================
# Take advantage of color terminal capabilities...
# =============================================================================
setTermColors() {
	if [ -t 1 ]; then						# set colors iff stdout is terminal
		ncolors=$(tput colors)				# ok terminal; does it do color?
		if test -n "$ncolors" && test $ncolors -ge 8; then
			# remember this method, which seems not to work on my machine...
			#bold="$(tput bold)"
			#underline="$(tput smul)"
			#standout="$(tput smso)"
			#normal="$(tput sgr0)"
			#black="$(tput setaf 0)"
			#red="$(tput setaf 1)"
			#green="$(tput setaf 2)"
			#yellow="$(tput setaf 3)"
			#blue="$(tput setaf 4)"
			#magenta="$(tput setaf 5)"
			#cyan="$(tput setaf 6)"
			#white="$(tput setaf 7)"

			# =================================================================
			# Color mnemonics for PS1 terminal prompt
			# =================================================================
			export BOLD='\[\033[1m\]'
			export BOLDOFF='\[\033[0m\]'
			#
			export NONE='\[\033[0m\]'
			export WHITE='\[\033[1;37m\]'
			export BLACK='\[\033[0;30m\]'
			export BLUE='\[\033[0;34m\]'
			export LIGHT_BLUE='\[\033[1;34m\]'
			export GREEN='\[\033[0;32m\]'
			export LIGHT_GREEN='\[\033[1;32m\]'
			export CYAN='\[\033[0;36m\]'
			export LIGHT_CYAN='\[\033[1;36m\]'
			export RED='\[\033[0;31m\]'
			export LIGHT_RED='\[\033[1;31m\]'
			export PURPLE='\[\033[0;35m\]'
			export LIGHT_PURPLE='\[\033[1;35m\]'
			export BROWN='\[\033[0;33m\]'
			export YELLOW='\[\033[1;33m\]'
			export GRAY='\[\033[1;37m\]'
			export LIGHT_GRAY='\[\033[0;37m\]'

			###echo -e "\033[0;31mRED \033[1;31mLIGHT_RED \033[0;33mBROWN \033[1;33mYELLOW \033[0;32mGREEN \033[1;32mLIGHT_GREEN \033[0;36mCYAN \033[1;36mLIGHT_CYAN \033[0;35mPURPLE \033[1;35mLIGHT_PURPLE \033[0;34mBLUE \033[1;34mLIGHT_BLUE \033[0;30mBLACK \033[1;37mGRAY \033[0;37mLIGHT_GRAY \033[1;37mWHITE"

		fi # end of if-terminal-supports-color
	fi # end of if-terminal
} # end setTermColors


# =============================================================================
# Set PROMPT, etc.
# =============================================================================
setTermPrompt() {
	if [ -t 1 ]; then						# set colors iff stdout is terminal
		ncolors=$(tput colors)				# ok terminal; does it do color?
		if test -n "$ncolors" && test $ncolors -ge 8; then

			# =================================================================
			# Change the color of the HOSTNAME part of the terminal prompt to
			# reflect the productionality & importantitude :-) of the host.
			#
			# Add a FQDN or regex into the arrays, orange or red.
			# =================================================================
			hostColor="${GREEN}"			# default color
			# staging & web-hosting machines; mid-level importance
			oranges=( 'stormdev' 'icpu2302' )
			# production machines; high-level importance
			reds=( '' )
		
			for element in "${oranges[@]}"	# check for orange machines
			do
				if [[ $HOSTNAME =~ $element ]]; then
					echo "orange $element"
					hostColor="${YELLOW}"	# 16 colors no orange :-/
				fi
			done
		
			for element in "${reds[@]}"		# check for red machines
			do
				if [[ $HOSTNAME =~ $element ]]; then
					hostColor="${RED}"
				fi
			done
		
			# =================================================================
			# Keep terminal prompt settings here and refactor for custom prompts
			# based upon location or hostname...
			#
			# So far this prompt pleases me globally.
			#
			# Change the terminal prompt to show current machine, command
			# number, and the user level (root = '#', normal = '$').
			# =================================================================
#			export PS1="${BOLD}${hostColor}\H ${BOLDOFF}${YELLOW}\! ${hostColor}\W ${NONE}\$ "
#			export PS1="${BOLD}${hostColor}${HOSTNAME%%.*} ${BOLDOFF}${YELLOW}\! ${hostColor}\W ${NONE}\$ "
			export PS1="${BOLD}${hostColor}${HOSTNAME%%.*} ${BOLDOFF}${BROWN}\! ${PURPLE}\W ${YELLOW}\$${NONE} "

		fi # end of if-terminal-supports-color
	fi # end of if-terminal
} # end setTermPrompt


# -----------------------------------------------------------------------------
# This is the end of the defined functions. The following is the main body.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Alias oft-used commands for all hosts, locations, etc.
# -----------------------------------------------------------------------------
alias cpbash='scp .bash_profile USERNAME_OVER_THERE@HOSTNAME:'
alias pd='pushd'							# see also 'popd'
alias python="python3"						# p3 libs incompat with p2
alias rmempty='find . -name .DS_Store -delete ; find . -type d -empty -delete'
alias sink='sync;sync;sync'					# write filesystem changes
alias vi='vim'								# colored vi editor

# -----------------------------------------------------------------------------
# for all UN*X history
# -----------------------------------------------------------------------------
alias h='history'							# see what happened before
HISTCONTROL=ignoreboth						# bash(1) don't add dups, etc.
HISTSIZE=1000								# bash(1) history command length
HISTFILESIZE=2000							# bash(1) history file size max
shopt -s histappend							# append, don't overwrite, history file
shopt -s checkwinsize						# after each command check window size...

# -----------------------------------------------------------------------------
# Run the functions defined above
# -----------------------------------------------------------------------------
doHostThings								# do host-specifics
doArchSpecifics								# do architecture-specifics
doOsSpecifics								# do OS-specifics
doLocationThingsIfNotExcluded				# do location-specifics
setTermColors								# set terminal colors
#setTermPrompt								# set the shell prompt

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
PATH=~/bin:$PATH							# find my stuff first
export PATH									# share and enjoy!
