"{{{ PATHOGEN
filetype on
filetype off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

" }}}
"{{{ GENERAL CONFIG

mapclear
filetype plugin indent on " Enable filetype-specific indenting and plugins
let mapleader = ","       " Map leader key to comma
set modelines=0           " Modelines are a security risk
set nocompatible          " We're running Vim, not Vi!
set shell=/bin/sh         " Don't try to use screen as a shell
language en_GB.UTF-8      " Specify language
set directory=$HOME/.vim/tmp " Set temporary directory for swp/tmp files
set hi=1000               " Set large history size
set hidden                " Manage multiple buffers in background
set visualbell            " Flash instead of beep
set grepprg=ack           " Use grep instead of ack
set autoindent            " Autoindent text
set copyindent            " Copy indentation when indenting
set cryptmethod=blowfish
set nojoinspaces          " Don't add spaces when joining lines
set backspace=indent,eol,start " Make backspace work in insert mode

set shortmess+=I          " Do not display vim start-up text

set list                  " Highlight whitespace characters
set listchars=trail:.,extends:#

if v:version >= 703
  set undofile              " Keep undo file of previous actions
  set undodir=$HOME/.vim/tmp
  set relativenumber        " Relative line numbering
  set colorcolumn=85        " Highlight when line reaches this length
endif

let g:yankring_persist = 1  " Persist yankring data

" }}}
"{{{ MOVEMENT

" Move over wrapped lines as expected
nnoremap j gj
nnoremap k gk

" Faster Esc
inoremap <Esc> <nop>
inoremap jj <ESC>

