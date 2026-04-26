local M = {}

local modes = {
	n = { "󰋜", "NORMAL" },
	no = { "󰋜", "OP-PENDING" },
	nov = { "󰋜", "OP-PENDING" },
	noV = { "󰋜", "OP-PENDING" },
	["no\22"] = { "󰋜", "OP-PENDING" },
	niI = { "󰋜", "NORMAL" },
	niR = { "󰋜", "NORMAL" },
	niV = { "󰋜", "NORMAL" },
	nt = { "󰋜", "NORMAL" },
	ntT = { "󰋜", "NORMAL" },
	i = { "󰏫", "INSERT" },
	ic = { "󰏫", "INSERT" },
	ix = { "󰏫", "INSERT" },
	v = { "󰒉", "VISUAL" },
	V = { "󰒉", "V-LINE" },
	["\22"] = { "󰒉", "V-BLOCK" },
	s = { "󰒉", "SELECT" },
	S = { "󰒉", "S-LINE" },
	["\19"] = { "󰒉", "S-BLOCK" },
	R = { "󰛔", "REPLACE" },
	Rc = { "󰛔", "REPLACE" },
	Rx = { "󰛔", "REPLACE" },
	Rv = { "󰛔", "V-REPLACE" },
	Rvc = { "󰛔", "V-REPLACE" },
	Rvx = { "󰛔", "V-REPLACE" },
	c = { "", "COMMAND" },
	cv = { "", "EX" },
	ce = { "", "EX" },
	r = { "󰑓", "PROMPT" },
	rm = { "󰑓", "MORE" },
	["r?"] = { "󰑓", "CONFIRM" },
	["!"] = { "", "SHELL" },
	t = { "", "TERM" },
}

local diagnostics = {
	{ vim.diagnostic.severity.ERROR, "DiagnosticError", "" },
	{ vim.diagnostic.severity.WARN, "DiagnosticWarn", "" },
	{ vim.diagnostic.severity.INFO, "DiagnosticInfo", "" },
	{ vim.diagnostic.severity.HINT, "DiagnosticHint", "󰌵" },
}

local git_cache = {}
local git_cache_limit = 32

local function apply_highlights()
	vim.api.nvim_set_hl(0, "DotStatusMode", { link = "ModeMsg" })
	vim.api.nvim_set_hl(0, "DotStatusFile", { link = "Directory" })
	vim.api.nvim_set_hl(0, "DotStatusGit", { link = "Special" })
	vim.api.nvim_set_hl(0, "DotStatusLsp", { link = "Identifier" })
	vim.api.nvim_set_hl(0, "DotStatusDim", { link = "Comment" })
	vim.api.nvim_set_hl(0, "DotStatusOk", { link = "DiagnosticOk" })
end

local function escape(text)
	return tostring(text):gsub("%%", "%%%%")
end

local function highlight(group, text)
	if not text or text == "" then
		return ""
	end
	return "%#" .. group .. "#" .. escape(text) .. "%#StatusLine#"
end

local function join(parts, separator)
	local filtered = {}
	for _, part in ipairs(parts) do
		if part and part ~= "" then
			table.insert(filtered, part)
		end
	end
	return table.concat(filtered, separator)
end

local function active_window()
	local winid = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(winid) then
		winid = vim.api.nvim_get_current_win()
	end
	return winid, vim.api.nvim_win_get_buf(winid)
end

local function mode_component()
	local current = vim.api.nvim_get_mode().mode
	local mode = modes[current] or modes[current:sub(1, 1)] or { "󰋜", current:upper() }
	return highlight("DotStatusMode", " " .. mode[1] .. " " .. mode[2] .. " ")
end

local function file_icon(path, filetype)
	if path ~= "" then
		local filename = vim.fn.fnamemodify(path, ":t")
		local extension = vim.fn.fnamemodify(filename, ":e")
		local ok, devicons = pcall(require, "nvim-web-devicons")
		if ok then
			local icon = devicons.get_icon(filename, extension, { default = true })
			if icon then
				return icon
			end
		end
	end

	local fallback = {
		bigfile = "󰈙",
		help = "󰋖",
		terminal = "",
	}
	return fallback[filetype] or "󰈙"
end

local function file_component(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local filetype = vim.bo[bufnr].filetype
	local icon = file_icon(path, filetype)
	local name = path == "" and "[No Name]" or vim.fn.fnamemodify(path, ":.")
	local flags = join({
		vim.bo[bufnr].modified and "●" or "",
		vim.bo[bufnr].readonly and "" or "",
	}, " ")

	return join({
		highlight("DotStatusFile", icon .. " " .. name),
		highlight("DotStatusDim", flags),
	}, " ")
end

local function git_root(path)
	if path == "" then
		return nil
	end

	local dir = vim.fn.fnamemodify(path, ":p:h")
	local marker = vim.fs.find(".git", { path = dir, upward = true })[1]
	if not marker then
		return nil
	end
	return vim.fs.dirname(marker)
end

local function read_git_branch(root)
	if vim.fn.executable("git") == 0 then
		return ""
	end

	local branch = vim.fn.systemlist({ "git", "-C", root, "branch", "--show-current" })
	if vim.v.shell_error == 0 and branch[1] and branch[1] ~= "" then
		return branch[1]
	end

	local sha = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--short", "HEAD" })
	if vim.v.shell_error == 0 and sha[1] and sha[1] ~= "" then
		return "@" .. sha[1]
	end

	return ""
end

local function cache_git_branch(root)
	local now = os.time()
	local cached = git_cache[root]
	if cached and now - cached.at <= 10 then
		return cached.branch
	end

	local branch = read_git_branch(root)
	git_cache[root] = { at = now, branch = branch }

	local roots = vim.tbl_keys(git_cache)
	if #roots > git_cache_limit then
		table.sort(roots, function(a, b)
			return git_cache[a].at < git_cache[b].at
		end)
		local pruned = 0
		for _, cached_root in ipairs(roots) do
			if cached_root ~= root and pruned < #roots - git_cache_limit then
				git_cache[cached_root] = nil
				pruned = pruned + 1
			end
		end
	end

	return branch
end

local function git_component(bufnr)
	local branch = vim.b[bufnr].gitsigns_head
	if (not branch or branch == "") and vim.fn.exists("*FugitiveHead") == 1 then
		branch = vim.fn.FugitiveHead()
	end
	if not branch or branch == "" then
		local root = git_root(vim.api.nvim_buf_get_name(bufnr))
		if root then
			branch = cache_git_branch(root)
		end
	end
	if not branch or branch == "" then
		return ""
	end
	return highlight("DotStatusGit", " " .. branch)
end

local function lsp_component(bufnr)
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if vim.tbl_isempty(clients) then
		return highlight("DotStatusDim", " none")
	end

	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end
	table.sort(names)

	local label = names[1]
	if #names > 1 then
		label = label .. "+" .. (#names - 1)
	end
	return highlight("DotStatusLsp", " " .. label)
end

local function diagnostics_component(bufnr)
	local counts = vim.diagnostic.count(bufnr)
	local parts = {}
	for _, item in ipairs(diagnostics) do
		local count = counts[item[1]] or 0
		if count > 0 then
			table.insert(parts, highlight(item[2], item[3] .. " " .. count))
		end
	end

	if vim.tbl_isempty(parts) then
		return highlight("DotStatusOk", "")
	end
	return join(parts, " ")
end

local function filetype_component(bufnr)
	local filetype = vim.bo[bufnr].filetype
	if filetype == "" then
		filetype = "text"
	end
	return highlight("DotStatusDim", " " .. filetype)
end

local function position_component(winid, bufnr)
	local cursor = vim.api.nvim_win_get_cursor(winid)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local progress = line_count == 0 and 0 or math.floor((cursor[1] / line_count) * 100)
	return highlight("DotStatusDim", string.format(" %d:%d %d%% ", cursor[1], cursor[2] + 1, progress))
end

function M.render()
	local winid, bufnr = active_window()
	local left = join({
		mode_component(),
		"%<",
		file_component(bufnr),
	}, " ")
	local center = join({
		git_component(bufnr),
		lsp_component(bufnr),
	}, "  ")
	local right = join({
		diagnostics_component(bufnr),
		filetype_component(bufnr),
		position_component(winid, bufnr),
	}, "  ")

	return table.concat({ left, "%=", center, "%=", right })
end

function M.setup()
	apply_highlights()

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("dotfiles_statusline", { clear = true }),
		callback = apply_highlights,
	})

	vim.opt.statusline = "%!v:lua.require'config.statusline'.render()"
end

return M
