#!/bin/bash

set -eu  # Exit on any error and undefined variables

# Function to print messages with a prefix and logging
console_output() {
    echo "[seokgukim_setup|$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HOME/seokgukim_setup.log"
}

console_output "Starting dotfiles setup..."

# Get the user who ran the script
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="/home/$SUDO_USER"
else
    TARGET_USER=$(id -un)
    TARGET_HOME="$HOME"
fi

if [ -z "$TARGET_USER" ]; then
    console_output "Error: Could not determine target user"
    exit 1
fi

# Verify target user exists
if ! id "$TARGET_USER" &>/dev/null; then
    console_output "Error: User $TARGET_USER does not exist"
    exit 1
fi

# Get current script directory and repo root
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Detect system architecture
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x64"
else
    ARCH="arm64"
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -S --needed --noconfirm"
elif command -v apt-get &> /dev/null; then
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt-get install -y"
else
    console_output "Error: No supported package manager found (pacman/apt)."
    exit 1
fi

console_output "Using $PKG_MGR for package management."

# Install base dependencies. nvim-treesitter `main` builds parsers
# locally, so apt/pacman paths must ship a C toolchain plus `tree-sitter`
# / `curl` / `tar` (the Nix path covers these via nix/packages.nix).
CORE_PKGS="git vim neovim ripgrep fd-find fzf locales fonts-noto-cjk language-pack-ko language-pack-ja build-essential curl tar"

# Decide whether the distro neovim is recent enough; only fall back to the
# neovim-ppa/unstable PPA when the candidate is < 0.12.0 (or unknown).
ensure_neovim_repo() {
    local cand cand_stripped
    cand=$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/ {print $2; exit}')
    cand_stripped="${cand#*:}"  # drop dpkg epoch ("1:0.10.0-2" -> "0.10.0-2")
    if [ -n "$cand_stripped" ] && [ "$cand_stripped" != "(none)" ] \
       && dpkg --compare-versions "$cand_stripped" ge 0.12.0; then
        console_output "distro neovim ${cand} is >= 0.12.0; skipping PPA"
        return 0
    fi
    console_output "distro neovim candidate=${cand:-unknown}; adding ppa:neovim-ppa/unstable"
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt-get update
}

if [ "$PKG_MGR" = "pacman" ]; then
    $INSTALL_CMD git vim neovim ripgrep fd fzf noto-fonts-cjk \
        base-devel tree-sitter tree-sitter-cli curl tar
elif [ "$PKG_MGR" = "apt" ]; then
    sudo apt-get update
    ensure_neovim_repo
    $INSTALL_CMD $CORE_PKGS
    # `tree-sitter` (CLI) is only packaged on recent Ubuntu releases; if
    # the package is unavailable the parser build will fall back to
    # whatever the user installs via cargo / npm. Try once and do not
    # fail the bootstrap when it is missing.
    sudo apt-get install -y tree-sitter-cli >/dev/null 2>&1 \
        || console_output "tree-sitter-cli not in apt; install via 'cargo install tree-sitter-cli' or 'npm i -g tree-sitter-cli' for nvim-treesitter main"
fi

# Set locale for CJK support (without changing system language)
console_output "Setting up locales..."
if [ "$PKG_MGR" = "apt" ]; then
    sudo locale-gen ko_KR.UTF-8 ja_JP.UTF-8
fi
# Note: We keep LANG=en_US.UTF-8 for the system to avoid non-ASCII paths

# Symlink dotfiles
console_output "Linking configurations..."
mkdir -p "$TARGET_HOME/.config"
ln -sf "$REPO_ROOT/config/nvim" "$TARGET_HOME/.config/nvim"
ln -sf "$REPO_ROOT/home/.vimrc" "$TARGET_HOME/.vimrc"

# Add current user to docker group
if ! getent group docker > /dev/null; then
    if [ "$(id -u)" -eq 0 ]; then
        groupadd docker
    else
        sudo groupadd docker
    fi
fi
if [ "$(id -u)" -eq 0 ]; then
    usermod -aG docker "$TARGET_USER"
else
    sudo usermod -aG docker "$TARGET_USER"
fi

# Final message
console_output "Setup completed successfully!"
console_output ""
console_output "To finish setup:"
console_output "1. Open a new terminal session or run: source $TARGET_HOME/.bashrc"
console_output "2. Verify docker access: docker --version (may require logout/login)"
console_output "3. Verify Neovim: nvim --version"
console_output "4. Run 'nvim' as $TARGET_USER to trigger lazy.nvim plugin installation"
console_output "5. In nvim, run ':checkhealth' to verify everything is working"
console_output ""
console_output "Note: Some plugins may require additional setup or dependencies."
