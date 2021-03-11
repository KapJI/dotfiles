let s:xsmall_window_width = 60
let s:small_window_width = 90
let s:symbols = {
\   'branch': "\uf126",
\   'menu': "\uf85b",
\   'modified': '•',
\   'readonly': "\uf023",
\   'separator': {'left': "\ue0b0", 'right': "\ue0b2"},
\   'subseparator': {'left': "\ue0b1", 'right': "\ue0b3"},
\   'user': "\uf007",
\   'zoom': "\uf848",
\ }
let s:short_modes = {
\   'NORMAL':   'N',
\   'INSERT':   'I',
\   'VISUAL':   'V',
\   'V-LINE':   'L',
\   'V-BLOCK':  'B',
\   'COMMAND':  'C',
\   'SELECT':   'S',
\   'S-LINE':   'S-L',
\   'S-BLOCK':  'S-B',
\   'TERMINAL': 'T',
\ }
let s:empty_file_name = '[No Name]'
let g:lightline = {}
let g:lightline.colorscheme = 'srcery'
let g:lightline.active =  {
\   'left': [['is_root', 'mode', 'paste'],
\            ['zoom', 'filename']],
\   'right': [['trailing', 'lineinfo'],
\             ['percent'],
\             ['gitbranch', 'githunks', 'fileformat', 'fileencoding', 'filetype']]
\ }
let g:lightline.component_function = {
\   'mode':         'LightlineModeStatus',
\   'githunks':     'LightlineGitGutter',
\   'gitbranch':    'LightlineGitBranch',
\   'filename':     'LightlineFilename',
\   'fileformat':   'LightlineFileformat',
\   'fileencoding': 'LightlineFileencoding',
\   'filetype':     'LightlineFiletype',
\   'zoom':         'LightlineZoom',
\   'lineinfo':     'LightlineLineinfo',
\   'percent':      'LightlinePercent',
\ }
let g:lightline.component_expand = {
\   'is_root':      'LightlineIsRoot',
\   'trailing':     'LightlineTrailing',
\ }
let g:lightline.component_type = {
\   'is_root': 'error',
\   'trailing': 'error',
\ }
let g:lightline.tabline = {
\   'left': [['tabs']],
\   'right': [['close']]
\ }
let g:lightline.tab = {
\   'active':   ['tabnum', 'filename', 'readonly', 'modified'],
\   'inactive': ['tabnum', 'filename', 'readonly', 'modified']
\ }
let g:lightline.tab_component_function = {
\   'filename': 'LightlineTabFilename',
\   'readonly': 'LightlineTabReadonly',
\   'modified': 'LightlineTabModified',
\ }
let g:lightline.separator = s:symbols.separator
let g:lightline.subseparator = s:symbols.subseparator
" lightline-trailing-whitespace
let g:lightline#trailing_whitespace#indicator = '•'

function! LightlineIsRoot()
  if $USER !=# 'root' | return '' | endif
  return s:symbols.user . " root"
endfunction

function! LightlineModeStatus()
  if &filetype ==# 'minimap'
    return ''
  elseif &filetype ==# 'fern'
    return 'Fern'
  elseif &buftype ==# 'help'
    return 'HELP'
  endif
  let mode_label = lightline#mode()
  if winwidth(0) < s:xsmall_window_width
      return get(s:short_modes, mode_label, mode_label)
  endif

  return mode_label
endfunction

function! LightlineGitGutter()
  if winwidth(0) < s:small_window_width || empty(FugitiveHead()) || &buftype ==# 'terminal' || &filetype ==# 'fern' || &filetype ==# 'vim-plug' || &filetype ==# 'minimap'
    return ''
  endif
  " let [l:added, l:modified, l:removed] = GitGutterGetHunkSummary()
  let [l:added, l:modified, l:removed] = sy#repo#get_stats()
  return printf('+%d -%d ~%d', l:added, l:removed, l:modified)
endfunction

