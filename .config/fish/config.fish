# Allow 256 colors in iTerm2 for pretty vim colors
set -Ux CLICOLOR 1
set TERM xterm-256color
set -Ux LSCOLORS BxfxCxDxCxexexabagacad

# Path
set -gx PATH ~/.rbenv/bin ~/bin $PATH

# ------

# Path to your oh-my-fish.
set -g OMF_PATH $HOME/.local/share/omf

# Path to your oh-my-fish configuration.
set -g OMF_CONFIG $HOME/.config/omf

### Configuration required to load oh-my-fish ###
# Note: Only add configurations that are required to be set before
# oh-my-fish is loaded. For common configurations, we advise you to
# add them to your $OMF_CONFIG/init.fish file or to create a custom
# plugin instead.
set -gx Z_SCRIPT_PATH /usr/local/etc/profile.d/z.sh

# Load oh-my-fish configuration.
source $OMF_PATH/init.fish

set -g -x fish_greeting ''

#-------

# Paths to your tackle
set tacklebox_path ~/.tackle ~/.tacklebox

# Theme
set tacklebox_theme agnoster

# Which modules would you like to load? (modules can be found in ~/.tackle/modules/*)
# Custom modules may be added to ~/.tacklebox/modules/
set tacklebox_modules virtualfish virtualhooks

# Which plugins would you like to enable? (plugins can be found in ~/.tackle/plugins/*)
# Custom plugins may be added to ~/.tacklebox/plugins/
set tacklebox_plugins extract grc pip python up

# Load Tacklebox configuration
. ~/.tacklebox/tacklebox.fish

# Load rbenv automatically
status --is-interactive; and . (rbenv init -|psub)

#alias ll "ls -lhG $argv"
alias cls	"clear"
alias grep	"command grep --color=always -I $argv"
alias gc	"git commit -a -m $argv"
alias gp	"git push origin master"
alias gs	"git status"
alias jk	"bundle exec jekyll serve --drafts"
alias jki	"bundle exec jekyll serve --incremental --drafts"
alias jkp	"bundle exec jekyll serve --profile --drafts"
alias jks-prod "jekyll serve --detach"
alias jkg	"ps aux | grep jekyll"
alias kurl	"curl -#0 $argv"
#
# fish ignore ~/.bash_history
#
alias la	"ls -lahG $argv"
alias ls	"command ls -hG $argv"
alias lsd	"ls -d */"
alias pd	"pushd"
alias reload "source ~/.config/fish/config.fish"
alias tw	"open -a "TextWrangler.app" $argv"

setenv PATH '/Users/msattler/.rbenv/shims' $PATH
setenv RBENV_SHELL fish
. '/Users/msattler/.rbenv/libexec/../completions/rbenv.fish'
command rbenv rehash 2>/dev/null
function rbenv
  set command $argv[1]
  set -e argv[1]

  switch "$command"
  case rehash shell
    . (rbenv "sh-$command" $argv|psub)
  case '*'
    command rbenv "$command" $argv
  end
end
