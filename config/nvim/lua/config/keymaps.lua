local function parse_delimited_text(text, delimiter)
	local rows = {}
	local current_row = {}
	local current_field = ""
	local in_quotes = false
	local i = 1
	local len = #text

	while i <= len do
		local c = text:sub(i, i)
		local next_c = text:sub(i + 1, i + 1)

		if in_quotes then
			if c == '"' then
				if next_c == '"' then
					current_field = current_field .. '"'
					i = i + 2
				else
					in_quotes = false
					i = i + 1
				end
			else
				current_field = current_field .. c
				i = i + 1
			end
		else
			if c == '"' then
				local is_only_whitespace = current_field:match("^%s*$") ~= nil
				if is_only_whitespace then
					current_field = ""
					in_quotes = true
					i = i + 1
				else
					current_field = current_field .. c
					i = i + 1
				end
			elseif c == delimiter then
				table.insert(current_row, current_field)
				current_field = ""
				i = i + 1
			elseif c == "\n" or c == "\r" then
				table.insert(current_row, current_field)
				table.insert(rows, current_row)
				current_row = {}
				current_field = ""
				if c == "\r" and next_c == "\n" then
					i = i + 2
				else
					i = i + 1
				end
			else
				current_field = current_field .. c
				i = i + 1
			end
		end
	end
	if #current_row > 0 or current_field ~= "" then
		table.insert(current_row, current_field)
		table.insert(rows, current_row)
	end
	return rows
end

local function parse_csv_text(text)
	return parse_delimited_text(text, ",")
end

local function parse_tsv_text(text)
	return parse_delimited_text(text, "\t")
end

local function format_tsv_field(field)
	if field:find('["\t\r\n]') then
		return '"' .. field:gsub('"', '""') .. '"'
	else
		return field
	end
end

local function format_csv_field(field)
	if field:find('["\n\r,]') then
		return '"' .. field:gsub('"', '""') .. '"'
	else
		return field
	end
end

