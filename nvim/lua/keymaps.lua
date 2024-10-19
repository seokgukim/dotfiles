local M = {}

function M.setup()
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
end

return M
