" PATHOGEN {{{
filetype on
filetype off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

" }}}

" GENERAL CONFIG {{{

filetype plugin indent on " Enable filetype-specific indenting and plugins
let mapleader = ","       " Map leader key to comma
set modelines=0           " Modelines are a security risk
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

if v:version >= 703
  set undofile              " Keep undo file of previous actions
  set undodir=/tmp
  set relativenumber        " Relative line numbering
  set colorcolumn=85        " Highlight when line reaches this length
endif

" }}}

" SEARCHING {{{

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

" }}}

" TABS {{{

set tabstop=2             " Tab equals two spaces
set shiftwidth=2
set softtabstop=2
set expandtab

" }}}

" APPEARANCE {{{

syntax on                 " Enable syntax highlighting
set scrolloff=3           " keep 3 lines above and below the cursor

set background=dark       " Terminal color scheme
colorscheme delek

set wrap
set textwidth=79
set formatoptions=qrn1

set laststatus=2                " Always show status line
set cmdheight=2                 " Status line is two rows high
set statusline=%<%f\ %h%m%r%=%-20.(line=%l,col=%c%V,totlin=%L%)\%h%m%r%=%-40(,%n%Y%)\%P

" }}}

" GUI APPEARANCE {{{
if has("gui_running")

  " Window size
  let g:halfsize = 86
  let g:fullsize = 171
  set lines=50
  let &columns = g:halfsize

  set guifont=Inconsolata:h17.00 " Font
  set guioptions-=T              " No toolbar
  set guioptions+=c              " Use console dialogs

  set guioptions-=l              " No scroll bars on left or right
  set guioptions-=L
  set guioptions-=r
  set guioptions-=R

  colorscheme molokai            " GUI colorscheme

  set cursorline                 " highlight the line the cursor is on

  function! ToggleWindowSize()
    if &columns == g:halfsize
      let &columns = g:fullsize
    else
      let &columns = g:halfsize
    end
  endfunction
  nmap <F1> :call ToggleWindowSize()<CR>

endif
" }}}

" WINDOWS {{{

" Move between windows using control
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
" Open new horizontal split window
nnoremap <leader>wh <C-w>v<C-w>l
" Close current window
nnoremap <leader>wj <ESC>:close<CR>
" }}}

" FILE NAVIGATION {{{

set wildmenu                    " Tab completion for and files/buffers
set wildmode=list:full          " Show a list for file tab completion
set wildignore+=.git " Files to ignore

" }}}

" EDITING {{{

" set formatoptions-=o " don't start new lines w/ comment leader on pressing 'o'
" set formatoptions+=t " auto format text as it's being edited
" set formatoptions+=c " only text wrap comments

" Pull word under cursor into LHS of a substitute (for quick search and
" replace)
nmap <leader>z :%s#\<<C-r>=expand("<cword>")<CR>\>#

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

" }}}

" NERDTREE {{{

let NERDTreeShowFiles=1           " Show hidden files
let NERDTreeShowHidden=1
let NERDTreeQuitOnOpen=1          " Quit on opening files from the tree
let NERDTreeHighlightCursorline=1 " Highlight the selected entry in the tree

" Don't display these kinds of files
let NERDTreeIgnore = []
let NERDTreeIgnore += ['^\.git$']
let NERDTreeIgnore += ['.rake_tasks']
let NERDTreeIgnore += ['.DS_Store']
let NERDTreeIgnore += ['.document']
let NERDTreeIgnore += ['.yardoc']
let NERDTreeIgnore += ['.sass-cache']
let NERDTreeIgnore += ['pkg']
let NERDTreeIgnore += ['doc']
let NERDTreeIgnore += ['Gemfile.lock']

" }}}

" IMPORTANT KEY MAPS {{{

" Reformat entire text width
nmap <leader>b gggqG

" Write the file
nmap <leader><leader> :w<CR>

" Folding
nnoremap <Space> za
vnoremap <Space> za

" Gundo
nnoremap <leader>u :GundoToggle<CR>

" Yank ring
nnoremap <leader>q :YRShow<CR>

" Make
nnoremap <leader>m <Esc>:make<CR>

" Ack 
nnoremap <leader>t :Ack<SPACE>

" NERDTree
nmap <leader>e :NERDTreeClose<CR>:NERDTreeToggle<CR>
nmap <leader>E :NERDTreeClose<CR>

" buffers
nnoremap <leader>a :LustyJuggler<CR>

" Command T search
nnoremap <leader>rr :CommandT<CR>
let g:CommandTMaxHeight = 10

" Bubble text using unimpaired
" single lines
nmap <D-k> [e
nmap <D-j> ]e
" visual model selected lines
vmap <D-k> [egv
vmap <D-j> ]egv

" }}}

" FOLDING {{{

set foldenable
set foldlevelstart=0      " Start with everything folded
set foldcolumn=2          " Extra column to highlight folds
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
" }}}

" MISC {{{

" Edit edit/reload the vimrc file
nmap <silent> <leader>ve :e $MYVIMRC<CR>
nmap <silent> <leader>vs :w<CR>:so $MYVIMRC<CR>

au FocusLost * :wa " Write file when focus moves away from editor

" Write current file as sudo
cmap w!! w !sudo tee % >/dev/null<CR>
" }}}

" MY COMMON TYPOS {{{
" Switch to abolish when this gets out of hand

" command line
cmap B<Space> buf<Space>
cmap Bd<Return> bd<Return>
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
iab statment statement
" }}}
