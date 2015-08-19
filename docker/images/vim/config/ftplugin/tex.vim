setlocal autoindent

" Fold based on the use of "{{{" markers
setlocal foldmethod=marker

" auto format text as it's being edited
setlocal formatoptions+=ta
setlocal textwidth=75
setlocal autoindent

setlocal spelllang=en_gb
setlocal spell

syn match TmlDoubleWords /\c\<\(\S\+\)\_s\+\1\ze\_s/
hi def link TmlDoubleWords ToDo
