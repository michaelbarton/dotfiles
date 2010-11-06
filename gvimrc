" Window size
let g:halfsize = 86
let g:fullsize = 171
set lines=50
let &columns = g:halfsize
 
" Font
set guifont=Inconsolata:h17.00
 
" No toolbar
set guioptions-=T
 
" Use console dialogs
set guioptions+=c

colorscheme molokai       " GUI colorscheme
set cursorline            " highlight the line the cursor is on

" Vim 7.3 options
set undofile              " Keep undo file of previous actions
set relativenumber        " Relative line numbering
set colorcolumn=85        " Highlight when line reaches this length

" Source gvim also
nmap <silent> <leader>vs :so $MYVIMRC<CR>:so $MYGVIMRC<CR>
