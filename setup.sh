#!/bin/bash

set -e  # Exit on any error

# Function to print messages with a prefix and logging
console_output() {
    echo "[seokgukim_setup|$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "/var/log/seokgukim_setup.log"
}

console_output "Starting dotfiles setup..."

# Assume the script is run with sudo or as root
if [ "$EUID" -ne 0 ]; then
    console_output "Please run as root or with sudo."
    exit 1
fi

# Get the user who ran the script (even with sudo) - MOVED TO TOP
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="/home/$SUDO_USER"
elif [ -z "$USER" ]; then
    console_output "Error: USER environment variable is not set"
    exit 1
elif [ "$USER" = "root" ]; then
    TARGET_USER="root"
    TARGET_HOME="/home/root"
    # For root, show a confirmation message to ask if they want to proceed
    console_output "Warning: You are running this script as root. Proceeding may affect the root user's environment."
    read -r -p "Do you want to continue? (y/n): " response < /dev/tty
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        console_output "Aborting setup."
        exit 1
    fi
else
    TARGET_USER="$USER"
    TARGET_HOME="$HOME"
fi

# Verify target user exists
if ! id "$TARGET_USER" &>/dev/null; then
    console_output "Error: User $TARGET_USER does not exist"
    exit 1
fi

# Get current script directory
SCRIPT_DIR="$TARGET_HOME/dotfiles"

# Detect system architecture
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x64"
else
    ARCH="arm64"
fi

# Detect OS
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
else
    console_output "Unsupported package manager. Please install packages manually."
    exit 1
fi

console_output "Detected package manager: $PKG_MANAGER"

# Install vim-gtk
console_output "Installing essential packages..."
if [ "$PKG_MANAGER" = "apt" ]; then
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt install -y sudo curl wget tar xz-utils git vim-gtk3
elif [ "$PKG_MANAGER" = "pacman" ]; then
    pacman -Syu --noconfirm sudo curl wget tar xz git gvim
elif [ "$PKG_MANAGER" = "dnf" ]; then
    dnf install -y sudo curl wget tar git vim-X11
fi

# Get the dotfiles repository from GitHub
if [ -d "$SCRIPT_DIR" ]; then
    console_output "Dotfiles directory already exists at $SCRIPT_DIR, skipping clone."
    console_output "The script may not work as intended if the repository is not up to date."
else
    console_output "Cloning dotfiles repository..."
    sudo -u "$TARGET_USER" git clone https://github.com/seokgukim/dotfiles.git "$SCRIPT_DIR"
fi

# Get specific versions information from the repository
if [ -f "$SCRIPT_DIR/versions.txt" ]; then
    source "$SCRIPT_DIR/versions.txt" # Load variables
    console_output "Loaded versions from versions.txt"
else
    console_output "versions.txt not found in $SCRIPT_DIR, proceeding without it."
fi

# Copy .bashrc if exists
if [ -f "$SCRIPT_DIR/bash/.bashrc" ]; then
    console_output "Setting up bash configuration..."
    cp "$SCRIPT_DIR/bash/.bashrc" "$TARGET_HOME/.bashrc"
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.bashrc"
    console_output "Copied .bashrc to $TARGET_HOME/.bashrc"
else
    console_output ".bashrc not found in $SCRIPT_DIR/bash/, skipping."
fi

# Symbolic link .vimrc to /root/.vimrc
console_output "Setting up vim configuration..."
ln -sf "$SCRIPT_DIR/vim/.vimrc" /root/.vimrc
console_output "Linked .vimrc to /root/.vimrc"

# Install Node.js (latest LTS)
console_output "Installing Node.js..."
if [ -z "$NODEJS_TARGET_VERSION" ]; then
    NODEJS_TARGET_VERSION="v22.19.0"  # Default to Current LTS as of Sept 2025
    console_output "NODEJS_TARGET_VERSION not set, defaulting to $NODEJS_TARGET_VERSION"
fi
NODEJS_TARGET="node-${NODEJS_TARGET_VERSION}-linux-${ARCH}.tar.xz"
NODEJS_URL="https://nodejs.org/dist/${NODEJS_TARGET_VERSION}/$NODEJS_TARGET"
NODEJS_DIR="/opt/nodejs"

