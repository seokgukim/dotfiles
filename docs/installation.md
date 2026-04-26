# Installation

## Recommended: Nix-based user install

Clone the repository and run the Nix installer as your normal user:

```bash
git clone https://github.com/seokgukim/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/install-nix.sh
```

The installer:

- Installs the tool index from `nix/packages.nix` using
  `nix profile add --file` (preferred), falling back to `nix-env -if`
  on installations without the new-style `nix` CLI.
- Symlinks `config/nvim/` to `~/.config/nvim`
- Symlinks `home/.vimrc` to `~/.vimrc`

By default, the script picks the installer mode automatically
(`NIX_INSTALL_MODE=auto`): on Linux hosts with systemd and sudo it uses the
multi-user `--daemon` installer, otherwise it falls back to `--no-daemon`.
Override explicitly when needed:

```bash
NIX_INSTALL_MODE=daemon    bash ~/dotfiles/scripts/install-nix.sh
NIX_INSTALL_MODE=no-daemon bash ~/dotfiles/scripts/install-nix.sh
```

The official installer may require `xz-utils` (or a compatible `xz`/`unxz`
command) to unpack the downloaded tarball. `scripts/install-nix.sh` checks this
before it starts a new Nix install.

### Validation without installing

Validate the Nix index without touching the system. This requires a working
`nix` (or legacy `nix-env`) on PATH:

```bash
bash ~/dotfiles/scripts/install-nix.sh --dry-run
```

Build the package index as a Nix derivation:

```bash
nix-build ~/dotfiles/nix
```

Run the same validation in Docker:

```bash
docker run --rm -v "$PWD":/work -w /work nixos/nix \
  sh -lc 'nix-instantiate --parse nix/packages.nix >/dev/null && \
          nix --extra-experimental-features nix-command \
              build --dry-run --file nix/packages.nix --no-link'
```

> This is a non-flake Nix flow. A `flake.nix` is intentionally not committed:
> this dotfiles is consumed on
> hosts that may not have the `nix-command`/`flakes` experimental features
> enabled, and a self-generated `flake.lock` would create a soft pin that the
> non-flake `nix profile add --file` path doesn't need. Flakes can be
> introduced in a follow-up once a target environment is fixed.
> The script enables `nix-command` per invocation only to use the new `nix`
> CLI; it does not enable or require flakes.

The Nix index includes Neovim, Nushell, ripgrep, fd, fzf, lazygit, zellij,
language servers, and formatters used by this Neovim config. GitHub Copilot
authentication still needs to be completed in Neovim with `:Copilot setup`.

### Scope compared with common Nix repositories

This repository intentionally keeps a small Nix surface: one user-profile tool
bundle plus symlinks for editor configuration.

| Reference | Typical flow | How this dotfiles differs |
| --- | --- | --- |
| `NixOS/nixpkgs` | Package collection, NixOS modules, Hydra-built binary cache | Consumes packages from nixpkgs; does not define system modules |
| `NixOS/templates` | `nix flake init --template ...` for new projects | Not used; this repository intentionally stays non-flake for now |
| `nix-community/home-manager` | Declarative user packages and dotfiles | Uses simple symlinks instead of Home Manager generations |
| `nix-darwin/nix-darwin` | Declarative macOS system configuration | Windows/macOS handling stays installer-level, not system-level |
| `cachix/devenv` | Per-project developer shells, services, tasks, tests | Provides global editor/dev tools, not project-local services |
| `DeterminateSystems/nix-installer` | Alternative installer with plans and uninstall support | Uses the upstream official installer by default |

If this repository grows beyond editor/dev-tool bootstrap, prefer adding a
separate RFC before introducing a flake, Home Manager, nix-darwin, or devenv.

### Long-term flake direction

Long term, a flake is the right direction for reproducible CI and fresh-machine
bootstrap because it can pin nixpkgs in `flake.lock` and expose standard outputs
such as `packages`, `devShells`, `formatter`, and `checks`. The recommended
migration path is additive, not a hard cutover:

1. Keep `nix/packages.nix` as the canonical tool list.
2. Add `flake.nix` as a thin wrapper around `nix/packages.nix`.
3. Keep the current non-flake installer path for hosts without flakes enabled.
4. Move CI smoke checks to flake outputs only after the fallback path is proven.

Do not introduce Home Manager, nix-darwin, or devenv as part of the initial
flake step; those are separate scope expansions.

## Legacy: distro package manager install

For systems without Nix, the legacy script installs a smaller base tool set
through apt or pacman. It requires root.

```bash
git clone https://github.com/seokgukim/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo bash scripts/setup.sh
```

The script will:

- Install essential packages through apt or pacman:
  - **pacman**: `base-devel`, `tree-sitter`, `tree-sitter-cli`, `curl`,
    `tar` so `nvim-treesitter` `main` can build parsers locally.
  - **apt**: `build-essential`, `curl`, `tar` (always); `tree-sitter-cli`
    is best-effort because it is only packaged on recent Ubuntu / Debian
    releases. When apt cannot find it the script logs a hint to install
    it via `cargo install tree-sitter-cli` or `npm i -g tree-sitter-cli`.
- For apt: prefer the distro `neovim` package when its candidate version is
  `>= 0.12.0`; otherwise add `ppa:neovim-ppa/unstable` automatically
- Symlink Neovim config to `~/.config/nvim` and Vim config to `~/.vimrc`
- Add the user to the `docker` group

## Windows

```bat
git clone https://github.com/seokgukim/dotfiles.git %USERPROFILE%\dotfiles
%USERPROFILE%\dotfiles\scripts\windows-setup.bat
```

The Windows script uses `winget` to install Neovim and Nushell, then links the
canonical `config/nvim/` directory into `%LOCALAPPDATA%\nvim`.

## Requirements

- Linux system with Nix, or apt/pacman for the legacy script
- Root access only for the legacy script
- Internet connection for downloading dependencies
