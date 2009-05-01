source ~/.bash_local

export EDITOR=vim

function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function proml {
  local        BLUE="\[\033[0;34m\]"
  local         RED="\[\033[0;31m\]"
  local   LIGHT_RED="\[\033[1;31m\]"
  local       GREEN="\[\033[0;32m\]"
  local LIGHT_GREEN="\[\033[1;32m\]"
  local       WHITE="\[\033[1;37m\]"
  local  LIGHT_GRAY="\[\033[0;37m\]"
  case $TERM in
    xterm*)
    TITLEBAR='\[\033]0;\u@\h:\w\007\]'
    ;;
    *)
    TITLEBAR=""
    ;;
  esac

PS1="${TITLEBAR}\
$BLUE[$RED\$(date +%H:%M)$BLUE]\
$BLUE[$RED\u@\h:\W$GREEN\$(parse_git_branch)$BLUE]\
$WHITE\$ "
PS2='> '
PS4='+ '
}
proml

# Git shortcuts
alias gl='git log --pretty=oneline'
alias gc='git commit'
alias ga='git add'
alias gap='git add --patch'
alias gd='git diff'
alias gs='git status'
alias gsw='git checkout'
alias gb='git branch'
alias grm='git rm'
alias gr='git rebase'
alias gri='git rebase --interactive'
alias gsvn='git svn'

# Long list
alias ls='ls -l -G -t'

# Vim instead of vi
alias vi='vim'

# Quiet R
alias R='R --quiet --vanilla'

# Sort process list by ram usage
alias top='top -o rsize'

# Three lines of context, and always add filename
alias grep='grep --color=auto'

export PATH=/opt/local/bin:/opt/local/sbin:~/.bash_scripts:/sw/bin:$PATH
export PATH=/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$PATH
