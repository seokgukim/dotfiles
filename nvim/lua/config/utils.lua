local M = {}

function M.setup()
    local is_windows = vim.fn.has("win32") == 1

	-- Git
    if is_windows then
	    vim.g.fugitive_git_executable = "git.exe"
    else
	    vim.g.fugitive_git_executable = "/usr/bin/git"
    end

	-- Clipboard
	vim.opt.clipboard = "unnamedplus"
end

return M
