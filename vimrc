"{{{ VIM BUNDLES

" Vim, not Vi!
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

" Additional text objects for vim
Bundle 'wellle/targets.vim'

" Show list of buffers
Plugin 'bling/vim-bufferline'

"}}}
"{{{ GENERAL CONFIG

" I don't use swap files
set noswapfile

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

" Stronger file encryption
set cryptmethod=blowfish

" Do not display vim start-up text
set shortmess+=I

" Use system clipboard
set clipboard=unnamed

" Write buffers without prompting
set autowrite

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

" N rows at top and bottom of screen
set scrolloff=9999

" }}}
" {{{ APPEARANCE
let g:solarized_termcolors = 256
let g:solarized_termtrans  = 1
colorscheme solarized

" Add number column on left-hand side
set number

set cursorline

set background=dark
highlight clear CursorLine
highlight CursorLine term=underline cterm=underline

" Enable viewing of fancy characters
set encoding=utf-8

" Use patched fonts for powerline status bar
let g:airline_powerline_fonts = 1

" }}}
" {{{ FUNCTIONS


" Insert ISO-8601 date
function! Iso8601Date()
  set formatoptions-=a
  r!date "+\%FT\%TZ"
  set formatoptions+=a
endfunction

" Insert human readable date
function! HumanDate()
  r!date
endfunction

" Removes trailing spaces

function! TrimWhiteSpace()
  %s/\s\+$//e
endfunction
autocmd BufWritePre * :call TrimWhiteSpace()

"}}}
"{{{ FILETYPES

set wildignore=*.pyc,*.egg-info/*

au BufNewFile,BufRead *.muttrc          set filetype=muttrc
au BufNewFile,BufRead GHI_*,*.md,*.Rmd  set filetype=markdown
au BufNewFile,BufRead Vagrantfile       set filetype=ruby
au BufNewFile,BufRead *.cwl             set filetype=yaml

autocmd User GnuPG setfiletype markdown

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
map l <nop>

" Up motion
map k <Plug>(easymotion-bd-b)

" Down motion
map j <Plug>(easymotion-bd-w)

" Faster Esc
inoremap jj <ESC>

" Double leader writes the file
nnoremap <leader><leader> <Esc>:w<CR>

" Prevent from entering Ex mode
nnoremap Q <nop>

" }}}
"{{{ ARROW KEY MAPS
map <up>    <nop>
map <down>  <nop>
map <left>  <nop>
map <right> <nop>
" }}}
"{{{ LEADER KEY MAPS
" {{{ UPPER LEFT
nnoremap <leader>q <ESC>:1<CR>a= <ESC>:call HumanDate()<CR>0bJA =<CR><CR><ESC>
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
" }}} {{{ LOWER LEFT

" Pull current word into S&R
nnoremap <leader>z :%s#\<<C-r>=expand("<cword>")<CR>\>#
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
nnoremap <leader>l <nop>
nnoremap <leader>k <nop>
" }}}
" {{{ LOWER RIGHT
nnoremap <leader>/ <nop>
nnoremap <leader>. <nop>
" nnoremap <leader>, <nop> " Commented out because this is the leader key
nnoremap <leader>m <nop>
" }}}
" }}}
"{{{ LEADER NUMBER KEY MAPS - COMMON LOCATIONS

nnoremap <leader>1 :e ~/Dropbox/personal/journal.gpg<CR>
nnoremap <leader>2 :e ~/Dropbox/personal/wiki/index.wiki<CR>
nnoremap <leader>3 :ScratchPreview<CR>
nnoremap <leader>4 <nop>
nnoremap <leader>5 <nop>
nnoremap <leader>6 <nop>
nnoremap <leader>7 <nop>
nnoremap <leader>8 <nop>
nnoremap <leader>9 <nop>
nnoremap <leader>0 :e $MYVIMRC<CR>                                " My .vimrc file

" }}}
"{{{ FUNCTION KEY MAPS - COMMON ACTIONS

nnoremap <F1>  <ESC>:source $MYVIMRC<CR> " Re-source the vimrc file
set pastetoggle=<F2>
nnoremap <F3>  <ESC>:2,.w !echo `wc -w` words<CR>
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
