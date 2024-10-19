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
	{ 
        "rcarriga/nvim-dap-ui",
		dependencies = {'nvim-neotest/nvim-nio'}
	},
	"theHamsta/nvim-dap-virtual-text",
	--TreeSitter
	"nvim-treesitter/nvim-treesitter",
	--Telescope
	{
        'nvim-telescope/telescope.nvim', tag = '0.1.8',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
	--Auto completion
	"neovim/nvim-lspconfig",
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
        'romgrk/barbar.nvim',
		dependencies = {
		'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
		},
		init = function() vim.g.barbar_auto_setup = false end,
		version = '^1.0.0', -- optional: only update when a new 1.x version is released
	},
    -- RSI
    'tpope/vim-rsi',
})


--Utils
require("utils").setup()

--LSP
require("mylsp").setup()

--Appearances
require("appearance").setup()

--DAP
require("mydap").setup()

--Keymaps
require("keymaps").setup()
