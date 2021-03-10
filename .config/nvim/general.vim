syntax on                   " syntax highlighting
" indentation
set autoindent              " indent a new line the same amount as the line just typed
set expandtab               " converts tabs to white space
set tabstop=4               " number of columns occupied by a tab character
set shiftwidth=4            " width for autoindents
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set shiftround              " always round indents to multiple of shiftwidth
filetype plugin indent on   " allows auto-indenting depending on file type
" appearance
set showmatch               " show matching brackets.
set noshowmode              " don't show current mode, it will be shown by lightline plugin
set nowrap                  " don't wrap lines
set wildmode=longest,list   " get bash-like tab completions
" search
set ignorecase              " case insensitive matching
set smartcase               " .. unless 'the search pattern contains upper case characters'
" line numbers
set number relativenumber   " add line numbers
" set noerrorbells            " disable beeps
" set cc=80                   " set an 80 column border for good coding style
set mouse=a                 " enable mouse support
" undo
set undofile
set undodir=~/.vim/undo/
" file management
set noswapfile              " disable creation of swap files
set nowritebackup           " disable writing backups
" split
set splitbelow
set splitright
set listchars=eol:$,tab:.\ ,trail:.,extends:>,precedes:<,nbsp:_ " whitespace chars
set updatetime=100          " faster updates for async vim-signify
let mapleader=" "           " set leader key to space

" Like tabdo but restore the current tab.
function! TabDo(command, ...)
  let range = get(a:, 1, '')
  let currTab=tabpagenr()
  execute range . 'tabdo ' . a:command
  execute 'tabn ' . currTab
endfunction

" Use it2copy as clipboard provider.
let g:clipboard = {
\   'name': 'it2copy',
\   'copy': {
\     '+': 'it2copy',
\     '*': 'it2copy',
\   },
\   'paste': {
\     '+': 'true',
\     '*': 'true',
\    },
\ }
