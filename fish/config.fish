#!/usr/local/bin/fish

bass source ~/.bashrc

starship init fish | source

function sp
	aspell -c $argv[1] && ~/.dotfiles/bin/sort_dictionary
end

# Language version manager
source /opt/homebrew/opt/asdf/libexec/asdf.fish
