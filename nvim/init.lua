local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")

-- Prevent Tree-sitter parser errors from blocking Neovim startup
local ts_start = vim.treesitter.start
vim.treesitter.start = function(bufnr, lang)
	local ok, _ = pcall(ts_start, bufnr, lang)
	if not ok then
		-- Fallback to standard regex highlighting if TS fails
		vim.bo[bufnr or 0].syntax = lang
	end
end

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

local is_windows = vim.fn.has("win32") == 1 -- Windos detect
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
	-- "airblade/vim-gitgutter",
	--DAP
	-- "mfussenegger/nvim-dap",
	-- "mfussenegger/nvim-dap-python",
	-- "suketa/nvim-dap-ruby",
	-- {
	-- 	"rcarriga/nvim-dap-ui",
	-- 	dependencies = { "nvim-neotest/nvim-nio" },
	-- },
	-- "theHamsta/nvim-dap-virtual-text",
	--TreeSitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = {
				enable = true,
			},
		},
		config = function(_, opts)
			local install = require("nvim-treesitter.install")
			install.prefer_git = true
			install.compilers = { "/usr/bin/gcc", "gcc", "clang" }
			require("nvim-treesitter").setup(opts)
		end,
	},
	--Snacks
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
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
	-- "tpope/vim-rsi",
	-- Auto LLM
	-- "ggml-org/llama.vim",
	-- Marp
	"mpas/marp-nvim",
	-- Conform
	"stevearc/conform.nvim",
	-- CSV
	{
	  "hat0uma/csvview.nvim",
	  ---@module "csvview"
	  ---@type CsvView.Options
	  opts = {
	    parser = { comments = { "#", "//" } },
	    keymaps = {
	      -- Text objects for selecting fields
	      textobject_field_inner = { "if", mode = { "o", "x" } },
	      textobject_field_outer = { "af", mode = { "o", "x" } },
	      -- Excel-like navigation:
	      -- Use <Tab> and <S-Tab> to move horizontally between fields.
	      -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
	      -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
	      jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
	      jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
	      jump_next_row = { "<Enter>", mode = { "n", "v" } },
	      jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
	    },
	  },
	  cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},
	-- mlua (Windows only, but testing local now)
	{
		dir = "~/projects/mlua.nvim",
		-- cond = function() return is_windows end,
	},
	{
		"seokgukim/mlua-debugger.nvim",
		cond = function() return is_windows end,
	},
	-- vawi
	{
		"seokgukim/vawi.nvim",
		cond = function() return is_windows end,
	}
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
-- require("config.dap").setup()

--Keymaps
require("config.keymaps").setup()

---mLua (Windows only, but testing local now)
-- if is_windows then
    require("mlua").setup({
		handlers = {
			["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
				syntax = false,
			}),
		},
		keymaps = {
    		-- Set to false to disable a specific keymap, or change the key
			hover = "K",
			definition = "gd",
			references = "gr",
			declaration = false,
			implementation = false,
			rename = "<leader>rn",
			code_action = "<leader>ca",
			format = "<leader>f",
			toggle_inlay_hints = false,
  		},
		deprecated_commands = false
	})
	
    if is_windows then
        require("mlua-debugger").setup({
            deprecated_commands = false
        })
    end
-- end

-- vawi
if is_windows then
    require("vawi").setup()
end
