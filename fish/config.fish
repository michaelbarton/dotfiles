#!/usr/local/bin/fish

# --- Cursor Terminal Fix ---
# The complex prompt from starship can cause the terminal in Cursor (which is
# based on VS Code) to hang, as it has trouble determining when a command
# has finished executing.
# To fix this, we detect if we are running inside Cursor's terminal by
# checking if TERM_PROGRAM is "vscode". If it is, we use a simple, minimal
# prompt. Otherwise, we use the full starship prompt.
# This ensures a stable experience in Cursor without sacrificing the rich
# prompt in other terminal emulators.
#
# see: https://forum.cursor.com/t/cursor-agent-mode-when-running-terminal-commands-often-hangs-up-the-terminal-requiring-a-click-to-pop-it-out-in-order-to-continue-commands/59969/22
#
if test "$TERM_PROGRAM" = vscode
    exit 0
end

# Initialize starship and zoxide
starship init fish | source
zoxide init fish | source

# Disable fish greeting
set fish_greeting ""

###################################################################
#
# Simple aliases - converted from bashrc
#
###################################################################

alias dot='cd ~/.dotfiles'
alias cache='cd ~/cache'
alias tmp='cd $(mktemp -d)'
alias wiki='vim ~/Dropbox/wiki/zettel/index.md'
alias g='git'

# Use modern alternatives
alias ls='eza --classify --oneline --git'
alias lls='eza --header --long --git'
alias tree='eza --tree'
alias vim='nvim'
alias cat='bat'
alias find='fd'

# Quiet R and octave
alias R='R --quiet --no-save --no-restore'
alias octave='octave --quiet'

# Print grep results in color
alias grep='grep --color=auto'

###################################################################
#
# Environment Variables - converted from bashrc
#
###################################################################

# Paths
set -x PYTHON_BIN $HOME/.venv/bin
set -x USER_BIN $HOME/.bin
set -x DOTFILES_BIN $HOME/.dotfiles/bin
set -x HOMEBREW_BIN /opt/homebrew/bin
set -x NPM_BIN $HOME/.npm-global/bin

# Prepend paths to PATH (fish uses fish_add_path for this)
fish_add_path $NPM_BIN
fish_add_path $HOMEBREW_BIN
fish_add_path $DOTFILES_BIN
fish_add_path $USER_BIN

# FZF configuration
set -x FZF_DEFAULT_COMMAND 'rg --files'
set -x FZF_DEFAULT_OPTS '-m --height 50% --border'

# Editor settings
set -x MANWIDTH 80
set -x EDITOR nvim
set -x VISUAL nvim

# Git settings
set -x EMAIL "mail@michaelbarton.me.uk"
set -x FULLNAME "Michael Barton"
set -x GIT_AUTHOR_NAME $FULLNAME
set -x GIT_COMMITTER_NAME $FULLNAME
set -x GIT_AUTHOR_EMAIL $EMAIL
set -x GIT_COMMITTER_EMAIL $EMAIL

# Pager settings
set -x PAGER less
set -x LESS '-R -M --shift 5'

# Java home - commented out as it adds startup delay
# Uncomment if you need Java development
# if test -x /usr/libexec/java_home
#     set -x JAVA_HOME (/usr/libexec/java_home -v 18 2>/dev/null)
# end

# Language settings
set -x LC_ALL 'en_GB.UTF-8'
set -x LANG 'en_GB.UTF-8'
set -x LC_CTYPE C
set -x DISPLAY :0

###################################################################
#
# GNU Coreutils aliases 
#
###################################################################

# Only create aliases if coreutils is installed
# Check for coreutils by looking for one of its binaries instead of running brew list
if test -x /opt/homebrew/bin/gcat
    # Use hardcoded path for M1/M2 Macs (adjust if on Intel Mac)
    set brew_prefix /opt/homebrew

    # Only alias the most commonly used commands to reduce startup time
    # Remove the ones you don't actually use
    alias cat="$brew_prefix/bin/gcat"
    alias cp="$brew_prefix/bin/gcp"
    alias date="$brew_prefix/bin/gdate"
    alias echo="$brew_prefix/bin/gecho"
    alias ls="$brew_prefix/bin/gls"
    alias mv="$brew_prefix/bin/gmv"
    alias rm="$brew_prefix/bin/grm"
    alias sed="$brew_prefix/bin/gsed"
    alias sort="$brew_prefix/bin/gsort"
    alias tail="$brew_prefix/bin/gtail"

    # Override ls alias with eza as you prefer
    alias ls='eza --classify --oneline --git'
end

###################################################################
#
# Functions
#
###################################################################

# Improve the ssh function to use mosh only when appropriate
function ssh
    if test (count $argv) -gt 0; and string match -qr '^[a-zA-Z0-9._-]+$' -- $argv[1]
        mosh $argv
    else
        command ssh $argv
    end
end

function sp
    aspell -c $argv[1]; and ~/.dotfiles/aspell/sort_dictionary
end

# Cat the contents of a file into the clipboard
function pbcat
    cat $argv[1] | pbcopy
end

# Use ctrl+s to fzf search the current directory
fzf_configure_bindings --directory=\cs

# Search for all files with matching name in path
function wiki_file
    fd . --base-directory="$HOME/Dropbox/wiki/" --type=file \
        | fzf --preview "bat --style=numbers --color=always $HOME/Dropbox/wiki/{}" --preview-window="right:65%" --height="70%" \
        | xargs -I {} -o nvim ~/Dropbox/wiki/{}
end
bind \cg wiki_file

# Search for all files *containing* text
function wt
    set dir (pwd)
    cd ~/Dropbox/wiki/zettel/; and rg $argv[1] --files-with-matches \
        | fzf --preview 'bat --style=numbers --color=always {}' --preview-window="right:65%" --height="70%" \
        | xargs -I {} -o nvim ~/Dropbox/wiki/zettel/{}
    cd $dir
end

# LESS colors for man pages
set -Ux LESS_TERMCAP_us \e\[1\;32m
set -Ux LESS_TERMCAP_md \e\[1\;31m
set -Ux LESS_TERMCAP_mb \e\[01\;31m
set -Ux LESS_TERMCAP_me \e\[0m
set -Ux LESS_TERMCAP_se \e\[0m
set -Ux LESS_TERMCAP_so \e\[01\;44\;33m
set -Ux LESS_TERMCAP_ue \e\[0m

# Source local environment variables if they exist 
if test -f ~/.local/environment.fish
    source ~/.local/environment.fish
end