cd /tmp
wget "$NODEJS_URL" -O nodejs.tar.xz
tar -xf nodejs.tar.xz
mv "node-${NODEJS_TARGET_VERSION}-linux-${ARCH}" "$NODEJS_DIR"
ln -sf "$NODEJS_DIR/bin/node" /usr/bin/node
ln -sf "$NODEJS_DIR/bin/npm" /usr/bin/npm
ln -sf "$NODEJS_DIR/bin/npx" /usr/bin/npx

# Add Node.js to PATH for current session and .bashrc
export PATH="$NODEJS_DIR/bin:$PATH"
if ! grep -q 'nodejs' "$TARGET_HOME/.bashrc"; then
    echo "export PATH=\"$NODEJS_DIR/bin:\$PATH\"" >> "$TARGET_HOME/.bashrc"
fi

console_output "Node.js installed: $(node --version)"

# Install Neovim
console_output "Installing Neovim..."
if [ -z "$NVIM_TARGET_VERSION" ]; then
    NVIM_TARGET_VERSION="v0.11.4"  # Default to latest stable as of Sept 2025
    console_output "NVIM_TARGET_VERSION not set, defaulting to $NVIM_TARGET_VERSION"
fi
NVIM_TARGET="nvim-linux-x86_64.tar.gz"
if [ "$ARCH" = "arm64" ]; then
    NVIM_TARGET="nvim-linux-arm64.tar.gz"
fi
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_TARGET_VERSION}/$NVIM_TARGET"
NVIM_DIR="/opt/nvim"

cd /tmp
wget "$NVIM_URL" -O nvim.tar.gz
tar -xf nvim.tar.gz
mv nvim-linux-* "$NVIM_DIR"
ln -sf "$NVIM_DIR/bin/nvim" /usr/bin/nvim

# Add Neovim to .bashrc as EDITOR and VISUAL
if ! grep -q 'nvim' "$TARGET_HOME/.bashrc"; then
    echo 'export EDITOR="nvim"' >> "$TARGET_HOME/.bashrc"
    echo 'export VISUAL="nvim"' >> "$TARGET_HOME/.bashrc"
fi

console_output "Neovim installed: $(nvim --version | head -1)"

console_output "Setting up Neovim configuration for user: $TARGET_USER"

# Create .config directory if it doesn't exist
sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.config"

# Symbolic link nvim directory
ln -sf "$SCRIPT_DIR/nvim" "$TARGET_HOME/.config/nvim"
chown -h "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/nvim"

console_output "Linked nvim config to $TARGET_HOME/.config/nvim"

# Install required tools for nvim plugins
console_output "Installing additional tools for Neovim..."

# Install tools like ripgrep and python, ruby, clangd, build-essential, docker and etc.
if [ "$PKG_MANAGER" = "apt" ]; then
    apt install -y \
        ripgrep fd-find xclip\
        libyaml-dev \
        python3 python3-pip python3-venv \
        ruby ruby-dev \
        clangd build-essential \
        docker.io \
        libssl-dev libreadline-dev zlib1g-dev autoconf bison libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev
elif [ "$PKG_MANAGER" = "pacman" ]; then
    pacman -S --noconfirm \
        ripgrep fd xclip \
        libyaml \
        python python-pip python-virtualenv \
        ruby \
        clang base-devel \
        docker \
        openssl readline zlib autoconf bison libyaml ncurses libffi gdbm
elif [ "$PKG_MANAGER" = "dnf" ]; then
    dnf install -y \
        ripgrep fd-find xclip \
        libyaml-devel \
        python3 python3-pip python3-virtualenv \
        ruby ruby-devel \
        clang-tools-extra gcc-c++ make \
        docker \
        openssl-devel readline-devel zlib-devel autoconf bison libyaml-devel ncurses-devel libffi-devel gdbm-devel
fi

# Install language servers and formatters via npm
console_output "Installing language servers and formatters... (via npm)"
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
    console_output "Python pip not found. Install Python and pip manually for Python formatters."
fi

# Setup rbenv for Ruby version management
console_output "Setting up rbenv for Ruby version management..."

