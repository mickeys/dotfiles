#!/usr/bin/env bash

# +------------------------+---------------------------------------------------
# .                        . This is a basic .bash_profile for Credit Karma. It
# .            `:-         . covers configuration for both local (laptop) and
# .            ./:         . remote hosts (CKVM & UAT).
# .     `...`  ./:     --` .
# .  `://:-::: ./:   `:/:  . Clone this file, test it by `source .bash_ck`, and
# . `//-       ./:  .//-   . when you're sure it's right for you, symlink it to
# . .//        ./:.://`    . your home by `ln -s .bash_ck .bash_profile`.
# . `//.       .///::/:`   .
# .  -//:...-: .//`  -//`  .
# .    .-::--. `--    .--` . Find me at https://github.com/mickeys/dotfiles/ or
# .                        . code.corp.creditkarma.com/michael-sattler-ck/dotfiles/
# +------------------------+---------------------------------------------------

#set -x										# toggle debugging verbosity
# github.com/koalaman/shellcheck is used to bomb-proof this (and other) scripts
# shellcheck disable=1090,1091				# tell shellcheck source script URLs
#set -u o pipefail							# unofficial bash strict mode

# =============================================================================
# User-specific settings broken out to keep secret things safe.
# =============================================================================
_MY_SECRETS="$HOME/.my_ck_secrets"
if [ -e "$_MY_SECRETS" ] ; then
	# shellcheck source=/Users/michael.sattler/.my_ck_secrets
	source "$_MY_SECRETS"
else
	echo "Configuration file \"$_MY_SECRETS\" not found."
fi

# =============================================================================
# Aliases, alphabetically
# =============================================================================
export BLOCKSIZE=1k							# default blocksize for ls, df, du

alias c='clear'								# clear terminal screen
alias df='df -h'							# show human-readable sizes
alias du='du -ch'							# human-readable with grand total
alias dv='dirs -v'							# show directory stack in rows
alias j='jobs -l'							# show background tasks (jobs)
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | $PAGER' # lr ~ fully-recursive directory listing
alias pd='pushd'							# manipulate directory stack
alias pv='echo -e ${PATH//:/\\n} | sort | uniq' # show $PATH one line per entry
alias td='pushd $(mktemp -d)'				# create a temp dir and pushd to it
alias wget='wget -c'						# resume transfers by default

# =============================================================================
# UN*X command history
# =============================================================================
alias h='history'							# see what happened before
HISTCONTROL=ignoredups:erasedups:ignorespace:ignoreboth # no dups;
HISTFILE=~/.bash_eternal_history			# "eternal" ~ don't get truncated
# was eternal (empty); now set at 999 (three digits easier to grok)
HISTFILESIZE=999							# "eternal" ~ no max size
HISTSIZE=999								# "eternal" ~ no max size
HISTTIMEFORMAT="[%m-%d %H:%M] "				# add 24-hour timestamp to history
shopt -s checkwinsize						# after each command check window size...
shopt -q -s histappend >/dev/null 2>&1		# append, don't overwrite, history file
export PROMPT_COMMAND='history -a' >/dev/null 2>&1

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

# =============================================================================
# GNU core utilities (coreutils) (via homebrew)
# =============================================================================
if command -v gls >& /dev/null ; then		# GNU coreutils are installed
	# -------------------------------------------------------------------------
	# coreutils default settings
	# -------------------------------------------------------------------------
	if command -v gdircolors > /dev/null ; then
		export COLUMNS						# remember columns for subprocesses
		eval "$(gdircolors)"				# activate default color database
	fi
	alias ls='gls --classify --almost-all --color'
	alias ll='gls -l --no-group --human-readable --classify --almost-all --color=auto -v --time-style=long-iso'
else
	# -------------------------------------------------------------------------
	# mimic coreutils as much as possible with built-ins
	# -------------------------------------------------------------------------
	if tput colors ne "-1" &> /dev/null ; then
		export CLICOLOR=1					# make ls colorful
		export LSCOLORS='BxGxfxfxCxdxdxhbadbxbx'
		export TERM=xterm-color				# use color-capable termcap
	fi
	alias ls='ls -AhF'						# long listing, some hiddens
	alias ll='ls -lAhF'						# kb, mb, gb; hiddens; classified
fi

