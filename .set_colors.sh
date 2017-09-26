#!/usr/local/bin/bash					# search PATH to get bash ~ portable
#set -x

# -----------------------------------------------------------------------------
# Terminals now support color :-) Let's use them!
#
# https://github.com/mickeys/dotfiles/blob/master/.set_colors.sh
# -----------------------------------------------------------------------------
if ((BASH_VERSINFO[0] < 4)); then echo "Error: bash 4.0 or later needed; quitting." >&2; exit 1; fi
# shellcheck disable=SC2034
declare -A COLORS=( [BLACK]=0 [RED]=1 [GREEN]=2 [YELLOW]=3 [PURPLE]=4 [PINK]=5 [CYAN]=6 [WHITE]=7 )
declare CNAMES=( BLACK RED GREEN YELLOW PURPLE PINK CYAN WHITE )

setTermColors() {
	if [ -t 1 ]; then						# set colors iff stdout is terminal
		ncolors=$( tput colors )			# ok terminal; does it do color?
		# ---------------------------------------------------------------------
		# Color mnemonics for PS1 terminal prompt
		# ---------------------------------------------------------------------
		if test -n "$ncolors" && test $ncolors -ge 8; then

			export BOLD="$( tput bold )"
			export BOLDOFF="$( tput sgr0 )"

			export NONE="$( tput sgr0 )"
			export BLACK="$( tput setaf ${COLORS[BLACK]} )"
			export LIGHT_BLUE="$( tput setaf ${COLORS[BLUE]} )"
			export BLUE="$BOLD$LIGHT_BLUE"
			export LIGHT_GREEN="$( tput setaf ${COLORS[GREEN]} )"
			export GREEN="$BOLD$LIGHT_GREEN"
			export LIGHT_RED="$( tput setaf ${COLORS[RED]} )"
			export RED="$BOLD$LIGHT_RED"
			export LIGHT_PURPLE="$( tput setaf ${COLORS[PURPLE]} )"
			export PURPLE="$BOLD$LIGHT_PURPLE"
			export YELLOW="$( tput setaf ${COLORS[YELLOW]} )"
			export GRAY="$( tput setaf ${COLORS[WHITE]} )"
			export WHITE="$BOLD$GRAY"

		else

			export BOLD='\033[1m'
			export BOLDOFF='\033[0m'
			#
			export NONE='foo \033[0m'
			export WHITE='\033[1;37m'
			export BLACK='\033[0;30m'
			export BLUE='\033[0;34m'
			export LIGHT_BLUE='\033[1;34m'
			export GREEN='\033[0;32m'
			export LIGHT_GREEN='\033[1;32m'
			export CYAN='\033[0;36m'
			export LIGHT_CYAN='\033[1;36m'
			export RED='\033[0;31m'
			export LIGHT_RED='\033[1;31m'
			export PURPLE='\033[0;35m'
			export LIGHT_PURPLE='\033[1;35m'
			export BROWN='\033[0;33m'
			export YELLOW='\033[1;33m'
			export GRAY='\033[1;37m'
			export LIGHT_GRAY='\033[0;37m'

		fi # end of if-terminal-supports-color
	else
		echo "$0: not a terminal"
	fi # end of if-terminal
} # end setTermColors

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
showColorsSimple() {
	for i in {0..7}
		do
			human="${CNAMES[$i]}"
			printf "$(tput setaf $i) $human $BOLD $human $(tput sgr0)\n"
		done
}

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
showColorsComplex() {
#	for i in {0..7}
#	do
#		for j in {0..7}
#		do
#			human=$( printf "%s on %s" "${CNAMES[$i]}" "${CNAMES[$j]}" )
#			printf "%s%s%-16s%s%-16s%s\n" $(tput setaf $i) $(tput setab $j) \
#				"$human" $(tput bold) "$human" $( tput sgr0 )
#		done
#	echo
#	done
#
#	echo '------'
#
	for i in {0..7}
	do
		for j in {0..7}
		do
			human=$( printf "%s on %s" "${CNAMES[$i]}" "${CNAMES[$j]}" )
###			printf "$(tput setaf $i) $(tput setab $j) %-15s $(tput bold) %-15s $(tput rev) REV %-15s $(tput sgr0)\n" $i $i $i

			printf "%s%s%-16s%s%-16s %s REV %-16s%s\n" $(tput setaf $i) $(tput setab $j) \
				"$human" $(tput bold) "$human" \
				$(tput rev) "$human" $(tput sgr0)
		done
	echo
	done

#
#	for i in {0..7}
#	do
#		for j in {0..7}
#		do
#			echo -n '-'
##			human="${c[$i]} on ${c[$j]}"
###			printf "$(tput setaf $i) $(tput setab $j) %-15s $(tput bold) %-15s $(tput rev) REV %-15s $(tput sgr0)\n" $i $i $i
##			echo "$(tput setaf $i) $(tput setab $j) $i $(tput bold) $i $(tput rev) REV $i $(tput sgr0)"
#		done
#		echo
#	done
	echo "$BOLDOFF"
}
