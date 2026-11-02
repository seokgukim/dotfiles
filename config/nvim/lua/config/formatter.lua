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
			cs = { "dotnet_format_whitespace" },
			ruby = { "rubocop" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			nix = { "nixpkgs_fmt" },
		},

		formatters = {
			-- Honors .editorconfig (csharp_preserve_single_line_* etc.), unlike csharpier.
			-- Runs on conform's temp copy beside the file so the nearest .editorconfig applies.
			dotnet_format_whitespace = {
				command = "dotnet",
				stdin = false,
				args = function(_, ctx)
					return {
						"format",
						"whitespace",
						"--folder",
						ctx.dirname,
						"--include",
						vim.fs.basename(ctx.filename),
					}
				end,
			},
		},

		format_on_save = {
			lsp_format = "fallback",
			timeout_ms = 30000,
		},
	})
end

return M
