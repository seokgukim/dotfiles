local M = {}

function M.setup()
	require("conform").setup({
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettier" },
			typescript = { "prettier" },
			html = { "prettier" },
			css = { "prettier" },
			json = { "prettier" },
			markdown = { "prettier" },
			yaml = { "prettier" },
			cpp = { "clang_format" },
			c = { "clang_format" },
			ruby = { "rubocop" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			nix = { "nixpkgs_fmt" },
		},

		format_on_save = {
			lsp_format = "fallback",
			timeout_ms = 1000,
		},
	})
end

return M
