#!/bin/bash							# search PATH to get bash ~ portable
#set -x
# -----------------------------------------------------------------------------
# Terminals now support color :-) Let's use them!
#
# https://github.com/mickeys/dotfiles/blob/master/.set_colors.sh
# -----------------------------------------------------------------------------
setTermColors() {
	if [ -t 1 ]; then						# set colors iff stdout is terminal
		ncolors=$( tput colors )			# ok terminal; does it do color?
		if test -n "$ncolors" && test $ncolors -ge 8; then
			# -----------------------------------------------------------------
			# Color mnemonics for PS1 terminal prompt
			# -----------------------------------------------------------------
#			export BOLD='\033[1m'
#			export BOLDOFF='\033[0m'
#			#
#			export NONE='foo \033[0m'
#			export WHITE='\033[1;37m'
#			export BLACK='\033[0;30m'
#			export BLUE='\033[0;34m'
#			export LIGHT_BLUE='\033[1;34m'
#			export GREEN='\033[0;32m'
#			export LIGHT_GREEN='\033[1;32m'
#			export CYAN='\033[0;36m'
#			export LIGHT_CYAN='\033[1;36m'
#			export RED='\033[0;31m'
#			export LIGHT_RED='\033[1;31m'
#			export PURPLE='\033[0;35m'
#			export LIGHT_PURPLE='\033[1;35m'
#			export BROWN='\033[0;33m'
#			export YELLOW='\033[1;33m'
#			export GRAY='\033[1;37m'
#			export LIGHT_GRAY='\033[0;37m'

if ((BASH_VERSINFO[0] < 4)); then echo "Error: bash 4.0 or later needed; quitting." >&2; exit 1; fi
# shellcheck disable=SC2034
declare -A COLORS=( [BLACK]=0 [RED]=1 [GREEN]=2 [YELLOW]=3 [PURPLE]=4 [PINK]=5 [BLUE]=6 [GREY]=7 )

			export BOLD="$(tput bold)"
			export BOLDOFF="$(tput sgr0)"
			#
			export NONE="$(tput sgr0)"
			export WHITE="${COLORS[WHITE]}"
			export BLACK="${COLORS[BLACK]}"
			export LIGHT_BLUE="${COLORS[BLUE]}"
			export BLUE="$BOLD$LIGHT_BLUE"
			export LIGHT_GREEN="${COLORS[GREEN]}"
			export GREEN="$BOLD$LIGHT_GREEN"
			export LIGHT_RED="${COLORS[RED]}"
			export RED="$BOLD$LIGHT_RED"
			export LIGHT_PURPLE="${COLORS[PURPLE]}"
			export PURPLE="$BOLD$LIGHT_PURPLE"
			export YELLOW="${COLORS[YELLOW]}"
			export LIGHT_GRAY="${COLORS[GRAY]}"
			export GRAY="$BOLD$LIGHT_GRAY"

			# -----------------------------------------------------------------
			# Uncomment the following to see each of the colors displayed.
			# -----------------------------------------------------------------
			 #echo -e "\033[0;31mRED \033[1;31mLIGHT_RED \033[0;33mBROWN\033[1;33mYELLOW \033[0;32mGREEN \033[1;32mLIGHT_GREEN\033[0;36mCYAN \033[1;36mLIGHT_CYAN \033[0;35mPURPLE\033[1;35mLIGHT_PURPLE \033[0;34mBLUE \033[1;34mLIGHT_BLUE\033[0;30mBLACK \033[1;37mGRAY \033[0;37mLIGHT_GRAY\033[1;37mWHITE"

		else
			echo "$0: color not supported"
		fi # end of if-terminal-supports-color
	else
		echo "$0: not a terminal"
	fi # end of if-terminal
} # end setTermColors