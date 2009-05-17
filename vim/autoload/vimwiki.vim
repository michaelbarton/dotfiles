" Vimwiki autoload plugin file
" Author: Maxim Kim <habamax@gmail.com>
" Home: http://code.google.com/p/vimwiki/

if exists("g:loaded_vimwiki_auto") || &cp
  finish
endif
let g:loaded_vimwiki_auto = 1

let s:wiki_badsymbols = '[<>|?*/\:"]'

" MISC helper functions {{{
function! s:msg(message) "{{{
  echohl WarningMsg
  echomsg 'vimwiki: '.a:message
  echohl None
endfunction
" }}}
function! s:get_file_name_only(filename) "{{{
  let word = substitute(a:filename, '\'.VimwikiGet('ext'), "", "g")
  let word = substitute(word, '.*[/\\]', "", "g")
  return word
endfunction
" }}}
function! s:edit_file(command, filename) "{{{
  let fname = escape(a:filename, '% ')
  execute a:command.' '.fname
endfunction
" }}}
function! s:search_word(wikiRx, cmd) "{{{
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    call s:msg('WikiWord not found')
  endif
endfunction
" }}}
function! s:get_word_at_cursor(wikiRX) "{{{
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    return strpart(line, ebeg, elen)
  else
    return ""
  endif
endf "}}}
function! s:strip_word(word, sym) "{{{
  function! s:strip_word_helper(word, sym)
    return substitute(a:word, s:wiki_badsymbols, a:sym, 'g')
  endfunction

  let result = a:word
  if strpart(a:word, 0, 2) == "[["
    " get rid of [[ and ]]
    let w = strpart(a:word, 2, strlen(a:word)-4)
    " we want "link" from [[link|link desc]]
    let w = split(w, "|")[0]
    let result = s:strip_word_helper(w, a:sym)
  endif
  return result
endfunction
" }}}
function! s:is_link_to_non_wiki_file(word) "{{{
  " Check if word is link to a non-wiki file.
  " The easiest way is to check if it has extension like .txt or .html
  if a:word =~ '\.\w\{1,4}$'
    return 1
  endif
  return 0
endfunction
" }}}
function! s:print_wiki_list() "{{{
  let idx = 0
  while idx < len(g:vimwiki_list)
    if idx == g:vimwiki_current_idx
      let sep = ' * '
      echohl TablineSel
    else
      let sep = '   '
      echohl None
    endif
    echo (idx + 1).sep.VimwikiGet('path', idx)
    let idx += 1
  endwhile
  echohl None
endfunction
" }}}
function! s:wiki_select(wnum)"{{{
  if a:wnum < 1 || a:wnum > len(g:vimwiki_list)
    return
  endif
  let b:vimwiki_idx = g:vimwiki_current_idx
  let g:vimwiki_current_idx = a:wnum - 1
endfunction
" }}}
function! vimwiki#mkdir(path) "{{{
  " TODO: add exception handling...
  let path = expand(a:path)
  if !isdirectory(path) && exists("*mkdir")
    if path[-1:] == '/' || path[-1:] == '\'
      let path = path[:-2]
    endif
    call mkdir(path, "p")
  endif
endfunction
" }}}
function! s:update_wiki_link(fname, old, new) " {{{
  echo "Updating links in ".a:fname
  let has_updates = 0
  let dest = []
  for line in readfile(a:fname)
    if !has_updates && match(line, a:old) != -1
      let has_updates = 1
    endif
    call add(dest, substitute(line, a:old, escape(a:new, "&"), "g"))
  endfor
  " add exception handling...
  if has_updates
    call rename(a:fname, a:fname.'#vimwiki_upd#')
    call writefile(dest, a:fname)
    call delete(a:fname.'#vimwiki_upd#')
  endif
endfunction
" }}}
function! s:update_wiki_links(old, new) " {{{
  let files = split(glob(VimwikiGet('path').'*'.VimwikiGet('ext')), '\n')
  for fname in files
    call s:update_wiki_link(fname, a:old, a:new)
  endfor
endfunction
" }}}
function! s:get_wiki_buffers() "{{{
  let blist = []
  let bcount = 1
  while bcount<=bufnr("$")
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ":p")
      if bname =~ VimwikiGet('ext')."$"
        let bitem = [bname, getbufvar(bname, "vimwiki_prev_word")]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction
" }}}
function! s:open_wiki_buffer(item) "{{{
  call s:edit_file('e', a:item[0])
  if !empty(a:item[1])
    call setbufvar(a:item[0], "vimwiki_prev_word", a:item[1])
  endif
