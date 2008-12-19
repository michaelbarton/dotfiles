set nocompatible          " We're running Vim, not Vi!
syntax on                 " Enable syntax highlighting
filetype plugin indent on " Enable filetype-specific indenting and plugins

set foldmethod=syntax     " Code folding based on the filetype
set foldnestmax=3         " Maximum level of folding is 3

" Load matchit (% to bounce from do to end, etc.)
runtime! macros/matchit.vim

" Use grep instead of ack
set grepprg=ack


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

" correct my common typos without me even noticing them:
abbreviate teh the
abbreviate hte the

" GUI options
if has("gui_running")
    colorscheme railscasts
    set lines=45
    set columns=115
    set noantialias
else
    " Any non-GUI options here
endif

" FuzzyFinderTextMate plugin key map
map <leader>t :FuzzyFinderTextMate<CR>
