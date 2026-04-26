#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '[seokgukim_nix_setup|%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PACKAGES_FILE="$REPO_ROOT/nix/packages.nix"
DRY_RUN=0
NIX_INSTALL_MODE="${NIX_INSTALL_MODE:-auto}"

if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
elif [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    printf 'Usage: %s [--dry-run]\n' "$0"
    printf '\nEnvironment:\n'
    printf '  NIX_INSTALL_MODE=auto|daemon|no-daemon  Installer mode when Nix is missing\n'
    printf '                                          (default: auto = daemon on Linux+systemd+sudo, otherwise no-daemon)\n'
    exit 0
elif [ "${1:-}" != "" ]; then
    log "Error: unknown option: $1"
    exit 1
fi

case "$NIX_INSTALL_MODE" in
    auto | no-daemon | daemon) ;;
    *)
        log "Error: NIX_INSTALL_MODE must be one of 'auto', 'no-daemon', 'daemon'"
        exit 1
        ;;
esac

has_systemd() {
    [ -d /run/systemd/system ]
}

can_sudo() {
    [ "$(id -u)" -eq 0 ] && return 0
    command -v sudo >/dev/null 2>&1 || return 1
    sudo -n true >/dev/null 2>&1 || sudo -v >/dev/null 2>&1
}

require_installer_prereqs() {
    if ! command -v curl >/dev/null 2>&1; then
        log "Error: curl is required to download the official Nix installer"
        exit 1
    fi
    if ! command -v xz >/dev/null 2>&1 && ! command -v unxz >/dev/null 2>&1; then
        log "Error: xz-utils (or a compatible xz/unxz command) is required by the official Nix installer"
        exit 1
    fi
}

resolve_install_mode() {
    if [ "$NIX_INSTALL_MODE" != auto ]; then
        printf '%s\n' "$NIX_INSTALL_MODE"
        return
    fi

    if [ "$(uname -s)" = "Linux" ] && has_systemd && can_sudo; then
        printf 'daemon\n'
    else
        printf 'no-daemon\n'
    fi
}

load_nix_profile() {
    for profile in \
        "$HOME/.nix-profile/etc/profile.d/nix.sh" \
        "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    do
        if [ -r "$profile" ]; then
            # shellcheck disable=SC1090
            . "$profile"
        fi
    done
    # PATH may now expose a freshly-installed `nix`; drop the cached
    # capability probe so subsequent calls re-detect the new CLI.
    unset _HAS_NEW_NIX_CLI
}

# Run a command using new-style `nix` if available, otherwise fall back.
# Probe the actual subcommand we need rather than just `command -v nix`,
# so locked-down builds without `nix-command`/`flakes` correctly fall back
# to `nix-env`.
have_new_nix_cli() {
    if [ -n "${_HAS_NEW_NIX_CLI:-}" ]; then
        [ "$_HAS_NEW_NIX_CLI" = 1 ]
        return
    fi
    if command -v nix >/dev/null 2>&1 \
       && nix --extra-experimental-features nix-command profile list >/dev/null 2>&1; then
        _HAS_NEW_NIX_CLI=1
    else
        _HAS_NEW_NIX_CLI=0
    fi
    [ "$_HAS_NEW_NIX_CLI" = 1 ]
}

nix_profile_add() {
    if nix --extra-experimental-features nix-command profile add --help >/dev/null 2>&1; then
        nix --extra-experimental-features nix-command profile add --file "$PACKAGES_FILE"
    else
        # Older new-style Nix releases exposed this operation as `install`.
        nix --extra-experimental-features nix-command profile install --file "$PACKAGES_FILE"
    fi
}

if [ ! -f "$PACKAGES_FILE" ]; then
    log "Error: $PACKAGES_FILE not found"
    exit 1
fi

load_nix_profile

if [ "$DRY_RUN" -eq 1 ]; then
    if ! command -v nix-env >/dev/null 2>&1 && ! have_new_nix_cli; then
        log "Error: neither new-style 'nix' nor 'nix-env' is available; install Nix before running --dry-run validation"
        exit 1
    fi

    log "Dry-run checking tool index from nix/packages.nix"
    # `nix profile add` has no --dry-run flag, so use `nix build --dry-run`
    # against the same file expression, falling back to legacy nix-env.
    if have_new_nix_cli; then
        nix --extra-experimental-features nix-command \
            build --dry-run --file "$PACKAGES_FILE" --no-link
    else
        nix-env -if "$PACKAGES_FILE" --dry-run
    fi
    log "Dry-run validation completed"
    exit 0
fi

if ! command -v nix-env >/dev/null 2>&1 && ! have_new_nix_cli; then
    INSTALL_MODE="$(resolve_install_mode)"
    log "Nix not found; installing with the official installer (--$INSTALL_MODE)"
    require_installer_prereqs
    curl -L https://nixos.org/nix/install | sh -s -- "--$INSTALL_MODE"
    load_nix_profile
fi

if ! command -v nix-env >/dev/null 2>&1 && ! have_new_nix_cli; then
    log "Error: 'nix' / 'nix-env' is still unavailable after loading the Nix profile"
    exit 1
fi

log "Installing tool index from nix/packages.nix"
# Prefer the new-style `nix profile add` and fall back to `nix-env -if` for
# environments without the new CLI.
if have_new_nix_cli; then
    nix_profile_add
else
    nix-env -if "$PACKAGES_FILE"
fi

log "Linking editor configurations"
mkdir -p "$HOME/.config"
ln -sfn "$REPO_ROOT/config/nvim" "$HOME/.config/nvim"
ln -sfn "$REPO_ROOT/home/.vimrc" "$HOME/.vimrc"

if command -v nu >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/nushell"
    if [ ! -f "$HOME/.config/nushell/config.nu" ]; then
        printf '$env.EDITOR = "nvim"\n$env.VISUAL = "nvim"\n' > "$HOME/.config/nushell/config.nu"
    fi
fi

log "Nix-based setup completed"
