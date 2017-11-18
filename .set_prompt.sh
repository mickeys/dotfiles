#!/usr/bin/env bash							# search PATH to get bash ~ portable
#set -x

prompt_color=''								# initialize

u_x=$'\342\234\227'							# unicode '✗'
u_cmark=$'\342\234\223'						# unicode '✓'
u_ellipsis=$'\u2026'						# unicode '…'
u_gt=$'\u27E9'								# unicode '⟩'

export GIT_PS1_SHOWDIRTYSTATE=1				# show unstaged '*' & staged '+' changes
export GIT_PS1_SHOWCOLORHINTS=1				# show color if nonempty value
export GIT_PS1_SHOWUNTRACKEDFILES=1			# show untracked '%'
export GIT_PS1_SHOWUPSTREAM="auto"			# '<' behind '>' ahead '<>' diverged '=' no difference
export GIT_PS1_HIDE_IF_PWD_IGNORED=1		# do nothing if cwd ignored by git

if ((BASH_VERSINFO[0] < 4)); then echo "Error: bash 4.0 or later needed; quitting." >&2; exit 1; fi
# shellcheck disable=SC2034
declare -A COLORS=( [BLACK]=0 [RED]=1 [GREEN]=2 [YELLOW]=3 [PURPLE]=4 [PINK]=5 [BLUE]=6 [GREY]=7 )
# get at the COLORS array by: ${COLORS[YELLOW]}
BOLD="\[$(tput bold)\]"
BOLDOFF="\[$(tput sgr0)\]"

# =============================================================================
# Configure bash's command prompt to display useful information *and* to be in
# color.
#
# https://github.com/mickeys/dotfiles/blob/master/.set_prompt.sh
# =============================================================================
dir="${BASH_SOURCE%/*}"						# pointer to this script's location
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi	# if not exist use current PWD
. "$dir/.set_colors.sh"						# we refer to colors below...
setTermColors								# actually set the colors

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
showColors() {								# for debugging
	echo "FOO $NONE NONE $WHITE WHITE $BLACK BLACK $BLUE BLUE $LIGHT_BLUE LIGHT_BLUE $GREEN GREEN $LIGHT_GREEN LIGHT_GREEN $CYAN CYAN $LIGHT_CYAN LIGHT_CYAN $RED RED $LIGHT_RED LIGHT_RED $PURPLE PURPLE $LIGHT_PURPLE LIGHT_PURPLE $BROWN BROWN $YELLOW YELLOW $GRAY GRAY $LIGHT_GRAY LIGHT_GRAY "
}

