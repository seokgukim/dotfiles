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
	vim.api.nvim_set_keymap("n", "<leader>bd", ":bd<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<leader>bn", ":bnext<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<leader>bp", ":bprevious<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<leader>bl", ":buffers<CR>:b ", { noremap = true, silent = true })
	for i = 1, 9 do
		vim.api.nvim_set_keymap("n", "<leader>b" .. i, ":buffer " .. i .. "<CR>", { noremap = true, silent = true })
	end
end

return M
