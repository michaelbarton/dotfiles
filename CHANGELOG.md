# CHANGELOG

## 2025-04-29

## 2025-04-29

- Changed nvim Python LSP from `basedpyright` to disabled by default
- Set shell to `fish` in nvim configuration
- Added ToggleTerm plugin for improved terminal management in nvim

## 2025-03-25

- Switch to LazyVim from kickstarter for nvim config.

## 2025-03-17

- Remove `apply_ansible` and move to Makefile.
- Update conform formatters.
- Add additional nvim plugins.

## 2025-03-09

- Reorganize file structure for better organization
- Remove tmux, irssi, and zsh configurations
- Additional nvim lua modules
- Minor fish shell config fixes
- Simplify and restructure README.md
- Remove .gitmodules file
- Update bash configuration with simplified aliases
- Remove old/unused scripts
- Remove Linux-specific apt packages file
- Replace nvim config with lua version
- Add ghostty config
- Remove iterm config
- Remove unused zettel files
- Update command for templating the today file

## 2024-09-08

- Add paperless-ngx setup

## 2024-05-18

- Add script to dump duckdb schema to file.
- Add python cookiecutter script.
- Add LLM prompt.
- Replace exa.
- Add script to convert poetry project to markdown.
- Add hammerspoon command to create window setup.
- Add npm PATH.
- Add additional bioinformatics scripts.
- Replace `process_today.sh` with automated version using launch agents.
- Remove copilot in vim

## 2023-04-07

- Fix path for creating wiki links
- Use `difft` for git diffs.
- Add script to get tax id from NCBI.
- PR layout in PR creation script.
- Add git lfs configuration.
- Add script query grafana.

## 2023-04-05

- Add bash script to create PR from CHANGELOG.md

## 2023-04-04

- Add fish completions for `gh`.
- Remove deprecated `convert_daily_log.py`.
- Update dictionary.
- Add script to remove unused git branches.
- Add script to bump poetry dependencies.
- Fix zettel path directory when creating a wiki link

## 2023-03-30

- Add nvim function to insert a wiki link found using fzf.
- Add python script to convert old format wiki entries into the new vimwiki
  format.
- The `today` script tries to insert a quote at the beginning.
- The `today` script loads a different template if it is a weekend.

## 2023-02-10

- Add `zoxide` command to fish.
- Add vim text alignment plugin.
- Update dictionary.

## 2023-01-17

- Added script to create the 'today' wiki file using a jinja template.
- Add bash shortcut to jump to temporary directory.
- Removed `convert_daily_log.py`. Use dedicated python package for this
  instead.
- Process today script also deletes the source file afterward.

## 2023-01-12

- Add CI workflow for checking files are formatted.
- Add markdown to pdf conversion script.
- Remove fish greeting.
- Add vim command to open current file in sublime.
- Fix aspell dictionary script.

## 2022-12-27

- Added parquet_less.sh script

## 2022-12-14

- Alias `mosh` to `ssh`.
- Add nextflow vim syntax highlighting.

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