function! LightlineGitBranch()
  if winwidth(0) < s:small_window_width || empty(FugitiveHead()) || &buftype ==# 'terminal' || &filetype ==# 'fern' || &filetype ==# 'vim-plug' || &filetype ==# 'minimap'
    return ''
  endif
  return s:symbols.branch . ' ' . FugitiveHead()
endfunction

function! LightlineFilename()
  if &filetype ==# 'fern' || &filetype ==# 'minimap'
    return ''
  endif
  let filename = expand('%:t') !=# '' ? expand('%:t') : s:empty_file_name
  let modified = &modified ? ' [' . s:symbols.modified . ']' : ''
  let readonly = &readonly ? s:symbols.readonly . ' ' : ''
  return readonly . filename . modified
endfunction

function! LightlineFileformat()
  if winwidth(0) < s:small_window_width || &buftype ==# 'terminal' || &buftype ==# 'help' || &filetype ==# 'minimap'
    return ''
  endif
  return &fileformat
endfunction

function! LightlineFileencoding()
  if &buftype ==# 'terminal' || &buftype ==# 'help' || &filetype ==# 'fern' || &filetype ==# 'minimap'
    return ''
  endif
  let l:encoding = strlen(&fileencoding) ? &fileencoding : &encoding
  let l:bomb     = &bomb ? '[BOM]' : ''
  return l:encoding . l:bomb
endfunction

function! LightlineFiletype()
  if winwidth(0) < s:small_window_width || &buftype ==# 'terminal' || &buftype ==# 'help' || &filetype ==# 'minimap'
    return ''
  endif
  return strlen(&filetype) ? nerdfont#find() . ' ' . &filetype : 'no ft'
endfunction

function! LightlineZoom()
  return exists('t:zoomed') && t:zoomed == 1 ? s:symbols.zoom . ' zoomed' : ''
endfunction

function! LightlineTrailing()
  if &filetype ==# 'minimap'
    return ''
  endif
  return lightline#trailing_whitespace#component()
endfunction

function! LightlineLineinfo()
  if &filetype ==# 'minimap'
    return ''
  endif
  return printf("%3d:%-2d", line('.'), col('.'))
endfunction

function! LightlinePercent()
  if &filetype ==# 'minimap'
    return ''
  endif
  return (100 * line('.') / line('$')) . '%'
endfunction

function! LightlineTabReadonly(n) abort
    let winnr = tabpagewinnr(a:n)
    return gettabwinvar(a:n, winnr, '&readonly') ? s:symbols.readonly : ''
endfunction

function! LightlineTabModified(n) abort
    let winnr = tabpagewinnr(a:n)
    return gettabwinvar(a:n, winnr, '&modified') ? s:symbols.modified : ''
endfunction

let s:buffer_count_by_basename = {}
augroup lightline_settings
    autocmd!
    autocmd BufEnter,WinEnter,WinLeave * call s:update_bufnrs()
augroup END

function! s:update_bufnrs() abort
    let s:buffer_count_by_basename = {}
    let bufnrs = filter(range(1, bufnr('$')), 'len(bufname(v:val)) && bufexists(v:val) && buflisted(v:val)')
    for name in map(bufnrs, 'expand("#" . v:val . ":t")')
        if name !=# ''
            let s:buffer_count_by_basename[name] = get(s:buffer_count_by_basename, name) + 1
        endif
    endfor
endfunction

function! LightlineTabFilename(n) abort
    let bufnr = tabpagebuflist(a:n)[tabpagewinnr(a:n) - 1]
    let bufname = expand('#' . bufnr . ':t')
    let path = expand('#' . bufnr . ':p')
    let ft = gettabwinvar(a:n, tabpagewinnr(a:n), '&filetype')
    if get(s:buffer_count_by_basename, bufname) > 1
        let fname = substitute(expand('#' . bufnr . ':p'), '.*/\([^/]\+/\)', '\1', '')
    else
        let fname = bufname !=# '' ? bufname : s:empty_file_name
    endif
    return ft ==# 'fern' ? s:symbols.menu . ' Fern' : nerdfont#find(path) . ' ' . fname
endfunction
