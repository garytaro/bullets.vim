" Vim plugin for automated bulleted lists
" Last Change: Friday Feb 12, 2016
" Maintainer: Dorian Karter
" License: MIT
" FileTypes: markdown, text, gitcommit

" Prevent execution if already loaded ------------------   {{{
if exists('g:loaded_bullets_vim')
  finish
endif
let g:loaded_bullets_vim = 1
" Prevent execution if already loaded ------------------   }}}

" Read user configurable options -----------------------   {{{
if !exists('g:bullets_enabled_file_types')
  let g:bullets_enabled_file_types = ['markdown', 'text', 'gitcommit']
endif

if !exists('g:bullets_set_mappings')
  let g:bullets_set_mappings = 1
end

if !exists('g:bullets_mapping_leader')
  let g:bullets_mapping_leader = ''
end


" ------------------------------------------------------   }}}

" Preserve Vim compatibility settings -------------------  {{{
let s:save_cpo = &cpo
set cpo&vim
" -------------------------------------------------------  }}}

" Generate bullets --------------------------------------  {{{
fun! s:insert_new_bullet()
  let curr_line_num = line(".")
  let curr_line = getline(curr_line_num)
  let matches = matchlist(curr_line, '\v(^\s*(-|*)( \[[x ]?\])? )(.*)')
  let send_return = 1
  let normal_mode = mode() == "n"

  if !empty(matches) && s:is_at_eol()
    if matches[4] == ''
      " check if current line is a bullet, if it is - was any text entered after the
      " bullet? (regex group 4) We don't want to create a new bullet if the previous 
      " one was not used, instead we want to delete the empty bullet - like word
      " processors do
      call setline(curr_line_num, '')
    else
      " insert next bullet
      let next_line_num = curr_line_num + 1
      call append(curr_line_num, [matches[1]])
      " got to next line after the new bullet
      call setpos(".", [0, next_line_num, strlen(getline(next_line_num))+1])
      let send_return = 0
    endif
  endif

  if send_return || normal_mode
    " start a new line
    if normal_mode
      startinsert!
    endif

    let keys = send_return ? "\<CR>" : ""
    call feedkeys(keys, 'n')
  endif

  " need to return a string since we are in insert mode calling with <C-R>=
  return ""
endfun

fun! s:is_at_eol()
  return strlen(getline(".")) + 1 == col(".")
endfun

command! InsertNewBullet call <SID>insert_new_bullet()
" --------------------------------------------------------- }}}

" Checkboxes ---------------------------------------------- {{{
fun! s:find_checkbox_position(lnum)
  let line_text = getline(a:lnum)
  return matchend(line_text, '\v\s*(\*|-) \[')
endfun

fun! s:select_checkbox(inner)
  let lnum = line(".")
  let checkbox_col = s:find_checkbox_position(lnum)

  if checkbox_col
    call setpos(".", [0, lnum, checkbox_col])

    " decide if we need to select the whole checkbox with brackets or just the
    " inside of it
    if a:inner
      normal! vi[
    else
      normal! va[
    endif
  endif
endfun

fun! s:toggle_checkbox()
  let initpos = getpos(".")
  let lnum = line(".")
  let pos = s:find_checkbox_position(lnum)
  let checkbox_content = getline(lnum)[pos]
  " select inside checkbox
  call setpos(".", [0, lnum, pos])
  if checkbox_content == "x"
    execute "normal! ci[\<Space>"
  else
    normal! ci[x
  endif
  call setpos(".", initpos)
endfun

command! SelectCheckboxInside call <SID>select_checkbox(1)
command! SelectCheckbox call <SID>select_checkbox(0)
command! ToggleCheckbox call <SID>toggle_checkbox()
" Checkboxes ---------------------------------------------- }}}

" Bullets ------------------------------------------------- {{{
fun! s:find_bullet_position(lnum)
  let line_text = getline(a:lnum)
  return matchend(line_text, '\v\s*(\*|-)')
endfun

fun! s:select_bullet(inner)
  let lnum = getpos(".")[1]
  let bullet_col = s:find_bullet_position(lnum)

  if bullet_col
    " decide if we need to select with the bullet or without
    let offset = a:inner? 2 : 0
    call setpos(".", [0, lnum, bullet_col + offset])
    normal! vg_
  endif
endfun

command! SelectBulletText call <SID>select_bullet(1)
command! SelectBullet call <SID>select_bullet(0)
" Bullets ------------------------------------------------- }}}

" Keyboard mappings --------------------------------------- {{{
fun! s:add_local_mapping(mapping_type, mapping, action)
  let file_types = join(g:bullets_enabled_file_types, ",")
  execute "autocmd FileType "  . file_types . " " . a:mapping_type . " <buffer> " . g:bullets_mapping_leader . a:mapping . " " . a:action
endfun

augroup TextBulletsMappings
  autocmd!

  if g:bullets_set_mappings
    " automatic bullets
    call s:add_local_mapping("inoremap", "<cr>", "<C-R>=<SID>insert_new_bullet()<cr>")
    call s:add_local_mapping("inoremap", "<C-cr>", "<cr>")

    call s:add_local_mapping("nnoremap", "o", ":call <SID>insert_new_bullet()<cr>")

    " indentation
    call s:add_local_mapping("inoremap", "<C-l>", "<esc>>>A")
    call s:add_local_mapping("inoremap", "<C-h>", "<esc><<A")

    " Toggle checkbox
    call s:add_local_mapping("nnoremap", "<leader>x", ":ToggleCheckbox<cr>")

    " Text Objects -------------------------------------------- {{{
    " inner bullet (just the text)
    call s:add_local_mapping("onoremap", "ib", ":SelectBulletText<cr>")
    " a bullet including the bullet markup
    call s:add_local_mapping("onoremap", "ab", ":SelectBullet<cr>")
    " inside a checkbox
    call s:add_local_mapping("onoremap", "ic", ":SelectCheckboxInside<cr>")
    " a checkbox
    call s:add_local_mapping("onoremap", "ac", ":SelectCheckbox<cr>")
    " Text Objects -------------------------------------------- }}}
  end
augroup END
" --------------------------------------------------------- }}}

" Restore previous external compatibility options --------- {{{
let &cpo = s:save_cpo
" --------------------------------------------------------  }}}


