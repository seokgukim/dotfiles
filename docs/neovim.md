# Neovim Configuration

Targets **Neovim 0.12+**. Uses native `vim.lsp.config` / `vim.lsp.enable` and
the `lsp/<server>.lua` runtimepath convention introduced in 0.12.

## Features

- **Plugin manager**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Theme**: [nightfox.nvim](https://github.com/EdenEast/nightfox.nvim) (`nordfox`)
- **UI / navigation**: [snacks.nvim](https://github.com/folke/snacks.nvim) for
  picker, dashboard, notifications, buffer delete, lazygit, status column,
  explorer, terminal, scratch, zen, gitbrowse, and toggles
- **Statusline**: native Lua statusline with mode/file icons, diagnostics,
  LSP, filetype, and cursor progress; Snacks provides the status column
- **LSP**: native Neovim 0.12 LSP — shared capabilities via
  `vim.lsp.config('*', …)`, servers auto-loaded from `lsp/<name>.lua`
- **Completion**: nvim-cmp with Snippy
- **Formatter**: conform.nvim with `lsp_format = "fallback"`
- **Git**: vim-fugitive and Snacks lazygit
- **Syntax**: nvim-treesitter (`main` branch). Tree-sitter is the only highlighting path; filetypes whose parser is not installed remain unhighlighted, with `smartindent` as the indent fallback.
- **AI**: GitHub Copilot (disabled by default; toggle with `<leader><F1>`)
- **Author plugins**: `mlua.nvim`, `mlua-debugger.nvim`, `vawi.nvim` are
  intentionally kept

## Plugin audit notes

This configuration is centered on Snacks. The following overlapping or unused
plugins were removed:

| Removed plugin | Replacement / reason |
| --- | --- |
| `romgrk/barbar.nvim` | Buffer workflows use `Snacks.picker.buffers()` and `Snacks.bufdelete()` |
| `lewis6991/gitsigns.nvim` | Was only present as a barbar dependency; Git workflow remains via fugitive and Snacks lazygit |
| `bluz71/nvim-linefly` | Replaced with a dedicated native Lua statusline; Snacks only owns the status column |
| `cmp-calc`, `cmp-nvim-lsp-signature-help`, `cmp-nvim-lsp-document-symbol`, `cmp-nvim-lua` | Not configured as active completion sources |

## Language support

| Language | Server | Formatter |
| --- | --- | --- |
| TypeScript / JavaScript | `ts_ls` | prettier |
| HTML / CSS / JSON | vscode-langservers-extracted | prettier |
| Python | `pyright` | black, isort |
| Ruby | `ruby_lsp` (via Nix) | rubocop |
| Bash | bash-language-server | shfmt |
| C / C++ | `clangd` | clang-format |
| Lua | `lua_ls` | stylua |
| Nix | nil | nixpkgs-fmt |

## Conventions

- LSP servers are defined in `config/nvim/lsp/<name>.lua`. Add a new server
  by dropping a file in that directory and adding its name to the enable list
  in `lua/config/lsp.lua`.
- Plugin-specific setup lives in the plugin spec's `config = function()` block,
  not in `init.lua`.
- `config/statusline.lua` owns the native statusline. Keep Snacks'
  `statuscolumn` enabled for the sign/line-number column instead of adding a
  second statusline plugin.
- Clipboard integration is via `vim.opt.clipboard = "unnamedplus"`. There are
  no system-clipboard leader maps by design.
- Neovim 0.12 default LSP keymaps (`gra`, `gri`, `grn`, `grr`, `grt`, `grx`,
  `i_CTRL-S`) are kept; `keymaps.lua` only adds non-default mappings.
- Leader prefix split: `<leader>g*` is reserved for Git (`gg` lazygit,
  `gB` gitbrowse), and LSP picker mappings are under `<leader>l*`
  (`ld` definitions, `lr` references, `li` implementations, `ls` symbols).
  `mlua.nvim`'s formatter is bound to `<leader>lf`.
- Snacks surfaces: `<leader>e` explorer, `<leader>tt` terminal, `<leader>z`
  zen, `<leader>.` scratch, `<leader>ut`/`<leader>ud` toggles.
