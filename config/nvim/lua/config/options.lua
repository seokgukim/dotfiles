local M = {}

-- Exposed so `keymaps.lua` can reuse the same parser-name translation
-- when wiring up the Tree-sitter toggle. `Snacks.toggle.treesitter()`
-- calls `vim.treesitter.start()` without a language argument and would
-- otherwise fail to restart `sh`/`help`/`*react` buffers.
M.lang_map = {
	sh = "bash",
	zsh = "bash",
	typescriptreact = "tsx",
	javascriptreact = "tsx",
	help = "vimdoc",
}

M.ts_filetypes = {
	"c", "cpp", "css", "help", "html", "javascript", "javascriptreact",
	"json", "lua", "markdown", "mlua", "nix", "python", "query", "ruby", "sh",
	"toml", "typescript", "typescriptreact", "vim", "yaml", "zsh",
}

function M.setup()
	-- Register custom filetypes and Treesitter languages ------------------
	vim.filetype.add({
		extension = {
			mlua = "mlua",
		},
	})

	if vim.treesitter.language.register then
		vim.treesitter.language.register("mlua", "mlua")
	end

	-- Editor options ------------------------------------------------------
	vim.opt.termguicolors = true
	vim.opt.tabstop = 4
	vim.opt.shiftwidth = 4
	vim.opt.smartindent = true
	vim.opt.expandtab = false
	vim.opt.wrap = false
	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.showmatch = true
	vim.opt.laststatus = 3

	-- System integration --------------------------------------------------
	vim.opt.clipboard = "unnamedplus"

	-- Plugin globals ------------------------------------------------------
	-- Use whatever `git` resolves to on PATH; works on Linux/macOS/WSL/Windows.
	vim.g.fugitive_git_executable = "git"

	-- Tree-sitter highlighting ------------------------------------------
	-- The nvim-treesitter `main` branch no longer wires `:TSEnable` style
	-- autocommands. Start the parser ourselves on a conservative whitelist
	-- of *Neovim filetypes* (not parser names) and translate to a parser
	-- language when they differ (e.g. `sh` -> `bash`, `help` -> `vimdoc`).
	-- `pcall` keeps a missing parser from breaking the buffer; `smartindent`
	-- remains the indent fallback when the parser hasn't installed yet.
	local lang_map = M.lang_map
	local ts_filetypes = M.ts_filetypes
	-- ft -> bool. Keys must be real Neovim filetypes, not parser names
	-- (`tsx` is a parser, never a filetype: TSX files report
	-- `typescriptreact`).
	local ts_indent = {
		lua = true, nix = true, python = true, c = true, cpp = true,
		javascript = true, javascriptreact = true,
		typescript = true, typescriptreact = true,
	}
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("dotfiles_treesitter", { clear = true }),
		pattern = ts_filetypes,
		callback = function(args)
			-- Snacks bigfile replaces the filetype with "bigfile"; this
			-- callback never fires for those buffers. Keep an explicit
			-- guard for the case where someone re-sets `ft` manually.
			if vim.bo[args.buf].filetype == "bigfile" then
				return
			end
			local ft = vim.bo[args.buf].filetype
			local lang = lang_map[ft]
			-- Only enable Tree-sitter indent when the parser actually
			-- attached; nvim-treesitter `main` installs parsers
			-- asynchronously and an early indentexpr call can otherwise
			-- raise E5108 before the parser is ready.
			local ok = pcall(vim.treesitter.start, args.buf, lang)
			if ok and ts_indent[ft] then
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end,
	})
end

return M
