local M = {}

function M.setup()
	-- Font
	local fontsize = 12
	function adjust_fontsize(amount)
		fontsize = fontsize + amount
		if fontsize < 6 then
			fontsize = 6
		elseif fontsize > 30 then
			fontsize = 30
		end
		vim.cmd("set guifont=vim.o.guifont:h" .. fontsize)
	end
	vim.api.nvim_set_keymap("n", "<C-=>", ":lua adjust_fontsize(1)<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<C-->", ":lua adjust_fontsize(-1)<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("i", "<C-=>", "<Esc>:lua adjust_fontsize(1)<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("i", "<C-->", "<Esc>:lua adjust_fontsize(-1)<CR>", { noremap = true, silent = true })

	-- Clipboard
	vim.api.nvim_set_keymap("n", "<leader>y", '"+y', { noremap = true, silent = true })
	vim.api.nvim_set_keymap("v", "<leader>y", '"+y', { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<leader>p", '"+p', { noremap = true, silent = true })
	vim.api.nvim_set_keymap("v", "<leader>p", '"+p', { noremap = true, silent = true })

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
	
	-- LSP via Snacks
	map("n", "<leader>gd", function() Snacks.picker.lsp_definitions() end, "Goto Definition")
	map("n", "<leader>gr", function() Snacks.picker.lsp_references() end, "References")
	map("n", "<leader>gi", function() Snacks.picker.lsp_implementations() end, "Implementation")
	map("n", "<leader>gs", function() Snacks.picker.lsp_symbols() end, "LSP Symbols")

	-- Other Snacks utilities
	map("n", "<leader>un", function() Snacks.notifier.show_history() end, "Notification History")
	map("n", "<leader>bd", function() Snacks.bufdelete() end, "Delete Buffer")
	map("n", "<leader>gg", function() Snacks.lazygit() end, "Lazygit")
end

return M
