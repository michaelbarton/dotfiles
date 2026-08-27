# --- XDG Base Directory Specification ---
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
set -x XDG_CACHE_HOME $HOME/.cache
set -x XDG_STATE_HOME $HOME/.local/state

# fish >= 4.3: key bindings moved from universal to global scope.
# The auto-migration file can leave fish_key_bindings empty; fix it here.
set -e -U fish_key_bindings 2>/dev/null
if test -z "$fish_key_bindings"; or not functions -q "$fish_key_bindings"
    set -g fish_key_bindings fish_default_key_bindings
end

# --- Cursor terminal prompt safety ---
# Keep Cursor terminals stable by avoiding starship there, but still load the
# rest of the fish environment (aliases, PATH, functions, etc).
if test "$TERM_PROGRAM" = vscode
    function fish_prompt
        set_color cyan
        echo -n (prompt_pwd) " > "
        set_color normal
    end

    function fish_right_prompt
    end
else
    if command -v starship &>/dev/null
        starship init fish | source
    end
end

# Auto-attach to tmux in Ghostty (but not inside nvim, scripts, or existing tmux)
if test "$TERM_PROGRAM" = ghostty; and not set -q TMUX; and not set -q NVIM; and status is-interactive
    tmux new-session -A -s main
end

# Initialize zoxide if installed
if command -v zoxide &>/dev/null
    zoxide init fish | source
end

# Initialize mise for runtime version management (if installed)
# Homebrew also ships vendor_conf.d/mise-activate.fish; guard against double init.
if command -v mise &>/dev/null
    if not functions -q __mise_env_eval
        mise activate fish | source
    end
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

abbr -a -- dot 'cd ~/.dotfiles'
abbr -a -- cache 'cd ~/cache'
abbr -a -- tmp 'cd (mktemp -d)'
abbr -a -- g git
abbr -a -- lg lazygit
abbr -a -- wiki 'vim ~/Dropbox/wiki/zettel/index.md'

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

# Paths — declarative via fish_add_path --global (not fish_user_paths universal)
set -x USER_BIN $HOME/.bin
set -x LOCAL_BIN $HOME/.local/bin
set -x HOMEBREW_BIN /opt/homebrew/bin
set -x HOMEBREW_SBIN /opt/homebrew/sbin
set -x GHOSTTY_BIN /Applications/Ghostty.app/Contents/MacOS
set -x NPM_BIN $HOME/.npm-global/bin

# fish_add_path prepends, so the LAST call ends up FIRST in PATH. LOCAL_BIN is
# therefore last on purpose: `keyring` exists in both ~/.local/bin and
# /opt/homebrew/bin, and uv needs the uv-tool one (it carries
# keyrings.codeartifact) for the private index. Reordering these breaks it.
fish_add_path --path --global $NPM_BIN
fish_add_path --path --global $HOMEBREW_BIN
fish_add_path --path --global $HOMEBREW_SBIN
fish_add_path --path --global $GHOSTTY_BIN
fish_add_path --path --global $USER_BIN
fish_add_path --path --global $LOCAL_BIN

# FZF configuration with better preview
if command -v fd &>/dev/null
    set -x FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
else
    set -x FZF_DEFAULT_COMMAND 'rg --files --hidden --glob !.git'
end
# --tmux opens fzf as a tmux popup (silently ignored outside tmux)
# bat --paging=never prevents bat spawning a nested pager in fzf preview
set -x FZF_DEFAULT_OPTS '--tmux center,80%,70% --layout=reverse --preview "bat --style=numbers --color=always --paging=never --line-range :500 {}" --preview-window=right:60%:wrap'

# bat theme: auto-select dark/light based on terminal background
set -x BAT_THEME_DARK "Catppuccin Frappe"
set -x BAT_THEME_LIGHT "Catppuccin Latte"

# bat as man pager
set -x MANPAGER "bat -plman"

# Suppress bat's pager and git's pager when inside a nvim terminal
# ($NVIM is set automatically by neovim in any terminal it spawns)
if set -q NVIM
    set -x BAT_PAGER ""
    set -x GIT_PAGER "delta --paging=never"
end

# ripgrep config
set -x RIPGREP_CONFIG_PATH "$HOME/.config/ripgrep/rc"

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

# Only alias the most commonly used commands to reduce startup time.
# Check each g* binary individually (rather than gating on gcat alone) so a
# partial coreutils install doesn't silently skip every alias below it.
# Use hardcoded path for M1/M2 Macs (adjust if on Intel Mac)
set brew_prefix /opt/homebrew
for pair in cp:gcp date:gdate echo:gecho mv:gmv rm:grm sed:gsed sort:gsort tail:gtail
    set -l parts (string split ":" $pair)
    if test -x "$brew_prefix/bin/$parts[2]"
        alias $parts[1]="$brew_prefix/bin/$parts[2]"
    end
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

# Search for all files with matching name in wiki
function wiki_file
    fd . --base-directory="$HOME/Dropbox/wiki/" --type=file \
        | fzf --tmux center,85%,75% \
        --preview "bat --style=numbers --color=always --paging=never $HOME/Dropbox/wiki/{}" \
        --preview-window="right:65%" \
        --bind "enter:become(nvim $HOME/Dropbox/wiki/{})"
end
bind \cg wiki_file

# Search for all files *containing* text
function wt
    rg $argv[1] --files-with-matches ~/Dropbox/wiki/zettel/ \
        | fzf --tmux center,85%,75% \
        --preview "bat --style=numbers --color=always --paging=never {}" \
        --preview-window="right:65%" \
        --bind "enter:become(nvim {})"
end

# Open file in existing nvim instance if inside nvim terminal, otherwise new nvim
function e
    if set -q NVIM
        nvim --server "$NVIM" --remote-tab $argv
    else
        nvim $argv
    end
end

# Yazi with cd-on-exit: navigating in yazi changes the shell's working directory
function y
    set tmp (mktemp -t "yazi-cwd.XXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
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

# Run tmp/scratch.sql against duckdb (default: in-memory, or pass a db path)
function dq
    if not test -f tmp/scratch.sql
        echo "dq: tmp/scratch.sql not found"
        return 1
    end
    duckdb $argv[1] <tmp/scratch.sql
end

# Same as dq, but pipe CSV output into visidata
function dv
    if not test -f tmp/scratch.sql
        echo "dv: tmp/scratch.sql not found"
        return 1
    end
    duckdb -csv $argv[1] <tmp/scratch.sql | vd -f csv -
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
