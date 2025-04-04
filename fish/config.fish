#!/usr/local/bin/fish

# Source bashrc, these are maintained so that a bash shell can still be used for debugging fish
bass source ~/.bashrc

# host specific environment variables, not version controlled
if test -f ~/.local/environment.bash
    bass source ~/.local/environment.bash
end

starship init fish | source
zoxide init fish | source

set fish_greeting ""

# Improve the ssh function to use mosh only when appropriate
function ssh
    if test (count $argv) -gt 0 && string match -qr '^[a-zA-Z0-9._-]+$' -- $argv[1]
        mosh $argv
    else
        command ssh $argv
    end
end

function sp
	aspell -c $argv[1] && ~/.dotfiles/aspell/sort_dictionary
end

# Cat th contents of a file into the clip board
function pbcat
	cat $argv[1] | pbcopy
end


# Use ctrl+s to fzf search the current directory
fzf_configure_bindings --directory=\cs

# Search for all files with matching name in patch.
#
# This can be interactive because fzf can filter on the file paths while typing.
function wiki_file
	fd . --base-directory="$HOME/Dropbox/wiki/" --type=file \
		| fzf --preview "bat --style=numbers --color=always $HOME/Dropbox/wiki/{}" --preview-window="right:65%" --height="70%"\
		| xargs -I {} -o nvim ~/Dropbox/wiki/{}
end
bind \cg wiki_file

# Search for all files *containing* text. No fish bound shortcut.
#
# An argument must be provided because ripgrep is run on all the files, then the
# fzf tool can be used to filter and search through the returned results.
function wt
	set dir (pwd)
	cd ~/Dropbox/wiki/zettel/ && rg $argv[1]  --files-with-matches \
		| fzf --preview 'bat --style=numbers --color=always {}' --preview-window="right:65%" --height="70%"\
		| xargs -I {} -o nvim ~/Dropbox/wiki/zettel/{}
	cd $dir
end

set -U*x* LESS_TERMCAP_us \e\[1\x3B32m
set -U*x* LESS_TERMCAP_md \e\[1\x3B31m
set -U*x* LESS_TERMCAP_mb \e\[01\x3B31m
set -U*x* LESS_TERMCAP_me \e\[0m
set -U*x* LESS_TERMCAP_se \e\[0m
set -U*x* LESS_TERMCAP_so \e\[01\x44\x33m
set -U*x* LESS_TERMCAP_ue \e\[0m
