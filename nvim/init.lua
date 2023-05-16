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
	--cp helper
	"MunifTanjim/nui.nvim",
	"xeluxee/competitest.nvim",
	--Emmet
	"mattn/emmet-vim",
	--Git
	"tpope/vim-fugitive",
	"airblade/vim-gitgutter",
	--DAP
	"mfussenegger/nvim-dap",
	"rcarriga/nvim-dap-ui",
	"theHamsta/nvim-dap-virtual-text",
	--TreeSitter
	"nvim-treesitter/nvim-treesitter",
	--fzf
	"junegunn/fzf",
	"junegunn/fzf.vim",
	--Auto completion
	"neovim/nvim-lspconfig",
	 { "hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-calc",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"hrsh7th/cmp-nvim-lua",
			"dcampos/nvim-snippy"
		},
	},
})

--TreeSitter
require "nvim-treesitter.install".prefer_git = false
require "nvim-treesitter.install".compilers = { "clang", "gcc" }
require"nvim-treesitter.configs".setup {
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

--fzf Ag
vim.g.ackprg = "ag --vimgrep"

--NvimTree and Status Line

vim.opt.termguicolors = true

require("nvim-web-devicons").setup()
--CP helper
require("competitest").setup()

--DAP Config
require("dapconfig").setup()
require("dapui").setup()
require("nvim-dap-virtual-text").setup()

vim.fn.sign_define("DapBreakpoint",{ text ="🔴", texthl ="LspDiagnosticsSignError", linehl ="", numhl =""})
vim.fn.sign_define("DapStopped",{ text ="▶️", texthl ="LspDiagnosticsSignInformation", linehl ="DiagnosticUnderlineInfo", numhl ="LspDiagnosticsSignInformation"})
vim.fn.sign_define("DapBreakpointRejected",{ text ="🚫", texthl ="LspDiagnosticsSignHint", linehl ="", numhl =""})

vim.g.dap_virtual_text = true

--AutoCompletion
local cmp = require"cmp"

cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
		expand = function(args)
			require("snippy").expand_snippet(args.body) -- For `snippy` users.
		end,
    },
    window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "snippy" }, -- For snippy users.
    }, 
	{
		{ name = "buffer" },
    })
})

-- Set configuration for specific filetype.
cmp.setup.filetype("gitcommit", {
    sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, 
	{
		{ name = "buffer" },
	})
 })

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won"t work anymore).
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" }
    }
})

-- Use cmdline & path source for ":" (if you enabled `native_menu`, this won"t work anymore).
cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" }
    }, {
      { name = "cmdline" }
    })
})

  -- Set up lspconfig.
local capabilities = require("cmp_nvim_lsp").default_capabilities()
  -- Replace <YOUR_LSP_SERVER> with each lsp server you"ve enabled.
 
require("lspconfig")["clangd"].setup {
	capabilities = capabilities
}

-- Theme
vim.cmd("syntax on")
vim.opt.termguicolors = true
vim.cmd("colorscheme Nordfox")
vim.cmd("set tabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set expandtab")

-- Git
vim.g.fugitive_git_executable = "C:/Program Files/Git/bin/git.exe"

-- Clipboard
vim.opt.clipboard = "unnamedplus"

--Keymaps
require("keymaps")
