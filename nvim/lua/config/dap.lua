local M = {}

function M.setup()
	--DAP Config
	require("dapui").setup()
	require("nvim-dap-virtual-text").setup()

	vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "LspDiagnosticsSignError", linehl = "", numhl = "" })
	vim.fn.sign_define(
		"DapStopped",
		{
			text = "▶️",
			texthl = "LspDiagnosticsSignInformation",
			linehl = "DiagnosticUnderlineInfo",
			numhl = "LspDiagnosticsSignInformation",
		}
	)
	vim.fn.sign_define(
		"DapBreakpointRejected",
		{ text = "🚫", texthl = "LspDiagnosticsSignHint", linehl = "", numhl = "" }
	)

	vim.g.dap_virtual_text = true

	--Debug
	local dap = require("dap")

	-- C, C++ DAP
	dap.adapters.gdb = {
		type = "executable",
		command = "gdb",
		args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
	}
	dap.adapters.cppdbg = {
		id = "cppdbg",
		type = "executable",
		command = os.getenv("HOME") .. "/cpptools/debugAdapters/bin/OpenDebugAD7",
		options = {
			detached = false,
		},
	}
	dap.configurations.cpp = {
		{
			id = "Launch",
			name = "C/C++ Launch file",
			type = "gdb",
			request = "launch",
			program = "${fileDirname}/${fileBasenameNoExtension}",
			cwd = "${fileDirname}",
			stopAtBeginningOfMainSubprogram = false,
		},
	}
	dap.configurations.c = dap.configurations.cpp

	-- Python DAP
	require("dap-python").setup("python")
	
	-- Ruby DAP
	dap.adapters.ruby = function(callback, config)
		callback({
			type = "server",
			host = "127.0.0.1",
			port = 34576,
			executable = {
				command = "rdbg",
				args = {
					"--open",
					"--port",
					"34576",
					"-c",
					"--",
					config.command,
					config.script,
					"<",
					config.input_file,
				},
			},
		})
	end
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Ruby debug current file",
			request = "attach",
			localfs = true,
			command = "ruby",
			script = "${file}",
			input_file = "${fileDirname}/ruby_input.txt",
		},
	}

	-- Keymaps
	vim.api.nvim_create_user_command("DapToggle", function()
		require("dapui").toggle()
	end, {}) -- Toggle DAP UI manually with :DapToggle
	vim.api.nvim_set_keymap("n", "<F5>", ':lua require("dap").continue()<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<F10>", ':lua require("dap").step_over()<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<F11>", ':lua require("dap").step_into()<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap("n", "<F12>", ':lua require("dap").step_out()<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap(
		"n",
		"<F9>",
		':lua require("dap").toggle_breakpoint()<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader><F9>",
		':lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>',
		{ silent = true }
	)

	-- Quick compile comands for preconfigured languages
	-- Currently supports C and C++
	local compile_commands = function(filetype)
		if filetype =="c" then
			return "gcc -g -o %:r %"
		elseif filetype == "cpp" then
			return "g++ -g -o %:r %"
		end
		return "echo 'No compile command for " .. filetype .. "'"
	end
	vim.api.nvim_create_user_command("Compile", function()
		vim.cmd("w")
		vim.cmd("!" .. compile_commands(vim.bo.filetype))
		-- Notiufy when compilation succeeds
		if vim.v.shell_error == 0 then
			print("Compilation succeeded: " .. vim.fn.expand("%:r"))
		else
			print("Compilation failed")
		end
	end, {})
end

return M
