export LC_ALL=en_US.UTF-8

[[ $TERM != "screen" ]] && exec tmux

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"

# MongoDB Aliases
alias mongod="mongod --dbpath /Users/ivelaval/mongodb/data/db"

export PATH=~/Library/Python/3.7/bin:$PATH


