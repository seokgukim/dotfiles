local M = {}

function M.setup()
	--TreeSitter
	require("nvim-treesitter.install").prefer_git = false
	require("nvim-treesitter.install").compilers = { "clang", "gcc" }
	require("nvim-treesitter.configs").setup({
		highlight = {
			enable = true,
			-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
			-- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
			-- Using this option may slow down your editor, and you may see some duplicate highlights.
			-- Instead of true it can also be a list of languages
			additional_vim_regex_highlighting = false,
		},
	})

	-- Git
	vim.g.fugitive_git_executable = "/usr/bin/git"

	-- Clipboard
	vim.opt.clipboard = "unnamedplus"
end

return M
