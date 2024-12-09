"================================================
" remap keys for Colemak-DH
"================================================

" normal
" navigation
nnoremap n h
nnoremap e j
nnoremap i k
nnoremap o l

" new line
nnoremap h o
nnoremap H O

" next/previous matches
nnoremap k n
nnoremap K N

" end of word
nnoremap l e
nnoremap L E

" insert mode
nnoremap s i

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

" visual
" navigation
vnoremap n h
vnoremap e j
vnoremap i k
vnoremap o l

" insert mode
vnoremap s i
vnoremap S I

" end of word
vnoremap l e
vnoremap L E

" operator
" end of word
onoremap l e
onoremap L E

"================================================
" General Config
"================================================

" UTF-8 suppport
set encoding=utf-8

"----------------------------
" jump to last position when reopening a file
if has("autocmd")
   au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

"----------------------------
" line number
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
"fallback original colors
colorscheme vim

"----------------------------
" set C-Backspace to delete word (insert mode)
inoremap <C-BS> <C-W>
