#!/bin/bash

# install neovim
brew install neovim ripgrep fd lazygit

# install LazyVim
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# install fonts
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono

# install github completion
mkdir -p ~/.zsh
curl -o ~/.zsh/.git-completion.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o ~/.zsh/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# create symbolic link
ln -snfv ~/dev/dotfiles/.zshrc ~/.zshrc
ln -snfv ~/dev/dotfiles/nvim ~/.config
