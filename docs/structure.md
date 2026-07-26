# Repository Structure

```
dotfiles/
├── README.md                       # Entry point
├── LICENSE
├── .gitignore
├── config/                         # XDG_CONFIG_HOME content (symlinked into ~/.config)
│   └── nvim/                       # Neovim configuration
│       ├── init.lua                # Bootstraps lazy.nvim and loads config modules
│       ├── lsp/                    # Neovim 0.12 native LSP server config files
│       │   │                       # (discovered on runtimepath; merged by
│       │   │                       # vim.lsp.config when enabled via
│       │   │                       # vim.lsp.enable(...))
│       │   ├── bashls.lua
│       │   ├── clangd.lua
│       │   ├── cssls.lua
│       │   ├── html.lua
│       │   ├── jsonls.lua
│       │   ├── lua_ls.lua
│       │   ├── nil_ls.lua
│       │   ├── pyright.lua
│       │   ├── ruby_lsp.lua
│       │   └── ts_ls.lua
│       └── lua/
│           ├── plugins/
│           │   └── init.lua        # lazy.nvim plugin specs
│           └── config/
│               ├── options.lua     # vim.opt.*, clipboard, fugitive, treesitter wrapper
│               ├── theme.lua       # Colorscheme and syntax fallback
│               ├── statusline.lua  # Native icon statusline
│               ├── keymaps.lua     # Custom key mappings
│               ├── completion.lua  # nvim-cmp configuration
│               ├── lsp.lua         # vim.lsp.config / vim.lsp.enable + diagnostics
│               ├── formatter.lua   # conform.nvim configuration
│               └── dap.lua         # Debug Adapter Protocol (kept commented by default)
├── home/                           # Platform-specific home setup
│   ├── unix/                       # Unix shell/Vim files and package installer
│   └── win/                        # PowerShell/Vim files and winget installer
├── scripts/                        # Installation and setup scripts
│   ├── install-nix.sh              # User-level Nix installation script
│   ├── markdown-to-pdf.ps1         # Markdown-to-PDF wrapper for PowerShell
│   └── markdown-to-pdf.sh          # Markdown-to-PDF wrapper for POSIX systems
├── nix/
│   └── packages.nix                # Nix package index for editor/dev tools
├── docs/                           # Detailed documentation (you are here)
└── docker/
    └── Dockerfile.test             # Container used to validate the setup
```

## Neovim file responsibilities

| File | Responsibility |
| --- | --- |
| `init.lua` | Bootstrap lazy.nvim and call `setup()` on each `config.*` module |
| `config/options.lua` | Editor options, clipboard, globals, FileType-driven Tree-sitter highlight |
| `config/theme.lua` | Colorscheme (Tree-sitter is the single highlighting path; no `syntax on` fallback) |
| `config/statusline.lua` | Native statusline with mode/file icons, diagnostics, LSP state, filetype, and position |
| `config/keymaps.lua` | Non-default key mappings (Neovim 0.12 default `gr*` maps are kept) |
| `config/completion.lua` | nvim-cmp setup and sources |
| `config/lsp.lua` | Shared `vim.lsp.config('*', …)` capabilities and `vim.lsp.enable(…)` |
| `config/formatter.lua` | conform.nvim and format-on-save |
| `config/dap.lua` | Debug Adapter Protocol scaffolding (intentionally inert) |
| `lsp/<server>.lua` | Per-server config files; discovered on runtimepath and merged by `vim.lsp.config` when the server is enabled via `vim.lsp.enable(...)` (Neovim 0.12) |
| `plugins/init.lua` | All lazy.nvim plugin specs; plugin-specific `setup()` lives inline |
