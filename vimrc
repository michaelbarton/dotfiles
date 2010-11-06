" Pathogen needs this
filetype on
filetype off

" Load pathogen bundles
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

let mapleader = ","       " Map leader key to comma

"
" VARIOUS CONFIG
"

set modelines=0
filetype plugin indent on " Enable filetype-specific indenting and plugins
set nocompatible          " We're running Vim, not Vi!
set shell=/bin/sh         " Don't try to use screen as a shell
language en_GB.UTF-8      " Specify language
set directory=/tmp/       " Set temporary directory for swp/tmp files
set t_Co=256              " Explicitly set 256 color support
set hi=1000               " Set large history size
set hidden                " Manage multiple buffers in background
set visualbell            " Flash instead of beep
set grepprg=ack           " Use grep instead of ack
set autoindent            " Autoindent text
set copyindent            " Copy indentation when indenting
set backspace=indent,eol,start " Make backspace work in insert mode

set list                  " Highlight whitespace characters
set listchars=trail:.,extends:#


"
" SEARCHING
"


set ignorecase            " Ignore case in searching
set smartcase             " ... unless searches contrain upper case letters
set incsearch             " show the `best match so far' as searches are typed
set hlsearch              " highlight matched searches
set gdefault              " make all substitutions global

" Turn off highlighted searches
nnoremap <leader><space> :noh<cr>
" Use normal regexes
nnoremap / /\v
vnoremap / /\v


"
" TABS
"


set tabstop=2             " Tab equals two spaces
set shiftwidth=2
set softtabstop=2
set expandtab


"
" APPEARANCE
"


syntax on                 " Enable syntax highlighting
set cursorline            " highlight the line the cursor is on
set scrolloff=3           " keep 3 lines above and below the cursor

set background=dark       " Terminal color scheme
colorscheme delek

set wrap
set textwidth=79
set formatoptions=qrn1

set statusline=%<%f\ %h%m%r%=%-20.(line=%l,col=%c%V,totlin=%L%)\%h%m%r%=%-40(,%n%Y%)\%P


"
" WINDOW NAVIGATION
"


" Move between windows using control
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
" Open new horizontal split window
nnoremap <leader>wh <C-w>v<C-w>l
" Close current window
nnoremap <leader>wj <ESC>:close<CR>


"
" MOVEMENT
"


" Unbind the arrow keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

" Move over wrapped lines as expected
nnoremap j gj
nnoremap k gk

" Faster Esc
inoremap <Esc> <nop>
inoremap jj <ESC>

" Use colon insead of semi colon for command mode
" Saves pressing shift
nnoremap ; :

" Jump to marked line AND column
nnoremap ' `
nnoremap ` '


"
" ACTION KEY MAPS
"


" Gundo
nnoremap <leader>u :GundoToggle<CR>

" Yank ring
nnoremap <leader>q :YRShow<CR>

" Make
nnoremap <leader>m <Esc>:make<CR>

" Ack 
nnoremap <leader>r :Ack<SPACE>

" NERDTree
nnoremap <leader>e :NERDTreeToggle<CR>

" buffers
nnoremap <leader>a :LustyJuggler<CR>

" Command T search
nnoremap <leader>t :CommandT<CR>


"
" FOLDING
"


set foldnestmax=4         " Maximum level of folding is 4
set foldmethod=syntax     " Code folding based on the filetype

" Steve Losh fold text method
function! MyFoldText()
    let line = getline(v:foldstart)

    let nucolwidth = &fdc + &number * &numberwidth
    let windowwidth = winwidth(0) - nucolwidth - 3
    let foldedlinecount = v:foldend - v:foldstart

    " expand tabs into spaces
    let onetab = strpart('          ', 0, &tabstop)
    let line = substitute(line, '\t', onetab, 'g')

    let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount) - 4
    return line . '…' . repeat(" ",fillcharcount) . foldedlinecount . '…' . ' '
endfunction
set foldtext=MyFoldText()


"
" MISC
"


" Edit edit/reload the vimrc file
nmap <silent> <leader>ve :e $MYVIMRC<CR>
nmap <silent> <leader>vs :w<CR>:so $MYVIMRC<CR>

au FocusLost * :wa " Write file when focus moves away from editor

" Write current file as sudo
cmap w!! w !sudo tee % >/dev/null<CR>


"
" MY COMMON TYPOS
"

" Switch to abolish when this gets out of hand

" command line
cmap B<Space> buf<Space>
cmap Bd<Space> bd<Space>
cmap W<Return> w<Return>
cmap X<Return> x<Return>
cmap w1<Return> w!<Return>

" insert mode
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
