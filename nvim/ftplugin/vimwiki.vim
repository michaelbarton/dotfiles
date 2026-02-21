" Clear formatexpr which was interfering with gq
setlocal formatexpr=

" Enable proper text wrapping
setlocal wrap
setlocal linebreak
setlocal breakindent
setlocal display+=lastline

" Set textwidth to 80 characters
setlocal textwidth=80

" Set formatoptions for intelligent text formatting:
" q - Allow formatting with gq command
" n - Recognize numbered lists
" l - Don't auto-wrap if line is already longer than textwidth
" 1 - Don't break a line after a one-letter word
" j - Remove comment leader when joining lines
" t - Enable auto-wrapping as you type
setlocal formatoptions=tqnl1jr

" Recognize asterisk as bullets (from your original file)
setlocal formatlistpat+=\\|^\\*\\s*

" Maintain indenting of paragraphs (from your original file)
setlocal autoindent

" Use two spaces for tabs (from your original file)
setlocal shiftwidth=2
setlocal tabstop=2
setlocal expandtab

" Markdown settings (from your original file)
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0

" Add soft word wrapping indicators
setlocal showbreak=↪\ 

" Cursor movement follows visual lines instead of file lines
nnoremap <buffer> j gj
nnoremap <buffer> k gk

" Enable breaking at word boundaries
setlocal breakat=\ ^I!@*-+;:,./?

" Enable better list formatting for vimwiki
setlocal comments=b:*,b:-,b:+,b:1.,b:a.
