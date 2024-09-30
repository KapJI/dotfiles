" Fern file explorer config
augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END

function! s:init_fern() abort
  nnoremap <Plug>(fern-close-drawer) :<C-u>FernDo close -drawer -stay<CR>
  nnoremap <Plug>(fern-close-drawer-tab) :<C-u>call TabDo('FernDo close -drawer -stay', '-')<CR>

  nmap <buffer><silent> <Plug>(fern-open-and-close)
      \ <Plug>(fern-action-open:edit-or-tabedit)
      \ <Plug>(fern-close-drawer)
      \ <Plug>(fern-close-drawer-tab)

  nmap <buffer><silent> <Plug>(fern-open-split-and-close)
      \ <Plug>(fern-action-open:split)
      \ <Plug>(fern-close-drawer)

  nmap <buffer><silent> <Plug>(fern-open-vsplit-and-close)
      \ <Plug>(fern-action-open:vsplit)
      \ <Plug>(fern-close-drawer)

  nmap <buffer><silent> <Plug>(fern-open-tabedit-and-close)
      \ <Plug>(fern-action-open:tabedit)
      \ <Plug>(fern-close-drawer-tab)

  " change current working directory on enter or leave
  nmap <buffer> <Plug>(fern-enter-and-tcd)
      \ <Plug>(fern-action-enter)
      \ <Plug>(fern-wait)
      \ <Plug>(fern-action-tcd:root)

  nmap <buffer><expr>
      \ <Plug>(fern-open-and-close-or-enter-and-tcd)
      \ fern#smart#leaf(
      \   "\<Plug>(fern-open-and-close)",
      \   "\<Plug>(fern-enter-and-tcd)",
      \ )

  nmap <buffer> <Plug>(fern-leave-and-tcd)
      \ <Plug>(fern-action-leave)
      \ <Plug>(fern-wait)
      \ <Plug>(fern-action-tcd:root)

  nmap <buffer><expr>
      \ <Plug>(fern-expand-or-collapse)
      \ fern#smart#leaf(
      \   "\<Plug>(fern-open-and-close)",
      \   "\<Plug>(fern-action-expand)",
      \   "\<Plug>(fern-action-collapse)",
      \ )

  nmap <buffer> N <Plug>(fern-action-new-path)
  nmap <buffer> T <Plug>(fern-action-new-file)
  nmap <buffer> D <Plug>(fern-action-new-dir)
  nmap <buffer> dd <Plug>(fern-action-remove)
  nmap <buffer> R <Plug>(fern-action-rename)
  nmap <buffer> M <Plug>(fern-action-move)
  nmap <buffer> C <Plug>(fern-action-new-copy)
  nmap <buffer> s <Plug>(fern-open-split-and-close)
  nmap <buffer> v <Plug>(fern-open-vsplit-and-close)
  nmap <buffer> t <Plug>(fern-open-tabedit-and-close)
  nmap <buffer> r <Plug>(fern-action-reload)
  nmap <buffer> w <Plug>(fern-action-mark)
  nmap <buffer> <Right> <Plug>(fern-action-expand)
  nmap <buffer> <Left> <Plug>(fern-action-collapse)
  nmap <buffer> <CR> <Plug>(fern-open-and-close-or-enter-and-tcd)
  nmap <buffer> <C-h> <Plug>(fern-leave-and-tcd)
  nmap <buffer> <2-LeftMouse> <Plug>(fern-expand-or-collapse)
endfunction

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END

" Automatically refresh file tree on entering Fern window
augroup FernTypeGroup
    autocmd! * <buffer>
    autocmd BufEnter <buffer> silent execute "normal \<Plug>(fern-action-reload)"
augroup END

let g:fern#drawer_width = 40
let g:fern#default_hidden = 1
let g:fern#smart_cursor = "hide"

" Nicer icons
let g:fern#renderer = "nerdfont"
let g:fern#mark_symbol = '●'

" fern-git-status config
let g:fern_git_status#disable_ignored    = 1
let g:fern_git_status#disable_untracked  = 1
let g:fern_git_status#disable_submodules = 1
