" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

" Markdown file support
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
Plug 'junegunn/limelight.vim', { 'for': 'markdown' }

" Solarised colour scheme
Plug 'overcache/NeoSolarized'

" Language specific plugins
Plug 'plasticboy/vim-markdown'
Plug 'elzr/vim-json'
Plug 'dag/vim-fish'

" status bar
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'


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

" Removes trailing spaces on write

function! TrimWhiteSpace()
  %s/\s\+$//e
endfunction
autocmd BufWritePre * :call TrimWhiteSpace()

"
" APPEARANCE
"

colorscheme NeoSolarized

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

