# :diamond_shape_with_a_dot_inside: SeokguKim's dotfiles
Here are my dotfiles, mostly for `Neovim` and `Vim`.

![Symbol_SeokguKim](https://github.com/SeokguKim/dotfiles/assets/43718966/0181c5a0-2258-4166-aea7-de9b61c296de)

## :file_folder: Structure
```
dotfiles/
├── README.md                    # This file
├── setup.sh                     # Automated installation script
├── .gitignore                   # Git ignore patterns
├── nvim/                        # Neovim configuration
│   ├── init.lua                 # Main Neovim config entry point
│   ├── lazy-lock.json           # Plugin version lock file
│   └── lua/
│       └── config/
│           ├── appearance.lua   # Theme and UI settings
│           ├── copilot.lua      # GitHub Copilot configuration
│           ├── dap.lua          # Debug Adapter Protocol setup
│           ├── formatter.lua    # Code formatting settings
│           ├── keymaps.lua      # Custom key mappings
│           ├── lsp.lua          # Language Server Protocol config
│           └── utils.lua        # Utility functions and settings
└── vim/
    └── .vimrc                   # Traditional Vim configuration
```

## :rocket: Installation
Run the following command to download and execute the setup script.  
This will run `setup.sh` in this repo with root privileges to ensure all dependencies are installed correctly.

```bash
curl -fsSL https://raw.githubusercontent.com/SeokguKim/dotfiles/main/setup.sh | sudo bash
```

Or clone the repository and run the setup script with root privileges:

```bash
sudo bash setup.sh
```

The script will:
- Install vim-gtk and required dependencies
- Install Node.js (latest LTS) for language servers
- Install Neovim (latest stable) from GitHub releases
- Set up symbolic links for configurations
- Install language servers and formatters
- Configure Docker access

## :gear: What's Included

### Neovim Features
- **Plugin Manager**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Theme**: [nightfox.nvim](https://github.com/EdenEast/nightfox.nvim)
- **LSP**: Full language server support with auto-completion
- **Formatter**: Code formatting with conform.nvim
- **Git Integration**: vim-fugitive and vim-gitgutter
- **File Explorer**: Telescope for fuzzy finding
- **Syntax Highlighting**: TreeSitter
- **Status Line**: nvim-linefly
- **Tab Management**: barbar.nvim
- **AI Assistance**: GitHub Copilot integration

### Language Support
- **TypeScript/JavaScript**: typescript-language-server, prettier, eslint
- **HTML/CSS/JSON**: vscode-langservers-extracted
- **Python**: pyright, black, isort, flake8
- **Ruby**: ruby-lsp
- **Bash**: bash-language-server
- **C/C++**: clangd

### Development Tools
- Docker integration
- Git workflow enhancements
- Advanced search with ripgrep
- File navigation with fd

## :keyboard: Key Features

- Modern Neovim setup with lazy loading plugins
- Comprehensive LSP configuration for multiple languages
- Automated code formatting on save
- Fuzzy finding for files, buffers, and content
- Git integration with visual indicators
- Debug adapter support (commented out by default)
- AI-powered code completion with GitHub Copilot

## :wrench: Requirements

- Linux system with apt, pacman, or dnf package manager
- Root access for installation
- Internet connection for downloading dependencies

## :page_facing_up: Post-Installation

After running the setup script:

1. Log out and back in for Docker group changes
2. Run `nvim` to trigger plugin installation
3. In Neovim, run `:checkhealth` to verify setup
4. Configure GitHub Copilot with `:Copilot setup`

## :memo: Notes

- Some plugins may require additional setup or API keys
- DAP (Debug Adapter Protocol) is commented out by default
- Configurations are modular and can be easily customized

