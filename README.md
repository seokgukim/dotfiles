# :diamond_shape_with_a_dot_inside: SeokguKim's dotfiles
Here are my dotfiles, mostly for `Neovim` and `Vim`.

![Symbol_SeokguKim](https://github.com/SeokguKim/dotfiles/assets/43718966/0181c5a0-2258-4166-aea7-de9b61c296de)

## :file_folder: Structure
```
dotfiles/
├── README.md                    # This file
├── LICENSE                      # License file
├── setup.sh                     # Automated installation script
├── versions.txt                 # Version information
├── .gitignore                   # Git ignore patterns
├── bash/
│   └── .bashrc                  # Bash configuration
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
curl -fsSL https://raw.githubusercontent.com/seokgukim/dotfiles/main/setup.sh | sudo bash
```

Or clone the repository and run the setup script with root privileges:

```bash
sudo bash setup.sh
```

The script will:
- Leave a directory at `~/dotfiles` with the cloned repository
- Install required packages based on your package manager (apt, pacman, dnf)
- Install Node.js (latest LTS) for language servers
- Install Neovim (latest stable) from GitHub releases, using `lazy.nvim` to manage plugins
- Install ripgrep, fd, and other CLI tools
- Install Python packages via system `pip`
- Install `rbenv` and Ruby for Ruby LSP
- Install language servers and formatters
- Set up symbolic links for configurations
- Configure Docker access
- Run `~/.bashrc` to apply changes

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

After running the setup script, follow these steps to complete the setup:

### 1. Refresh Your Environment
Open a new terminal session or run:
```bash
source ~/.bashrc
```

### 2. Verify Tool Installation
Check that the development tools are working:
```bash
# Verify rbenv
rbenv --version

# Verify Node.js and npm
node --version
npm --version

# Verify Neovim
nvim --version

# Verify Docker (may require logout/login first)
docker --version
```

### 3. Initialize Neovim
Run Neovim to trigger automatic plugin installation:
```bash
nvim
```
- Lazy.nvim will automatically install all configured plugins
- Wait for the installation to complete
- Exit Neovim with `:q`

### 4. Health Check
Run Neovim's health check to verify everything is working:
```bash
nvim -c ':checkhealth'
```
This will show you:
- Which language servers are available
- If formatters are properly installed
- Any missing dependencies

### 5. Configure GitHub Copilot (Optional)
If you want to use GitHub Copilot:
```bash
nvim -c ':Copilot setup'
```
Follow the prompts to authenticate with your GitHub account.

### 6. Docker Group Access
For Docker commands to work without sudo:
- Log out and log back in, or
- Run: `newgrp docker` in your current session

### Troubleshooting

If you encounter issues:

1. **rbenv not found**: Restart your terminal or run `source ~/.bashrc`
2. **Language servers not working**: Run `:checkhealth lsp` in Neovim
3. **Docker permission denied**: Ensure you're in the docker group with `groups`
4. **Plugins not loading**: Delete `~/.local/share/nvim` and restart Neovim

## :memo: Notes

- Some plugins may require additional setup or API keys
- DAP (Debug Adapter Protocol) is commented out by default
- Configurations are modular and can be easily customized
- The setup installs tools system-wide but configurations are user-specific

