set number

set cursorline

set scrolloff=5

set hlsearch
nnoremap <ESC><ESC> :nohlsearch<CR>

inoremap <silent> jj <ESC>

syntax on
" set syntax=whitespace

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"


set tabstop=2 shiftwidth=2 expandtab
