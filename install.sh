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

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# install alacritty
brew install --cask alacritty

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
brew install --cask font-jetbrains-mono-nerd-font

# install tmux
brew install tmux

# install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# create symbolic link for tmux.conf
mkdir -p $HOME/.config/tmux
ln -snfv ~/dev/dotfiles/tmux.conf $HOME/.config/tmux/tmux.conf

# install github completion
mkdir -p ~/.zsh
curl -o ~/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o ~/.zsh/git-completion.zsh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
curl -o ~/.zsh/git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# create symbolic link
ln -snfv ~/dev/dotfiles/.zshrc ~
rm -rf ~/.config/nvim
ln -snfv ~/dev/dotfiles/nvim ~/.config
ln -snfv ~/dev/dotfiles/alacritty.toml $HOME/.config/alacritty.toml

# load config
source ~/.zshrc
