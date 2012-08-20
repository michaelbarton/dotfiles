setlocal formatoptions+=ta
setlocal textwidth=79
setlocal autoindent

setlocal spelllang=en_gb
setlocal spell

" Reformat file contents when it's opened for editting
%!par -rTbgqR B\=.,?_A_a Q\=_s\>\|

syntax enable
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

syn match TmlDoubleWords /\c\<\(\S\+\)\_s\+\1\ze\_s/ 
hi def link TmlDoubleWords ToDo 
