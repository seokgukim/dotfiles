# Post-Installation

After running an installer, complete the setup as follows.

## 1. Refresh your environment

Open a new terminal session first. If you need to refresh the current shell,
source the Nix profile script that exists for your installation mode, then
reload your regular shell profile:

```bash
if [ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
source $HOME/.bashrc
# Or start Nushell now:
nu
```

## 2. Verify tool installation

```bash
node --version
npm --version
nvim --version
rg --version
fd --version
lazygit --version
```

## 3. Initialize Neovim

```bash
nvim
```

lazy.nvim installs all configured plugins on first launch. Wait for it to
finish, then exit with `:q`.

## 4. Health check

```bash
nvim -c ':checkhealth'
```

Inspect `:checkhealth lsp` to verify which language servers attached.

### Headless verification (optional)

```bash
nvim --headless '+Lazy! sync' +qa
# nvim-treesitter `main` installs parsers asynchronously. In automation,
# wait for the install to settle before running parser-aware healthchecks:
nvim --headless "+lua require('nvim-treesitter').install({ 'lua', 'vim', 'vimdoc' }):wait(300000)" +qa
nvim --headless '+checkhealth nvim-treesitter' +qa
nvim --headless '+checkhealth snacks' +qa
```

## 5. Configure GitHub Copilot (optional)

```bash
nvim -c ':Copilot setup'
```

Copilot is disabled by default and can be toggled in Neovim with
`<leader><F1>`.

## 6. Docker group access (legacy setup only)

For Docker commands to work without sudo, log out and back in, or run:

```bash
newgrp docker
```

## 7. Nix profile maintenance

The Nix-based installer adds one profile entry for `nix/packages.nix`. Inspect
profile generations before cleaning them so rollback stays available:

These commands use the new `nix` CLI via `nix-command`; this repository still
uses a non-flake `nix/packages.nix` expression.

```bash
nix --extra-experimental-features nix-command profile list
nix --extra-experimental-features nix-command profile history
nix --extra-experimental-features nix-command profile rollback --dry-run
```

If the current generation is broken, roll back to the previous one:

```bash
nix --extra-experimental-features nix-command profile rollback
```

Only delete older generations when you no longer need to roll back to them:

```bash
nix --extra-experimental-features nix-command profile wipe-history --dry-run --older-than 14d
nix --extra-experimental-features nix-command profile wipe-history --older-than 14d
```

Then check and collect unreachable store paths:

```bash
nix-store --gc --print-dead
nix-store --gc
```

On multi-user daemon installs, store GC and old-generation deletion may affect
more than the current shell session. If permissions fail or the machine is
shared, review the daemon policy and prefer dry-run/history commands before
deleting generations.

On legacy `nix-env` profiles, use the equivalent generation flow:

```bash
nix-env --list-generations
nix-env --rollback
nix-env --delete-generations 14d
nix-store --gc
```

## Troubleshooting

| Symptom | Try |
| --- | --- |
| Language servers not attaching | `:checkhealth lsp` |
| Docker permission denied | `groups` to confirm `docker` membership |
| Plugins not loading | Remove `~/.local/share/nvim` and relaunch |
| Treesitter highlight errors | `:TSUpdate` |
| Nix installer cannot unpack the download | Install `xz-utils` or provide a compatible `xz` / `unxz` command |
| New-style profile conflicts with `nix-env` | Continue using `nix profile`; Nix marks profiles created by the new CLI as incompatible with `nix-env` |
