# --- XDG Base Directory Specification ---
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_STATE_HOME $HOME/.local/state

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

#
if test "$TERM_PROGRAM" = vscode
    exit 0
end

# Auto-attach to tmux in Ghostty (but not inside nvim, scripts, or existing tmux)
if test "$TERM_PROGRAM" = ghostty; and not set -q TMUX; and not set -q NVIM; and status is-interactive
    tmux new-session -A -s main
end

# Initialize starship and zoxide
starship init fish | source
zoxide init fish | source

# Initialize mise for runtime version management (if installed)
if command -v mise &>/dev/null
    mise activate fish | source
end

# Initialize atuin for enhanced shell history (if installed)
if command -v atuin &>/dev/null
    atuin init fish | source
end

# Disable fish greeting
set fish_greeting ""

###################################################################
#
# Simple aliases
#
###################################################################

alias dot='cd ~/.dotfiles'
alias cache='cd ~/cache'
alias tmp='cd $(mktemp -d)'
alias wiki='vim ~/Dropbox/wiki/zettel/index.md'
alias g='git'
alias lg='lazygit'
alias y='yazi'

# Use coreutils alternatives
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
set -x LOCAL_BIN $HOME/.local/bin
set -x DOTFILES_BIN $HOME/.dotfiles/bin
set -x HOMEBREW_BIN /opt/homebrew/bin
set -x NPM_BIN $HOME/.npm-global/bin

# Prepend paths to PATH (fish uses fish_add_path for this)
fish_add_path $NPM_BIN
fish_add_path $HOMEBREW_BIN
fish_add_path $DOTFILES_BIN
fish_add_path $USER_BIN
fish_add_path $LOCAL_BIN
fish_add_path $PYTHON_BIN

# FZF configuration with better preview
set -x FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -x FZF_DEFAULT_OPTS '--height 60% --border --layout=reverse --preview "bat --style=numbers --color=always --line-range :500 {}" --preview-window=right:60%:wrap'

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

# Java home (only set if java_home exists and returns a valid path)
if test -x /usr/libexec/java_home
    set -l java_home (/usr/libexec/java_home 2>/dev/null)
    if test -n "$java_home"
        set -gx JAVA_HOME $java_home
    end
end

# Language settings
set -x LC_ALL 'en_GB.UTF-8'
set -x LANG 'en_GB.UTF-8'

###################################################################
#
# GNU Coreutils aliases to replace OXS versions
#
###################################################################

# Only create aliases if coreutils is installed
# Check for coreutils by looking for one of its binaries instead of running brew list
if test -x /opt/homebrew/bin/gcat
    # Use hardcoded path for M1/M2 Macs (adjust if on Intel Mac)
    set brew_prefix /opt/homebrew

    # Only alias the most commonly used commands to reduce startup time
    alias cp="$brew_prefix/bin/gcp"
    alias date="$brew_prefix/bin/gdate"
    alias echo="$brew_prefix/bin/gecho"
    alias mv="$brew_prefix/bin/gmv"
    alias rm="$brew_prefix/bin/grm"
    alias sed="$brew_prefix/bin/gsed"
    alias sort="$brew_prefix/bin/gsort"
    alias tail="$brew_prefix/bin/gtail"

end

###################################################################
#
# Functions
#
###################################################################

function sp
    aspell -c $argv[1]; and ~/.dotfiles/aspell/sort_dictionary
end

# Cat the contents of a file into the clipboard
function pbcat
    command cat $argv[1] | pbcopy
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
    rg $argv[1] --files-with-matches ~/Dropbox/wiki/zettel/ \
        | fzf --preview "bat --style=numbers --color=always {}" --preview-window="right:65%" --height="70%" \
        | xargs -I {} -o nvim {}
end

# Wrapper around `just` that sends a macOS notification on completion.
# Useful for long-running builds where you switch context.
function jn
    just $argv
    set -l code $status
    set -l label (string join " " -- just $argv)
    if test $code -eq 0
        osascript -e "display notification \"$label succeeded\" with title \"just\" sound name \"Glass\""
    else
        osascript -e "display notification \"$label FAILED (exit $code)\" with title \"just\" sound name \"Sosumi\""
    end
    return $code
end

# Watch a qmd file and its partials for changes, re-rendering on save.
# Quarto preview only watches the main file; this also watches _*.qmd
# partials and helpers (*.py, *.yml) in the same directory. When any of
# them change, it touches the main file to trigger quarto's re-render.
# Requires: fswatch (brew install fswatch)
function qwatch
    set -l qmd $argv[1]
    if test -z "$qmd"
        echo "usage: qwatch <file.qmd>"
        return 1
    end

    if not command -v fswatch &>/dev/null
        echo "qwatch requires fswatch: brew install fswatch"
        return 1
    end

    set -l dir (path dirname $qmd)
    echo "Watching $qmd + partials in $dir/"

    uv run quarto preview $qmd --to html &
    set -l quarto_pid $last_pid

    fswatch -i '_.*\.qmd$' -i '\.py$' -i '\.yml$' -e '.*' $dir \
        | while read -l changed
            echo "Changed: "(path basename $changed)" → re-rendering"
            command touch $qmd
        end

    kill $quarto_pid 2>/dev/null
end

# LESS colors for man pages
set -gx LESS_TERMCAP_us \e\[1\;32m
set -gx LESS_TERMCAP_md \e\[1\;31m
set -gx LESS_TERMCAP_mb \e\[01\;31m
set -gx LESS_TERMCAP_me \e\[0m
set -gx LESS_TERMCAP_se \e\[0m
set -gx LESS_TERMCAP_so \e\[01\;44\;33m
set -gx LESS_TERMCAP_ue \e\[0m

# Source local environment variables if they exist
if test -f ~/.local/environment.fish
    source ~/.local/environment.fish
end
