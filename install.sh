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

# install neovim
brew install neovim ripgrep fd lazygit tree-sitter-cli

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

# install herdr
brew install herdr

# create symbolic link for herdr config
mkdir -p "$HOME/.config/herdr"
ln -snfv "$HOME/dev/dotfiles/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# create symbolic link for Rex config
mkdir -p "$HOME/.config/rex"
ln -snfv "$HOME/dev/dotfiles/rex/init.lua" "$HOME/.config/rex/init.lua"

# Link the CLI from an existing Rex installation.
rex_cli="/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"
if [[ -x "$rex_cli" ]]; then
  mkdir -p "$HOME/.local/bin"
  if [[ ! -e "$HOME/.local/bin/rex" && ! -L "$HOME/.local/bin/rex" ]]; then
    ln -sv "$rex_cli" "$HOME/.local/bin/rex"
  fi
  if ! grep -Fqx 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zprofile" 2>/dev/null; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zprofile"
  fi
fi

# install fzf
brew install fzf

# install zoxide (smarter cd)
brew install zoxide

# install Obsidian and seed a portable Markdown vault
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/obsidian/install.sh" || exit 1

# install github completion
mkdir -p $HOME/.zsh
curl -o $HOME/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o $HOME/.zsh/git-completion.zsh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
curl -o $HOME/.zsh/git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# install gh
brew install gh

# install Syntax Highlight (Quick Look Extension)
brew install --no-quarantine syntax-highlight

# create symbolic link
ln -snfv $HOME/dev/dotfiles/.zshrc $HOME
rm -rf $HOME/.config/nvim
ln -snfv $HOME/dev/dotfiles/nvim $HOME/.config
ln -snfv $HOME/dev/dotfiles/alacritty.toml $HOME/.config/alacritty.toml

mkdir -p $HOME/Library/Application\ Support/lazygit
ln -snfv $HOME/dev/dotfiles/lazygit/config.yml $HOME/Library/Application\ Support/lazygit/config.yml

# load config
source $HOME/.zshrc
