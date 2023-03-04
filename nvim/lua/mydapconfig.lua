local M = {}

function M.setup()
	local dap = require('dap')
	dap.adapters.codelldb = {
		type = 'server',
		port = "${port}",
		executable = {
			command = 'C:/Users/rokja/.vscode/extensions/vadimcn.vscode-lldb-1.8.1/adapter/codelldb.exe',
			args = {"--port", "${port}"},
			detached = false,
		}
	}
	dap.configurations.cpp = {
		{
			name = "Launch",
			type = "codelldb",
			request = "launch",
			program = "${fileDirname}/${fileBasenameNoExtension}.exe",
			cwd = "${fileDirname}",
			stopOnEntry = false,
		},
	}
end

return M
