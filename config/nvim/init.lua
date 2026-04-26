local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require("plugins"), {
	checker = { enabled = false },
})

require("config.options").setup()
require("config.theme").setup()
require("config.statusline").setup()
require("config.completion").setup()
require("config.lsp").setup()
require("config.formatter").setup()
require("config.keymaps").setup()

-- DAP is intentionally left disabled.
-- require("config.dap").setup()
