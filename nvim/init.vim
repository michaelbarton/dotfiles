" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

" Markdown file support
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
Plug 'junegunn/limelight.vim', { 'for': 'markdown' }

" Dark Nord colour scheme
Plug 'arcticicestudio/nord-vim'

" Light gruvbox colour scheme
Plug 'morhetz/gruvbox'

" Language specific plugins
Plug 'plasticboy/vim-markdown'
Plug 'elzr/vim-json'
Plug 'dag/vim-fish'
Plug 'NoahTheDuke/vim-just'
Plug 'LukeGoodsell/nextflow-vim'

" status bar
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Seemless navigation between vim and tmux windows
Plug 'christoomey/vim-tmux-navigator'

" Support for fzf for searching files
" TODO: Consider phasing this out and use telescope instead.
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Using telescope for searching files
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" HTML tags
Plug 'mattn/emmet-vim'

" Vimwiki setup for zettelkasten
Plug 'vimwiki/vimwiki'

" Support simple commands such as deleting and renaming files and buffers
Plug 'tpope/vim-eunuch'

" Initialize plugin system
call plug#end()

autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

"
" GENERAL CONFIG
"

" Map leader key to comma
let mapleader = ","

" Don't try to use screen/tmux as a shell
set shell=/bin/bash

" Specify language
language en_GB.UTF-8

" Set temporary directory for swp/tmp files
set directory=$HOME/.vim/tmp

" Set large history size
set hi=1000

" Flash instead of beep
set visualbell

" Don't add spaces when joining lines
set nojoinspaces

" Write buffers without prompting
set autowrite

" Keep undo file of previous actions
set undofile
set undodir=$HOME/.vim/tmp
set colorcolumn=85        " Highlight when line reaches this length


"
" FUNCTIONS
"

" Removes trailing spaces on write
function! TrimWhiteSpace()
  %s/\s\+$//e
endfunction
autocmd BufWritePre * :call TrimWhiteSpace()
autocmd FileType html setlocal shiftwidth=2 tabstop=2

" Search for files in wiki
command! -bang WikiSearch call fzf#vim#files('~/Dropbox/wiki', <bang>0)

" Insert file path from wiki
inoremap <expr> <c-x><c-f> fzf#vim#complete#path(
	\ 'fd --base-directory ~/Dropbox/wiki --type file \| sed -e "s#zettel/##;s#literature/##g;s#\.md##"')

"
" FILE TYPES
"

set wildignore=*.pyc,*.egg-info/*
autocmd BufRead,BufNewFile *.njk setfiletype html


"
" APPEARANCE
"

colorscheme nord

" Add number column on left-hand side
set number

set cursorline

set background=dark
highlight clear CursorLine
highlight CursorLine term=underline cterm=underline

" Enable viewing of fancy characters
set encoding=utf-8

let g:airline_powerline_fonts = 1

set termguicolors

"
" SETTINGS FOR VIM WIKI
"


let g:vimwiki_list = [{'path': '~/Dropbox/wiki/zettel', 'syntax': 'markdown', 'ext': '.md'}]
let g:vimwiki_ext2syntax = {'.md': 'markdown', '.markdown': 'markdown', '.mdown': 'markdown'}

"  This will make sure vimwiki will only set the filetype of markdown files
"  inside a wiki directory, rather than globally.
"
"  See: https://www.reddit.com/r/vim/comments/9riu4c/using_vimwiki_with_markdown/e8hag4f/?context=8&depth=9
let g:vimwiki_global_ext = 0


"
" GENERAL KEY MAPS
"

" Faster Esc
inoremap jj <ESC>

" Double leader writes the file
nnoremap <leader><leader> <Esc>:w<CR>

" Prevent from entering Ex mode
nnoremap Q <nop>

" Leader key maps
nnoremap <leader>f :nohlsearch<CR>
nnoremap <leader>g :b#<CR>    " Switch to the last used buffer

" Use F1 to source the vimrc file
nnoremap <F1>  <ESC>:source $MYVIMRC<CR>

" Use F2 to turn on unformatted pasting of text.
set pastetoggle=<F2>

" Use F3 to search wiki files when not in insert mode
nnoremap <F3>  <ESC>:WikiSearch<CR>

" Paste the current date header
inoremap <F3> <C-R>=strftime("## [[%Y%m%d]]")<CR>

" Create new entry in the wiki
let g:wiki = "~/Dropbox/wiki/"
command! -nargs=1 NewZettel :execute ":e" wiki . "zettel/" . strftime("%Y%m%d%H%M") . "_<args>.md"
command! -nargs=1 NewBlogIdea :execute ":e" wiki . "blog/" . strftime("%Y%m%d%H%M") . "_<args>.md"
