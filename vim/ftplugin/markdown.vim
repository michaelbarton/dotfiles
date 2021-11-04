setlocal textwidth=79

" auto format text as it's being edited
" n=format lists
setlocal formatoptions+=tan

" recognize asterisk as bullets
" https://unix.stackexchange.com/a/31348
setlocal formatlistpat+=\\\|^\\*\\s*

" Maintain indenting of paragraphs in the text
setlocal autoindent

" Use two spaces for tabs
setlocal shiftwidth=2
setlocal tabstop=2
setlocal expandtab

" support front matter of various format
let g:vim_markdown_frontmatter = 1  " for YAML format
let g:vim_markdown_toml_frontmatter = 1  " for TOML format
let g:vim_markdown_json_frontmatter = 1  " for JSON format

" disable header folding
let g:vim_markdown_folding_disabled = 1

" do not use conceal feature
let g:vim_markdown_conceal = 0

let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
