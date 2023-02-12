call plug#begin()

"Theme
Plug 'savq/melange-nvim'
"Tree struct browser
Plug 'scrooloose/nerdtree'
"Emmet
Plug 'mattn/emmet-vim'
"Cxx highlighter
Plug 'jackguo380/vim-lsp-cxx-highlight'
"Icons
Plug 'ryanoasis/vim-devicons'
"Find files with ctrl + p
Plug 'ctrlpvim/ctrlp.vim'

call plug#end()

"melange theme
set termguicolors
colorscheme melange

"CtrlP option
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

"font
let s:fontsize = 12
function! AdjustFontSize(amount)
  let s:fontsize = s:fontsize+a:amount
  :execute "GuiFont! Hurmit NFM:h" . s:fontsize
endfunction

noremap <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
noremap <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
inoremap <C-ScrollWheelUp> <Esc>:call AdjustFontSize(1)<CR>a
inoremap <C-ScrollWheelDown> <Esc>:call AdjustFontSize(-1)<CR>a

"nerdtree shortcut
nnoremap <C-leader> :NERDTreeFocus<CR>
nnoremap <C-t> :NERDTreeToggle C:\Users\rokja<CR>

"auto
autocmd VimEnter * NERDTreeToggle C:\Users\rokja
autocmd VimEnter * GuiFont Hurmit NFM:h12