# -----------------------------------------------------------------------------
# make color-space color escape codes given fg|bg and a color value
# -----------------------------------------------------------------------------
c8() {
	if [[ ${#@} -ne 2 ]] ; then
	echo "got $@"
		echo "usage: $0 fg|bg color_code" ; exit
	elif [ "$1" == "bg" ] ; then mode='b' ; else mode='f' ; fi
	echo "\[$(tput set${mode} ${2} )\]"
}


c256() {									# usage c256 fg|bg #
	if [[ ${#@} -ne 2 ]] ; then
		echo "usage: $0 fg|bg color_code" ; exit
	elif [ "$1" == "bg" ] ; then mode='48' ; else mode='38' ; fi

	echo "\[\e[${mode};5;${2}m\]"			# nicely-bracketed escape code
}

setTermPrompt() {
	if [ $( tput colors ) != "" ]; then		# set colors if capable
		ncolors=$(tput colors)				# ok terminal; does it do color?
		if test -n "$ncolors" && test $ncolors -ge 8; then

			# =================================================================
			# Change the color of the HOSTNAME part of the terminal prompt to
			# reflect the productionality & importantitude :-) of the host.
			#
			# Add a FQDN or regex into the arrays, orange or red.
			# =================================================================
			hostColor="$(c8 fg ${COLORS[GREEN]})"	# default color
			# staging & web-hosting machines; mid-level importance
			oranges=( 'stormdev' 'icpu2302' )
			# production machines; high-level importance
			reds=( '' )

			for fqdn in "${oranges[@]}"	# check for orange machines
			do
				if [[ $HOSTNAME =~ $fqdn ]]; then
					echo "orange $fqdn"
					hostColor="$(c8 fg ${COLORS[YELLOW]})"	# 16 colors no orange :-/
				fi
			done

			for fqdn in "${reds[@]}"		# check for red machines
			do
				if [[ $HOSTNAME =~ $fqdn ]]; then
					hostColor="$(c8 fg ${COLORS[RED]})"
				fi
			done

			local last_cmd=$?				# result of the last command run

			# colors for each component, from the 256 color set
			# darkest (higher number) to lightest (lower number) in palette
			# https://jonasjacek.github.io/colors/
			BG1='241' ; BG2='239' ; BG3='236' ; BG4='232' ; BG5='0'
			BG1_2='240' ; BG2_3='238' ; BG3_4='238'
			FG1='231'


			BG1='248' ; BG2='246' ; BG3='244' ; BG4='242' ; BG5='240'
			BG1_2='247' ; BG2_3='245' ; BG3_4='243'

			BG1='250' ; BG2='248' ; BG3='246' ; BG4='244' ; BG5='242'
			BG1_2='249' ; BG2_3='247' ; BG3_4='245'

#_t_="$( c256 bg "$BG1" ) BG1"
#echo -e "$( c256 bg "$BG1" )$( c256 fg "232" ) this is a test ${BOLD}another test${BOLDOFF}"



			PS1=""							# start with an empty prompt string

			PS1+="$( c256 bg "$BG3" ) "		# lay down a background color

			# -------------------------------------------------------------------------
			# show a red '✗' or a green '✓' and previous command return code.
			# -------------------------------------------------------------------------
			if [[ $last_cmd == 0 ]]; then	# if return code shows success...
#				PS1+="$(c8 fg ${COLORS[GREEN]})"
				PS1+="${BOLD}$( c256 fg "46" )" # Green1
				PS1+="${BOLD}"
				PS1+="$u_cmark"				# display a green '✓'...
				PS1+="${BOLDOFF}"
			else							# otherwise...
#				PS1+="$(c8 ${COLORS[RED]})"
				PS1+="${BOLD}$( c256 fg "196" )" # Red1
				PS1+="${BOLD}"
				PS1+="$u_x $last_cmd"		# display a red '✗'
				PS1+="${BOLDOFF}"
			fi

			PS1+="$( c256 bg "$BG1_2" ) "	# interim color

			# -------------------------------------------------------------------------
			PS1+="${BOLD}$( c256 fg "232" )"
			PS1+="$( c256 bg "$BG1" ) \A"	# time stamp
			PS1+="$( c256 bg "$BG1_2" ) "	# interim color
			PS1+="$( c256 bg "$BG2" ) \!"	# history number
			PS1+="$( c256 bg "$BG2_3" ) "	# interim color
			if [ "${HOSTNAME%%.*}" != "michael" ] ; # don't show hostname on my usual box
			then
				PS1+="$( c256 bg "$BG3" ) $(c8 fg ${hostColor})${HOSTNAME%%.*}" # hostname
			fi
			PS1+="$( c256 bg "$BG3_4" ) "	# interim color

			# -------------------------------------------------------------------------
			# current working directory
			# -------------------------------------------------------------------------
			local -r depth=3				# show the last n dirs deep
			local mypath="$u_ellipsis/"		# start truncated path with '…'
			local sep='/'					# separate path with this '/'
#			local sep="$( c256 fg "$BG1" )$u_gt$( c256 fg "232" )"

			IFS=/ read -a p <<< "$PWD"
			lp=${#p[@]}						# pwd is n directories deep
			if [[ $lp > $depth ]] ; then	# do we need to truncate?
				for (( i=$((lp-depth)); i<lp; i++ )); do mypath+="${p[$i]}$sep" ; done
			else
				mypath="$PWD"				# not deep; show full path
			fi

			# -------------------------------------------------------------------------
			PS1+="$(c8 fg ${COLORS[GREEN]})"
			PS1+=" $mypath"					# current path (was \w)

			# -------------------------------------------------------------------------
			# Run $PROMPT_COMMAND each time before displaying the prompt.
			# -------------------------------------------------------------------------
#			export PROMPT_COMMAND='export _branch=$( __git_ps1 "[%s]" )'
			export PROMPT_COMMAND='setTermPrompt'
			_branch=$( __git_ps1 "[%s]" )
			PS1+=" ${_branch} "
			PS1+="$( c256 bg "$BG1" )$( c256 fg "$BG5" )"
			PS1+="▶\[${BOLDOFF}\] ${_prmt} "
			export PS1

		fi # end of if-terminal-supports-color
	fi # end of if-terminal
} # end setTermPrompt

#PROMPT_COMMAND='setTermPrompt'				# run this to generate the prompt