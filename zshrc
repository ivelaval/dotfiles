# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/ivanavila/.oh-my-zsh"

ZSH_THEME="agnoster"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git bundler osx vi-mode)

source $ZSH/oh-my-zsh.sh

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"

TERM=xterm-256color

# Customise the Powerlevel9k prompts
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  custom_medium custom_freecodecamp dir vcs newline status
)

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M \uf073 %d/%m/%y}"
POWERLEVEL9K_TIME_BACKGROUND='white'
POWERLEVEL9K_RAM_BACKGROUND='yellow'
POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND="white"
POWERLEVEL9K_LOAD_WARNING_BACKGROUND="white"
POWERLEVEL9K_LOAD_NORMAL_BACKGROUND="white"
POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND="red"
POWERLEVEL9K_LOAD_WARNING_FOREGROUND="yellow"
POWERLEVEL9K_LOAD_NORMAL_FOREGROUND="black"
POWERLEVEL9K_LOAD_CRITICAL_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_LOAD_WARNING_VISUAL_IDENTIFIER_COLOR="yellow"
POWERLEVEL9K_LOAD_NORMAL_VISUAL_IDENTIFIER_COLOR="green"
POWERLEVEL9K_HOME_ICON=''
POWERLEVEL9K_HOME_SUB_ICON=''
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_STATUS_VERBOSE=true
POWERLEVEL9K_STATUS_CROSS=true

POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_STATUS_OK_BACKGROUND='235'

# Add the custom Medium M icon prompt segment
POWERLEVEL9K_CUSTOM_MEDIUM="echo -n $'\uF534'"
POWERLEVEL9K_CUSTOM_MEDIUM_FOREGROUND="black"
POWERLEVEL9K_CUSTOM_MEDIUM_BACKGROUND="red"

# Add the custom freeCodeCamp prompt segment
POWERLEVEL9K_CUSTOM_FREECODECAMP="echo -n $'\uF489' Vennet"
POWERLEVEL9K_CUSTOM_FREECODECAMP_FOREGROUND="black"
POWERLEVEL9K_CUSTOM_FREECODECAMP_BACKGROUND="white"

# Load Nerd Fonts with Powerlevel9k theme for Zsh
POWERLEVEL9K_MODE='nerdfont-complete'

# Set a color for iTerm2 tab title background using rgb values
function title_background_color {
  echo -ne "\033]6;1;bg;red;brightness;$ITERM2_TITLE_BACKGROUND_RED\a"
  echo -ne "\033]6;1;bg;green;brightness;$ITERM2_TITLE_BACKGROUND_GREEN\a"
  echo -ne "\033]6;1;bg;blue;brightness;$ITERM2_TITLE_BACKGROUND_BLUE\a"
}
ITERM2_TITLE_BACKGROUND_RED="18"
ITERM2_TITLE_BACKGROUND_GREEN="26"
ITERM2_TITLE_BACKGROUND_BLUE="33"
title_background_color

# Set iTerm2 tab title text
function title_text {
    echo -ne "\033]0;"$*"\007"
}
title_text freeCodeCamp

source ~/powerlevel9k/powerlevel9k.zsh-theme

