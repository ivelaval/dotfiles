call plug#begin('~/.local/share/nvim/plugged')

" On-demand loading
Plug 'scrooloose/nerdtree'
Plug 'dracula/vim', { 'as': 'dracula' }

Plug 'neoclide/coc.nvim', {'do': './install.sh nightly'}
Plug 'sheerun/vim-polyglot'
Plug 'editorconfig/editorconfig-vim'

call plug#end()

set termguicolors     " enable true colors support
set number
syntax on
color dracula

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

