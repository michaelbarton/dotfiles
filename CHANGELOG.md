# CHANGELOG

## 2022-12-13

- Convert `today` alias to a bash script that copies over the template file.
- Update dictionary
- Add gruvbox as a light theme

## 2022-12-01

- Add shell script helpers for running common bioinformatics tools.
- Add python script for converting blast to coverage file.
- Increase font size

## 2022-11-01

- Update wiki scripts

## 2022-10-31

- Use Nord colours for iterm and vim

## 2022-09-30

- Add vim plugin for moving, deleting, ... files.
- Additional aliases working files.

## 2022-08-22

- Remove vundle submodule.
- Fix ansible install steps.
- Fix for fish shell path in tmux.
- iterm is setup using the iterm profiles instead.

## 2022-08-22

- Use vim wiki for personal wiki.
- Add telescope vim plugin.

## 2022-07-23

- Additional commands for searching personal wiki
- Update dictionary.

## 2022-02-17

- Additional scripts for working with yml and parquet.
- Update dictionary.

## 2022-01-24

- Add script preview parchet.
- Add script to convert md to docx
- Add script to fetch genome FASTA
- Add script to preview hocon files.
- Justfile syntax highlighting
- `git merge` no longer tries to sign commit.
- iterm2 starts in cache directory.

## 2021-12-03

- Add scripts to fetch data from NCBI.
- Run black on python files.
- Streamline output file from converting daily log

## 2021-11-17

- Fix shell path so python venv bin is first.
- Fix syntax highlighting in less.

## 2021-11-15

- Remove unused git submodules
- Update README
- Add additional bash and fish shortcuts
- Remove zshrc

## 2021-11-10

- Add HTML syntax support to vim
- The asdf language manager uses `brew ---prefix` instead of hard coded path.
- Remove code completion plugin for the time being.
- Remove tmux `escape-time` option that was causing issues with command line
  edit in fish.

## 2021-11-09

- Add support for using fzf in vim

## 2021-11-08

- Remove old and out of date files.
- Additional vim short cuts.
- Move aspell files to directory.

## 2021-11-05

- Fix for parsing pubmed dates when creating markdown page.
- Move fish config files to top-level directory.
- Add fish syntax highlighting to vim.
- Symbolic link for aspell dictionary.
- Use exa instead of ls

## 2021-11-04

- Add rc for nvim at nvim/init.vim
- Update markdown filetype settings to use the vim-markdown plugin.
- Remove old `shell_settings` directory instead use `.bashrc` for common functions
  between shells.
- Use ansible to install all dotfiles
- Add a script to create markdown pages from pubmed entries.
