# mLua LSP Setup for Neovim

Full LSP support for mLua files in Neovim with code completion, syntax highlighting, and all standard LSP features.

## Prerequisites

- Neovim 0.8+
- Node.js (for running the language server)
- `curl` and `unzip`

## Installation

The mLua LSP is managed automatically. To install:

```vim
:MluaInstall
```

## Structure

```
nvim/
├── init.lua                      # Loads mlua setup
├── lua/
│   ├── config/lsp.lua            # General LSP with semantic tokens
│   └── mlua/
│       ├── init.lua              # Main setup (keybindings, config)
│       ├── lsp.lua               # LSP manager (install/update)
│       └── debug.lua             # Debug utilities
├── syntax/mlua.vim               # Basic syntax highlighting
├── ftdetect/mlua.vim             # Filetype detection
└── ftplugin/mlua.vim             # Filetype settings
```

## Features

- ✅ Code completion (Lua + mLua keywords, snippets)
- ✅ Syntax highlighting (basic + semantic tokens)
- ✅ Go to definition/declaration/implementation
- ✅ Hover documentation
- ✅ Find references
- ✅ Rename symbols
- ✅ Diagnostics
- ✅ Code actions
- ✅ Signature help
- ✅ Document formatting

## Keybindings

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `gi` | Go to implementation |
| `<C-k>` | Signature help |
| `gr` | Find references |
| `<space>rn` | Rename symbol |
| `<space>ca` | Code actions |
| `<space>f` | Format document |
| `<space>D` | Type definition |
| `<space>h` | Toggle inlay hints |
| `<C-Space>` | Trigger completion |

## Virtual Text & Diagnostics

**Diagnostic Virtual Text**: Enabled by default
- Error/warning messages appear inline at the end of lines
- Prefix: `●` with spacing for readability
- Shows source when multiple diagnostics present

**Inlay Hints**: Enabled automatically if server supports them
- Type hints for variables
- Parameter names in function calls
- Toggle on/off with `<space>h`

**Note**: The mLua server may have limited inlay hint support. Virtual text is primarily for diagnostics (errors/warnings).

## Commands

- `:MluaInstall` - Install language server
- `:MluaUpdate` - Update to latest version
- `:MluaCheckVersion` - Check versions
- `:MluaUninstall` - Remove language server
- `:MluaRestart` - Restart LSP server
- `:MluaDebug` - Show debug info
- `:MluaLogs` - View LSP logs

## Troubleshooting

### JSON Error ("is not valid JSON")

If you see an error like:
```
Request initialize failed with message: "[object Object]" is not valid JSON
```

**Solution:**
This was caused by init_options serialization. The configuration now omits init_options entirely, letting the server use its defaults. This is already fixed in the current version.

### Timeout Error ("The promise has timed out")

If you see an error like:
```
The promise has timed out.
Error at C.setCurrentStack
```

**Solution:**
The server is taking too long to initialize. This is usually fixed by:

1. Restart the LSP:
   ```vim
   :MluaRestart
   ```

2. If the error persists, check available memory:
   ```bash
   free -h
   ```

3. The configuration now includes `--max-old-space-size=4096` for Node.js to prevent memory issues.

### LSP not starting
```vim
:MluaDebug
```
Check if Node.js is installed and mLua LSP is present.

### No completion
Verify filetype is set correctly:
```vim
:set filetype?
```
Should show `filetype=mlua`

### No syntax highlighting
Check semantic tokens in debug output:
```vim
:MluaDebug
```

### View errors
```vim
:MluaLogs
```

## How It Works

The VSCode mLua extension is downloaded and extracted. The TypeScript language server (compiled to JavaScript) runs via Node.js and communicates with Neovim through LSP. Proper initialization options enable all features including completion and semantic highlighting.

The key fix was ensuring initialization options are passed as a Lua table (not JSON string), which allows the server to recognize all capability requests.
