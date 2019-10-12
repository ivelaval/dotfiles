#!/bin/bash

echo "Starting bootstrapping"

xcode-select --install

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if [[ ! -e ~/.bash_profile ]]; then
    touch ~/.bash_profile
    echo ".bash_profile file was created"
fi

if [[ ! -e ~/.zhsrc ]]; then 
    touch ~/.zhsrc
    echo ".zhsrc file was created"
fi

echo "Brew is updating..."

brew update
brew tap homebrew/cask
brew tap homebrew/cask-versions

# Core tools
brew install bash
brew install make
brew install git
brew install rsync


# Install packages
PACKAGES=(
    git
    rabbitmq
    terminal-notifier
    tmux
    tree
    vim
    wget
)

echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

echo "Installing cask apps..."
brew cask install firefox
brew cask install google-chrome
brew cask install google-chrome-canary
brew cask install firefox-developer-edition
brew cask install visual-studio-code
brew cask install visual-studio-code-insiders
brew cask install postman
brew cask install docker
brew install neovim 
brew cask install slack
brew cask install vlc

echo "Cleaning up..."
brew cleanup

echo "Installing fonts..."
brew tap homebrew/cask-fonts
brew cask install font-fira-code
brew cask install font-meslo-nerd-font
brew cask install font-firacode-nerd-font-mono
brew cleanup


echo "Install Oh my zsh"

brew install zsh zsh-completions
zsh --version


echo "Install powerlevel9k theme"

git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

git clone https://github.com/powerline/fonts.git

cd fonts

./install.sh

cd ~


echo "Installing nvm -> node version manager"
brew uninstall --ignore-dependencies node
brew uninstall --force node
brew install nvm

mkdir ~/.nvm
cd ~

source ~/.bash_profile

echo "Configuring OSX..."

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 0

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "Creating folder structure..."
cd ~
[[ ! -d github ]] && mkdir github
[[ ! -d vennet ]] && mkdir vennet
[[ ! -d mongodb ]] && mkdir -p mongodb/data/db

echo "Bootstrapping complete"


