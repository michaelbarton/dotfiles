" Remap the make to source vim files
nmap <leader><space> <Esc>:w<CR>:so %<CR>

" auto format text as it's being edited
setlocal formatoptions+=ta
setlocal textwidth=79

" Fold based on the use of "{{{" markers
setlocal foldmethod=marker
