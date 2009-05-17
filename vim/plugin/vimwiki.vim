" Vimwiki plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("loaded_vimwiki") || &cp
  finish
endif
let loaded_vimwiki = 1

let s:old_cpo = &cpo
set cpo&vim

" HELPER functions {{{
function! s:default(varname, value) "{{{
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction "}}}

function! s:find_wiki(path) "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    let path = expand(VimwikiGet('path', idx))
    if path[:-2] == a:path
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction "}}}

function! s:setup_buffer_leave()"{{{
  if !exists("b:vimwiki_idx")
    let b:vimwiki_idx=g:vimwiki_current_idx
  endif
endfunction"}}}

function! s:setup_buffer_enter() "{{{
  if exists("b:vimwiki_idx")
    let g:vimwiki_current_idx = b:vimwiki_idx
  else
    " Find what wiki current buffer belongs to.
    " If wiki does not exist in g:vimwiki_list -- add new wiki there with
    " buffer's path and ext.
    " Else set g:vimwiki_current_idx to that wiki index.
    let path = expand('%:p:h')
    let ext = '.'.expand('%:e')
    let idx = s:find_wiki(path)
    if idx == -1
      call add(g:vimwiki_list, {'path': path, 'ext': ext})
      let g:vimwiki_current_idx = len(g:vimwiki_list) - 1
    else
      let g:vimwiki_current_idx = idx
    endif

    let b:vimwiki_idx = g:vimwiki_current_idx
  endif

  if &filetype != 'vimwiki'
    setlocal ft=vimwiki
  else
    setlocal syntax=vimwiki
  endif
endfunction "}}}
" }}}
" DEFAULT wiki {{{
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.path_html = '~/vimwiki_html/'
let s:vimwiki_defaults.css_name = 'style.css'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.folding = 1
let s:vimwiki_defaults.maxhi = 1
let s:vimwiki_defaults.syntax = 'default'
let s:vimwiki_defaults.gohome = 'split'
let s:vimwiki_defaults.html_header = ''
let s:vimwiki_defaults.html_footer = ''
"}}}
" DEFAULT options {{{
call s:default('upper', 'A-ZА-Я')
call s:default('lower', 'a-zа-я')
call s:default('other', '0-9')
call s:default('stripsym', '_')
call s:default('auto_listitem', 1)
call s:default('auto_checkbox', 1)
call s:default('use_mouse', 0)
call s:default('menu', 1)
call s:default('current_idx', 0)
call s:default('list', [s:vimwiki_defaults])

let upp = g:vimwiki_upper
let low = g:vimwiki_lower
let oth = g:vimwiki_other
let nup = low.oth
let nlo = upp.oth
let any = upp.nup

let g:vimwiki_word1 = '\C\<['.upp.']['.nlo.']*['.
      \ low.']['.nup.']*['.upp.']['.any.']*\>'
let g:vimwiki_word2 = '\[\[[^\]]\+\]\]'
let g:vimwiki_rxWikiWord = g:vimwiki_word1.'\|'.g:vimwiki_word2
"}}}
" OPTION get/set functions {{{
" return value of option for current wiki or if second parameter exists for
" wiki with a given index.
function! VimwikiGet(option, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  if !has_key(g:vimwiki_list[idx], a:option) &&
        \ has_key(s:vimwiki_defaults, a:option)
    if a:option == 'path_html'
      let g:vimwiki_list[idx][a:option] =
            \VimwikiGet('path', idx)[:-2].'_html/'
    else
      let g:vimwiki_list[idx][a:option] =
            \s:vimwiki_defaults[a:option]
    endif
  endif

  " if path's ending is not a / or \
  " then add it
  if a:option == 'path' || a:option == 'path_html'
    let p = g:vimwiki_list[idx][a:option]
    if p !~ '[\/]$'
      let g:vimwiki_list[idx][a:option] = p.'/'
    endif
  endif

  return g:vimwiki_list[idx][a:option]
endfunction "}}}

" set option for current wiki or if third parameter exists for
" wiki with a given index.
function! VimwikiSet(option, value, ...) "{{{
  if a:0 == 0
    let idx = g:vimwiki_current_idx
  else
    let idx = a:1
  endif
  let g:vimwiki_list[idx][a:option] = a:value
endfunction "}}}
" }}}
" FILETYPE setup for all known wiki extensions {{{
" Getting all extensions that different wikies could have
let extensions = {}
for wiki in g:vimwiki_list
  if has_key(wiki, 'ext')
    let extensions[wiki.ext] = 1
  else
    let extensions['.wiki'] = 1
  endif
endfor

augroup vimwiki
  autocmd!
  for ext in keys(extensions)
    execute 'autocmd BufEnter *'.ext.' call s:setup_buffer_enter()'
    execute 'autocmd BufLeave,BufHidden *'.ext.' call s:setup_buffer_leave()'

    " ColorScheme could have or could have not a wikiHeader1..wikiHeader6
    " highlight groups. We need to refresh syntax after colorscheme change.
    execute 'autocmd ColorScheme *'.ext.' set syntax=vimwiki'
  endfor
augroup END
"}}}
" COMMANDS {{{
command! VimwikiUISelect call vimwiki#WikiUISelect()
command! -count VimwikiGoHome
      \ call vimwiki#WikiGoHome(v:count1)
command! -count VimwikiTabGoHome tabedit <bar>
      \ call vimwiki#WikiGoHome(v:count1)
"}}}
" MAPPINGS {{{
if !hasmapto('<Plug>VimwikiGoHome')
  map <silent><unique> <Leader>ww <Plug>VimwikiGoHome
endif
noremap <unique><script> <Plug>VimwikiGoHome :VimwikiGoHome<CR>

if !hasmapto('<Plug>VimwikiTabGoHome')
  map <silent><unique> <Leader>wt <Plug>VimwikiTabGoHome
endif
noremap <unique><script> <Plug>VimwikiTabGoHome :VimwikiTabGoHome<CR>

if !hasmapto('<Plug>VimwikiUISelect')
  map <silent><unique> <Leader>ws <Plug>VimwikiUISelect
endif
noremap <unique><script> <Plug>VimwikiUISelect :VimwikiUISelect<CR>

"}}}
" MENU {{{
function! s:build_menu(path)
  let idx = 0
  while idx < len(g:vimwiki_list)
    execute 'menu '.a:path.'.'.VimwikiGet('path', idx).
          \ ' :call vimwiki#WikiGoHome('.(idx + 1).')<CR>'
    let idx += 1
  endwhile
endfunction

if g:vimwiki_menu == 1
  call s:build_menu('Vimwiki')
elseif g:vimwiki_menu == 2
  call s:build_menu('Plugin.Vimwiki')
endif
" }}}

let &cpo = s:old_cpo
