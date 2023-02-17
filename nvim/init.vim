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
"Debug
Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'
Plug 'mfussenegger/nvim-dap-python'
Plug 'theHamsta/nvim-dap-virtual-text'
"git and Build
Plug 'tpope/vim-fugitive'
Plug 'cdelledonne/vim-cmake'

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

local dap_breakpoint = {
	error = {
		text = "🔴",
		texthl = "LspDiagnosticsSignError",
		linehl = "",
		numhl = "",
	},
	rejected = {
		text = "🚫",
		texthl = "LspDiagnosticsSignHint",
		linehl = "",
		numhl = "",
	},
	stopped = {
		text = "⭐️",
		texthl = "LspDiagnosticsSignInformation",
		linehl = "DiagnosticUnderlineInfo",
		numhl = "LspDiagnosticsSignInformation",
	},
}

vim.fn.sign_define("DapBreakpoint", dap_breakpoint.error)
vim.fn.sign_define("DapStopped", dap_breakpoint.stopped)
vim.fn.sign_define("DapBreakpointRejected", dap_breakpoint.rejected)
require('dapui').setup()
require("nvim-dap-virtual-text").setup()

EOF
nnoremap <silent> <tab> :NvimTreeToggle<CR>
nnoremap <silent> <C-tab> :NvimTreeFocus<CR>

" Theme
syntax on
set termguicolors
colorscheme catppuccin-frappe

" Git and etc
set clipboard+=unnamedplus
let g:fugitive_git_executable = 'C:\Program Files\Git\bin\git.exe'
let g:dap_virtual_text = v:true

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

" DAP UI
let g:dapui_mappings = 0
let g:dapui_sidebar_position = 'left'
let g:dapui_winnr_width = 40
let g:dapui_winnr_height = 15

" debugging
lua require('mydapconfig').setup()

" COC Config
" Add languages you want to have LSP support for
let g:coc_global_extensions = [
	\ 'coc-json',
	\ 'coc-clangd',
	\ 'coc-python',
	\ 'coc-lua'
	\ ]
  
" DAP key mappings
nnoremap <silent> <F2> :lua require('dapui').toggle()<CR>
nnoremap <silent> <F5> :lua require ('dap').continue()<CR>
nnoremap <silent> <F6> :CMakeBuild<CR>
nnoremap <silent> <F9> :lua require('dap').toggle_breakpoint()<CR>
nnoremap <silent> <F10> :lua require ('dap').step_over()<CR>
nnoremap <silent> <F11> :lua require ('dap').step_into()<CR>
nnoremap <silent> <F12> :lua require ('dap').step_out()<CR>
nnoremap <silent> <leader>lp :lua require('dap').run_last()<CR>

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
nnoremap <silent> <C-c> "+y<CR>
inoremap <silent> <C-c> <Esc>"+y<CR>
nnoremap <silent> <C-v> "+p<CR>
inoremap <silent> <C-v> <Esc>"+p<CR>
let g:clipboard = {
    \   'name': 'win32yank-wsl',
    \   'copy': {
    \      '+': 'C:/tools/neovim/nvim-win64/bin/win32yank.exe -i --crlf',
    \      '*': 'C:/tools/neovim/nvim-win64/bin/win32yank.exe -i --crlf',
    \    },
    \   'paste': {
    \      '+': 'C:/tools/neovim/nvim-win64/bin/win32yank.exe -o --lf',
    \      '*': 'C:/tools/neovim/nvim-win64/bin/win32yank.exe -o --lf',
    \   },
    \   'cache_enabled': 0,
    \ }
