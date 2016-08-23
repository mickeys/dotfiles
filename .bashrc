echo "$0: you REALLY mean to be using this?"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

alias kibana='ssh msattler@operations.getlocalmotion.com -L 8080:10.0.0.102:8080 -L 5601:10.0.0.112:5601'

