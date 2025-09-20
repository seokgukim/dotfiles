local M = {}

function M.setup()
	require("conform").setup({
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "black" },
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
		},

		format_on_save = {
			lsp_fallback = true,
			timeout_ms = 1000,
		},
	})
end

return M
