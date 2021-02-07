" use alt+hjkl to move between split/vsplit panels
tnoremap <A-h> <C-\><C-n><C-w>h
tnoremap <A-j> <C-\><C-n><C-w>j
tnoremap <A-k> <C-\><C-n><C-w>k
tnoremap <A-l> <C-\><C-n><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
" same for arrow keys
tnoremap <A-Left> <C-\><C-n><C-w>h
tnoremap <A-Down> <C-\><C-n><C-w>j
tnoremap <A-Up> <C-\><C-n><C-w>k
tnoremap <A-Right> <C-\><C-n><C-w>l
nnoremap <A-Left> <C-w>h
nnoremap <A-Down> <C-w>j
nnoremap <A-Up> <C-w>k
nnoremap <A-Right> <C-w>l

" Open fzf
nnoremap <silent> <C-p> :FZF<CR>
nnoremap <silent> <A-p> :FZF %:h<CR>

" Save file hotkey
nnoremap <silent> <C-s> :w<CR>
imap <C-s> <C-o><C-s>

" Toggle fern
nnoremap <silent> <C-b> :Fern . -drawer -toggle<CR>
nnoremap <silent> <A-b> :Fern %:h -drawer -toggle<CR>

" Toggle the terminal
nnoremap <silent> <C-n> :call MonkeyTerminalToggle()<CR>
tnoremap <silent> <C-n> <C-\><C-n>:call MonkeyTerminalToggle()<CR>

" turn terminal to normal mode with escape
tnoremap <Esc> <C-\><C-n>

" Close window
nnoremap <silent> <C-w> :q<CR>
imap <C-w> <C-o><C-w>
tnoremap <silent> <C-w> <C-\><C-n>:q<CR>

" Show whitelist chars (display unprintable characters).
nnoremap <Leader>sw :set list!<CR>

" Tab hotkeys
nnoremap <silent> <C-t> :tabnew<C-m>
vnoremap <silent> <C-t> <ESC>:tabnew<C-m>i
inoremap <silent> <C-t> <ESC>:tabnew<C-m>i

nnoremap <silent> <S-Tab> :tabprev<C-m>
vnoremap <silent> <S-Tab> <ESC>:tabprev<C-m>i
inoremap <silent> <S-Tab> <ESC>:tabprev<C-m>i

nnoremap <silent> <A-Tab> :tabnext<C-m>
vnoremap <silent> <A-Tab> <ESC>:tabnext<C-m>i
inoremap <silent> <A-Tab> <ESC>:tabnext<C-m>i

" Select tab by number
nnoremap <silent> <Leader>1 :1tabnext<CR>
nnoremap <silent> <Leader>2 :2tabnext<CR>
nnoremap <silent> <Leader>3 :3tabnext<CR>
nnoremap <silent> <Leader>4 :4tabnext<CR>
nnoremap <silent> <Leader>5 :5tabnext<CR>
nnoremap <silent> <Leader>6 :6tabnext<CR>
nnoremap <silent> <Leader>7 :7tabnext<CR>
nnoremap <silent> <Leader>8 :8tabnext<CR>
nnoremap <silent> <Leader>9 :9tabnext<CR>
nnoremap <silent> <Leader>0 :10tabnext<CR>

" Close tab by number
noremap <silent> <Leader>c1 :1tabclose<CR>
noremap <silent> <Leader>c2 :2tabclose<CR>
noremap <silent> <Leader>c3 :3tabclose<CR>
noremap <silent> <Leader>c4 :4tabclose<CR>
noremap <silent> <Leader>c5 :5tabclose<CR>
noremap <silent> <Leader>c6 :6tabclose<CR>
noremap <silent> <Leader>c7 :7tabclose<CR>
noremap <silent> <Leader>c8 :8tabclose<CR>
noremap <silent> <Leader>c9 :9tabclose<CR>
noremap <silent> <Leader>c0 :10tabclose<CR>

" vim-signify
nnoremap <silent> <Leader>hd :SignifyDiff<CR>
nnoremap <silent> <Leader>hp :SignifyHunkDiff<CR>
nnoremap <silent> <Leader>hu :SignifyHunkUndo<CR>

 " hunk text object
omap ic <plug>(signify-motion-inner-pending)
xmap ic <plug>(signify-motion-inner-visual)
omap ac <plug>(signify-motion-outer-pending)
xmap ac <plug>(signify-motion-outer-visual)