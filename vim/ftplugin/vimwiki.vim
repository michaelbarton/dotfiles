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

" Enabling wimwiki folding results in extremely slow performance with
" auto-formatting enabled.
let g:vimwiki_folding = 0
setlocal foldmethod=expr
setlocal foldexpr=GetWikiFold(v:lnum)
setlocal foldcolumn=5

function! GetWikiFold(lnum)
	if getline(a:lnum) =~? '\v^\=\s.+'
		return '>1'
	elseif getline(a:lnum) =~? '\v^\=\=\s.+'
		return '>2'
	elseif getline(a:lnum) =~? '\v^\=\=\=\s.+'
		return '>3'
	else
		return LastTitleLevel(a:lnum-1)
	endif
endfunction

function! LastTitleLevel(lnum)
	if getline(a:lnum) =~? '\v^\=\s.+'
		return '1'
	elseif getline(a:lnum) =~? '\v^\=\=\s.+'
		return '2'
	elseif getline(a:lnum) =~? '\v^\=\=\=\s.+'
		return '3'
	elseif a:lnum == 1
		return '0'
	else
		return LastTitleLevel(a:lnum-1)
	endif
endfunction


setlocal hlsearch incsearch
