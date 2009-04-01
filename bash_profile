export EDITOR=vim

PS1="\W $ "

# Long list
alias ls='ls -l -G -t'

# Vim instead of vi
alias vi='vim'

# Quiet R
alias R='R --quiet --vanilla'

# Sort process list by ram usage
alias top='top -o rsize'

# Three lines of context, and always add filename
alias grep='grep --color=always'

export PATH=/opt/local/bin:/opt/local/sbin:~/.bash_scripts:/sw/bin:$PATH
export PATH=/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$PATH
