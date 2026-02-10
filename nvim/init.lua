local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	--Theme
	"EdenEast/nightfox.nvim",
	--Status
	"nvim-tree/nvim-web-devicons",
	"bluz71/nvim-linefly",
	--Emmet
	"mattn/emmet-vim",
	--Git
	"tpope/vim-fugitive",
	"airblade/vim-gitgutter",
	--DAP
	"mfussenegger/nvim-dap",
	"mfussenegger/nvim-dap-python",
	"suketa/nvim-dap-ruby",
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "nvim-neotest/nvim-nio" },
	},
	"theHamsta/nvim-dap-virtual-text",
	--TreeSitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local is_windows = vim.fn.has("win32") == 1
			require("nvim-treesitter.install").prefer_git = false
			require("nvim-treesitter.install").compilers = is_windows and { "clang", "gcc", "cl" } or { "clang", "gcc" }
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
			})
		end,
	},
	--Snacks
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			notifier = { enabled = true, timeout = 3000 },
			picker = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},
	--Auto completion
	-- "neovim/nvim-lspconfig",
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-calc",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"hrsh7th/cmp-nvim-lua",
			"dcampos/nvim-snippy",
			"dcampos/cmp-snippy",
		},
	},
	--TabLine
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
	-- RSI
	"tpope/vim-rsi",
	-- Copilot
	-- "github/copilot.vim",
	{
		"stevearc/conform.nvim",
		opts = {},
	},
	-- mlua (Windows only)
	{
		"seokgukim/mlua.nvim",
		cond = function() return vim.fn.has("win32") == 1 end,
	},
	{
		"seokgukim/mlua-debugger.nvim",
		cond = function() return vim.fn.has("win32") == 1 end,
	},
	-- vawi
	"seokgukim/vawi.nvim"
})

--Utils
require("config.utils").setup()

--LSP
require("config.lsp").setup()

--Formatter
require("config.formatter").setup()

--Appearances
require("config.appearance").setup()

--DAP
require("config.dap").setup()

--Copilot
-- require("config.copilot").setup()

--Keymaps
require("config.keymaps").setup()

---mLua (Windows only)
if vim.fn.has("win32") == 1 then
    require("mlua").setup()
    require("mlua-debugger").setup()
end

-- vawi
require("vawi").setup()
