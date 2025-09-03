local M = {}

function M.setup()
	-- Copilot toggle functionality
	vim.keymap.set("n", "<leader><f1>", function()
		if vim.g.copilot_enabled then
			vim.g.copilot_enabled = false
			print("Copilot disabled")
		else
			vim.g.copilot_enabled = true
			print("Copilot enabled")
		end
	end, { desc = "Toggle Copilot" })

	-- Disable copilot by default
	vim.g.copilot_enabled = false
end

return M
