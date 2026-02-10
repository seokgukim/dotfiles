local M = {}

function M.setup()
    local is_windows = vim.fn.has("win32") == 1

	--TreeSitter
	require("nvim-treesitter.install").prefer_git = false
	require("nvim-treesitter.install").compilers = is_windows and { "clang", "gcc", "cl" } or { "clang", "gcc" }
	require("nvim-treesitter.configs").setup({
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
	})

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
