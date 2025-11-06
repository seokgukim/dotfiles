" mLua filetype plugin
" Language: mLua
" Maintainer: auto-generated

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Use Lua indentation and settings
setlocal expandtab
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal tabstop=4
setlocal commentstring=--\ %s

let b:undo_ftplugin = "setl et< sw< sts< ts< cms<"

if exists("loaded_matchit")
  let b:match_ignorecase = 0
  let b:match_words =
    \ '\<\%(do\|function\|if\|script\|method\|handler\|operator\|constructor\)\>:' .
    \ '\<\%(return\|else\|elseif\)\>:' .
    \ '\<end\>,' .
    \ '\<repeat\>:\<until\>,' .
    \ '\%(--\)\=\[\(=*\)\[:]\1]'
  let b:undo_ftplugin .= " | unlet! b:match_words b:match_ignorecase"
endif

" Enable semantic tokens for syntax highlighting
lua << EOF
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Enable semantic token highlighting when LSP attaches
  vim.api.nvim_create_autocmd("LspAttach", {
    buffer = bufnr,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "mlua" then
        if client.server_capabilities.semanticTokensProvider then
          vim.lsp.semantic_tokens.start(bufnr, client.id)
        end
      end
    end,
  })
EOF

" b:undo_ftplugin already initialized above