# =============================================================================
# ffmpeg
# =============================================================================
if command -v ffmpeg &> /dev/null ; then
	# -------------------------------------------------------------------------
	# concatenate mp3s
	# -------------------------------------------------------------------------
	alias mp3cat='ffmpeg -f concat -safe 0 -i <(for f in ./*.mp3; do echo "file $PWD/$f"; done) -c copy concatenated.mp3'

	# -------------------------------------------------------------------------
	# Convert "HH:MM:SS" into seconds; used below for ffmpeg.
	# -------------------------------------------------------------------------
	ts2sec() { s=(${1//:/ }) ; ss=$(((${s[0]}*60*60)+(${s[1]}*60)+${s[2]})) ; echo $ss ;}

	# -------------------------------------------------------------------------
	# vsplit "original.mp4" segment_span_in_seconds # "$(( 1*59 ))"
	# -------------------------------------------------------------------------
	#vsplit() { segment_time=$( gdate -d@${2} -u +%H:%M:%S ) ; ffmpeg -i "$1" -c:v libx264 -crf 22 -map 0 -segment_time $segment_time -g 9 -sc_threshold 0 -force_key_frames "expr:gte(t,n_forced*9)" -reset_timestamps 1 -f segment segment_%03d.mp4 ; }
	vsplit() { SRC="$1" ; SPAN=$( gdate -d@${2} -u +%H:%M:%S ) ; ffmpeg -i "$SRC" -c:v libx264 -crf 22 -map 0 -segment_time $SPAN -g 9 -sc_threshold 0 -force_key_frames "expr:gte(t,n_forced*9)" -reset_timestamps 1 -f segment "segment_%03d.${SRC##*.}" ; }

	# -------------------------------------------------------------------------
	# vseg "movie.mp4" "00:00:09" "00:00:12"
	# 1. ffmpeg force key-frames for the requested segment
	# 2. ffmpeg accurately cut the segment without re-encoding
	# -------------------------------------------------------------------------
	#ts2sec() { gdate -d"$1" +%s; }	# timestamp "HH:MM:SS" to seconds
	#vseg() { local SRC="$1" ; local START="$2" ; local END="$3" ; local SPAN="$(($( ts2sec "$END" )-$( ts2sec "$START" ) ))" ; local OUT="${START//:/_} to ${END//:/_}.${SRC##*.}" ; ffmpeg -i "$SRC" -force_key_frames $START,$END wip.mp4 ; ffmpeg -ss $START -i wip.mp4 -t $SPAN -vcodec copy -acodec copy -y "$OUT" ; ls -l "$SRC" wip.mp4 "$OUT" ; }

	# -------------------------------------------------------------------------
	# Accurately cut a segment from a video with two passes of ffmpeg.
	#
	# Usage: vseg movie.mp4 start_timestamp end_timestamp
	# -------------------------------------------------------------------------
	vseg() {
		# Put the supplied parameters into easier-to-read variables.
		SRC="$1" ; START="$2" ; END="$3"

		# Calculate the segment time (in seconds) requested.
		SPAN="$(($( ts2sec "$END" )-$( ts2sec "$START" ) ))"

		# Generate an output filename in macOS-friendly format; replace the
		# colons with underscores and use the same filename  extension as the
		# source video such that an input of "vseg movie.mp4 00:00:00 00:01:00"
		# results in an output filename # of "00_00_00 to 00_01_00.mp4".
		OUT="${START//:/_} to ${END//:/_}.${SRC##*.}"

		# Generate a temporary working file; add the approprite suffix.
		T="$(mktemp video_XXXX)" || exit 1
		WIP="$T.${SRC##*.}"
		mv "$T" "$WIP"

		# Force regeneration of key frames within the desired segment to enable
		# an exact segment cut (with the next command); place into $WIP.
		ffmpeg -i "$SRC" -force_key_frames "$START,$END" -y "$WIP"

		# Cut exactly the segment requested into $OUT.
		ffmpeg -ss "$START" -i "$WIP" -t "$SPAN" -vcodec copy -acodec copy -y "$OUT"

		# Remove the work-in-progress file. List the input and output files.
		rm "$WIP"
		ls -l "$SRC" "$OUT"
	}

# =============================================================================
# Miscellaneous common things.
# =============================================================================
if command -v less &> /dev/null ; then export PAGER='less' ; else export PAGER='more' ; fi

mkcd() { if [ $# != 1 ]; then echo "Usage: mkcd DIR" else mkdir -p "$1" && pushd "$1" || exit; fi }
up() { cd "$(eval printf '../'%.0s '{1..$1}')" || exit ; } # go up $1 number of directories

export IGNOREEOF="2"						# must ctrl-D twice to exit shell

# =============================================================================
# Determine whether you're on a local or remote (vagrant) instance.
# =============================================================================
if [[ $HOSTNAME == ip-* ]] ; then			# vagrant hosts = 'ip-12-34-56-78'

	#.,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``#
	#																		  #
	#		Vagrant (remote) host environment configuration section.		  #
	#																		  #
	#``°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸#

	# -------------------------------------------------------------------------
	# Show elapsed time of last shell command as part of the prompt string.
	# -------------------------------------------------------------------------
	function timer_start { timer=${timer:-$SECONDS} ; }
	function timer_stop { export timer_show=$((SECONDS - timer)) ; unset timer ; }
	trap 'timer_start' DEBUG

	if [ -n "${PROMPT_COMMAND:-}" ]; then
		PROMPT_COMMAND="$PROMPT_COMMAND; timer_stop"
	else
		PROMPT_COMMAND="timer_stop"
	fi

	# -------------------------------------------------------------------------
	# Set the terminal prompt.
	# -------------------------------------------------------------------------
	__h=${HOSTNAME#*-}						# preserve everything after first '-'
	__g=${__h//-/.}							# substitute '-' with '.'

	# shellcheck disable=SC2016				# we really need the variable name
	_TIMER='${timer_show}s'					# single-quotes important here!
	_ELAPS="\[\033[38;5;248m\]$_TIMER$(tput bold)\]"
	_HOST="\[\033[38;5;1m\]${__g}\[$(tput sgr0)\]"
	_DIR="\[\033[38;5;248m\]\W\[$(tput sgr0)\]"
	_BRANCH="\[\033[01;31m\]$(git branch 2>/dev/null | cut -f2 -d\* -s)\[\033[01;32m\]"
	_PROMPT="\[\033[38;5;2m\]\\$\[$(tput sgr0)\]"

	export PS1="$_ELAPS $_HOST $_DIR $_BRANCH $_PROMPT "

else

	#.,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``°º¤ø.¸,ø¤º°``#
	#																		  #
	#		Local (laptop) host environment configuration section.			  #
	#																		  #
	#``°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸¸,ø¤º°`°º¤ø,¸#

	alias rs='rsync -av --progress'

	alias wss='while true ; do /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep CtlRSSI; sleep 0.5; done'
	alias woff='networksetup -setairportpower en0 off'
	alias won='networksetup -setairportpower en0 on'
	alias wls='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport scan'
	alias wjoin='networksetup -setairportnetwork en0' #  WIFI_SSID WIFI_PASSWORD

	# macOS audio levels
	alias mute='sudo osascript -e "set Volume 0"'
	alias loud='sudo osascript -e "set Volume 10"'
	alias quiet='sudo osascript -e "set Volume 3"'

	# macOS video levels
	if command -v brightness > /dev/null ; then	# if brew brightness is installed
		alias bright='brightness 1.0'
		alias dim='brightness 0.3'
		alias black='brightness 0.1'
		alias howbright='brightness -l'
	fi

	# -------------------------------------------------------------------------
	# git version control system (git-scm.com)
	#
	# see also: http://nuclearsquid.com/writings/git-tricks-tips-workflows/
	# and also: http://durdn.com/blog/2012/11/22/must-have-git-aliases-advanced-examples/
	#
	# also don't forget to:
	# git config --global alias.loa 'log --graph --oneline --all' # visualization alias
	# -------------------------------------------------------------------------
	complete -o default -o nospace -F _git g # autocomplete for 'g' as well
#	ga() { git add "$1" ; }				# add files to be tracked
	gc() { git commit -m "$@" ; }			# commit changes locally
	keysx() { tr '[:upper:]' '[:lower:]' < "$1" | sort | uniq | wc -l ; }

	alias g='git'							# save 66% of typing
	alias ga='git add'
	alias gb='git branch'					# so many parallel universes :-)
	alias gd='git difftool'					# see what happened
	alias gh='git log --follow '			# git history for a file
	alias gi='git check-ignore -v *'		# see what's being ignored
#	alias gl='git log --pretty=format:" ~ %s (%cr)" --no-merges'
	alias gl='git log --no-merges --date=short --pretty=format:"| %cd | %s [%an]"'
	alias go='git remote show origin'
#	alias gp='git push -u origin master'	# send changes upstream
	alias gp='git push origin HEAD'			# send changes upstream
	alias gs='git status'					# summarize; you may like --short
	alias gsl='git stash list'				# git-stash(1)
	alias gsp='git stash pop'				# git-stash(1)
	alias gss='git stash save'				# git-stash(1)

	# -------------------------------------------------------------------------
	# node package manager (npm)
	# -------------------------------------------------------------------------
	if command -v npm > /dev/null ; then	# if npm is installed
		alias gqlserv="pushd \$HOME/git-repos/ck/cinf_graphiql-app/ ; npm run hot-dev-server"
		alias gql="pushd \$HOME/git-repos/ck/cinf_graphiql-app/ ; npm run start-hot"
	fi

	# -------------------------------------------------------------------------
	# Homebrew macOS package manager (brew.sh)
	# -------------------------------------------------------------------------
	if command -v brew > /dev/null ; then	# if homebrew is installed
		alias brewski='brew -v update && brew -v upgrade && brew -v cleanup; brew -v doctor'
		alias brew_installed='brew leaves'	# top-level installed packages
		alias brew_versions='brew list --versions'
		export PATH="/usr/local/bin:$PATH"
		_BREW=1								# remember: homebrew is installed
	else
		unset _BREW							# remember: homebrew not installed
	fi

	# -------------------------------------------------------------------------
	# MySQL (via homebrew)
	# -------------------------------------------------------------------------
	export _MYSQL='/usr/local/opt/mysql@5.6/'
	if [ -e "$_MYSQL" ] ; then
		export PATH="${_MYSQL}/bin:$PATH"	# find executables
		export LDFLAGS="-L${_MYSQL}/lib"	# for compilers
		export CPPFLAGS="-I${_MYSQL}/include"

		alias mysql='mysql -uroot'	# connect
		alias mysql_start='${_MYSQL}/bin/mysql.server start' # start manually
		# brew services start mysql@5.6		# start automatically
	else
		unset _MYSQL						# not installed? not needed!
	fi

	# -------------------------------------------------------------------------
	# Emacs text editor
	# -------------------------------------------------------------------------
	_EMACS='/Applications/Emacs.app/Contents/MacOS/Emacs'
	if [ -e "$_EMACS" ] ; then
		alias e="$_EMACS -nw"
	fi

	# -------------------------------------------------------------------------
	# OpenSSL (via homebrew)
	#
	# A CA file has been bootstrapped using certificates from the SystemRoots
	# keychain. To add additional certificates (e.g. the certificates added in
	# the System keychain), place .pem files in /usr/local/etc/openssl/certs and
	# run openssl_rehash.
	# -------------------------------------------------------------------------
	export _OPENSSL="/usr/local/opt/openssl"
	if [ -e "$_OPENSSL" ] ; then
		export PATH="${_OPENSSL}/bin:$PATH"	# find executables
		export LDFLAGS="-L${_OPENSSL}/lib"	# for compilers
		export CPPFLAGS="-I${_OPENSSL}/include"

		alias openssl_rehash='${_OPENSSL}/bin/c_rehash'
	else
		unset _OPENSSL						# not installed? not needed!
	fi

	# -------------------------------------------------------------------------
	# gpg2 (via homebrew) used by rvm
	# -------------------------------------------------------------------------
	if command -v gpg2 > /dev/null ; then	# if package is installed
		export LDFLAGS="-L/usr/local/opt/libffi/lib"	# for compilers
		export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig" # for pkg-config
	fi

	# -------------------------------------------------------------------------
	# Bash-completion (via homebrew) presents options to the user when the Tab
	# key is pressed. Read github.com/bobthecow/git-flow-completion
	# -------------------------------------------------------------------------
	if [[ -n ${_BREW-} ]] && brew ls --versions bash-completion > /dev/null; then
		# shellcheck source=/usr/local/opt/git/etc/bash_completion.d/git-completion.bash
		source "$( brew --prefix git )"/etc/bash_completion.d/git-completion.bash
		# shellcheck source=/usr/local/opt/git/etc/bash_completion.d/git-prompt.sh
		source "$( brew --prefix git )"/etc/bash_completion.d/git-prompt.sh
	fi

	# -------------------------------------------------------------------------
	# Homebrew OpenSSL required environmental variables for gem bundler.
	# -------------------------------------------------------------------------
	if [[ -n ${_BREW-} ]] && brew ls --versions openssl > /dev/null; then
		_BREW_OPENSSL="$(brew --prefix openssl)"
		export LDFLAGS=-L"${_BREW_OPENSSL}/lib"
		export CPPFLAGS=-I"${_BREW_OPENSSL}include"
		# For pkg-config to find this software you may need to set:
		export PKG_CONFIG_PATH="${_BREW_OPENSSL}lib/pkgconfig"
	fi

	# -------------------------------------------------------------------------
	# Test 'net connection to local machines...
	# -------------------------------------------------------------------------
	net () { nc -dznw1 ${1:-8.8.8.8} ${2:-53} ; }	# 53=DNS, 8.8.8.8=google
	png () { i='' ; h="$1" ; n="$2" ;
		if [[ $n && ${n-_} ]] ; then i="-i $n" ; fi ;
		c="ping -A $i $h | grep -oP 'time=\K(\d*)\.\d*'" ; # cut -d '=' -f4 ;
		echo $c
		eval $c
	}
	alias pgg='png 8.8.8.8 3'				# Google DNS nameserver

	# -------------------------------------------------------------------------
	# Set the terminal prompt.
	# -------------------------------------------------------------------------
	# store colors
	MAGENTA="\[\033[0;35m\]"
	YELLOW="\[\033[01;33m\]"
	BLUE="\[\033[00;34m\]"
	LIGHT_GRAY="\[\033[0;37m\]"
	CYAN="\[\033[0;36m\]"
	GREEN="\[\033[00;32m\]"
	RED="\[\033[0;31m\]"
	VIOLET='\[\033[01;35m\]'

	function color_my_prompt {
		local __user_and_host="$GREEN\u@\h"
		local __cur_location="$BLUE\W"		# capital 'W': current directory, small 'w': full file path
		local __git_branch_color="$GREEN"
		local __prompt_tail="$VIOLET$"
		local __user_input_color="$GREEN"
		local __git_branch='$(__git_ps1)';

		# colour branch name depending on state
		if [[ "$(__git_ps1)" =~ "*" ]]; then	# if repository is dirty
				__git_branch_color="$RED"
		elif [[ "$(__git_ps1)" =~ "$" ]]; then	# if there is something stashed
				__git_branch_color="$YELLOW"
		elif [[ "$(__git_ps1)" =~ "%" ]]; then	# if there are only untracked files
				__git_branch_color="$LIGHT_GRAY"
		elif [[ "$(__git_ps1)" =~ "+" ]]; then	# if there are staged files
				__git_branch_color="$CYAN"
		fi

		# Build the PS1 (Prompt String)
#		PS1="$__user_and_host $__cur_location$__git_branch_color$__git_branch $__prompt_tail$__user_input_color "
		PS1="$__cur_location$__git_branch_color$__git_branch $__prompt_tail$__user_input_color "
	}

	# configure PROMPT_COMMAND which is executed each time before PS1
	export PROMPT_COMMAND=color_my_prompt

	if [ -f ~/.git-prompt.sh ]; then
		GIT_PS1_SHOWDIRTYSTATE=true
		GIT_PS1_SHOWSTASHSTATE=true
		GIT_PS1_SHOWUNTRACKEDFILES=true
		GIT_PS1_SHOWUPSTREAM="auto"
		GIT_PS1_HIDE_IF_PWD_IGNORED=true
		GIT_PS1_SHOWCOLORHINTS=true
		. ~/.git-prompt.sh
	fi

	# shellcheck disable=SC2155				# ignore well-established convention
#	_DIR="\[\033[38;5;248m\]\W\[$(tput sgr0)\]"
#	_BRANCH="\[\033[01;31m\]$(']", \branch 2>/dev/null | cut -f2 -d\* -s)\[\033[01;32m\]"
#	_PROMPT="\[\033[38;5;2m\]\\$\[$(tput sgr0)\]"
#	export PS1="$_DIR$_BRANCH $_PROMPT "
#	export PROMPT_COMMAND=' __git_ps1'
#	export PROMPT_COMMAND='$_DIR __git_ps1 $_PROMPT '
#	export PROMPT_COMMAND="echo -ne $_DIR __git_ps1 $_PROMPT "

	# -------------------------------------------------------------------------
	# Solutions to developing locally (on a laptop) while testing on a remote
	# (vagrant) instance. First pass of this covers working with one remote; if
	# multiple remotes become common we'll tackle that situation next.
	#
	# 1 Spin up your remote (vagrant UAT).
	# 2 Place the remote IP address into _REMO, below.
	# 3 Generate proper commands with `source ~/.bash_profile`.
	# 4 `cpk` for password-less secure shell (ssh, scp).
	# 5 `cpb` to make the remote login shell behave as you've specified above.
	# 6 `sshr` to connect; enjoy!
	# -------------------------------------------------------------------------
	cpbash() {
		if [ -z "$1" ] ; then				# explain proper usage if no host
			echo "usage: ${FUNCNAME[0]} UserName@RemoteHost:"
		else
			echo scp -L -i "$_SSHK" "$HOME/.bash-profile" "$1" # copy this to remote
		fi
	}

	# -------------------------------------------------------------------------
	# Print a red line to make it easy to scroll back to this point in terminal.
	# -------------------------------------------------------------------------
	full_width_rule () {
		printf -v _hr "%*s" $(tput cols) && echo -e ${_hr// /${1--}}
	}
	alias d='full_width_rule "\033[31;1;31m*"' # can't turn color off :-/
	alias d='full_width_rule \#'

	# -------------------------------------------------------------------------
	# Keep just one ssh-agent running in a multi-tab environment, per
	# http://rabexc.org/posts/pitfalls-of-ssh-agents
	#
	# ssh-add(1) says exit status is 0 on success, 1 if the specified command
	# fails, and 2 if ssh-add is unable to contact the authentication agent.
	# -------------------------------------------------------------------------
	ssh-add -l &>/dev/null					# ssh-add list all known keys
	if [ "$?" == 2 ]; then					# if unable to contact ssh-agent
		test -r ~/.ssh-agent && \
			eval "$(<~/.ssh-agent)" >/dev/null # if file readable read environ

		ssh-add -l &>/dev/null				# ssh-add list all known keys
		if [ "$?" == 2 ]; then				# if unable to contact ssh-agent
			(umask 066; ssh-agent > ~/.ssh-agent) # start w 066 & save output
			eval "$(<~/.ssh-agent)" >/dev/null	# if file readable read environ
			ssh-add							# add keys
		fi
	fi

	# -------------------------------------------------------------------------
	# Which SSH private key to be used for authenticating to remotes?
	# -------------------------------------------------------------------------
	if [ -f "$HOME/.ssh/github-ck" ] ; then
		export _SSHK="$HOME/.ssh/github-ck"	# CK-specific private SSH key
	else
		export _SSHK="$HOME/.ssh/id_rsa"	# default private SSH key
	fi

	alias cpb="cpbash vagrant@\${_REMO}:"	# copy this bash file to remote
	alias cpk="ssh-copy-id -i \${_SSHK} vagrant@\${_REMO}" # copy key; no passwd
	alias sshr="ssh vagrant@\${_REMO}"		# -i ${_SSHK} unneeded

	# -------------------------------------------------------------------------
	# Set up and sanity-check local and remote cheddar git trees.
	# -------------------------------------------------------------------------
	export _REMO_CHEDDAR="/var/www/git-repos/automation/cheddar"
	export _LOCAL_CHEDDAR="$HOME/git-repos/ck/automation/cheddar"

	if [ ! -d "$_LOCAL_CHEDDAR" ] ; then
		echo "warning: not finding local cheddar at \"${_LOCAL_CHEDDAR/$HOME/\~}\""
	else
		# cheddar exists: work-related shortcuts to frequently-visited directories
		alias cheddar="pushd \$_LOCAL_CHEDDAR"		# mimic the vagrant command
		alias graphql="pushd \$_LOCAL_CHEDDAR/spec/graphql/credit_cards/marketplace/"

		# work-related tasks
		alias mm='git-up mexit-master'
		# start headless chrome webdriver (needed to run automated tests locally)
		alias headless="pushd \$_LOCAL_CHEDDAR/util/ ; ./run_standalone_webdriver.sh"
	fi

	# aliases to commonly-used non-cheddar directies
	alias aranya="pushd $HOME/git-repos/me/aranya"
	alias sher="pushd ${HOME}/git-repos/ck/sheriff/scripts/"

	# if ( remote-checking-wanted and network-is-present ) check remote
	_NETWORK_DOWN=$(eval nc -dzw1 8.8.8.8 443 &> /dev/null)
	_CHECK_REMOTE_CHEDDAR="true"

	if [[ ${_CHECK_REMOTE_CHEDDAR:-} && ! $_NETWORK_DOWN ]] ; then
		if ! ssh -o ConnectTimeout=2 -i "$_SSHK" vagrant@"${_REMO}" test -d "$_REMO_CHEDDAR" ; then
			echo "warning: not finding remote cheddar at \"$_REMO:$_REMO_CHEDDAR/\""
		fi
	else
		echo 'info: not checking remote cheddar file structure.'
	fi

	alias webd="\$_LOCAL_CHEDDAR/util/run_standalone_webdriver.sh 2>&1 | ccze"

	# -------------------------------------------------------------------------
	# Copy local work to the remote in one fell swoop! Git commit at success!
	# -------------------------------------------------------------------------
	alias rch="rsync --dry-run --human-readable --progress \
		-e \"ssh -i \$_SSHK\" \
		-avz \$_LOCAL_CHEDDAR/ vagrant@\$_REMO:\$_REMO_CHEDDAR/"

	# -------------------------------------------------------------------------
	# SauceLabs
	# -------------------------------------------------------------------------
	if [[ ${_SAUCE_LABS_ACCESS_KEY:-} ]] ; then

		_SL_L_PRETTY="${_SAUCE_DIR/$HOME/\~}"	# easier-to-read output below
		# shellcheck disable=SC2086				# must glob to expand matches
		set -- $_SAUCE_DIR						# glob expand all matching dirs
		if [[ $# -eq 0 ]] ; then
			echo "warning: missing SauceLabs folder at \"$_SL_L_PRETTY\"."
		elif [[ $# -gt 1 ]] ; then
			echo "warning: too many SauceLabs folders at \"$_SL_L_PRETTY\"."
		fi

		# shellcheck disable=2139				# expand when aliased
		alias sauce="ulimit -n 8000 && $_SAUCE_DIR/bin/sc \
			-u \"$_SAUCE_USERNAME\" \
			-k \"$_SAUCE_LABS_ACCESS_KEY\" \
			-i \"$_SAUCE_TUNNELNAME\""
	fi

	# -------------------------------------------------------------------------
	# iTerm2 -- www.iterm2.com
	#
	# this is an expanded, corrected version of:
	# https://superuser.com/questions/419775/with-bash-iterm2-how-to-name-tabs
	# -------------------------------------------------------------------------
	# if iTerm2 shell integration exists then use it
	test -e "${HOME}/.iterm2_shell_integration.bash" && \
		source "${HOME}/.iterm2_shell_integration.bash"

	# -------------------------------------------------------------------------
	# set iTerm2 tab titles automagically (and manually)
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2120				# it's ok to call title() w/o args
	title() {
		if [ "$ITERM_SESSION_ID" ]; then	# only relavent if within iTerm?
			if [[ $# -ne 0 ]] ; then		# if the user supplied a tab title
				# shellcheck disable=SC2015
				test -e "${HOME}/.iterm2_shell_integration.bash" \
					&& export PROMPT_COMMAND='__bp_precmd_invoke_cmd' \
					|| unset PROMPT_COMMAND
				echo -ne "\033]0;${*}\007"
			else							# if there's no tab title use PWD
				# shellcheck disable=SC2015
				test -e "${HOME}/.iterm2_shell_integration.bash" \
					&& export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/\~}\007";__bp_precmd_invoke_cmd' \
					|| export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/\~}\007"'
			fi								# end of use PWD
		fi									# end of ITERM_SESSION_ID
	}										# end of title()

	# shellcheck disable=SC2119				# it's ok to call title() w/o args
	title									# set iTerm tab if within iTerm

	# -------------------------------------------------------------------------
	# BBEdit -- barebones.com/products/bbedit/
	# -------------------------------------------------------------------------
	if command -v bbedit &> /dev/null ; then
		if [[ ${SSH_CONNECTION:-} ]] ; then
			export EDITOR="vi"				# really vim on current macOS
		else
			alias bb='bbedit'				# use BBEdit with less keystrokes
			alias diff='bbdiff'				# use BBEdit to show file differences
			export EDITOR="${HOME}/bin/bbedit_wait_resume" # for crontab
		fi
	fi

	# -------------------------------------------------------------------------
	# docker -- docker.com
	# -------------------------------------------------------------------------
	if command -v docker &> /dev/null ; then
		alias dk='docker'					# faster command-line time :-)
		# list
		alias di='docker images list'
		alias dc='docker container ls --all'
		# destructively remove (!)
		alias dxc='docker rm $(docker ps --all --quiet)'
		alias dxi='docker rmi $(docker images --quiet)'
		alias dclean='dxc ; dxi'
	fi

	# -------------------------------------------------------------------------
	# Gas Mask (hosts file manager) -- github.com/2ndalpha/gasmask
	# -------------------------------------------------------------------------
	MASK='/Applications/Gas Mask.app/Contents/MacOS/Gas Mask'
	if [ -x "$MASK" ] ; then
		# shellcheck disable=SC2139
		alias mask="sudo -b \"$MASK\""
	fi

	# -------------------------------------------------------------------------
	# Sublime Text -- sublimetext.com
	# -------------------------------------------------------------------------
	_subl=''
	SUBL="/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"
	if [ -e "$SUBL" ] ; then _subl="$SUBL" ;
	elif [ -e "$HOME/$SUBL" ] ; then _subl="$HOME/$SUBL" ;
	fi

	if [ -n "$_subl" ] ; then
		export EDITOR="$_subl --wait"		# use as the system editor
		# shellcheck disable=SC2139			# expands when defined...
		alias subl="$_subl"					# use directly from the command line
	fi

	# -------------------------------------------------------------------------
	# vagrant -- www.vagrantup.com
	# -------------------------------------------------------------------------
	if command -v vagrant &> /dev/null ; then
		alias vhalt='vagrant halt'
		alias vreload='vagrant reload'
		alias vssh='vagrant ssh'
		alias vstat='vagrant status'
		alias vup='vagrant up'
	fi

	# -------------------------------------------------------------------------
	# Miscellany
	# -------------------------------------------------------------------------
	alias ag='alias | egrep'				# find an aliased command
	alias cf='caffeinate -dims'				# prevent sleep until command done
	alias hg='history | egrep'				# find a history item
	alias hosts='cat /etc/hosts'			# to what exactly are you pointing?
	alias keys='cat ~/Documents/pub_ssh_keys/* | pbcopy ; echo "$(pbpaste | wc -l) keys copied to clipboard!"'
	alias mykey='cat ~/Documents/pub_ssh_keys/$(whoami)-id_rsa.pub | pbcopy ; echo "On clipboard."'
	alias kurl='curl -#O'					# download file with orig filename
	alias pv="echo \"\${PATH//:/$'\n'}\" | sort" # PATH, line by line
	alias sc='shellcheck -x'				# syntax-check shell scripts
	alias sortdate='date +%Y%m%d_%H%M%S'	# more useful date format for sorting
	alias sshkey='ssh-keygen -l -E MD5 -f'	# fingerprint ssh key to verify

	# shellcheck disable=SC2155				# declare and assign separately...
	export JAVA_HOME=$(/usr/libexec/java_home) # dynamically get proper value
	if command -v thefuck &> /dev/null ; then eval "$(thefuck --alias)" ; fi

	# --------------------
	# Credit Karma-centric
	# --------------------
	# RSpec / Cheddar shortcuts
	RS_ARGS='--format documentation --format progress'
	alias runchc='c; d; AUTOMATION_MYSQL_HOST=$_REMO AUTOMATION_MEMCACHED_HOST=$_REMO rspec $RS_ARGS '
	alias runch='c; d; SKIP_DB_CONNECTION=true rspec $RS_ARGS '

	# IT
	alias ckup='sudo jamf recon ; sudo jamf policy'

	# -------------------------------------------------------------------------
	# Cisco Umbrella roaming client - resetting to route around occasional issue
	# -------------------------------------------------------------------------
	umbrella () {
		# stop
		sudo launchctl remove com.opendns.osx.RoamingClientConfigUpdater
		launchctl remove com.opendns.osx.RoamingClientMenubar
		sudo killall OpenDNSDiagnostic &>/dev/null
		# start
		sudo launchctl load /Library/LaunchDaemons/com.opendns.osx.RoamingClientConfigUpdater.plist
		launchctl load /Library/LaunchAgents/com.opendns.osx.RoamingClientMenubar.plist
	}

	# -----------------------------------------------------------------------------
	# extract best-known archives with one command
	# -----------------------------------------------------------------------------
	extract () {
		if [ -f "$1" ] ; then
		  case "$1" in
			*.tar.bz2)   tar xjf "$1" ;;	# tar ~ bzip2
			*.tar.gz)    tar xzf "$1" ;;	# tar ~ gzip
			*.bz2)       bunzip2 "$1" ;;	# bzip2
			*.rar)       unrar e "$1" ;;	# Roshal Archive (win.rar)
			*.gz)        gunzip "$1" ;;		# gzip
			*.tar)       tar xf "$1" ;;		# tar
			*.tbz2)      tar xjf "$1" ;;	# bzip2-compressed tar archive
			*.tgz)       tar xzf "$1" ;;	# really tar.gz
			*.zip)       unzip "$1" ;;		# zip (pkware)
			*.Z)         uncompress "$1" ;;	# compress
			*.7z)        7z x "$1" ;;		# 7-Zip
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
	#bu () { mkdir -p bak ; cp "$1" $(basename "$1")-$(date +%Y%m%d%H%M).backup ; }
	bak () {
		bkdir='./bak'						# write backups in your dir
		dn="$( dirname "$1" )"				# /path/to/file --> /path/to
		bn="$( basename "$1" )"				# /path/to/file --> file
		fn="${bn%.*}"						# filename: a.b.c.xyz --> a.b.c
		ex="${bn##*.}"						# extension: a.b.c.xyz --> xyz

		if [ ! "$1" ] ; then				# did you pass me a anything to backup?
			echo "usage: $0 [ file | directory ]"
			return							# nope. get it right, you!
		elif [ ! -w "$dn" ] ; then			# can I put a backup here?
			echo "$0: fatal: \"$dn\" not writable; quitting."
			return							# nope. try again
		elif [ ! -e "$1" ] ; then			# does the source exist?
			echo "$0: '$1' doesn't exist; quitting."
			return							# what are you thinking of?
		fi

		# TO-DO: l & r lowercase here and uppercased below -- WTF?
		if [ -d "$1" ] ; then echo "DEBUG: $1 is dir"; P='/'	; L='-r' ; fi	# is dir? tweak syntax

		mkdir -p "$bkdir"					# in case it doesn't exist
		d=$( date +%Y%m%d_%H%M%S )			# allow breadcrumbing through time

echo "DEBUG: fn $fn d $d ex $ex R $R L $L"
echo "DEBUG: " cp "$L" "$1" "$bkdir/${fn}_${d}.${ex}$R"
		if ! cp "$L" "$1" "$bkdir/${fn}_${d}.${ex}$R" ; then
			echo "$bn: error occured!"
		fi
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

	# -------------------------------------------------------------------------
	# to avoid xvfb "not found on your system" error when running chrome-driver
	# -------------------------------------------------------------------------
	if [ -e /usr/local/opt/libxml2/bin ] ; then
		export PATH="/usr/local/opt/libxml2/bin:$PATH"
	fi

	if [ -e ~/bin ] ; then
		export PATH="$HOME/bin:$PATH"		# put my own stuff at the front
	fi

	# -------------------------------------------------------------------------
	# Remove duplicate $PATH entries.
	# -------------------------------------------------------------------------
	cleanPath() {
		if [ -n "$PATH" ]; then				# if the system PATH exists
		  oldPath=$PATH:; newPath=			# make a copy & new working space
		  while [ -n "$oldPath" ]; do		# while there's still something left
			x=${oldPath%%:*}				# get the first remaining entry
			case $newPath: in
			  *:"$x":*) ;;					# already there, do nothing
			  *) newPath=$newPath:$x;;    	# not there yet; add
			esac
			oldPath=${oldPath#*:}
		  done
		  PATH=${newPath#:}					# set system PATH to uniq'd version
		  unset oldPath newPath x			# clean up after ourselves
		fi
	}
	cleanPath								# remove duplicates from PATH
	export PATH								# share and enjoy!

	# -------------------------------------------------------------------------
	# /Users/michael.sattler/git-repos/ck/sheriff/scripts/sheriff.sh
	# -------------------------------------------------------------------------
	export PATH="$PATH:$HOME/git-repos/ck/sheriff/scripts"
	alias sheriff='sheriff.sh cc'

	# -------------------------------------------------------------------------
	# THIS MUST BE AT THE END OF THE FILE BECAUSE rvm IS FRAGILE AND WILL YELL
	# ABOUT "is not at first place". GRRRR
	# -------------------------------------------------------------------------
	if command -v ruby &> /dev/null ; then

		alias gems="pushd ~/.rvm/gems/${RUBY_VERSION}/gems && ls -al"
		alias rs='ruby-beautify --spaces --indent_count 2 --overwrite'
		alias rt='ruby-beautify --tabs --indent_count 1 --overwrite'
		alias rv='ruby -e "puts \"ruby-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}\""'

#		export RUBYOPT="-w $RUBYOPT"		# issue warnings for common errors
# following finds 2.3.0 when I'm using 2.3.3 :-/
#    	export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"

		# ---------------------------------------------------------------------
		# THIS MUST BE AT THE END OF THE .BASH* BECAUSE rvm IS FRAGILE AND WILL
		# YELL ABOUT "is not at first place". GRRRR
		#
		# Load RVM into a shell session _as a function_
		# ---------------------------------------------------------------------
#		export rvm_bash_nounset=${rvm_bash_nounset:-} # initialize if unbound variable
#		export rvm_error_clr=${rvm_error_clr:-}	# initialize if unbound variable
#		export _system_name=${_system_name:-}	# initialize if unbound variable
#		export __rvm_sed=${__rvm_sed:-}			# initialize if unbound variable


	fi
fi # Local (laptop) host environment configuration section

# -----------------------------------------------------------------------------
export PATH="/usr/local/opt/curl/bin:$PATH"
# -----------------------------------------------------------------------------
#If you need to have openssl first in your PATH run:
export PATH="/usr/local/opt/openssl/bin:$PATH"
#For compilers to find openssl you may need to set:
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
#For pkg-config to find openssl you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
# -----------------------------------------------------------------------------
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
export PATH="/usr/local/sbin:$PATH"
cleanPath										# get rid of duplicate path entries
