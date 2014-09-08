" statbufline (C) 2014 b4b4r07

scriptencoding utf-8
if &diff | finish | endif

" Load Once {{{
if get(g:, 'g:loaded_buftabs', 0) || &cp
  finish
endif
let g:loaded_buftabs = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Some variables {{{
let s:original_left_statusline = matchstr(&statusline, "%=.*")
let s:original_statusline      = &statusline
let g:buftabs_enabled         = get(g:, 'buftabs_enabled',          1)
let g:buftabs_in_statusline   = get(g:, 'buftabs_in_statusline',    1)
let g:buftabs_in_cmdline      = get(g:, 'buftabs_in_cmdline',       0)
let g:buftabs_only_basename   = get(g:, 'buftabs_only_basename',    1)
let g:buftabs_marker_start    = get(g:, 'buftabs_marker_start',    '[')
let g:buftabs_marker_end      = get(g:, 'buftabs_marker_end',      ']')
let g:buftabs_marker_modified = get(g:, 'buftabs_marker_modified', '+')
let g:buftabs_separator       = get(g:, 'buftabs_separator',       '#')
let g:buftabs_active_highlight_group     = get(g:, 'buftabs_active_highlight_group', 'Visual')
let g:buftabs_inactive_highlight_group   = get(g:, 'buftabs_inactive_highlight_group',     '')
let g:buftabs_statusline_highlight_group = get(g:, 'buftabs_statusline_highlight_group',   '')
"}}}
" Toggle buftabs {{{
function! s:buftabs_toggle(...)
  if a:0 && a:1 == 1
    let g:buftabs_enabled = 1
  endif
  if a:0 && a:1 == 0
    let g:buftabs_enabled = 0
  endif

  if a:0 == 0
    if g:buftabs_enabled == 1
      let g:buftabs_enabled = 0
    elseif g:buftabs_enabled == 0
      let g:buftabs_enabled = 1
    endif
  endif

  call s:buftabs_show(-1)
endfunction
"}}}
" Draw the buftabs {{{
function! s:buftabs_show(deleted_buf)
  " Show original statusline
  if g:buftabs_enabled == 0
    for buf in range(1, bufnr('$'))
      if bufexists(buf) && buflisted(buf)
        let &statusline = s:original_statusline
        bprev
      endif
    endfor
    return
  endif

  let i = 1
  let s:list = ''
  let start = 0
  let end = 0
  let from = 0

  " Walk the list of buffers
  while(i <= bufnr('$'))
    " Only show buffers in the list, and omit help screens
    if buflisted(i) && getbufvar(i, "&modifiable") && a:deleted_buf != i

      " Get the name of the current buffer, and escape characters that might
      " mess up the statusline
      if g:buftabs_only_basename
        let name = fnamemodify(bufname(i), ':t')
      else
        let name = bufname(i)
      endif
      let name = substitute(name, "%", "%%", "g")

      " Append the current buffer number and name to the list. If the buffer
      " is the active buffer, enclose it in some magick characters which will
      " be replaced by markers later. If it is modified, it is appended with
      " an appropriate symbol (an exclamation mark by default)
      if winbufnr(winnr()) == i
        let start = strlen(s:list)
        let s:list = s:list . "\x01"
      else
        let s:list = s:list . ' '
      endif

      let s:list = s:list . i . g:buftabs_separator
      let s:list = s:list . name

      if getbufvar(i, "&modified") == 1
        let s:list = s:list . g:buftabs_marker_modified
      endif

      if winbufnr(winnr()) == i
        let s:list = s:list . "\x02"
        let end = strlen(s:list)
      else
        let s:list = s:list . ' '
      endif
    end

    let i = i + 1
  endwhile

  " If the resulting list is too long to fit on the screen, chop
  " out the appropriate part
  let width = winwidth(0) - 12

  if(start < from) 
    let from = start - 1
  endif
  if end > from + width
    let from = end - width 
  endif

  let s:list = strpart(s:list, from, width)

  " Replace the magic characters by visible markers for highlighting the
  " current buffer. The markers can be simple characters like square brackets,
  " but can also be special codes with highlight groups
  if exists("g:buftabs_in_cmdline") && g:buftabs_in_cmdline
    redraw
    let s:list2 = copy(s:list)
    let s:list2 = substitute(s:list2, "\x01", g:buftabs_marker_start, 'g')
    let s:list2 = substitute(s:list2, "\x02", g:buftabs_marker_end,   'g')
    ""call s:echo_buftabs(s:list2)
  end

  if exists("g:buftabs_active_highlight_group")
    if exists("g:buftabs_in_statusline")
      let buftabs_marker_start = "%#" . g:buftabs_active_highlight_group . "#" . g:buftabs_marker_start
      let buftabs_marker_end = g:buftabs_marker_end . "%##"
    end
  end

  if exists("g:buftabs_inactive_highlight_group")
    if exists("g:buftabs_in_statusline")
      let s:list = '%#' . g:buftabs_inactive_highlight_group . '#' . s:list
      let s:list .= '%##'
      let buftabs_marker_end = g:buftabs_marker_end . '%#' . g:buftabs_inactive_highlight_group . '#'
    end
  end

  let s:list = substitute(s:list, "\x01", buftabs_marker_start, 'g')
  let s:list = substitute(s:list, "\x02", buftabs_marker_end, 'g')

  " Show the list. The buftabs_in_statusline variable determines of the list
  " is displayed in the command line (volatile) or in the statusline
  " (persistent)
  if exists("g:buftabs_in_statusline") && g:buftabs_in_statusline
    if match(&statusline, s:list) == -1
      if exists("g:buftabs_statusline_highlight_group")
        let s:original_left_statusline = '%=' . '%#' . g:buftabs_statusline_highlight_group . '#' . 
              \ substitute(substitute(s:original_left_statusline, '^%=', '', ''), '%#.*#', '', '')
      endif
      let &statusline = s:list . s:original_left_statusline
    end
  end
endfunction
"}}}

command! -nargs=0 BuftabsToggle  call s:buftabs_toggle()
command! -nargs=0 BuftabsEnable  call s:buftabs_toggle(1)
command! -nargs=0 BuftabsDisable call s:buftabs_toggle(0)

autocmd VimEnter * let g:buftabs_enabled = exists('g:buftabs_enabled') ? g:buftabs_enabled : 1
autocmd VimEnter,BufNew,BufEnter,BufWritePost * call s:buftabs_show(-1)
autocmd BufDelete * call s:buftabs_show(expand('<abuf>'))
if version >= 700
  autocmd InsertLeave,VimResized * call s:buftabs_show(-1)
end

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
" vim:set et fdm=marker ft=vim ts=2 sw=2 sts=2:
