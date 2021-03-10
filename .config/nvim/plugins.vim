call plug#begin("~/.vim/plugged")
  Plug 'srcery-colors/srcery-vim'
  " {{ Fern plugins
  Plug 'lambdalisue/fern.vim'
  Plug 'lambdalisue/fern-renderer-nerdfont.vim'
  Plug 'lambdalisue/fern-git-status.vim'
  Plug 'lambdalisue/fern-hijack.vim'
  Plug 'lambdalisue/nerdfont.vim'
  Plug 'lambdalisue/glyph-palette.vim'
  Plug 'antoinemadec/FixCursorHold.nvim' " fix performance issues in nvim for several plugins
  " }}
  " {{ fuzzy find
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  " }}
  " {{ Lightline plugins
  Plug 'itchyny/lightline.vim'
  Plug 'mengelbrecht/lightline-bufferline'
  Plug 'maximbaz/lightline-trailing-whitespace'
  Plug 'tpope/vim-fugitive'
  " }}
  " Plug 'airblade/vim-gitgutter'
  Plug 'mhinz/vim-signify'
  Plug 'markstory/vim-zoomwin'
  Plug 'cespare/vim-toml'
  " Plug 'neoclide/coc.nvim', {'branch': 'release'}
  " let g:coc_global_extensions = ['coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-tsserver']
call plug#end()
