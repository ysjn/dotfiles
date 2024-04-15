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
mv $HOME/.config/nvim{,.bak}
mv $HOME/.local/share/nvim{,.bak}
mv $HOME/.local/state/nvim{,.bak}
mv $HOME/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter $HOME/.config/nvim
rm -rf $HOME/.config/nvim/.git

# install fonts
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font

# install tmux
brew install tmux

# install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm

# create symbolic link for tmux.conf
mkdir -p $HOME/.config/tmux
ln -snfv $HOME/dev/dotfiles/tmux.conf $HOME/.config/tmux/tmux.conf

# install fzf (for tmux-fzf-url)
brew install fzf

# install github completion
mkdir -p $HOME/.zsh
curl -o $HOME/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o $HOME/.zsh/git-completion.zsh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
curl -o $HOME/.zsh/git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# create symbolic link
ln -snfv $HOME/dev/dotfiles/.zshrc ~
rm -rf $HOME/.config/nvim
ln -snfv $HOME/dev/dotfiles/nvim ~/.config
ln -snfv $HOME/dev/dotfiles/alacritty.toml $HOME/.config/alacritty.toml

# load config
source $HOME/.zshrc