local function paste_tsv_as_csv(is_visual)
	local tsv_text = vim.fn.getreg("+")
	if tsv_text == "" then
		vim.notify("Clipboard is empty!", vim.log.levels.WARN)
		return
	end

	local rows = parse_tsv_text(tsv_text)
	local csv_lines = {}
	for _, row in ipairs(rows) do
		local csv_fields = {}
		for _, field in ipairs(row) do
			table.insert(csv_fields, format_csv_field(field))
		end
		table.insert(csv_lines, table.concat(csv_fields, ","))
	end
	local csv_text = table.concat(csv_lines, "\n")

	local regtype = vim.fn.getregtype("+")
	local original_reg = vim.fn.getreg("z")
	local original_regtype = vim.fn.getregtype("z")

	vim.fn.setreg("z", csv_text, regtype)
	if is_visual then
		vim.cmd('normal! gv"zp')
	else
		vim.cmd('normal! "zp')
	end

	vim.fn.setreg("z", original_reg, original_regtype)
	vim.notify("Pasted clipboard as CSV (" .. #csv_lines .. " rows)", vim.log.levels.INFO)
end

local M = {}

function M.setup()
	-- Clipboard: rely on `vim.opt.clipboard = "unnamedplus"` set in options.lua
	-- so that p / y / d already use the system clipboard. No extra leader maps.

	-- Buffers
	-- vim.api.nvim_set_keymap("n", "<leader>bd", ":bd<CR>", { noremap = true, silent = true })
	-- vim.api.nvim_set_keymap("n", "<leader>bn", ":bnext<CR>", { noremap = true, silent = true })
	-- vim.api.nvim_set_keymap("n", "<leader>bp", ":bprevious<CR>", { noremap = true, silent = true })
	-- vim.api.nvim_set_keymap("n", "<leader>bl", ":buffers<CR>:b ", { noremap = true, silent = true })
	-- for i = 1, 9 do
	-- 	vim.api.nvim_set_keymap("n", "<leader>b" .. i, ":buffer " .. i .. "<CR>", { noremap = true, silent = true })
	-- end

	-- Snacks Pickers (Replacing Telescope)
	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { desc = desc })
	end

	map("n", "<leader>ff", function() Snacks.picker.files() end, "Find Files")
	map("n", "<leader>/", function() Snacks.picker.grep() end, "Live Grep")
	map("n", "<leader>fb", function() Snacks.picker.buffers() end, "Buffers")
	map("n", "<leader>fh", function() Snacks.picker.help() end, "Help Tags")
	map("n", "<leader>fr", function() Snacks.picker.recent() end, "Recent Files")
	map("n", "<leader>fp", function() Snacks.picker.projects() end, "Projects")

	-- Add buffer-local maps only for advertised LSP methods. Some servers
	-- register capabilities after the initial LspAttach.
	local lsp_maps = {
		{ "n", "gd", "textDocument/definition", vim.lsp.buf.definition, "LSP Definition" },
		{ "n", "gD", "textDocument/declaration", vim.lsp.buf.declaration, "LSP Declaration" },
		{ "n", "gi", "textDocument/implementation", vim.lsp.buf.implementation, "LSP Implementation" },
		{ "n", "gr", "textDocument/references", vim.lsp.buf.references, "LSP References" },
		{ "n", "<leader>lw", "workspace/symbol", vim.lsp.buf.workspace_symbol, "LSP Workspace Symbols" },
		{ "n", "<leader>rn", "textDocument/rename", vim.lsp.buf.rename, "LSP Rename" },
		{ { "n", "x" }, "<leader>ca", "textDocument/codeAction", vim.lsp.buf.code_action, "LSP Code Action" },
		{
			"n",
			"<leader>lf",
			"textDocument/formatting",
			function() vim.lsp.buf.format({ async = true }) end,
			"LSP Format",
		},
		{
			"n",
			"<leader>lI",
			"textDocument/inlayHint",
			function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
			end,
			"Toggle LSP Inlay Hints",
		},
		{
			"n",
			"<leader>lc",
			"textDocument/codeLens",
			vim.lsp.codelens.run,
			"Run LSP Code Lens",
		},
		{
			"n",
			"<leader>lC",
			"textDocument/codeLens",
			function() vim.lsp.codelens.refresh({ bufnr = 0 }) end,
			"Refresh LSP Code Lens",
		},
		{ "n", "<leader>lci", "textDocument/prepareCallHierarchy", vim.lsp.buf.incoming_calls, "Incoming Calls" },
		{ "n", "<leader>lco", "textDocument/prepareCallHierarchy", vim.lsp.buf.outgoing_calls, "Outgoing Calls" },
		{
			"n",
			"<leader>lts",
			"textDocument/prepareTypeHierarchy",
			function() vim.lsp.buf.typehierarchy("supertypes") end,
			"LSP Supertypes",
		},
		{
			"n",
			"<leader>ltt",
			"textDocument/prepareTypeHierarchy",
			function() vim.lsp.buf.typehierarchy("subtypes") end,
			"LSP Subtypes",
		},
		{ "n", "<leader>lH", "textDocument/documentHighlight", vim.lsp.buf.document_highlight, "LSP Document Highlight" },
		{ "n", "<leader>lX", "textDocument/documentHighlight", vim.lsp.buf.clear_references, "Clear LSP Highlights" },
		{ "n", "<leader>le", "", vim.diagnostic.open_float, "Line Diagnostics" },
		{ "n", "<leader>lp", "", vim.diagnostic.goto_prev, "Previous Diagnostic" },
		{ "n", "<leader>ln", "", vim.diagnostic.goto_next, "Next Diagnostic" },
		{ "n", "<leader>lq", "", function() vim.diagnostic.setloclist({ open = true }) end, "Diagnostics List" },
	}

	local function attach_lsp_keymaps(client, bufnr)
		for _, entry in ipairs(lsp_maps) do
			local mode, lhs, method, rhs, desc = unpack(entry)
			if method == "" or client:supports_method(method, bufnr) then
				vim.keymap.set(mode, lhs, function()
					rhs()
				end, { buffer = bufnr, desc = desc })
			end
		end
	end

	local lsp_group = vim.api.nvim_create_augroup("dotfiles_lsp_keymaps", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = lsp_group,
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client then
				attach_lsp_keymaps(client, args.buf)
			end
		end,
	})

	local register_capability = vim.lsp.handlers["client/registerCapability"]
	vim.lsp.handlers["client/registerCapability"] = function(err, result, ctx)
		local response = register_capability(err, result, ctx)
		local client = ctx and vim.lsp.get_client_by_id(ctx.client_id)
		if client then
			for bufnr in pairs(client.attached_buffers) do
				attach_lsp_keymaps(client, bufnr)
			end
		end
		return response
	end

	-- Snacks UI surfaces
	map("n", "<leader>e", function() Snacks.explorer() end, "File Explorer")
	map("n", "<leader>tt", function() Snacks.terminal() end, "Toggle Terminal")
	map("n", "<leader>z", function() Snacks.zen() end, "Zen Mode")
	map("n", "<leader>.", function() Snacks.scratch() end, "Toggle Scratch Buffer")

	-- Snacks toggles. `Snacks.toggle.diagnostics():map(lhs)` is the
	-- idiomatic form and exposes status metadata to which-key /
	-- statuscolumn integrations.
	-- For Tree-sitter we wrap a custom toggle so the language argument
	-- from `options.lang_map` is honoured on restart (the built-in
	-- `Snacks.toggle.treesitter()` calls `vim.treesitter.start()` without
	-- arguments and would silently fail to reattach `sh` / `help` /
	-- `typescriptreact` buffers).
	if Snacks and Snacks.toggle then
		local options = require("config.options")
		Snacks.toggle.new({
			id = "treesitter",
			name = "Treesitter",
			get = function()
				return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
			end,
			set = function(state)
				local buf = vim.api.nvim_get_current_buf()
				if state then
					local ft = vim.bo[buf].filetype
					pcall(vim.treesitter.start, buf, options.lang_map[ft] or ft)
				else
					pcall(vim.treesitter.stop, buf)
				end
			end,
		}):map("<leader>ut")
		Snacks.toggle.diagnostics():map("<leader>ud")
	end

	-- Other Snacks utilities
	map("n", "<leader>un", function() Snacks.notifier.show_history() end, "Notification History")
	map("n", "<leader>bd", function() Snacks.bufdelete() end, "Delete Buffer")

	-- Git
	map("n", "<leader>gg", function() Snacks.lazygit() end, "Lazygit")
	map("n", "<leader>gB", function() Snacks.gitbrowse() end, "Git Browse")
	map("n", "]h", function() require("gitsigns").nav_hunk("next") end, "Next Hunk")
	map("n", "[h", function() require("gitsigns").nav_hunk("prev") end, "Prev Hunk")
	map("n", "<leader>gp", function() require("gitsigns").preview_hunk() end, "Preview Hunk")

	-- Copy CSV selection as TSV to clipboard
	vim.api.nvim_create_user_command("CsvToTsvCopy", function(opts)
		local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
		local text = table.concat(lines, "\n")
		local rows = parse_csv_text(text)
		local tsv_lines = {}
		for _, row in ipairs(rows) do
			local tsv_fields = {}
			for _, field in ipairs(row) do
				table.insert(tsv_fields, format_tsv_field(field))
			end
			table.insert(tsv_lines, table.concat(tsv_fields, "\t"))
		end
		local tsv_text = table.concat(tsv_lines, "\n")
		vim.fn.setreg("+", tsv_text)
		vim.fn.setreg('"', tsv_text)
		vim.notify("Copied " .. #tsv_lines .. " rows as TSV to clipboard!", vim.log.levels.INFO)
	end, { range = true, desc = "Copy CSV selection as TSV to clipboard" })

	-- Visual or normal mode mapping: CSV Yank (cy)
	map("n", "<leader>cy", "<cmd>CsvToTsvCopy<cr>", "Copy CSV as TSV to clipboard")
	map("x", "<leader>cy", ":CsvToTsvCopy<cr>", "Copy CSV as TSV to clipboard")

	-- Paste TSV selection as CSV
	vim.api.nvim_create_user_command("TsvToCsvPaste", function()
		paste_tsv_as_csv(false)
	end, { desc = "Paste TSV clipboard as CSV" })

	-- Visual or normal mode mapping: TSV Paste (cp)
	map("n", "<leader>cp", function() paste_tsv_as_csv(false) end, "Paste TSV from clipboard as CSV")
	map("x", "<leader>cp", function() paste_tsv_as_csv(true) end, "Paste TSV from clipboard as CSV")
end

return M
