local M = {}

function M.setup()
	local cmp = require("cmp")
	local cmp_nvim_lsp = require("cmp_nvim_lsp")

	-- Get default capabilities and enhance them
	local capabilities = cmp_nvim_lsp.default_capabilities()
	
	-- Enable semantic tokens
	capabilities.textDocument.semanticTokens = {
		dynamicRegistration = false,
		requests = {
			range = true,
			full = {
				delta = true
			}
		},
		tokenTypes = {
			"namespace", "type", "class", "enum", "interface", "struct",
			"typeParameter", "parameter", "variable", "property", "enumMember",
			"event", "function", "method", "macro", "keyword", "modifier",
			"comment", "string", "number", "regexp", "operator"
		},
		tokenModifiers = {
			"declaration", "definition", "readonly", "static", "deprecated",
			"abstract", "async", "modification", "documentation", "defaultLibrary"
		},
		formats = { "relative" }
	}

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
		}, {
			{ name = "buffer" },
		}),
	})

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

	-- Set configuration for specific filetype.
	cmp.setup.filetype("gitcommit", {
		sources = cmp.config.sources({
			{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
		}, {
			{ name = "buffer" },
		}),
	})

	-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won"t work anymore).
	cmp.setup.cmdline({ "/", "?" }, {
		mapping = cmp.mapping.preset.cmdline(),
		sources = {
			{ name = "buffer" },
		},
	})

	-- Use cmdline & path source for ":" (if you enabled `native_menu`, this won"t work anymore).
	cmp.setup.cmdline(":", {
		mapping = cmp.mapping.preset.cmdline(),
		sources = cmp.config.sources({
			{ 
				name = "path",
			 	option = {
					get_cwd = function(params)
    		      		-- Trigger path completion for cp and mv commands
        				local cmdline = params.context.cursor_before_line
          				if cmdline:match('^%s*CP%s') or cmdline:match('^%s*MV%s') then
            				return vim.fn.getcwd()
          				end
          				return vim.fn.getcwd()
        			end
				},
			},
			{ name = "cmdline" },
		}),
	})

    -- vim.lsp.enable("clangd")
    vim.lsp.enable("pyright")
    -- vim.lsp.enable("ruby_lsp")
    -- vim.lsp.enable("lua_ls")
end

return M
