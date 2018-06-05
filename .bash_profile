# export

# - vscode
export EDITOR='code -r -w'

# - nvm directory
export NVM_DIR="$HOME/.nvm"

# source

# - nvm
[ -s "$NVM_DIR/nvm.sh" ] && . $NVM_DIR/nvm.sh

# - enhancd
[ -r ~/.enhancd/init.sh ] && . ~/.enhancd/init.sh

# - git-completion
[ -r /usr/local/git/contrib/completion/.git-completion.bash ] &&
   . /usr/local/git/contrib/completion/.git-completion.bash
[ -r /usr/local/git/contrib/completion/.git-prompt.sh ] &&
   . /usr/local/git/contrib/completion/.git-prompt.sh

# - powerline
[ -r /usr/local/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh ] &&
   . /usr/local/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh

# set nvm path
nvm_path=~/.nvm/current
if [ -d $nvm_path/bin ]; then
  export PATH="$nvm_path/bin" : $PATH
fi

[ -r ~/.bashrc ] && . ~/.bashrc