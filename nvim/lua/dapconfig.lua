local M = {}

function M.setup()
	--Debug
	local dap = require("dap")
	dap.adapters.cppdbg = {
		id = "cppdbg",
		type = "executable",
		command = "C:/Users/rokja/.vscode/extensions/ms-vscode.cpptools-1.15.4-win32-x64/debugAdapters/bin/OpenDebugAD7.exe",
		options = {
			detached = false
		},
	}
	dap.configurations.cpp = {
		{
			id = "Launch",
			type = "cppdbg",
			request = "launch",
			program = "${fileDirname}/${fileBasenameNoExtension}.exe",
			cwd = "${fileDirname}",
			stopAtEntry = false,
			MIMode = "gdb",
			MIDebuggerPath = "C:/msys64/mingw64/bin/gdb.exe",
			setupCommands = {  
				{	 
					text = '-enable-pretty-printing',
					description =  'enable pretty printing',
					ignoreFailures = false 
				},
			},
		},
	}
end

return M
