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

# Use ctrl+s to fzf search
fzf_configure_bindings --directory=\cs
