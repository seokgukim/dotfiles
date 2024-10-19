-- Font
local fontsize = 12
function adjust_fontsize(amount)
  fontsize = fontsize + amount
  if fontsize < 6 then
    fontsize = 6
  elseif fontsize > 30 then
    fontsize = 30;
  end
  vim.cmd('set guifont=0xProto\\ Nerd\\ Font:h' .. fontsize)
end
vim.cmd('set guifont=0xProto\\ Nerd\\ Font:h12')
vim.api.nvim_set_keymap('n', '<C-=>', ':lua adjust_fontsize(1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-->', ':lua adjust_fontsize(-1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-=>', '<Esc>:lua adjust_fontsize(1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-->', '<Esc>:lua adjust_fontsize(-1)<CR>', { noremap = true, silent = true })

-- DAP
vim.api.nvim_set_keymap('n', '<leader>b', ':w<CR> :!g++ -g -o %:r.exe %<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F2>', ':lua require("dapui").toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F5>', ':lua require("dap").continue()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', ':lua require("dap").step_over()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', ':lua require("dap").step_into()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', ':lua require("dap").step_out()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F9>', ':lua require("dap").toggle_breakpoint()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader><F9>', ':lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', {silent = true})
