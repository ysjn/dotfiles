
# This loads nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 

# Source
source $HOME/.git-completion.bash
source $HOME/.git-prompt.sh


# variables
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
txtrst='\e[0m'    # Text Reset



# export
export PS1="---$bldred$(__git_ps1)$txtrst\n[ $bldcyn\W$txtrst ] ✏️  : "
export NVM_DIR="$HOME/.nvm"



# alias
alias npminstalled='npm ls --depth=0 -g'
alias lscd='peco-lscd'
alias subp='sublime-projects'


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


function peco-lscd {
  local dir="$( find . -maxdepth 1 -type d | sed -e 's;\./;;' | peco )"
  if [ ! -z "$dir" ] ; then
    cd "$dir"
  fi
}


