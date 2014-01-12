"{{{ VIM BUNDLES

" Vim, not Vi!
set nocompatible

" Required to setup Vundle
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

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
Bundle 'vim-scripts/VimClojure'

" Indent, syntax and detect files for clojure
Bundle 'vim-scripts/Align'

" Indent, syntax and detect files for clojure
Bundle 'vim-scripts/paredit.vim'

" Fast movement around file
Bundle 'Lokaltog/vim-easymotion'

Bundle 'bling/vim-airline'

" Interactive repl for vim
Bundle 'tpope/vim-fireplace'

"}}}
"{{{ GENERAL CONFIG

" Filetype-specific indenting and plugins
filetype plugin indent on

scriptencoding utf-8
set encoding=utf-8

" Map leader key to comma
let mapleader = ","

" Modelines are a security risk
set modelines=0

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
" {{{ MOVEMENT

let g:EasyMotion_leader_key = '<Space>'

" Highlight search matches
set hlsearch

" Ten rows at top and bottom of screen
set scrolloff=7

" Set backspace to work in all situations
set backspace=indent,eol,start

" }}}
" {{{ APPEARANCE
syntax enable
set t_Co=256              " Explicitly set 256 color support
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

" Add number column on left-hand side
set number

" Make the status bar appear
set laststatus=2

" Highlight the cursor position
set cursorline


" higlight trailing whitespace with a dot
set list listchars=trail:·

" }}}
" {{{ FUNCTIONS

" Insert date
function! InsertDate()
  set formatoptions-=a
  r!date "+\%A \%B \%d, \%Y"
  set formatoptions+=a
endfunction

"}}}
"{{{ FILETYPES

au BufNewFile,BufRead Vagrantfile setf ruby
au BufNewFile,BufRead *.fasta,*.fa,*.fna,*.faa setf fasta
au BufNewFile,BufRead *.tex.pre setf tex
au BufNewFile,BufRead *.txt setf txt
au BufNewFile,BufRead *.rdoc setf rdoc

" Edit gpg files securely
au BufNewFile,BufReadPre *.gpg :set secure vimi= noswap noback nowriteback hist=0 binary
au BufReadPost *.gpg :%!gpg -d 2>/dev/null
au BufWritePre *.gpg :%!gpg -e -r 'mail@michaelbarton.me.uk' 2>/dev/null
au BufWritePost *.gpg u

" }}}
" {{{ GUI

set guifont=Inconsolata:h17.00
set guioptions-=T " Remove toolbar
set guioptions+=c " Use console dialogs

set guioptions-=lLrR " Remove scroll bars

if has('gui_running')
let &columns = 90 " Number of columns in window
endif

" }}}
" {{{ GENERAL KEY MAPS

" Train myself not to use the home row keys to move around
map h <nop>
map j <nop>
map k <nop>
map l <nop>

" Faster Esc
inoremap jj <ESC>

" Double leader writes the file
nnoremap <leader><leader> <Esc>:w<CR>

inoremap qq http://issues.jgi-psf.org/browse/SEQQC-

" }}}
"{{{ ARROW KEY MAPS
map <up>    <nop>
map <down>  <nop>
map <left>  <nop>
map <right> <nop>
" }}}
"{{{ LEADER KEY MAPS
" {{{ UPPER LEFT
nnoremap <leader>q :r!date<CR>
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
nnoremap <leader>f :nohlsearch<CR>
nnoremap <leader>g :b#<CR>    " Switch to the last used buffer
" }}}
" {{{ LOWER LEFT
nnoremap <leader>z <nop>
nnoremap <leader>x <nop>
nnoremap <leader>c <nop>
nnoremap <leader>v <nop>
" }}}
" {{{ UPPER RIGHT
nnoremap <leader>u <nop>
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

nnoremap <F1>  :e $MYVIMRC<CR>                                " My .vimrc file
nnoremap <F2>  :e ~/Dropbox/personal/wiki/Futures.wiki<CR>    " My TODO page
nnoremap <F3>  :e ~/Dropbox/personal/wiki/index.wiki<CR>      " Index page for wiki
nnoremap <F4>  :e ~/Dropbox/personal/wiki/Reflection.wiki<CR>
nnoremap <F5>  :e ~/Dropbox/personal/wiki/Daily\ Todo.wiki<CR>
nnoremap <F6>  :e ~/Dropbox/personal/wiki/Evening\ Todo.wiki<CR>
nnoremap <F7>  :e ~/Dropbox/personal/wiki/Weekend\ Todo.wiki<CR>
nnoremap <F8>  :e ~/Dropbox/personal/wiki/Monthly\ Todo.wiki<CR>
nnoremap <F9>  <nop>
nnoremap <F10> <nop>
nnoremap <F11> <nop>
nnoremap <F12> <nop>

" }}}
