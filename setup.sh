#!/bin/bash

set -e  # Exit on any error

# Function to print messages with a prefix and logging
console_output() {
    echo "[seokgukim_setup|$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HOME/seokgukim_setup.log"
}

console_output "Starting dotfiles setup..."

# Get the user who ran the script
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="/home/$SUDO_USER"
elif [ -z "$USER" ]; then
    console_output "Error: USER environment variable is not set"
    exit 1
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

# Use Nix for package management
# Source Nix profile for target user if exists
if [ -f "/home/$TARGET_USER/.nix-profile/etc/profile.d/nix.sh" ]; then
    . /home/$TARGET_USER/.nix-profile/etc/profile.d/nix.sh || true
fi
if ! command -v nix &> /dev/null; then
    console_output "Nix not found. Installing Nix package manager for $TARGET_USER..."
    if [ ! -d /nix ]; then
        mkdir -m 0755 /nix
    fi
    chown -R "$TARGET_USER" /nix
    if ! getent group nixbld > /dev/null; then
        groupadd nixbld
    fi
    su - "$TARGET_USER" -c 'curl -L https://nixos.org/nix/install | sh'
    su - "$TARGET_USER" -c '. $HOME/.nix-profile/etc/profile.d/nix.sh || true'
fi

if [ -f "/home/$TARGET_USER/.nix-profile/etc/profile.d/nix.sh" ]; then
    . /home/$TARGET_USER/.nix-profile/etc/profile.d/nix.sh || true
fi

console_output "Using Nix for package management."
console_output "Installing essential packages with Nix..."
su -l "$TARGET_USER" -c 'nix-env -iA \
  nixpkgs.wget \
  nixpkgs.git \
  nixpkgs.vim \
  nixpkgs.neovim \
  nixpkgs.nushell \
  nixpkgs.ripgrep \
  nixpkgs.fd \
  nixpkgs.xclip \
  nixpkgs.python3 \
  nixpkgs.ruby \
  nixpkgs.docker \
  nixpkgs.nodejs \
  nixpkgs.gcc \
  nixpkgs.gnumake \
  nixpkgs.openssl \
  nixpkgs.readline \
  nixpkgs.zlib \
  nixpkgs.autoconf \
  nixpkgs.bison \
  nixpkgs.ncurses \
  nixpkgs.libffi \
  nixpkgs.gdbm \
  nixpkgs.zellij \
  nixpkgs.zoxide \
  nixpkgs.yazi \
  nixpkgs.uutils-coreutils \
  nixpkgs.lazygit \
  nixpkgs.jj \
  nixpkgs.lazydocker \
  nixpkgs.harlequin \
  nixpkgs.btop \
  nixpkgs.fzf \
  nixpkgs.typescript-language-server \
  nixpkgs.vscode-langservers-extracted \
  nixpkgs.bash-language-server \
  nixpkgs.pyright \
  nixpkgs.prettier \
  nixpkgs.eslint \
  nixpkgs.black \
  nixpkgs.isort \
  nixpkgs.ruby-lsp \
  nixpkgs.rubocop \
  nixpkgs.nushell \
  --quiet'


# Get the dotfiles repository from GitHub
if [ -d "$SCRIPT_DIR" ]; then
    console_output "Dotfiles directory already exists at $SCRIPT_DIR, skipping clone."
    console_output "The script may not work as intended if the repository is not up to date."
else
    console_output "Cloning dotfiles repository..."
    su -l "$TARGET_USER" -c "export SCRIPT_DIR='$SCRIPT_DIR'; git clone https://github.com/seokgukim/dotfiles.git \"\$SCRIPT_DIR\""
fi

# Symbolic link .vimrc to /root/.vimrc
console_output "Setting up vim configuration..."
ln -sf "$SCRIPT_DIR/vim/.vimrc" /root/.vimrc
console_output "Linked .vimrc to /root/.vimrc"

console_output "Setting up Neovim configuration for user: $TARGET_USER"

# Create .config directory if it doesn't exist
su -l "$TARGET_USER" -c "export TARGET_HOME='$TARGET_HOME'; mkdir -p \"\$TARGET_HOME/.config\"; ln -sf '$SCRIPT_DIR/nvim' \"\$TARGET_HOME/.config/nvim\"; chown -h $TARGET_USER:$TARGET_USER \"\$TARGET_HOME/.config/nvim\""
console_output "Linked nvim config to $TARGET_HOME/.config/nvim"

# Add current user to docker group
if ! getent group docker > /dev/null; then
    groupadd docker
fi
usermod -aG docker "$TARGET_USER"

# SSH configuration
console_output "Setting up SSH configuration..."
SSH_DIR="$TARGET_HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    su -l "$TARGET_USER" -c "export SSH_DIR='$SSH_DIR'; mkdir -p \"\$SSH_DIR\""
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

# Add Neovim to .bashrc as EDITOR and VISUAL
su -l "$TARGET_USER" -c "cat >> \$HOME/.bashrc <<'BASHRC'
export EDITOR=\"nvim\"
export VISUAL=\"nvim\"
. \$HOME/.nix-profile/etc/profile.d/nix.sh
BASHRC"

su -l "$TARGET_USER" -c "mkdir -p \$HOME/.config/nushell && cat >> \$HOME/.config/nushell/config.nu <<'NUSHELLCFG'
\$env.EDITOR = \"nvim\"
\$env.VISUAL = \"nvim\"
source ~/.nix-profile/etc/profile.d/nix.sh
NUSHELLCFG"


# Final message
console_output "Setup completed successfully!"
console_output ""
console_output "To finish setup:"
console_output "1. Open a new terminal session or run: source $TARGET_HOME/.bashrc"
console_output "2. Verify docker access: docker --version (may require logout/login)"
console_output "3. Run 'nvim' as $TARGET_USER to trigger lazy.nvim plugin installation"
console_output "4. In nvim, run ':checkhealth' to verify everything is working"
console_output "5. Nushell is now your default shell (log out and back in to activate)"
console_output ""
console_output "Note: Some plugins may require additional setup or dependencies."
