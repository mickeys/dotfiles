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
#			export PS1="${BOLD}${hostColor}\H ${BOLDOFF}${YELLOW}\! ${hostColor}\W ${NONE}\$ "
#			export PS1="${BOLD}${hostColor}${HOSTNAME%%.*} ${BOLDOFF}${YELLOW}\! ${hostColor}\W ${NONE}\$ "
			export PS1="${BOLD}${hostColor}${HOSTNAME%%.*} ${BOLDOFF}${BROWN}\! ${PURPLE}\W ${YELLOW}\$${NONE} "

		fi # end of if-terminal-supports-color
	fi # end of if-terminal
} # end setTermPrompt
