#!/usr/bin/env bash

set -euo pipefail
export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
MIN_NEOVIM_VERSION="0.12.0"

# Get the user who ran the script
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER=$(id -un)
fi

if [ -z "$TARGET_USER" ]; then
    echo "Error: Could not determine target user" >&2
    exit 1
fi

# Verify target user exists
if ! id "$TARGET_USER" &>/dev/null; then
    echo "Error: User $TARGET_USER does not exist" >&2
    exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [ -z "$TARGET_HOME" ]; then
    echo "Error: Could not determine home directory for $TARGET_USER" >&2
    exit 1
fi

LOG_FILE="$TARGET_HOME/seokgukim_setup.log"

# Function to print messages with a prefix and logging
console_output() {
    printf '[seokgukim_setup|%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo env DEBIAN_FRONTEND="$DEBIAN_FRONTEND" "$@"
    fi
}

apt_is_ubuntu() {
    [ -r /etc/os-release ] || return 1
    # shellcheck disable=SC1091
    . /etc/os-release
    [ "${ID:-}" = "ubuntu" ]
}

version_ge() {
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n 1)" = "$2" ]
}

current_nvim_version() {
    command -v nvim >/dev/null 2>&1 || return 1
    nvim --version 2>/dev/null | awk 'NR == 1 { sub(/^v/, "", $2); print $2; exit }'
}

nvim_version_ge_min() {
    local version
    version="$(current_nvim_version || true)"
    [ -n "$version" ] && version_ge "$version" "$MIN_NEOVIM_VERSION"
}

require_supported_neovim() {
    local version
    version="$(current_nvim_version || true)"
    if [ -z "$version" ]; then
        console_output "Error: Neovim is not installed; expected Neovim >= $MIN_NEOVIM_VERSION"
        exit 1
    fi
    if ! version_ge "$version" "$MIN_NEOVIM_VERSION"; then
        console_output "Error: Neovim $version is below the required $MIN_NEOVIM_VERSION baseline"
        exit 1
    fi
    console_output "Verified Neovim $version"
}

console_output "Starting dotfiles setup..."

# Get current script directory and repo root
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Detect package manager
if command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
elif command -v apt-get &> /dev/null; then
    PKG_MGR="apt"
else
    console_output "Error: No supported package manager found (pacman/apt)."
    exit 1
fi

console_output "Using $PKG_MGR for package management."

# Install base dependencies. nvim-treesitter `main` builds parsers
# locally, so apt/pacman paths must ship a C toolchain plus `tree-sitter`
# / `curl` / `tar` (the Nix path covers these via nix/packages.nix).
APT_CORE_PKGS=(git vim ripgrep fd-find fzf locales fonts-noto-cjk build-essential curl tar)
APT_LOCALE_PKGS=()
if apt_is_ubuntu; then
    APT_LOCALE_PKGS=(language-pack-ko language-pack-ja)
fi

# Decide whether the distro neovim is recent enough; only fall back to the
# neovim-ppa/unstable PPA when the candidate is < 0.12.0 (or unknown) and the
# caller explicitly opts in.
ensure_neovim_repo() {
    local cand cand_stripped
    cand=$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/ {print $2; exit}')
    cand_stripped="${cand#*:}"  # drop dpkg epoch ("1:0.10.0-2" -> "0.10.0-2")
    if [ -n "$cand_stripped" ] && [ "$cand_stripped" != "(none)" ] \
       && dpkg --compare-versions "$cand_stripped" ge "$MIN_NEOVIM_VERSION"; then
        console_output "distro neovim ${cand} is >= $MIN_NEOVIM_VERSION; skipping PPA"
        return 0
    fi
    if ! apt_is_ubuntu; then
        console_output "Error: distro neovim candidate=${cand:-unknown} is < $MIN_NEOVIM_VERSION and the Ubuntu PPA fallback is unsupported on this distro; use the Nix installer or install Neovim $MIN_NEOVIM_VERSION+ manually"
        exit 1
    fi
    if [ "${ALLOW_NEOVIM_PPA:-0}" != "1" ]; then
        console_output "Error: distro neovim candidate=${cand:-unknown} is < $MIN_NEOVIM_VERSION; rerun with ALLOW_NEOVIM_PPA=1 to opt into ppa:neovim-ppa/unstable, or use the Nix installer"
        exit 1
    fi
    # This is an explicit third-party fallback for Ubuntu hosts whose distro
    # Neovim is too old; prefer distro packages whenever they meet the floor.
    console_output "distro neovim candidate=${cand:-unknown}; adding ppa:neovim-ppa/unstable"
    run_privileged apt-get install -y software-properties-common
    run_privileged add-apt-repository ppa:neovim-ppa/unstable -y
    run_privileged apt-get update
    cand=$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/ {print $2; exit}')
    cand_stripped="${cand#*:}"
    if [ -z "$cand_stripped" ] || [ "$cand_stripped" = "(none)" ] \
       || ! dpkg --compare-versions "$cand_stripped" ge "$MIN_NEOVIM_VERSION"; then
        console_output "Error: ppa:neovim-ppa/unstable did not provide Neovim >= $MIN_NEOVIM_VERSION on this host"
        exit 1
    fi
}

if [ "$PKG_MGR" = "pacman" ]; then
    run_privileged pacman -S --needed --noconfirm git vim neovim ripgrep fd fzf noto-fonts-cjk \
        base-devel tree-sitter tree-sitter-cli curl tar
elif [ "$PKG_MGR" = "apt" ]; then
    APT_NEOVIM_PKGS=()
    run_privileged apt-get update
    if nvim_version_ge_min; then
        console_output "existing Neovim $(current_nvim_version) is >= $MIN_NEOVIM_VERSION; skipping apt Neovim install"
    else
        ensure_neovim_repo
        APT_NEOVIM_PKGS=(neovim)
    fi
    run_privileged apt-get install -y "${APT_CORE_PKGS[@]}" "${APT_LOCALE_PKGS[@]}" "${APT_NEOVIM_PKGS[@]}"
    # `tree-sitter` (CLI) is only packaged on recent Ubuntu releases; if
    # the package is unavailable the parser build will fall back to
    # whatever the user installs via cargo / npm. Try once and do not
    # fail the bootstrap when it is missing.
    run_privileged apt-get install -y tree-sitter-cli >/dev/null 2>&1 \
        || console_output "tree-sitter-cli not in apt; install via 'cargo install tree-sitter-cli' or 'npm i -g tree-sitter-cli' for nvim-treesitter main"
fi

# Set locale for CJK support (without changing system language)
console_output "Setting up locales..."
if [ "$PKG_MGR" = "apt" ]; then
    run_privileged locale-gen en_US.UTF-8 ko_KR.UTF-8 ja_JP.UTF-8
fi
# Note: We keep LANG=en_US.UTF-8 for the system to avoid non-ASCII paths

# Symlink dotfiles
console_output "Linking configurations..."
mkdir -p "$TARGET_HOME/.config"
ln -sfn "$REPO_ROOT/config/nvim" "$TARGET_HOME/.config/nvim"
ln -sfn "$REPO_ROOT/home/.vimrc" "$TARGET_HOME/.vimrc"

# Add current user to docker group
if ! getent group docker > /dev/null; then
    run_privileged groupadd docker
fi
    run_privileged usermod -aG docker "$TARGET_USER"

require_supported_neovim

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
