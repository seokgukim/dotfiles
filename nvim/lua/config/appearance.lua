local M = {}

function M.setup()
	--Status Line
	vim.opt.termguicolors = true

	--Devicons
	require("nvim-web-devicons").setup()

	-- Theme
	vim.cmd("colorscheme nordfox")
	vim.cmd("syntax on")
	vim.opt.termguicolors = true
	vim.cmd("set tabstop=4")
	vim.cmd("set shiftwidth=2")
	vim.cmd("set smartindent")
	vim.cmd("set expandtab")
	vim.cmd("set number")
	vim.cmd("set relativenumber")
	vim.cmd("set showmatch")
	require("barbar").setup({ animation = false })
end

return M
