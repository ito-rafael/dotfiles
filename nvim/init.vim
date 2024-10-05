""================================================
"" packer.nvim
""================================================
lua require('plugins')

""================================================
"" Vundle: Vim plugin manager
""================================================
"
"set nocompatible             " be iMproved, required
"filetype off                 " required
"
""set the runtime path to include Vundle and initialize
"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
"
""---------------------------------------
""let Vundle manage Vundle, required
"Plugin 'VundleVim/Vundle.vim'
""---------------------------------------
""YouCompleteMe: a code-completion engine for Vim
"Bundle 'Valloric/YouCompleteMe'
""---------------------------------------
""Zenburn: low-contrast color scheme for Vim
"Plugin 'jnurmine/Zenburn'
""---------------------------------------
""fugitive.vim: Git wrapper
"Plugin 'tpope/vim-fugitive'
""---------------------------------------
""NERDTree
"Plugin 'preservim/nerdtree'
""---------------------------------------
""Powerline
"Plugin 'powerline/powerline'
""---------------------------------------
"" Table mode
"Plugin 'dhruvasagar/vim-table-mode'
""---------------------------------------
"" Limelight: context focus
"Plugin 'junegunn/limelight.vim'
""---------------------------------------
"" Syntax checking
"Plugin 'vim-syntastic/syntastic'
""=======================================
"" Python
""=======================================
""Auto-Indentation with multiple lines
"Plugin 'vim-scripts/indentpython.vim'
""---------------------------------------
"" Flake8 (PEP 8)
"Plugin 'nvie/vim-flake8'
""=======================================
"" Markdown
""=======================================
"" Markdown syntax, folding & more
"Plugin 'godlygeek/tabular'
"Plugin 'preservim/vim-markdown'
""---------------------------------------
"" Markdown instant preview
"Plugin 'suan/vim-instant-markdown'
""=======================================
"" LaTeX
""=======================================
""LaTeX support
"Plugin 'lervag/vimtex'
""---------------------------------------
""Lively previewing LaTeX PDF output
"Plugin 'xuhdev/vim-latex-live-preview'
""=======================================
""Ansible filetypes syntax highlighting
"Plugin 'pearofducks/ansible-vim'
""---------------------------------------
""
""
""PYTHON: when open ( automatically open ). the same for [] and {}
""
"
"" All of your Plugins must be added before the following line
"call vundle#end()            " required
"filetype plugin indent on    " required
"
"" To ignore plugin indent changes, instead use:
""filetype plugin on
"
""
"" Brief help
"" :PluginList       - lists configured plugins
"" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
"" :PluginSearch foo - searches for foo; append `!` to refresh local cache
"" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
""
"" see :h vundle for more details or wiki for FAQ
"" Put your non-Plugin stuff after this line

"================================================
" Plugins Config
"================================================

"---------------------------------------
" Powerline
"---------------------------------------
set laststatus=2

"---------------------------------------
" Limelight
"---------------------------------------
" color name (:help cterm-colors) or ANSI code
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240

"---------------------------------------
" vim-instant-markdown 
"---------------------------------------
" set default browser
"let g:instant_markdown_browser = 'firefox-developer-edition --new-window'
let g:instant_markdown_browser = 'brave --new-window'

"================================================
" LaTeX
"================================================
"change frequency that the output PDF is updated
autocmd Filetype tex setl updatetime=1

"specify PDF viewer
"let g:livepreview_previewer = 'evince'

"specify TeX engine
"let g:livepreview_engine = 'pdflatex'
"let g:livepreview_engine = 'xelatex'
"let g:livepreview_engine = 'latexmk'

"----------------------------
" UTF-8 suppport
"----------------------------
set encoding=utf-8

"----------------------------
" code folding
"----------------------------
"enable folding
set foldmethod=indent
set foldlevel=99

"enable folding with the space bar
noremap <space> za

"----------------------------
" jump to last position when reopening a file
"----------------------------
if has("autocmd")
   au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

"================================================
" Python Config
"================================================

"----------------------------
" PEP 8: indentation
au BufNewFile, BufRead *.py
    \ set tabstop=4
    \ set softtabstop=4
    \ set shiftwidth=4
    \ set textwidth=79
    \ set expandtab
    \ set autoindent
    \ set fileformat=unix

"----------------------------
" flagging extra whitespace
au BufRead, BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

"----------------------------
" Syntax Checking/Highlighting
let python_highlight_all=1
syntax on

"================================================
" HTML
"================================================
" bold
autocmd FileType html inoremap ;b <b></b><Space><++><Esc>FbT>i
" paragraph
autocmd FileType html inoremap ;p <p></p><Enter><Enter><++><Esc>2ki

"================================================
" remap navigation keys
"================================================

nnoremap h ;
nnoremap j h
nnoremap k j
nnoremap l k
"nnoremap / l
"nnoremap ? /

"nnoremap f13 + a = á
"nnoremap f13 + e = é
"nnoremap f13 + i = í
"nnoremap f13 + o = ó
"nnoremap f13 + u = ú
"nnoremap f13 + c = ç

"nnoremap f13 + A = Á
"nnoremap f13 + E = É
"nnoremap f13 + I = Í
"nnoremap f13 + O = Ó
"nnoremap f13 + U = Ú
"nnoremap f13 + C = Ç

vnoremap h ;
vnoremap j h
vnoremap k j
vnoremap l k
"vnoremap / l
"vnoremap ? /
"================================================
" General Config
"================================================
"
set nospell
"----------------------------
" write with sudo
"----------------------------
"cmap W w !sudo tee > /dev/null %
cnoremap w! SudaWrite

"----------------------------
" line number
"----------------------------
"display line number
set number
"display relative line number
set relativenumber

"----------------------------
" tab width
"----------------------------
"show existing tab with 4 spaces width
set tabstop=4

"when indenting with '>', use 4 spaces width
set shiftwidth=4

"on pressing tab, insert spaces
set expandtab

"----------------------------
" other config
"----------------------------
"disable auto-indentig for pasting
"set paste

"use clipboard as default register
set clipboard=unnamedplus

"----------------------------
" disable system beep
"----------------------------
set belloff=all

"----------------------------
" Mapping keys
"----------------------------
"map <Leader> key to <Space>
nnoremap <SPACE> <Nop>
let mapleader = "\<Space>"

"write the current file as sudo
noremap <Leader>W :w !sudo tee % > /dev/null

"split navigations
"
"********* NOT WORKING **********
"
"nnoremap <C-J> <C-W><C-J>
"nnoremap <C-K> <C-W><C-K>
"nnoremap <C-L> <C-W><C-L>
"nnoremap <C-H> <C-W><C-H>
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <C-h> <C-w>h

"----------------------------
"Spell checking
:setlocal spell spelllang=en_us

"----------------------------
"fallback original colors
colorscheme vim

"----------------------------
" set C-Backspace to delete word (insert mode)
inoremap <C-BS> <C-W>
