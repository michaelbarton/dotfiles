setlocal textwidth=79

" auto format text as it's being edited
setlocal formatoptions+=ta

" Maintain indenting of paragraphs in the text
setlocal autoindent

" Use two spaces for tabs
setlocal shiftwidth=2
setlocal tabstop=2
setlocal expandtab

syntax enable
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

syn match TmlDoubleWords /\c\<\(\S\+\)\_s\+\1\ze\_s/
hi def link TmlDoubleWords ToDo
