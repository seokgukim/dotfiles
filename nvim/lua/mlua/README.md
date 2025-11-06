# mLua Module

mLua LSP integration for Neovim.

## Files

- `init.lua` - Main setup function with keybindings and LSP configuration
- `lsp.lua` - LSP manager (install, update, version management)
- `debug.lua` - Debug utilities for troubleshooting

## Usage

In your `init.lua`:
```lua
require("mlua").setup()
```

## Commands

- `:MluaInstall` - Install language server
- `:MluaUpdate` - Update to latest version
- `:MluaDebug` - Show debug information
- `:MluaRestart` - Restart LSP server
- `:MluaLogs` - View LSP logs

See `../../MLUA_SETUP.md` for complete documentation.
