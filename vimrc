"{{{ GENERAL CONFIG

" Filetype-specific indenting and plugins
filetype plugin indent on

" Map leader key to comma
let mapleader = ","

" Modelines are a security risk
set modelines=0

" Vim, not Vi!
set nocompatible

" Don't try to use screen/tmux as a shell
set shell=/bin/sh

" Specify language
language en_GB.UTF-8

" Set temporary directory for swp/tmp files
set directory=$HOME/.vim/tmp

" Set large history size
set hi=1000

" Flash instead of beep
set visualbell

" Use grep instead of ack
set grepprg=ack

" Don't add spaces when joining lines
set nojoinspaces

" Much stronger file encryption
set cryptmethod=blowfish

" Do not display vim start-up text
set shortmess+=I

if v:version >= 703
  " Keep undo file of previous actions
  set undofile
  set undodir=$HOME/.vim/tmp
  set colorcolumn=85        " Highlight when line reaches this length
endif

" }}}

" Faster Esc
inoremap jj <ESC>

" Double leader writes the file
nnoremap <leader><leader> <Esc>:w<CR>

"{{{ ARROW KEY MAPS
map <up>    <nop>
map <down>  <nop>
map <left>  <nop>
map <right> <nop>
" }}}
"{{{ LEADER KEY MAPS
" {{{ UPPER LEFT
nnoremap <leader>q <nop>
nnoremap <leader>w <nop>
nnoremap <leader>e <nop>
nnoremap <leader>E <nop>
nnoremap <leader>r <nop>
nnoremap <leader>t <nop>
" }}}
" {{{ HOME LEFT
nnoremap <leader>a <nop>
nnoremap <leader>s <nop>
nnoremap <leader>d <nop>
nnoremap <leader>f <nop>
nnoremap <leader>g <nop>
" }}}
" {{{ LOWER LEFT
nnoremap <leader>z <nop>
nnoremap <leader>x <nop>
nnoremap <leader>c <nop>
nnoremap <leader>v <nop>
" }}}
" {{{ UPPER RIGHT
nnoremap <leader>p <nop>
nnoremap <leader>o <nop>
nnoremap <leader>i <nop>
" }}}
" {{{ HOME RIGHT
nnoremap <leader>; <nop>
nnoremap <leader>l <nop>
nnoremap <leader>k <nop>
nnoremap <leader>j <nop>
" }}}
" {{{ LOWER RIGHT
nnoremap <leader>/ <nop>
nnoremap <leader>. <nop>
" nnoremap <leader>, <nop> " Commented out because this is the leader key
nnoremap <leader>m <nop>
" }}}
" }}}
"{{{ LEADER NUMBER KEY MAPS - COMMON OPERATIONS

nnoremap <leader>1 <ESC>:source $MYVIMRC<CR> " Re-source the vimrc file
nnoremap <leader>2 <nop>
nnoremap <leader>3 <nop>
nnoremap <leader>4 <nop>
nnoremap <leader>5 <nop>
nnoremap <leader>6 <nop>
nnoremap <leader>7 <nop>
nnoremap <leader>8 <nop>
nnoremap <leader>9 <nop>
nnoremap <leader>0 <nop>

" }}}
"{{{ FUNCTION KEY MAPS - COMMON LOCATIONS

nnoremap <F1>  :e $MYVIMRC<CR> " Edit the .vimrc file
nnoremap <F2>  <nop>
nnoremap <F3>  <nop>
nnoremap <F4>  <nop>
nnoremap <F5>  <nop>
nnoremap <F6>  <nop>
nnoremap <F7>  <nop>
nnoremap <F8>  <nop>
nnoremap <F9>  <nop>
nnoremap <F10> <nop>
nnoremap <F11> <nop>
nnoremap <F12> <nop>

" }}}
