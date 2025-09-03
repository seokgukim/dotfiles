#!/bin/bash

set -e  # Exit on any error

echo "Starting dotfiles setup..."

# Detect OS
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
else
    echo "Unsupported package manager. Please install vim-gtk manually."
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"

# Install vim-gtk
echo "Installing vim-gtk..."
if [ "$PKG_MANAGER" = "apt" ]; then
    apt update && apt install -y vim-gtk3 curl wget tar xz-utils
elif [ "$PKG_MANAGER" = "pacman" ]; then
    pacman -Syu --noconfirm gvim curl wget tar xz
elif [ "$PKG_MANAGER" = "dnf" ]; then
    dnf install -y vim-X11 curl wget tar
fi

# Get current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symbolic link .vimrc to /root/.vimrc
echo "Setting up vim configuration..."
ln -sf "$SCRIPT_DIR/vim/.vimrc" /root/.vimrc
echo "Linked .vimrc to /root/.vimrc"

# Install Node.js (latest LTS)
echo "Installing Node.js..."
NODEJS_VERSION="v22.9.0"  # Current LTS as of Sept 2025
NODEJS_URL="https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz"

cd /tmp
wget "$NODEJS_URL" -O nodejs.tar.xz
tar -xf nodejs.tar.xz
mv "node-${NODEJS_VERSION}-linux-x64" /opt/nodejs
ln -sf /opt/nodejs/bin/node /usr/bin/node
ln -sf /opt/nodejs/bin/npm /usr/bin/npm
ln -sf /opt/nodejs/bin/npx /usr/bin/npx

echo "Node.js installed: $(node --version)"

# Install Neovim
echo "Installing Neovim..."
NVIM_VERSION="v0.11.4"  # Latest stable release
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"

cd /tmp
wget "$NVIM_URL" -O nvim.tar.gz
tar -xf nvim.tar.gz
mv nvim-linux64 /opt/nvim
ln -sf /opt/nvim/bin/nvim /usr/bin/nvim

echo "Neovim installed: $(nvim --version | head -1)"

# Get the user who ran the script (even with sudo)
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="/home/$SUDO_USER"
elif [ "$USER" = "root" ]; then
    TARGET_USER="root"
    TARGET_HOME="/root"
else
    TARGET_USER="$USER"
    TARGET_HOME="$HOME"
fi

echo "Setting up Neovim configuration for user: $TARGET_USER"

# Create .config directory if it doesn't exist
sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.config"

# Symbolic link nvim directory
ln -sf "$SCRIPT_DIR/nvim" "$TARGET_HOME/.config/nvim"
chown -h "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/nvim"

echo "Linked nvim config to $TARGET_HOME/.config/nvim"

# Install required tools for nvim plugins
echo "Installing additional tools for Neovim..."

# Install tools like ripgrep and python, ruby, clangd, build-essential, docker and etc.
if [ "$PKG_MANAGER" = "apt" ]; then
    apt install -y \
        ripgrep fd-find \
        python3 python3-pip \
        ruby ruby-dev \
        clangd build-essential \
        docker.io
elif [ "$PKG_MANAGER" = "pacman" ]; then
    pacman -S --noconfirm \
        ripgrep fd \
        python python-pip \
        ruby \
        clang base-devel \
        docker
elif [ "$PKG_MANAGER" = "dnf" ]; then
    dnf install -y \
        ripgrep fd-find \
        python3 python3-pip \
        ruby ruby-devel \
        clang-tools-extra gcc-c++ make \
        docker
fi

# Install language servers and formatters via npm
echo "Installing language servers and formatters..."
npm install -g \
    typescript-language-server \
    vscode-langservers-extracted \
    bash-language-server \
    pyright \
    prettier \
    eslint

# Install Python packages for formatters
if command -v pip3 &> /dev/null; then
    # If pip has --break-system-packages option, use it
    if pip3 install --help | grep -q -- '--break-system-packages'; then
        pip3 install --break-system-packages \
            black \
            isort \
            flake8
    else
        pip3 install \
            black \
            isort \
            flake8
    fi
elif command -v pip &> /dev/null; then
    if pip install --help | grep -q -- '--break-system-packages'; then
        pip install --break-system-packages \
            black \
            isort \
            flake8
    else
        pip install \
            black \
            isort \
            flake8
    fi
else
    echo "Python pip not found. Install Python and pip manually for Python formatters."
fi

# Install Ruby gems for formatters and language servers
if command -v gem &> /dev/null; then
    gem install ruby-lsp
else
    echo "Ruby gem not found. Install Ruby and gem manually for Ruby formatters."
fi

# Add current user to docker group
if ! getent group docker > /dev/null; then
    groupadd docker
fi
usermod -aG docker "$TARGET_USER"

echo "Setup completed successfully!"
echo ""
echo "To finish setup:"
echo "1. Log out and back in for docker group changes to take effect"
echo "2. Run 'nvim' as $TARGET_USER to trigger lazy.nvim plugin installation"
echo "3. In nvim, run ':checkhealth' to verify everything is working"
echo ""
echo "Note: Some plugins may require additional setup or dependencies."