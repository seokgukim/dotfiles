call plug#begin()

"Theme
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
"Tree struct browser
Plug 'nvim-tree/nvim-tree.lua'
"Emmet
Plug 'mattn/emmet-vim'
"Icons
Plug 'ryanoasis/vim-devicons'
"Find files with ctrl + p
Plug 'ctrlpvim/ctrlp.vim'
"Coc linter
Plug 'neoclide/coc.nvim', {'branch': 'release'}
"CP Helper
Plug 'MunifTanjim/nui.nvim'
Plug 'xeluxee/competitest.nvim'
"git and Build
Plug 'tpope/vim-fugitive'

call plug#end()

"Tree Struct and lua configs
lua << EOF

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
    width = 30,
    mappings = {
      list = {
        { key = "u", action = "dir_up" },
      },
    },
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})

require('competitest').setup()

EOF
nnoremap <silent> <tab> :NvimTreeToggle<CR>
nnoremap <silent> <C-tab> :NvimTreeFocus<CR>

" Theme
syntax on
set termguicolors
colorscheme catppuccin-frappe

" Git
let g:fugitive_git_executable = 'C:\Program Files\Git\bin\git.exe'


" CtrlP option
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

" Font
let s:fontsize = 12
function! AdjustFontSize(amount)
  let s:fontsize = s:fontsize+a:amount
  :execute "GuiFont! Anonymice NF:h" . s:fontsize
endfunction
autocmd VimEnter * GuiFont Anonymice NF:h12

nnoremap <silent> <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
nnoremap <silent> <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
inoremap <silent> <C-ScrollWheelUp> <Esc>:call AdjustFontSize(1)<CR>a
inoremap <silent> <C-ScrollWheelDown> <Esc>:call AdjustFontSize(-1)<CR>a

" COC Config
" Add languages you want to have LSP support for
let g:coc_global_extensions = [
	\ 'coc-json',
	\ 'coc-clangd',
	\ 'coc-python',
	\ 'coc-lua'
	\ ]

"CP Helper
cd C:\Users\rokja\ps
nnoremap <silent> <F5> :CompetiTestRun<CR>
nnoremap <silent> <F6> :CompetiTestRunNE<CR>
nnoremap <silent> <F2> :CompetiTestAdd<CR>
nnoremap <silent> <F3> :CompetiTestEdit<CR>
nnoremap <silent> <F4> :CompetiTestDelete<CR>

" ShortCuts
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <Esc>:w<CR>
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <Esc>:q<CR>
nnoremap <silent> <C-z> :u<CR>
inoremap <silent> <C-z> <Esc>:u<CR>
nnoremap <silent> <C-y> :red<CR>
inoremap <silent> <C-y> <Esc>:red<CR>

" ClipBoard
set clipboard+=unnamedplus
nnoremap <silent> <C-c> "+y<CR>
vnoremap <silent> <C-c> "+y<CR>
nnoremap <silent> <C-v> "+p<CR>
vnoremap <silent> <C-v> "+p<CR>
inoremap <silent> <C-v> <Esc>"+p<CR>
