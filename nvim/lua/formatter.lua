local M = {}

function M.setup()
    require("conform").setup({
        format_on_save = {
            lsp_fallback = true,
            timeout_ms = 1000,
        },
    })
end

return M