" Jump to marked line AND column
nnoremap ' `
nnoremap ` '

" Use colon insead of semi colon for command mode
" Saves pressing shift
nnoremap ; :

" }}}
"{{{ SEARCHING

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
"{{{ TABS

set tabstop=2             " Tab equals two spaces
set shiftwidth=2
set softtabstop=2
set expandtab

" }}}
"{{{ FOLDING

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
" }}}
"{{{ APPEARANCE

syntax on                 " Enable syntax highlighting
set scrolloff=3           " keep 3 lines above and below the cursor

set wrap
set textwidth=79

set laststatus=2                " Always show status line
set cmdheight=2                 " Status line is two rows high
set statusline=%<%f\ %h%m%r%=%-20.(line=%l,col=%c%V,totlin=%L%)\%h%m%r%=%-40(,%n%Y%)\%P

" }}}
"{{{ NON-FANCY APPEARANCE

colorscheme vividchalk

" }}}
"{{{ XTERM-256 APPEARANCE
if &term == "xterm-256color"

  set t_Co=256              " Explicitly set 256 color support
  set background=dark
  let g:solarized_termcolors=256
  colorscheme solarized

  set cursorline
  set foldtext=MyFoldText()

endif
" }}}
"{{{ GUI APPEARANCE
if has("gui_running")

  set t_Co=256              " Explicitly set 256 color support
  colorscheme molokai

  set cursorline
  set foldtext=MyFoldText()

  " Window size
  let g:halfsize = 86
  let g:fullsize = 171
  set lines=50
  let &columns = g:halfsize

  set guifont=Inconsolata:h15.00 " Font
  set guioptions-=T              " No toolbar
  set guioptions+=c              " Use console dialogs

  set guioptions-=l              " No scroll bars on left or right
  set guioptions-=L
  set guioptions-=r
  set guioptions-=R

  " Full screen options
  set fuoptions=background:Normal

endif
" }}}
"{{{ WINDOWS
" Move between windows using control
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
" }}}
"{{{ FILE NAVIGATION

set wildmenu                    " Tab completion for and files/buffers
set wildmode=list:full          " Show a list for file tab completion
set wildignore+=.git " Files to ignore

" }}}
"{{{ EDITING

set formatoptions+=q " Format comments
set formatoptions+=r " Insert comment leader when opening a new line

" }}}
"{{{ FUNCTIONS

" Underline current line
function! Underline()
  yank
  put
  s/./-/
endfunction

" Insert underlined date
function! InsertDate()
  set formatoptions-=a
  r!date "+\%A \%B \%d, \%Y"
  call Underline()
  set formatoptions+=a
endfunction

" Turn format options on and off
function! ToggleFormatOptions()
  if &formatoptions == ""
    let &formatoptions = g:OldFormatOptions
  else
    let g:OldFormatOptions = &formatoptions
    let &formatoptions = ""
  end
endfunction

"}}}
"{{{ KEY MAPS
" {{{ ARROW KEYS   - UNBOUND
map <up>    <nop>
map <down>  <nop>
map <left>  <nop>
map <right> <nop>
" }}}
" {{{ UPPER LEFT   - EDITING
nnoremap <leader>q :YRShow<CR>
nnoremap <leader>w :TComment<CR>
nnoremap <leader>e :set paste<CR>
nnoremap <leader>E :set nopaste<CR>
nnoremap <leader>r :GundoToggle<CR>
nnoremap <leader>t :call ToggleFormatOptions()<CR>
" }}}
" {{{ HOME LEFT    - FILE/BUFFER NAVIGATION
nnoremap <leader>a :CommandT<CR>
nnoremap <leader>s :NERDTreeToggle<CR>
nnoremap <leader>d :CommandTBuffer<CR>
nnoremap <leader>f :Ack<SPACE>
nnoremap <leader>g :b#<CR> " Alternate buffer/file
" }}}
" {{{ LOWER LEFT   - GIT
nnoremap <leader>z :Gstatus<CR>
nnoremap <leader>x :Gwrite<CR>
nnoremap <leader>c :Gcommit<CR>
nnoremap <leader>v <nop>
" }}}
" {{{ UPPER RIGHT  - MINOR EDIT SHORTCUTS
nnoremap <leader>p :call Underline()<CR>
nnoremap <leader>o :call InsertDate()<CR>
nnoremap <leader>i :%s#\<<C-r>=expand("<cword>")<CR>\># " Search/replace word
let g:EasyMotion_leader_key = '<leader>u'
" }}}
" {{{ HOME RIGHT
nnoremap <leader>; <nop>
nnoremap <leader>l <nop>
nnoremap <leader>k <nop>
nnoremap <leader>j <nop>
" }}}
" {{{ LOWER RIGHT  - FILE ACTIONS
nnoremap <leader>/ <Esc>:w!! w !sudo tee % >/dev/null<CR>
nnoremap <leader>. <nop>
nnoremap <leader><leader> <Esc>:w<CR>
nnoremap <leader>m <Esc>:make<CR>
" }}}

" }}}
"{{{ NUMBER KEY MAPS

nnoremap <leader>1 :e $MYVIMRC<CR>
nnoremap <leader>2 :e ~/Dropbox/nv/reflection.txt<CR>
nnoremap <leader>3 :e ~/Dropbox/nv/goals.txt<CR>
nnoremap <leader>4 :CommandT ~/.dotfiles/<CR>
nnoremap <leader>5 :CommandT ~/Dropbox/nv/<CR>
nnoremap <leader>6 :CommandT ~/.bioinformatics-zen/content/markup/<CR>
nnoremap <leader>7 <nop>
nnoremap <leader>8 <nop>
nnoremap <leader>9 :CommandT spec<CR>
nnoremap <leader>0 :CommandT lib<CR>

" }}}
"{{{ FUNCTION KEY MAPS

nnoremap <F1>  :edit `post `<left>
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
"{{{ NERDTREE

let NERDTreeShowFiles=1           " Show hidden files
let NERDTreeShowHidden=1
let NERDTreeQuitOnOpen=1          " Quit on opening files from the tree
let NERDTreeHighlightCursorline=1 " Highlight the selected entry in the tree

" Don't display these kinds of files
let NERDTreeIgnore = []
let NERDTreeIgnore += ['^\.git$']
let NERDTreeIgnore += ['^\.rake_tasks$']
let NERDTreeIgnore += ['^.DS_Store$']
let NERDTreeIgnore += ['^.document$']
let NERDTreeIgnore += ['^.yardoc$']
let NERDTreeIgnore += ['^.sass-cache$']
let NERDTreeIgnore += ['^pkg$']
let NERDTreeIgnore += ['^doc$']
let NERDTreeIgnore += ['^Gemfile.lock$']
let NERDTreeIgnore += ['^.rspec$']
let NERDTreeIgnore += ['^cucumber.yml$']
let NERDTreeIgnore += ['^LICENSE.txt$']
let NERDTreeIgnore += ['^VERSION$']
let NERDTreeIgnore += ['^.gitignore$']
let NERDTreeIgnore += ['^\.autotest$']
let NERDTreeIgnore += ['^autotest$']
let NERDTreeIgnore += ['^tmp$']
let NERDTreeIgnore += ['^\.travis.yml']
let NERDTreeIgnore += ['.aux', '.bbl', '.blg', '.dvi', '.log', '.pdf']

" }}}
"{{{ MISC

au FocusLost * :wa " Write file when focus moves away from editor

" }}}
"{{{ MY COMMON TYPOS
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
iab acorss across
" }}}
