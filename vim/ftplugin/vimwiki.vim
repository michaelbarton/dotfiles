" Enabling wimwiki folding results in extremely slow performance with
" auto-formatting enabled.
let g:vimwiki_folding = 0

setlocal formatoptions+=ta
setlocal textwidth=79
setlocal autoindent

setlocal spelllang=en_gb
setlocal spell

" Set for bulletted, etc. lists
setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^[-*+]\\s\\+
