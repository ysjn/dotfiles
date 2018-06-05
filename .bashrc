# git-completion
__git_complete gb _git_branch
__git_complete gc _git_checkout
__git_complete push _git_branch
__git_complete stash _git_stash

# Power-line
# powerline-daemon -q
# POWERLINE_BASH_CONTINUATION=1
# POWERLINE_BASH_SELECT=1

# alias
alias la='ls -a'
alias npmlist='npm ls --depth=0 -g'
alias lscd='peco-lscd'
alias subp='sublime-projects'
alias cpwd='pwd | tr -d "\n" | pbcopy'

alias ssh@scre='ssh -i ~/.ssh/id_rsa jyoshida@scre11.search.ssk.ynwm.yahoo.co.jp'

alias lsport='lsof -Pn -i4'
alias killport='sudo kill -9'


# github
alias g='git'
alias ga='git add'
alias gs='git status'
alias gc='git checkout'
alias gb='git branch'
alias stash='git stash'
alias fetch='git fetch'
alias pull='git pull'
alias push='git push'
alias commit='git commit'

#npm
alias ns='npm start'
alias nb='npm run build'

# yui compressor
alias yuicomp='java -jar ~/yuicomp.jar'

# ls
alias ls='ls -G -F'

# functions
function sublime-projects() {
  subl_root='~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Projects'
  root_len=${#subl_root}+3
  # files=`(ls -l ~/Projects/sublime_projects | grep project | cut -d " " -f 10)`
  files=`find ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Projects -name "*sublime-project"`
  if [[ -n "$files" ]]; then
    project=`echo $files | awk '{ name=substr($0,'${root_len}'); print substr(name,0,index(name,".sublime-project"))}'| peco`
    if [[ -n "$project" ]]; then
      subl `echo $files | grep $project`
    fi
  else
    echo "no projects"
  fi
}


function peco-lscd() {
  local dir="$( find . -maxdepth 1 -type d | sed -e 's;\./;;' | peco )"
  if [ ! -z "$dir" ] ; then
    cd "$dir"
  fi
}


function light() {
    if [ -z "$2" ]; then
        src="pbpaste"
    else
        src="cat $2"
    fi

    $src | highlight -O rtf --syntax $1 --font=Ricty --style=molokai --font-size 24 | pbcopy
}

function showDesktopIcon() {
    defaults write com.apple.finder CreateDesktop -boolean $1
    killAll Finder
}


###-begin-npm-completion-###
#
# npm command completion script
#
# Installation: npm completion >> ~/.bashrc  (or ~/.zshrc)
# Or, maybe: npm completion > /usr/local/etc/bash_completion.d/npm
#

if type complete &>/dev/null; then
  _npm_completion () {
    local words cword
    if type _get_comp_words_by_ref &>/dev/null; then
      _get_comp_words_by_ref -n = -n @ -w words -i cword
    else
      cword="$COMP_CWORD"
      words=("${COMP_WORDS[@]}")
    fi

    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           npm completion -- "${words[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -o default -F _npm_completion npm
elif type compdef &>/dev/null; then
  _npm_completion() {
    local si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 npm completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef _npm_completion npm
elif type compctl &>/dev/null; then
  _npm_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       npm completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K _npm_completion npm
fi
###-end-npm-completion-###
