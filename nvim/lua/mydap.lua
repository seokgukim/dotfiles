local M = {}

function M.setup()
    --DAP Config
    require("dapui").setup()
    require("nvim-dap-virtual-text").setup()

    vim.fn.sign_define("DapBreakpoint",{ text ="🔴", texthl ="LspDiagnosticsSignError", linehl ="", numhl =""})
    vim.fn.sign_define("DapStopped",{ text ="▶️", texthl ="LspDiagnosticsSignInformation", linehl ="DiagnosticUnderlineInfo", numhl ="LspDiagnosticsSignInformation"})
    vim.fn.sign_define("DapBreakpointRejected",{ text ="🚫", texthl ="LspDiagnosticsSignHint", linehl ="", numhl =""})

    vim.g.dap_virtual_text = true

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

    require("dap-python").setup("python")

    dap.adapters.ruby = function(callback, config)
        callback {
            type = "server",
            host = "127.0.0.1",
            port = 34576,
            executable = {
                command = "rdbg",
                args = {
                    "--open", "--port", "34576", "-c", "--", config.command, config.script, "<", config.input_file
                },
            },
        }
    end
    dap.configurations.ruby = {
        {
            type = "ruby",
            name = "debug current file",
            request = "attach",
            localfs = true,
            command = "ruby",
            script = "${file}",
            input_file = "${fileDirname}/ruby_input.txt",
        },
    }

    vim.api.nvim_set_keymap('n', '<leader>b', ':w<CR> :!g++ -g -o %:r.exe %<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F2>', ':lua require("dapui").toggle()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F5>', ':lua require("dap").continue()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F10>', ':lua require("dap").step_over()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F11>', ':lua require("dap").step_into()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F12>', ':lua require("dap").step_out()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F9>', ':lua require("dap").toggle_breakpoint()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader><F9>', ':lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', {silent = true})
end

return M
