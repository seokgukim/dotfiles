local M = {}

-- Servers we manage. Each name corresponds to a file in `lsp/<name>.lua`
-- which Neovim 0.12 auto-merges into `vim.lsp.config()`. The second value
-- is the executable to probe before enabling.
local servers = {
	bashls = "bash-language-server",
	clangd = "clangd",
	cssls = "vscode-css-language-server",
	html = "vscode-html-language-server",
	jsonls = "vscode-json-language-server",
	lua_ls = "lua-language-server",
	nil_ls = "nil",
	pyright = "pyright-langserver",
	ruby_lsp = "ruby-lsp",
	ts_ls = "typescript-language-server",
}

function M.setup()
	-- Build capabilities from the protocol baseline, then deep-merge
	-- cmp_nvim_lsp's additions and our semanticTokens override.
	-- Note: `cmp_nvim_lsp.default_capabilities(override)` reads `override`
	-- as a flat option table, not a capabilities tree, so we merge with
	-- `vim.tbl_deep_extend` instead of passing `base` as an argument.
	local capabilities = vim.tbl_deep_extend(
		"force",
		vim.lsp.protocol.make_client_capabilities(),
		require("cmp_nvim_lsp").default_capabilities(),
		{
		textDocument = {
			semanticTokens = {
				dynamicRegistration = false,
				requests = {
					range = true,
					full = { delta = true },
				},
				tokenTypes = {
					"namespace", "type", "class", "enum", "interface", "struct",
					"typeParameter", "parameter", "variable", "property", "enumMember",
					"event", "function", "method", "macro", "keyword", "modifier",
					"comment", "string", "number", "regexp", "operator",
				},
				tokenModifiers = {
					"declaration", "definition", "readonly", "static", "deprecated",
					"abstract", "async", "modification", "documentation", "defaultLibrary",
				},
				formats = { "relative" },
			},
		},
		}
	)

	vim.lsp.config("*", { capabilities = capabilities })

	-- Diagnostic UI
	vim.diagnostic.config({
		virtual_text = {
			spacing = 4,
			source = "if_many",
			prefix = "●",
		},
		signs = true,
		update_in_insert = false,
		underline = true,
		severity_sort = true,
		float = {
			border = "rounded",
			source = "always",
			header = "",
			prefix = "",
		},
	})

	-- Enable each server only if its executable is available.
	for name, exe in pairs(servers) do
		if vim.fn.executable(exe) == 1 then
			vim.lsp.enable(name)
		end
	end
end

return M