endfunction
" }}}
" }}}
" SYNTAX highlight {{{
function! vimwiki#WikiHighlightWords() "{{{
  let wikies = glob(VimwikiGet('path').'*'.VimwikiGet('ext'))
  "" remove .wiki extensions
  let wikies = substitute(wikies, '\'.VimwikiGet('ext'), "", "g")
  let g:vimwiki_wikiwords = split(wikies, '\n')
  "" remove paths
  call map(g:vimwiki_wikiwords, 'substitute(v:val, ''.*[/\\]'', "", "g")')
  "" remove backup files (.wiki~)
  call filter(g:vimwiki_wikiwords, 'v:val !~ ''.*\~$''')

  for word in g:vimwiki_wikiwords
    if word =~ g:vimwiki_word1 && !s:is_link_to_non_wiki_file(word)
      execute 'syntax match wikiWord /\%(^\|[^!]\)\zs\<'.word.'\>/'
    endif
    execute 'syntax match wikiWord /\[\[\<'.
          \ substitute(word, g:vimwiki_stripsym, s:wiki_badsymbols, "g").
          \ '\>\%(|\+.*\)*\]\]/'
  endfor
  execute 'syntax match wikiWord /\[\[.\+\.\%(jpg\|png\|gif\)\%(|\+.*\)*\]\]/'
endfunction
" }}}
function! vimwiki#hl_exists(hl)"{{{
  if !hlexists(a:hl)
    return 0
  endif
  redir => hlstatus
  exe "silent hi" a:hl
  redir END
  return (hlstatus !~ "cleared")
endfunction
"}}}

"}}}
" WIKI functions {{{
function! vimwiki#WikiNextWord() "{{{
  call s:search_word(g:vimwiki_rxWikiWord, '')
endfunction
" }}}
function! vimwiki#WikiPrevWord() "{{{
  call s:search_word(g:vimwiki_rxWikiWord, 'b')
endfunction
" }}}
function! vimwiki#WikiFollowWord(split) "{{{
  if a:split == "split"
    let cmd = ":split "
  elseif a:split == "vsplit"
    let cmd = ":vsplit "
  else
    let cmd = ":e "
  endif
  let word = s:strip_word(s:get_word_at_cursor(g:vimwiki_rxWikiWord),
        \                                      g:vimwiki_stripsym)
  " insert doesn't work properly inside :if. Check :help :if.
  if word == ""
    execute "normal! \n"
    return
  endif
  if s:is_link_to_non_wiki_file(word)
    call s:edit_file(cmd, word)
  else
    let vimwiki_prev_word = [expand('%:p'), getpos('.')]
    call s:edit_file(cmd, VimwikiGet('path').word.VimwikiGet('ext'))
    let b:vimwiki_prev_word = vimwiki_prev_word
  endif
endfunction
" }}}
function! vimwiki#WikiGoBackWord() "{{{
  if exists("b:vimwiki_prev_word")
    " go back to saved WikiWord
    let prev_word = b:vimwiki_prev_word
    execute ":e ".substitute(prev_word[0], '\s', '\\\0', 'g')
    call setpos('.', prev_word[1])
  endif
endfunction
" }}}
function! vimwiki#WikiGoHome(index) "{{{
  call s:wiki_select(a:index)
  call vimwiki#mkdir(VimwikiGet('path'))

  try
    execute ':e '.VimwikiGet('path').VimwikiGet('index').VimwikiGet('ext')
  catch /E37/ " catch 'No write since last change' error
    " this is really unsecure!!!
    execute ':'.VimwikiGet('gohome').' '.
          \ VimwikiGet('path').
          \ VimwikiGet('index').
          \ VimwikiGet('ext')
  catch /E325/ " catch 'ATTENTION' error
    " TODO: Hmmm, if open already opened index.wiki there is an error...
    " Find out what is the reason and how to avoid it. Is it dangerous?
    echomsg "Unknown error!"
  endtry
endfunction
"}}}
function! vimwiki#WikiDeleteWord() "{{{
  "" file system funcs
  "" Delete WikiWord you are in from filesystem
  let val = input('Delete ['.expand('%').'] (y/n)? ', "")
  if val != 'y'
    return
  endif
  let fname = expand('%:p')
  try
    call delete(fname)
  catch /.*/
    call s:msg('Cannot delete "'.expand('%:t:r').'"!')
    return
  endtry
  execute "bdelete! ".escape(fname, " ")

  " reread buffer => deleted WikiWord should appear as non-existent
  if expand('%:p') != ""
    execute "e"
  endif
endfunction
"}}}
function! vimwiki#WikiRenameWord() "{{{
  "" Rename WikiWord, update all links to renamed WikiWord
  let wwtorename = expand('%:t:r')
  let isOldWordComplex = 0
  if wwtorename !~ g:vimwiki_word1
    let wwtorename = substitute(wwtorename, g:vimwiki_stripsym,
          \ s:wiki_badsymbols, "g")
    let isOldWordComplex = 1
  endif

  " there is no file (new one maybe)
  if glob(expand('%:p')) == ''
    call s:msg('Cannot rename "'.expand('%:p').
          \ '". It does not exist! (New file? Save it before renaming.)')
    return
  endif

  let val = input('Rename "'.expand('%:t:r').'" (y/n)? ', "")
  if val!='y'
    return
  endif
  let newWord = input('Enter new name: ', "")
  " check newWord - it should be 'good', not empty
  if substitute(newWord, '\s', '', 'g') == ''
    call s:msg('Cannot rename to an empty filename!')
    return
  endif
  if s:is_link_to_non_wiki_file(newWord)
    call s:msg('Cannot rename to a filename with extension (ie .txt .html)!')
    return
  endif

  if newWord !~ g:vimwiki_word1
    " if newWord is 'complex wiki word' then add [[]]
    let newWord = '[['.newWord.']]'
  endif
  let newFileName = s:strip_word(newWord, g:vimwiki_stripsym).VimwikiGet('ext')

  " do not rename if word with such name exists
  let fname = glob(VimwikiGet('path').newFileName)
  if fname != ''
    call s:msg('Cannot rename to "'.newFileName.
          \ '". File with that name exist!')
    return
  endif
  " rename WikiWord file
  try
    echomsg "Renaming ".expand('%:t:r')." to ".newFileName
    let res = rename(expand('%:p'), expand(VimwikiGet('path').newFileName))
    if res != 0
      throw "Cannot rename!"
    end
  catch /.*/
    call s:msg('Cannot rename "'.expand('%:t:r').'" to "'.newFileName.'"')
    return
  endtry

  let &buftype="nofile"

  let cur_buffer = [expand('%:p'),
        \getbufvar(expand('%:p'), "vimwiki_prev_word")]

  let blist = s:get_wiki_buffers()

  " save wiki buffers
  for bitem in blist
    execute ':b '.escape(bitem[0], ' ')
    execute ':update'
  endfor

  execute ':b '.escape(cur_buffer[0], ' ')

  " remove wiki buffers
  for bitem in blist
    execute 'bwipeout '.escape(bitem[0], ' ')
  endfor

  let setting_more = &more
  setlocal nomore

  " update links
  if isOldWordComplex
    call s:update_wiki_links('\[\['.wwtorename.'\]\]', newWord)
  else
    call s:update_wiki_links('\<'.wwtorename.'\>', newWord)
  endif

  " restore wiki buffers
  for bitem in blist
    if bitem[0] != cur_buffer[0]
      call s:open_wiki_buffer(bitem)
    endif
  endfor

  call s:open_wiki_buffer([VimwikiGet('path').newFileName, cur_buffer[1]])
  " execute 'bwipeout '.escape(cur_buffer[0], ' ')

  echomsg wwtorename." is renamed to ".newWord

  let &more = setting_more
endfunction
" }}}
function! vimwiki#WikiUISelect()"{{{
  call s:print_wiki_list()
  let idx = input("Select Wiki (specify number): ")
  if idx == ""
    return
  endif
  call vimwiki#WikiGoHome(idx)
endfunction
"}}}
" }}}
" TEXT OBJECTS functions {{{

function! vimwiki#TO_header(inner) "{{{
  if !search('^\(=\+\)[^=]\+\1\s*$', 'bcW')
    return
  endif
  let level = vimwiki#count_first_sym(getline(line('.')))
  normal V
  if search('^\(=\{1,'.level.'}\)[^=]\+\1\s*$', 'W')
    call cursor(line('.') - 1, 0)
  else
    call cursor(line('$'), 0)
  endif
  if a:inner && getline(line('.')) =~ '^\s*$'
    let lnum = prevnonblank(line('.') - 1)
    call cursor(lnum, 0)
  endif
endfunction
"}}}
function! vimwiki#count_first_sym(line) "{{{
  let idx = 0
  while a:line[idx] == a:line[0] && idx < len(a:line)
    let idx += 1
  endwhile
  return idx
endfunction "}}}

function! vimwiki#AddHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)

  if line =~ '^\s*$'
    return
  endif

  if line !~ '^\(=\+\).\+\1\s*$'
    let line = substitute(line, '^\s*', ' ', '')
    let line = substitute(line, '\s*$', ' ', '')
  endif
  let level = vimwiki#count_first_sym(line)
  if level < 6
    call setline(lnum, '='.line.'=')
  endif
endfunction
"}}}
function! vimwiki#RemoveHeaderLevel() "{{{
  let lnum = line('.')
  let line = getline(lnum)

  if line =~ '^\s*$'
    return
  endif

  if line =~ '^\(=\+\).\+\1\s*$'
    let line = strpart(line, 1, len(line) - 2)
    if line =~ '^\s'
      let line = strpart(line, 1, len(line))
    endif
    if line =~ '\s$'
      let line = strpart(line, 0, len(line) - 1)
    endif
    call setline(lnum, line)
  endif
endfunction
" }}}

" }}}
