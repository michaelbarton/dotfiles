#!/usr/local/bin/fish

bass source ~/.bashrc

starship init fish | source

function sp
	aspell -c $argv[1] && ~/.dotfiles/bin/sort_dictionary
end

# Cat th contents of a file into the clip board
function pbcat
	cat $argv[1] | pbcopy
end

# Language version manager
source (brew --prefix)/opt/asdf/libexec/asdf.fish

# Use ctrl+s to fzf search the current directory
fzf_configure_bindings --directory=\cs

# Quickly find and edit a file in the wiki
function wikisearch
	fd . --base-directory="$HOME/Dropbox/wiki/" | fzf | xargs -I {} -o nvim ~/Dropbox/wiki/{}
end
bind \cg wikisearch

set -U*x* LESS_TERMCAP_us \e\[1\x3B32m
set -U*x* LESS_TERMCAP_md \e\[1\x3B31m
set -U*x* LESS_TERMCAP_mb \e\[01\x3B31m
set -U*x* LESS_TERMCAP_me \e\[0m
set -U*x* LESS_TERMCAP_se \e\[0m
set -U*x* LESS_TERMCAP_so \e\[01\x44\x33m
set -U*x* LESS_TERMCAP_ue \e\[0m
