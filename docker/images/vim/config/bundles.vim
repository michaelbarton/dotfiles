set nocompatible

" Required to setup Vundle
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Sensible vim plugins
Bundle "tpope/vim-sensible"

" let Vundle manage Vundle
Bundle 'gmarik/vundle'

" This plugin automatically reloads changed vim scripts in the current vim
" session. I like this because it makes it simple to add changes to
" vim/ftplugin/*.vim files and have the changes appear immediately.
Bundle 'xolox/vim-misc'
Bundle 'xolox/vim-reload'

" Nice colorscheme for vim
Bundle 'altercation/vim-colors-solarized'

" Personal wiki plugin. I prefer this one because it's simple and uses plain
" text files.
Bundle 'vim-scripts/vimwiki'

" Faster file searching
Bundle 'kien/ctrlp.vim'

" Indent, syntax and detect files for clojure
Bundle 'guns/vim-clojure-static'
Bundle 'kien/rainbow_parentheses.vim'

" Useful for aligning columns of text
Bundle 'vim-scripts/Align'

" Good for matching parentheses in lisps
Bundle 'vim-scripts/paredit.vim'

" Fast movement around file
Bundle 'Lokaltog/vim-easymotion'

" Default status line for vim
Bundle 'bling/vim-airline'

" Interactive clojure repl for vim
Bundle 'tpope/vim-fireplace'

" Syntax highlighting for Dockerfiles
Bundle "ekalinin/Dockerfile.vim"

" Seemless navigation between vim and tmux windows
Bundle 'christoomey/vim-tmux-navigator'

" Manage git repositories inside vim
Bundle 'tpope/vim-fugitive'

" Syntax highlighting for less file
Bundle 'groenewege/vim-less'

" GPG encrypted file
Bundle 'jamessan/vim-gnupg'
