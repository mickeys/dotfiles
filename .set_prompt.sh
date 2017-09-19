#!/usr/bin/env bash							# search PATH to get bash ~ portable

# =============================================================================
# Configure bash's command prompt to display useful information *and* to be in
# color.
#
# https://github.com/mickeys/dotfiles/blob/master/.set_prompt.sh
# =============================================================================
dir="${BASH_SOURCE%/*}"						# pointer to this script's location
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi	# if not exist use current PWD
. "$dir/.set_colors.sh"						# we refer to colors below...
setTermColors
showColors() {
#			export BOLD='\[\033[1m\]'
#			export BOLDOFF='\[\033[0m\]'
			#
			echo "FOO $NONE NONE $WHITE WHITE $BLACK BLACK $BLUE BLUE $LIGHT_BLUE LIGHT_BLUE $GREEN GREEN $LIGHT_GREEN LIGHT_GREEN $CYAN CYAN $LIGHT_CYAN LIGHT_CYAN $RED RED $LIGHT_RED LIGHT_RED $PURPLE PURPLE $LIGHT_PURPLE LIGHT_PURPLE $BROWN BROWN $YELLOW YELLOW $GRAY GRAY $LIGHT_GRAY LIGHT_GRAY "
}

setTermPrompt() {
#	if [ $( tput colors ) != "" ]; then echo "terminal" ; else echo "not terminal" ; fi

	if [ $( tput colors ) != "" ]; then		# set colors if capable
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

			for fqdn in "${oranges[@]}"	# check for orange machines
			do
				if [[ $HOSTNAME =~ $fqdn ]]; then
					echo "orange $fqdn"
					hostColor="${YELLOW}"	# 16 colors no orange :-/
				fi
			done

			for fqdn in "${reds[@]}"		# check for red machines
			do
				if [[ $HOSTNAME =~ $fqdn ]]; then
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
			# Turn the prompt symbol red if the user is root
			if [ $(id -u) -eq 0 ];
			then # you are root, make the prompt red
				#PS1="[\e[01;34m\u @ \h\e[00m]----[\e[01;34m$(pwd)\e[00m]\n\e[01;31m#\e[00m "
				_prmt="${RED} #"
			else
				#PS1="[\e[01;34m\u @ \h\e[00m]----[\e[01;34m$(pwd)\e[00m]\n$ "
				_prmt="${GREEN} %"
			fi
##			export PS1="${BOLD}${hostColor}\H ${BOLDOFF}${YELLOW}\! ${hostColor}\W ${NONE}\$ "
##			export PS1="${BOLD}${hostColor}${HOSTNAME%%.*} ${BOLDOFF}${YELLOW}\! ${hostColor}\W ${NONE}\$ "
##			export PS1="${BOLD}${hostColor}${HOSTNAME%%.*} ${BOLDOFF}${BROWN}\! ${PURPLE}\w ${YELLOW}\$${NONE} "
#			_time="${YELLOW}\A"
#			_hist="${BLUE}\!"
#			_host="${hostColor}${HOSTNAME%%.*}" # ${BOLD}${BOLDOFF}
#			_path="${CYAN}\w"
##			_shel="${YELLOW}\$$"
##			export PS1="${_host} ${_numb} ${_dir_} ${_shel} ${NONE} "
##			export PS1="${YELLOW}\A ${CYAN}\! ${GREEN}\h ${LIGHT_GRAY}\w ${WHITE}% ${NONE}"
#			export PS1="${_time} ${_hist} ${_host} ${_path}${_prmt} ${NONE}"

if ((BASH_VERSINFO[0] < 4)); then echo "Error: bash 4.0 or later needed; quitting." >&2; exit 1; fi
# shellcheck disable=SC2034
declare -A COLORS=( [BLACK]=0 [RED]=1 [GREEN]=2 [YELLOW]=3 [PURPLE]=4 [PINK]=5 [BLUE]=6 [GREY]=7 )
			export BOLD="$(tput bold)"
			export BOLDOFF="$(tput sgr0)"

			_time="$(tput setaf ${COLORS[YELLOW]})\A"
			_hist="$(tput setaf ${COLORS[PINK]})\!"
			_host="${hostColor}${HOSTNAME%%.*}" # ${BOLD}\w${BOLDOFF}
			_path="$(tput setaf ${COLORS[PURPLE]})\w"

			export PS1=".set_prompt.shX ${_time} ${_hist} ${_host} ${_path}${_prmt}$BOLDOFF "

		fi # end of if-terminal-supports-color
	fi # end of if-terminal
set +x
} # end setTermPrompt
