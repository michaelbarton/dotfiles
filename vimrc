set nocompatible          " We're running Vim, not Vi!
syntax on                 " Enable syntax highlighting
filetype plugin indent on " Enable filetype-specific indenting and plugins

language en_GB.UTF-8

set number

" Set temporary directory (don't litter local dir with swp/tmp files)
set directory=/tmp/

" Set to auto read when a file is changed from the outside
set autoread

" Explicitly set 256 color support
set t_Co=256

" Make backspace work in insert mode
set backspace=indent,eol,start

" Color scheme
colorscheme vividchalk
highlight NonText guibg=#060606
highlight Folded guibg=#0A0A0A guifg=#9090D0

set foldmethod=syntax     " Code folding based on the filetype
set foldnestmax=4         " Maximum level of folding is 4

let mapleader = ","

" Execute current file with F1
:map <F1> <Esc>:w<CR>:!!<CR>
" Execute R scripts as slave with F2
:map <F2> <Esc>:w<CR>:!R --slave --file=%<CR>

" Set large history size
set hi=1000

" Load matchit (% to bounce from do to end, etc.)
runtime! macros/matchit.vim

" Manage multiple buffers in background
set hidden

" Flash instead of beep
set visualbell

" Use grep instead of ack
set grepprg=ack

" Jump to marked line AND column
nnoremap ' `
nnoremap ` '


augroup myfiletypes
  " Clear old autocmds in group
  autocmd!
  " autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml set ai sw=2 sts=2 et
augroup END

" make searches case-insensitive, unless they contain upper-case letters:
set ignorecase
set smartcase

" show the `best match so far' as search strings are typed:
set incsearch

" Status line shown at the bottom of each window
set statusline=%<%f\ %h%m%r%=%-20.(line=%l,col=%c%V,totlin=%L%)\%h%m%r%=%-40(,%n%Y%)\%P

" FuzzyFinderTextMate plugin key map
map <leader>t :FuzzyFinderTextMate<CR>

" Mini buffer explorer key map
map <Leader>w :MiniBufExplorer<cr>
map <Leader>W :CMiniBufExplorer<cr>

" Ack key map
map <leader>r :Ack<SPACE>

" Activate NERDTree
map <leader>e :NERDTreeToggle<CR>

" Set vimwiki path
let g:vimwiki_list = [{'path': '~/Dropbox/.vimwiki/'}]

" Indent using the tab key
set sts=4
set et
imap <S-Tab> <C-o><<

" correct common typos
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
