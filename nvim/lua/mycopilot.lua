local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>cp", function()
    vim.cmd("Copilot panel")
  end, { desc = "Open Copilot Panel", silent = true })
  vim.keymap.set("i", "<C-l>", "<Plug>(copilot-next)", { desc = "Next Copilot Suggestion", noremap = true })
  vim.keymap.set("i", "<C-h>", "<Plug>(copilot-previous)", { desc = "Previous Copilot Suggestion", noremap = true })
  vim.keymap.set("i", "<leader><Tab>", "<Plug>(copilot-accept)", { desc = "Accept Copilot Suggestion", noremap = true })
end

return M
