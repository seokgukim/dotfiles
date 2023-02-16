local M = {}

function M.setup()
	local dap = require('dap')
	dap.adapters.lldb = {
		type = 'executable',
		command = 'C:/Program Files/LLVM/bin/lldb-vscode',
		name = "lldb"
	}

	dap.configurations.cpp = {
		{
			name = "Launch",
			type = "lldb",
			request = "launch",
			program = "C:/tools/neovim/nvim-win64/bin/Debug/Debug/Problem.exe",
			cwd = '${workspaceFolder}',
			stopOnEntry = false,
			args = {},
			runInTerminal = false,
			preLaunchTask = "build program",
		}
	}

	dap.configurations.shell = {
	  {
		name = "build program",
		type = "shell",
		command = "nvim --headless -c 'cd ${workspaceFolder}' -c 'CMakeBuild' -c 'qa'",
		problemMatcher = {},
		group = {
		  kind = "build",
		  isDefault = true
		}
	  }
	}
	
	dap.adapters.python = {
	  type = 'executable',
	  command = 'python',
	  args = { '-m', 'debugpy.adapter' },
	}
	dap.configurations.python = {
	  {
		type = 'python',
		request = 'launch',
		name = 'Launch file',
		program = '${file}',
		pythonPath = 'C:/Users/rokja/AppData/Local/Programs/Python/Python311/python.exe',
	  }
	}
end

return M
