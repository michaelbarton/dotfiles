set nocompatible          " We're running Vim, not Vi!
syntax on                 " Enable syntax highlighting
filetype plugin indent on " Enable filetype-specific indenting and plugins
set shell=/bin/sh         " Don't try to use screen as a shell
language en_GB.UTF-8      " Specify language
set number                " Line numbering
set directory=/tmp/       " Set temporary directory for swp/tmp files
set t_Co=256              " Explicitly set 256 color support
set foldnestmax=4         " Maximum level of folding is 4
set foldmethod=syntax     " Code folding based on the filetype
set hi=1000               " Set large history size
set hidden                " Manage multiple buffers in background
set visualbell            " Flash instead of beep
set grepprg=ack           " Use grep instead of ack
set nowrap                " Don't wrap lines around
set autoindent            " Autoindent text
set copyindent            " Copy indentation when indenting

set list                  " Highlight whitespace characters
set listchars=trail:.,extends:#

set ignorecase            " Ignore case in searching
set smartcase             " ... unless searches contrain upper case letters
set incsearch             " show the `best match so far' as searches are typed
set hlsearch              " highlight matched searches

colorscheme molokai       " Nice colors for sytax

set backspace=indent,eol,start " Make backspace work in insert mode

" Status line shown at the bottom of each window
set statusline=%<%f\ %h%m%r%=%-20.(line=%l,col=%c%V,totlin=%L%)\%h%m%r%=%-40(,%n%Y%)\%P

" Load pathogen bundles
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

let mapleader = ","       " Map leader key to comma

" Write current file as sudo
cmap w!! w !sudo tee % >/dev/null

" Use colon insead of semi colon for command mode
" Saves pressing shift
nnoremap ; :

" Move between windows using control
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" Unbind the arrow keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

" Edit edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

" End typing and write the file
imap XX <Esc>:w<CR> 

" Run make on current file
:map <leader>q <Esc>:make<CR>

" Ack key map
map <leader>r :Ack<SPACE>

" Activate NERDTree
map <leader>e :NERDTreeToggle<CR>


" Jump to marked line AND column
nnoremap ' `
nnoremap ` '


" command line typos
cmap B<Space> buf<Space>
cmap Bd<Space> bd<Space>
cmap W<Return> w<Return>
cmap w1<Return> w!<Return>

" insert mode typos
iab teh  the
iab th   the
iab hte  the
iab te   the
iab thsi this
iab htis this
iab tis  this
iab ths this
iab htese these
iab htat that
iab smae same
iab ot   to
iab fo   of
iab og   of
iab os   so
iab si   is
iab wiht with
iab od of
iab geneome genome
iab whihc which
iab involed involved
iab uou you
iab howeer however
iab wth with
iab thae the
iab descibe describe
iab nad and
iab adn and
