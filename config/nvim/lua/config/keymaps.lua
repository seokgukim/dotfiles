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

	-- LSP via Snacks (kept under <leader>l* so that <leader>g* stays Git-only).
	map("n", "<leader>ld", function() Snacks.picker.lsp_definitions() end, "Goto Definition")
	map("n", "<leader>lr", function() Snacks.picker.lsp_references() end, "References")
	map("n", "<leader>li", function() Snacks.picker.lsp_implementations() end, "Implementation")
	map("n", "<leader>ls", function() Snacks.picker.lsp_symbols() end, "LSP Symbols")

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
end

return M
