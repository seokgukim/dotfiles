-- NvimTree
vim.api.nvim_set_keymap('n', '<Tab>', ':NvimTreeToggle<CR>', {silent = true})
vim.api.nvim_set_keymap('n', '<C-tab>', ':NvimTreeFocus<CR>', {silent = true})

-- Font
local fontsize = 12
function adjust_fontsize(amount)
  fontsize = fontsize + amount
  if fontsize < 6 then
    fontsize = 6
  end
  vim.cmd('set guifont=Anonymice\\ NF:h' .. fontsize)
end
vim.cmd('set guifont=Anonymice\\ NF:h12')
vim.api.nvim_set_keymap('n', '<C-ScrollWheelUp>', ':lua adjust_fontsize(1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-ScrollWheelDown>', ':lua adjust_fontsize(-1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-ScrollWheelUp>', '<Esc>:lua adjust_fontsize(1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-ScrollWheelDown>', '<Esc>:lua adjust_fontsize(-1)<CR>', { noremap = true, silent = true })

-- CP Helper
vim.cmd('cd C:\\Users\\rokja\\ps')
vim.api.nvim_set_keymap('n', '<leader>cr', ':CompetiTestRun<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>cn', ':CompetiTestRunNE<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ca', ':CompetiTestAdd<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ce', ':CompetiTestEdit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>cd', ':CompetiTestDelete<CR>', { noremap = true, silent = true })

-- DAP
vim.api.nvim_set_keymap('n', '<leader>cp', ':!g++ -g -o %:r %<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F2>', ':lua require("dapui").toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F5>', ':lua require("dap").continue()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', ':lua require("dap").step_over()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', ':lua require("dap").step_into()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', ':lua require("dap").step_out()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F9>', ':lua require("dap").toggle_breakpoint()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader><F9>', ':lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', {silent = true})

-- ShortCuts
vim.api.nvim_set_keymap('n', '<C-s>', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-s>', '<Esc>:w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-q>', ':q<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-q>', '<Esc>:q<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-z>', ':u<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-z>', '<Esc>:u<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-y>', ':red<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-y>', '<Esc>:red<CR>', { noremap = true, silent = true })
