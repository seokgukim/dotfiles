-- mLua LSP Setup
-- Consolidates all mLua configuration and management

local M = {}

-- Load submodules
local lsp = require("mlua.lsp")
local debug = require("mlua.debug")

-- Setup function to be called from init.lua
function M.setup()
	-- Get capabilities from nvim-cmp for LSP
	local capabilities = require("cmp_nvim_lsp").default_capabilities()

	-- Setup mlua LSP with proper configuration
	lsp.setup({
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			-- Enable completion triggered by <c-x><c-o>
			vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

			-- Enable inlay hints if supported
			if client.server_capabilities.inlayHintProvider then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			-- Keymaps
			local opts = { buffer = bufnr, noremap = true, silent = true }
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
			vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
			vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "<space>f", function()
				vim.lsp.buf.format({ async = true })
			end, opts)
			
			-- Toggle inlay hints
			vim.keymap.set("n", "<space>h", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
			end, opts)

			-- Enable document highlight
			if client.server_capabilities.documentHighlightProvider then
				vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
				vim.api.nvim_clear_autocmds({
					buffer = bufnr,
					group = "lsp_document_highlight",
				})
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					group = "lsp_document_highlight",
					buffer = bufnr,
					callback = vim.lsp.buf.document_highlight,
				})
				vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
					group = "lsp_document_highlight",
					buffer = bufnr,
					callback = vim.lsp.buf.clear_references,
				})
			end

			vim.notify("mLua LSP attached to buffer " .. bufnr, vim.log.levels.INFO)
		end,
		settings = {
			mlua = {
				completion = {
					commitCharacterSupport = true,
				},
			},
		},
	})
end

-- Export submodule functions for direct access if needed
M.debug = debug
M.lsp = lsp

return M
