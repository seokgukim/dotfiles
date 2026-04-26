local M = {}

function M.setup()
	-- Tree-sitter is the single highlighting path; regex `syntax on` is not
	-- enabled. Filetypes without an installed parser remain unhighlighted.
	vim.cmd("colorscheme nordfox")
end

return M
