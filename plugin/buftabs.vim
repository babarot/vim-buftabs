" buftabs (C) 2014 b4b4r07

let s:save_cpo = &cpo
set cpo&vim

if &diff | finish | endif
if exists("g:loaded_buftabs")
  finish
endif
let g:loaded_buftabs = 1

" Back-up the original statusline {{{
let s:original_left_statusline = matchstr(&statusline, "%=.*")
let s:original_statusline = &statusline
"}}}

" Some g:variables {{{
if !exists('g:buftabs_enabled')
  let g:buftabs_enabled = 1
endif

if !exists('g:buftabs_in_statusline')
  let g:buftabs_in_statusline = 1
endif

if !exists('g:buftabs_in_cmdline')
  let g:buftabs_in_cmdline = 0
endif

if !exists('g:buftabs_only_basename')
  let g:buftabs_only_basename = 1
endif

if !exists('g:buftabs_active_highlight_group')
	let g:buftabs_active_highlight_group = ''
endif

if !exists('g:buftabs_inactive_highlight_group')
	let g:buftabs_inactive_highlight_group = ''
endif

if !exists('g:buftabs_statusline_highlight_group')
  let g:buftabs_statusline_highlight_group = ''
endif

if !exists('g:buftabs_marker_start')
  let g:buftabs_marker_start = '['
endif

if !exists('g:buftabs_marker_end')
  let g:buftabs_marker_end = ']'
endif

if !exists('g:buftabs_separator')
  let g:buftabs_separator = '-'
endif

if !exists('g:buftabs_marker_modified')
  let g:buftabs_marker_modified = '!'
endif
"}}}

" Show the buftabs in cmdline {{{
let s:echo_buftabs = ''
function! s:echo_buftabs(msg)
  if &updatetime != 1 
    let s:hold_ut = &updatetime
    let &updatetime = 1
  endif
  let s:echo_buftabs =a:msg
  augroup echo_buftabs
    au CursorHold * if s:echo_buftabs != ''
          \| echo s:echo_buftabs
          \| let s:echo_buftabs = ''
          \| let &ut=s:hold_ut
          \| endif
          \| augroup echo_buftabs
          \| execute 'autocmd!'
          \| augroup END
          \| augroup! echo_buftabs
  augroup END
endfunction
"}}}

" Toggle buftabs {{{
function! s:buftabs_toggle(boolean)
  if a:boolean == 1 | let g:buftabs_enabled = 1 | endif
  if a:boolean == 0 | let g:buftabs_enabled = 0 | endif

  if a:boolean == -1
    if g:buftabs_enabled == 1
      let g:buftabs_enabled = 0
    elseif g:buftabs_enabled == 0
      let g:buftabs_enabled = 1
    endif
  endif

  " Show the buftabs
  if g:buftabs_enabled == 1
    call s:buftabs_show(-1)
    return
  endif

  " Show original statusline
  if g:buftabs_enabled == 0
    for buf in range(1, bufnr('$'))
      if bufexists(buf) && buflisted(buf)
        let &l:statusline = s:original_statusline
        bprev
      endif
    endfor
    return
  endif
endfunction
"}}}

