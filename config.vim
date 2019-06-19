call plug#begin('~/.local/share/nvim/plugged')

Plug 'tmsvg/pear-tree' " Auto add pairs to quotes, brackets, etc...
Plug '/usr/local/opt/fzf' " Fuzzy find everything, change to install directory
Plug 'junegunn/fzf.vim' " An interface to FZF
  
" On-demand loading
Plug 'scrooloose/nerdtree'
Plug 'dracula/vim', { 'as': 'dracula' }

Plug 'neoclide/coc.nvim', {'do': './install.sh nightly'}
Plug 'sheerun/vim-polyglot'
Plug 'editorconfig/editorconfig-vim'

" Git
Plug 'tpope/vim-fugitive' " Git wrapper
Plug 'junegunn/gv.vim' " Git commit browser
Plug 'sodapopcan/vim-twiggy' " Git branch browser
Plug 'airblade/vim-gitgutter' " Git hunk indicator

Plug 'Shougo/defx.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'kristijanhusak/defx-icons'
Plug 'kristijanhusak/defx-git'

" Language support
Plug 'fatih/vim-go'
Plug 'zchee/deoplete-go', { 'do': 'make'}      " Go auto completion
Plug 'leafgarland/typescript-vim'  
Plug 'lifepillar/pgsql.vim'
Plug 'mxw/vim-jsx'
Plug 'pangloss/vim-javascript'                 " JavaScript syntax highlighting

" surround
Plug 'sheerun/vim-polyglot' " syntax all things
Plug 'tpope/vim-commentary' " press gcc for commentaries
Plug 'tpope/vim-unimpaired' " Pair other commands
Plug 'tpope/vim-sleuth'
Plug 'skywind3000/asyncrun.vim'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'

" Icons
Plug 'ryanoasis/vim-devicons'

" Vim airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'easymotion/vim-easymotion'

call plug#end()

set termguicolors     " enable true colors support
set number
syntax on
color dracula
set encoding=UTF-8

map <space> <leader>

nnoremap <Leader>n :NERDTreeToggle<CR>
nnoremap <Leader>m :NERDTreeFind<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>s :w<CR>
inoremap jj <Esc>
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
map <C-+> <C-w>+
map <C--> <C-w>-

" Disable arrow keys 
nnoremap <up>    <nop>
nnoremap <down>  <nop>
nnoremap <left>  <nop>
nnoremap <right> <nop>
inoremap <up>    <nop>
inoremap <down>  <nop>
inoremap <left>  <nop>
inoremap <right> <nop>

" EasyMotion
" Configuration
let g:EasyMotion_do_mapping = 0 " Disable default mappings

" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
nmap s <Plug>(easymotion-overwin-f)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
nmap s <Plug>(easymotion-overwin-f2)

" Turn on case-insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)


