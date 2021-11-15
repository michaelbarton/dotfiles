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
