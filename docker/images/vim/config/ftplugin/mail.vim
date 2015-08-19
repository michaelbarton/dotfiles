setlocal formatoptions+=ta
setlocal textwidth=75
setlocal autoindent

setlocal spelllang=en_gb
setlocal spell

" Reformat file contents when it's opened for editting
%!mail-text-formatter -f %
%!par -w75 -rTbgqR B\=.,?_A_a Q\=_s\>\|

syntax enable
setlocal background=dark
colorscheme solarized

syn match TmlDoubleWords /\c\<\(\S\+\)\_s\+\1\ze\_s/
hi def link TmlDoubleWords ToDo 
