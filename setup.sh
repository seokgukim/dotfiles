#!/bin/bash

set -eu  # Exit on any error and undefined variables

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
    if [ "$(id -u)" -eq 0 ]; then
        console_output "Running multi-user Nix daemon installer (requires root)"
        curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes

        # Ensure daemon is running (for containers/non-systemd)
        if ! pgrep -x "nix-daemon" > /dev/null; then
             console_output "Nix daemon not running. Starting it in background..."
             # Source the profile to get nix-daemon in path or use absolute path
             if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
                 . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
             fi
             nix-daemon >/dev/null 2>&1 &
             
             # Wait for socket
             console_output "Waiting for Nix daemon socket..."
             for i in {1..10}; do
                 if [ -e /nix/var/nix/daemon-socket/socket ]; then break; fi
                 sleep 1
             done
        fi
    else
        su - "$TARGET_USER" -c 'curl -L https://nixos.org/nix/install | sh -s -- --yes'
    fi
fi

# Source Nix environment (Multi-user or Single-user)
if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
elif [ -f "/home/$TARGET_USER/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "/home/$TARGET_USER/.nix-profile/etc/profile.d/nix.sh"
fi

console_output "Using Nix for package management."

# Get the dotfiles repository from GitHub
if [ -d "$SCRIPT_DIR" ]; then
    console_output "Dotfiles directory already exists at $SCRIPT_DIR, skipping clone."
    console_output "The script may not work as intended if the repository is not up to date."
else
    console_output "Cloning dotfiles repository..."
    # Use system git to clone
    su -l "$TARGET_USER" -c "export SCRIPT_DIR='$SCRIPT_DIR'; git clone https://github.com/seokgukim/dotfiles.git \"\$SCRIPT_DIR\""
fi

# Configure Nix for Flakes
mkdir -p "$TARGET_HOME/.config/nix"
echo "experimental-features = nix-command flakes" >> "$TARGET_HOME/.config/nix/nix.conf"
chown -R "$TARGET_USER" "$TARGET_HOME/.config"

# Update username in Nix files to match current user
if [ "$TARGET_USER" != "seokgukim" ]; then
    console_output "Updating configuration for user: $TARGET_USER"
    sed -i "s/seokgukim/$TARGET_USER/g" "$SCRIPT_DIR/flake.nix"
    sed -i "s/seokgukim/$TARGET_USER/g" "$SCRIPT_DIR/home.nix"
fi

console_output "Applying Home Manager configuration..."
# We use 'nix run' to execute home-manager from the flake without installing it globally first
# Nix Flakes require files to be tracked by git.
su -l "$TARGET_USER" -c "cd '$SCRIPT_DIR' && git add . && nix --extra-experimental-features 'nix-command flakes' run home-manager/master -- switch --flake .#$TARGET_USER -b backup"

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
console_output "3. Run 'nvim' as $TARGET_USER to trigger lazy.nvim plugin installation"
console_output "4. In nvim, run ':checkhealth' to verify everything is working"
console_output ""
console_output "Note: Some plugins may require additional setup or dependencies."
