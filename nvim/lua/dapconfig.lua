local M = {}

function M.setup()
	--Debug
	local dap = require("dap")
	dap.adapters.cppdbg = {
		id = "cppdbg",
		type = "executable",
		command = "/home/seokgukim/cpptools/debugAdapters/bin/OpenDebugAD7",
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
			MIDebuggerPath = "/usr/bin/gdb",
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
