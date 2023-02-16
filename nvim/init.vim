call plug#begin()

"Theme
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
"Tree struct browser
Plug 'scrooloose/nerdtree'
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
Plug 'jamesharr/vim-variable-autoassign'

call plug#end()

"theme
syntax on
set termguicolors
colorscheme catppuccin-frappe
set clipboard+=unnamedplus
let g:fugitive_git_executable = 'C:\Program Files\Git\bin\git.exe'
lua << EOF
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
let g:dap_virtual_text = v:true

"CtrlP option
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

"font
let s:fontsize = 12
function! AdjustFontSize(amount)
  let s:fontsize = s:fontsize+a:amount
  :execute "GuiFont! Hurmit NFM:h" . s:fontsize
endfunction
autocmd VimEnter * GuiFont Hurmit NFM:h12

nnoremap <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
nnoremap <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
inoremap <C-ScrollWheelUp> <Esc>:call AdjustFontSize(1)<CR>a
inoremap <C-ScrollWheelDown> <Esc>:call AdjustFontSize(-1)<CR>a

"nerdtree shortcut
nnoremap <C-leader> :NERDTreeFocus<CR>
nnoremap <C-t> :NERDTreeToggle C: <CR>

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
  \ 'coc-python'
  \ ]
  
" DAP key mappings
nnoremap <silent> <F2> :lua require('dapui').toggle()<CR>
nmap <silent> <F5> :lua require ('dap').continue()<CR>
nmap <silent> <F9> :lua require('dap').toggle_breakpoint()<CR>
nmap <silent> <F10> :lua require ('dap').step_over()<CR>
nmap <silent> <F11> :lua require ('dap').step_into()<CR>
nmap <silent> <F12> :lua require ('dap').step_out()<CR>
nmap <silent> <leader>lp :lua require('dap').run_last()<CR>
