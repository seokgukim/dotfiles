local is_windows = vim.fn.has("win32") == 1

return {
	-- Theme
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 900,
	},

	-- Icons used by Snacks picker and other UI integrations.
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},

	-- Editing helpers without overlap with Snacks.
	{
		"mattn/emmet-vim",
		ft = { "css", "eruby", "html", "javascriptreact", "less", "sass", "scss", "typescriptreact", "vue" },
	},

	-- Git commands remain useful alongside Snacks.lazygit().
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git", "Gdiffsplit", "Gread", "Gwrite" },
	},

	-- Git signs in the signcolumn for changed lines/hunks
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPre",
		config = function()
			require("gitsigns").setup({})
		end,
	},


	-- Tree-sitter (nvim-treesitter `main` branch).
	-- The main branch dropped the `opts`-style API: parsers are installed
	-- by `require('nvim-treesitter').install({...})` and highlighting is
	-- started per-buffer from `lua/config/options.lua`.
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local parsers = {
				"bash", "c", "cpp", "css", "html", "javascript", "json",
				"lua", "markdown", "markdown_inline", "nix", "python",
				"query", "ruby", "toml", "tsx", "typescript", "vim",
				"vimdoc", "yaml",
			}
			require("nvim-treesitter").install(parsers)
		end,
	},

	-- Snacks is the primary UI/navigation layer.
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			bufdelete = { enabled = true },
			dashboard = { enabled = true },
			explorer = { enabled = true },
			gitbrowse = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			lazygit = { enabled = true },
			notifier = { enabled = true, timeout = 3000 },
			picker = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scratch = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			terminal = { enabled = true },
			toggle = { enabled = true },
			words = { enabled = true },
			zen = { enabled = true },
		},
	},

	-- Completion: keep only sources configured in config/completion.lua.
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"dcampos/nvim-snippy",
			"dcampos/cmp-snippy",
		},
	},

	{
		"mpas/marp-nvim",
		ft = "markdown",
		cond = function()
			return vim.fn.executable("marp") == 1
		end,
	},

	"stevearc/conform.nvim",

	{
		"hat0uma/csvview.nvim",
		---@module "csvview"
		---@type CsvView.Options
		opts = {
			parser = { comments = { "#", "//" } },
			keymaps = {
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
				jump_next_row = { "<Enter>", mode = { "n", "v" } },
				jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
			},
		},
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},

	-- seokgukim-authored plugins are intentionally kept.
	{
		"seokgukim/mlua.nvim",
		branch = "dev",
		config = function()
			require("mlua").setup({
				keymaps = {
					hover = "K",
					definition = "gd",
					references = "gr",
					declaration = false,
					implementation = false,
					rename = "<leader>rn",
					code_action = "<leader>ca",
					format = "<leader>lf",
					toggle_inlay_hints = false,
				},
			})
		end,
	},
	{
		"seokgukim/mlua-debugger.nvim",
		branch = "dev",
		cond = function()
			return is_windows
		end,
		config = function()
			require("mlua-debugger").setup({
				deprecated_commands = false,
			})
		end,
	},
	{
		"seokgukim/vawi.nvim",
		cond = function()
			return is_windows
		end,
		config = function()
			require("vawi").setup()
		end,
	},

	{
		"github/copilot.vim",
		cmd = "Copilot",
		event = "InsertEnter",
		init = function()
			-- These globals must be set BEFORE the plugin sources its
			-- runtime files, otherwise copilot.vim binds <Tab> in insert
			-- mode and races with nvim-cmp.
			vim.g.copilot_enabled = false
			-- vim.g.copilot_no_tab_map = true
		end,
		config = function()
			vim.keymap.set("n", "<leader><f1>", function()
				vim.g.copilot_enabled = not vim.g.copilot_enabled
				print("Copilot " .. (vim.g.copilot_enabled and "enabled" or "disabled"))
			end, { desc = "Toggle Copilot" })
		end,
	},

	-- "ggml-org/llama.vim",

	{
		"folke/sidekick.nvim",
		dependencies = { "folke/snacks.nvim" },
		opts = {
			cli = {
				mux = {
					backend = "zellij",
					enabled = vim.fn.executable("zellij") == 1,
				},
			},
		},
		keys = {
			-- NES (`<tab>`) requires the copilot-language-server to be
			-- attached. Until that is wired up, the binding is a dead
			-- map that races with nvim-cmp; intentionally omitted here.
			{
				"<c-.>",
				function()
					require("sidekick.cli").focus()
				end,
				desc = "Sidekick Focus",
				mode = { "n", "t", "i", "x" },
			},
			{
				"<leader>aa",
				function()
					require("sidekick.cli").toggle()
				end,
				desc = "Sidekick Toggle CLI",
			},
			{
				"<leader>as",
				function()
					require("sidekick.cli").select()
				end,
				desc = "Select CLI",
			},
			{
				"<leader>ad",
				function()
					require("sidekick.cli").close()
				end,
				desc = "Detach a CLI Session",
			},
			{
				"<leader>at",
				function()
					require("sidekick.cli").send({ msg = "{this}" })
				end,
				mode = { "x", "n" },
				desc = "Send This",
			},
			{
				"<leader>af",
				function()
					require("sidekick.cli").send({ msg = "{file}" })
				end,
				desc = "Send File",
			},
			{
				"<leader>av",
				function()
					require("sidekick.cli").send({ msg = "{selection}" })
				end,
				mode = "x",
				desc = "Send Visual Selection",
			},
			{
				"<leader>ap",
				function()
					require("sidekick.cli").prompt()
				end,
				mode = { "n", "x" },
				desc = "Sidekick Select Prompt",
			},
			{
				"<leader>ac",
				function()
					require("sidekick.cli").toggle({ name = "claude", focus = true })
				end,
				desc = "Sidekick Toggle Claude",
			},
		},
	},
}
