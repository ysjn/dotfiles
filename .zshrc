# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

export CLICOLOR=1

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NODE_PATH=$(realpath $(dirname $(nvm which current))/../lib/node_modules)

[ -f ${HOME}/.zsh/git-completion.bash ] && zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash 
[ -f ${HOME}/.zsh/git-prompt.sh ] && source ${HOME}/.zsh/git-prompt.sh

fpath=(~/.zsh $fpath)

# load completion
autoload -Uz compinit && compinit

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto

setopt PROMPT_SUBST; PS1=$'%F{green}%~%f %F{cyan}$(__git_ps1 "(%s)")%f
👉 '

alias ls='ls -Ga'
alias gs='git status'
alias ga='git add'
alias gb='git branch'
alias gc='git checkout'
alias commit='git commit'
alias pull='git pull'
alias push='git push'

alias ns='npm start'
alias nd='npm run dev'
alias nb='npm run build'
alias ys='yarn start'
alias yd='yarn dev'
alias yb='yarn build'
alias ybs='yarn build && yarn start'
alias ysb='NODE_OPTIONS="--openssl-legacy-provider" yarn storybook'

gbl() {
  branchList=($(git for-each-ref refs/heads/ --format="%(refname:short)"));
  for b in $branchList; do
    if test $b != "develop" -a $b != "master"; then
      data=$(gh pr view $b --json title,state,url --jq '[.state,.title,.url]')
      data=("${(@s/,/)data//\"}")

      state=${data[1]//\[}
      title=${data[2]}
      url=${data[3]//\]}

      NC='\033[0m'
      if [ "${state}" = "OPEN" ]; then
        SC='\033[0;32m' # green
      elif [ "${state}" = "MERGED" ]; then
        SC='\033[0;35m' # purple
      elif [ "${state}" = "CLOSED" ]; then
        SC='\033[0;31m' # red
      else
        SC='\033[0m'
      fi

      if [ "${state}" = "MERGED" -o "${state}" = "CLOSED" ]; then
        echo "${SC}${state}${NC} ${b} ${title} ${url}"
        gb -D $b
        echo -e "\n"
      elif [ "${state}" = "" ]; then
        echo ""
      else
        echo -e "${SC}${state}${NC} ${b} ${title} ${url}\n"
      fi
    fi
  done
}

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