# Check if rbenv already exists
if [ ! -d "$TARGET_HOME/.rbenv" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/rbenv/rbenv.git "$TARGET_HOME/.rbenv"
    cd "$TARGET_HOME/.rbenv" && sudo -u "$TARGET_USER" src/configure && sudo -u "$TARGET_USER" make -C src || console_output "Warning: rbenv dynamic bash extension compilation failed (optional)"
fi

if [ ! -d "$TARGET_HOME/.rbenv/plugins/ruby-build" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/rbenv/ruby-build.git "$TARGET_HOME/.rbenv/plugins/ruby-build"
fi

# Add rbenv to bashrc if not already present
if ! grep -q 'rbenv' "$TARGET_HOME/.bashrc"; then
    echo "export PATH=\"$TARGET_HOME/.rbenv/bin:\$PATH\"" >> "$TARGET_HOME/.bashrc"
    echo 'eval "$(rbenv init - bash)"' >> "$TARGET_HOME/.bashrc"
fi

# Install Ruby with proper environment setup
if [ -z "$RUBY_TARGET_VERSION" ]; then
    RUBY_TARGET_VERSION="3.4.5"  # Default to latest stable as of Sept 2025
    console_output "RUBY_TARGET_VERSION not set, defaulting to $RUBY_TARGET_VERSION"
fi
console_output "Installing Ruby $RUBY_TARGET_VERSION..."

# Check if Ruby version is already installed
if ! sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && rbenv versions 2>/dev/null | grep -q \"$RUBY_TARGET_VERSION\""; then
    console_output "Installing Ruby $RUBY_TARGET_VERSION (this may take several minutes)..."
    sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && rbenv install $RUBY_TARGET_VERSION"
else
    console_output "Ruby $RUBY_TARGET_VERSION already installed"
fi

# Set global Ruby version
sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && rbenv global $RUBY_TARGET_VERSION"
sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && rbenv rehash"

# Verify Ruby installation
RUBY_VERSION=$(sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && ruby -v" 2>/dev/null || echo "Ruby installation failed")
console_output "Ruby installed: $RUBY_VERSION"

# Install Ruby gems for formatters and language servers
console_output "Installing Ruby LSP and RuboCop..."
if echo "$RUBY_VERSION" | grep -q "ruby $RUBY_TARGET_VERSION"; then
    sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && gem install ruby-lsp" || console_output "Failed to install ruby-lsp"
    sudo -H -u "$TARGET_USER" bash -c "export PATH=\"$TARGET_HOME/.rbenv/bin:$TARGET_HOME/.rbenv/shims:\$PATH\" && eval \"\$(rbenv init - bash)\" && gem install rubocop" || console_output "Failed to install rubocop"
else
    console_output "Ruby not properly installed. Skipping ruby-lsp installation."
fi

# Add current user to docker group
if ! getent group docker > /dev/null; then
    groupadd docker
fi
usermod -aG docker "$TARGET_USER"

# SSH configuration
console_output "Setting up SSH configuration..."
SSH_DIR="$TARGET_HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    sudo -u "$TARGET_USER" mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    console_output "Created $SSH_DIR"
else
    console_output "$SSH_DIR already exists, skipping creation."
fi

# Basic GitHub SSH config
GITHUB_SSH_CONFIG="$SSH_DIR/config"
if [ ! -f "$GITHUB_SSH_CONFIG" ]; then
    {
        echo "Host github.com"
        echo "  HostName github.com"
        echo "  User git"
        echo "  AddKeysToAgent yes"
        echo "  IdentityFile $SSH_DIR/seokgukim.pem"
        echo "  IdentitiesOnly yes"
    } >> "$GITHUB_SSH_CONFIG"
    chmod 600 "$GITHUB_SSH_CONFIG"
    chown "$TARGET_USER:$TARGET_USER" "$GITHUB_SSH_CONFIG"
    console_output "Created basic GitHub SSH config at $GITHUB_SSH_CONFIG"
else
    console_output "SSH config already exists at $GITHUB_SSH_CONFIG, skipping."
fi


# Final message
console_output "Setup completed successfully!"
console_output ""
console_output "To finish setup:"
console_output "1. Open a new terminal session or run: source $TARGET_HOME/.bashrc"
console_output "2. Verify rbenv works: rbenv --version"
console_output "3. Verify docker access: docker --version (may require logout/login)"
console_output "4. Run 'nvim' as $TARGET_USER to trigger lazy.nvim plugin installation"
console_output "5. In nvim, run ':checkhealth' to verify everything is working"
console_output ""
console_output "Note: Some plugins may require additional setup or dependencies."
