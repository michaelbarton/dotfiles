" Enabling wimwiki folding results in extremely slow performance with
" auto-formatting enabled.
let g:vimwiki_folding = 0

setlocal formatoptions+=ta
setlocal textwidth=79
setlocal autoindent

setlocal shiftwidth=2
setlocal tabstop=2
setlocal expandtab

setlocal spelllang=en_gb
setlocal spell

syntax enable
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

syn match TmlDoubleWords /\c\<\(\S\+\)\_s\+\1\ze\_s/
hi def link TmlDoubleWords ToDo
