#!/bin/bash

# check if homebrew is installed
which -s brew
if [[ $? != 0 ]]; then
  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # update PATH
  echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>$HOME/.zprofile
  eval $(/opt/homebrew/bin/brew shellenv)
else
  brew update
fi

# raycast
brew install --cask raycast

# pearcleaner
brew tap alienator88/homebrew-cask
brew install --cask pearcleaner

# Google Japanese Input Method Editor
brew install --cask google-japanese-ime

# hammerspoon
brew install --cask hammerspoon
mkdir -p $HOME/.hammerspoon
ln -snfv $HOME/dev/dotfiles/.hammerspoon.lua $HOME/.hammerspoon/init.lua