" Draw the buftabs {{{
function! s:buftabs_show(deleted_buf)
  if exists('g:buftabs_enabled') && g:buftabs_enabled == 0
    return
  endif

  let l:i = 1
  let s:list = ''
  let l:start = 0
  let l:end = 0
  if ! exists("g:from") 
    let g:from = 0
  endif

  "let l:buftabs_marker_modified = "!"
  "if exists("g:buftabs_marker_modified")
  "  let l:buftabs_marker_modified = g:buftabs_marker_modified
  "endif

  "let l:buftabs_separator = "-"
  "if exists("g:buftabs_separator")
  "  let l:buftabs_separator = g:buftabs_separator
  "endif

  "let l:buftabs_marker_start = "["
  "if exists("g:buftabs_marker_start")
  "  let l:buftabs_marker_start = g:buftabs_marker_start
  "endif

  "let l:buftabs_marker_end = "]"
  "if exists("g:buftabs_marker_end")
  "  let l:buftabs_marker_end = g:buftabs_marker_end
  "endif

  " Walk the list of buffers
  while(l:i <= bufnr('$'))

    " Only show buffers in the list, and omit help screens

    if buflisted(l:i) && getbufvar(l:i, "&modifiable") && a:deleted_buf != l:i

      " Get the name of the current buffer, and escape characters that might
      " mess up the statusline

      "if exists("g:buftabs_only_basename")
      if g:buftabs_only_basename
        let l:name = fnamemodify(bufname(l:i), ":t")
      else
        let l:name = bufname(l:i)
      endif
      let l:name = substitute(l:name, "%", "%%", "g")

      " Append the current buffer number and name to the list. If the buffer
      " is the active buffer, enclose it in some magick characters which will
      " be replaced by markers later. If it is modified, it is appended with
      " an appropriate symbol (an exclamation mark by default)

      if winbufnr(winnr()) == l:i
        let l:start = strlen(s:list)
        let s:list = s:list . "\x01"
      else
        let s:list = s:list . ' '
      endif

      let s:list = s:list . l:i . g:buftabs_separator
      let s:list = s:list . l:name

      if getbufvar(l:i, "&modified") == 1
        let s:list = s:list . g:buftabs_marker_modified
      endif

      if winbufnr(winnr()) == l:i
        let s:list = s:list . "\x02"
        let l:end = strlen(s:list)
      else
        let s:list = s:list . ' '
      endif
    end

    let l:i = l:i + 1
  endwhile

  " If the resulting list is too long to fit on the screen, chop
  " out the appropriate part

  let l:width = winwidth(0) - 12

  if(l:start < g:from) 
    let g:from = l:start - 1
  endif
  if l:end > g:from + l:width
    let g:from = l:end - l:width 
  endif

  let s:list = strpart(s:list, g:from, l:width)

  " Replace the magic characters by visible markers for highlighting the
  " current buffer. The markers can be simple characters like square brackets,
  " but can also be special codes with highlight groups

  if exists("g:buftabs_in_cmdline") && g:buftabs_in_cmdline
    redraw
    let s:list2 = copy(s:list)
    let s:list2 = substitute(s:list2, "\x01", g:buftabs_marker_start, 'g')
    let s:list2 = substitute(s:list2, "\x02", g:buftabs_marker_end,   'g')
    call s:echo_buftabs(s:list2)
  end

  if exists("g:buftabs_active_highlight_group")
    if exists("g:buftabs_in_statusline")
      let l:buftabs_marker_start = "%#" . g:buftabs_active_highlight_group . "#" . g:buftabs_marker_start
      let l:buftabs_marker_end = g:buftabs_marker_end . "%##"
    end
  end

  if exists("g:buftabs_inactive_highlight_group")
    if exists("g:buftabs_in_statusline")
      let s:list = '%#' . g:buftabs_inactive_highlight_group . '#' . s:list
      let s:list .= '%##'
      let l:buftabs_marker_end = g:buftabs_marker_end . '%#' . g:buftabs_inactive_highlight_group . '#'
    end
  end

  let s:list = substitute(s:list, "\x01", l:buftabs_marker_start, 'g')
  let s:list = substitute(s:list, "\x02", l:buftabs_marker_end, 'g')

  " Show the list. The buftabs_in_statusline variable determines of the list
  " is displayed in the command line (volatile) or in the statusline
  " (persistent)

  if exists("g:buftabs_in_statusline") && g:buftabs_in_statusline
    if match(&statusline, "%{buftabs#statusline()}") == -1
      if exists("g:buftabs_statusline_highlight_group")
        let s:original_left_statusline = '%=' . '%#' . g:buftabs_statusline_highlight_group . '#' . 
              \ substitute(substitute(s:original_left_statusline, '^%=', '', ''), '%#.*#', '', '')
      endif
      let &l:statusline = s:list . s:original_left_statusline
    end
  end
endfunction

function! buftabs#statusline(...)
  return s:list
endfunction
"}}}

command! -nargs=0 BuftabsToggle  call s:buftabs_toggle(-1)
command! -nargs=0 BuftabsEnable  call s:buftabs_toggle(1)
command! -nargs=0 BuftabsDisable call s:buftabs_toggle(0)

nnoremap <silent> <Plug>(buftabs-toggle)  :<C-u>call <SID>buftabs_toggle(-1)<CR>
nnoremap <silent> <Plug>(buftabs-enable)  :<C-u>call <SID>buftabs_toggle(1)<CR>
nnoremap <silent> <Plug>(buftabs-disable) :<C-u>call <SID>buftabs_toggle(0)<CR>

autocmd VimEnter * let g:buftabs_enabled = exists('g:buftabs_enabled') ? g:buftabs_enabled : 1
autocmd VimEnter,BufNew,BufEnter,BufWritePost * call s:buftabs_show(-1)
autocmd BufDelete * call s:buftabs_show(expand('<abuf>'))
if version >= 700
  autocmd InsertLeave,VimResized * call s:buftabs_show(-1)
end

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et fdm=marker ft=vim ts=2 sw=2 sts=2:
