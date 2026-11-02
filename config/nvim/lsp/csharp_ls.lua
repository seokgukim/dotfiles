-- With metadata-uris, definitions into external assemblies (UnityEngine, ...)
-- come back as csharp:/ URIs; load their decompiled source via csharp/metadata.
vim.api.nvim_create_autocmd("BufReadCmd", {
	pattern = "csharp:/*",
	callback = function(args)
		local client = vim.lsp.get_clients({ name = "csharp_ls" })[1]
		if not client then
			return
		end
		local res = client:request_sync("csharp/metadata", { textDocument = { uri = args.match } }, 10000, 0)
		local source = res and res.result and res.result.source or ""
		vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, vim.split(source, "\n", { plain = true }))
		vim.bo[args.buf].filetype = "cs"
		vim.bo[args.buf].modifiable = false
		vim.bo[args.buf].modified = false
	end,
})

return {
	cmd = { "csharp-ls", "--features", "metadata-uris" },
	filetypes = { "cs" },
	-- csharp-ls dynamically registers hover/definition/rename/etc. with a
	-- documentSelector requiring language == "csharp" (the LSP-standard id),
	-- but Neovim's default get_language_id sends the 'filetype' value ("cs")
	-- as textDocument.languageId. That mismatch makes the selector never
	-- match, so those dynamically-registered methods silently never attach
	-- to the buffer even though the client itself is alive and initialized.
	get_language_id = function(_, _)
		return "csharp"
	end,
	-- Unity project root: the ancestor holding both Assets/ and ProjectSettings/.
	-- (vim.fs.find upward never descends into Packages/, so a manifest.json
	-- lookup can not work.) Prefer a solution next to it, else common markers.
	root_dir = function(bufnr, on_dir)
		local root =
			vim.fs.root(bufnr, function(_, path)
				return vim.uv.fs_stat(path .. "/ProjectSettings/ProjectVersion.txt") ~= nil
					and vim.uv.fs_stat(path .. "/Assets") ~= nil
			end)
			or vim.fs.root(bufnr, function(name)
				return name:match("%.slnx?$") ~= nil
			end)
			or vim.fs.root(bufnr, { "Directory.Build.props", "global.json", ".git" })
			or vim.fs.root(bufnr, function(name)
				return name:match("%.csproj$") ~= nil
			end)
		on_dir(root)
	end,
}
