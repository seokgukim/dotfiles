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
	vim.g.fugitive_git_executable = "git.exe"

	-- Clipboard
	vim.opt.clipboard = "unnamedplus"
	
	-- cp and mv commands for Neovim on Windows
	local function ensure_dir(path)
	local dir = vim.fn.fnamemodify(path, ':h')
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, 'p')
		end
	end

	local function cp_command(args)
		local src = args.fargs[1]
		local dest = args.fargs[2]
		
		if not src then
			vim.notify("Usage: :CP <source> [<destination>]", vim.log.levels.ERROR)
			return
		end
		
		src = vim.fn.expand(src)
		
		if not dest then
			-- Copy in same directory with _copy suffix
			local dir = vim.fn.fnamemodify(src, ':h')
			local basename = vim.fn.fnamemodify(src, ':t:r')
			local ext = vim.fn.fnamemodify(src, ':e')
			dest = dir .. '/' .. basename .. '_copy'
			if ext ~= '' then
			dest = dest .. '.' .. ext
			end
		else
			dest = vim.fn.expand(dest)
			ensure_dir(dest)
		end
		
		local result = vim.fn.system(string.format('copy "%s" "%s"', src, dest))
		if vim.v.shell_error == 0 then
			vim.notify("Copied: " .. src .. " -> " .. dest)
		else
			vim.notify("Copy failed: " .. result, vim.log.levels.ERROR)
		end
	end

	local function mv_command(args)
		local src = args.fargs[1]
		local dest = args.fargs[2]
		
		if not src or not dest then
			vim.notify("Usage: :mv <source> <destination>", vim.log.levels.ERROR)
			return
		end
		
		src = vim.fn.expand(src)
		dest = vim.fn.expand(dest)
		
		-- Check if source is the current buffer
		local current_file = vim.fn.expand('%:p')
		local is_current_buffer = (src == current_file)
		
		ensure_dir(dest)
		
		local result = vim.fn.system(string.format('move "%s" "%s"', src, dest))
		if vim.v.shell_error == 0 then
			-- If we moved the current buffer, update it
			if is_current_buffer then
			vim.cmd('saveas! ' .. vim.fn.fnameescape(dest))
			vim.fn.delete(src)
			end
			vim.notify("Moved: " .. src .. " -> " .. dest)
		else
			vim.notify("Move failed: " .. result, vim.log.levels.ERROR)
		end
	end

	vim.api.nvim_create_user_command('CP', cp_command, { nargs = '+' })
	vim.api.nvim_create_user_command('MV', mv_command, { nargs = '+' })

end

return M
