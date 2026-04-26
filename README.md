# :diamond_shape_with_a_dot_inside: SeokguKim's dotfiles

Personal dotfiles, centered on **Neovim 0.12+**, **Nix**, and **Snacks**.

![Symbol_SeokguKim](https://github.com/SeokguKim/dotfiles/assets/43718966/0181c5a0-2258-4166-aea7-de9b61c296de)

## Quick install

```bash
git clone https://github.com/seokgukim/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/install-nix.sh
```

This installs the Nix tool index from `nix/packages.nix` and symlinks
`config/nvim/` and `home/.vimrc` into place.

## Documentation

- [Installation](docs/installation.md) — Nix, legacy apt/pacman, Windows, dry-run validation
- [Repository structure](docs/structure.md) — directory layout and Neovim file responsibilities
- [Neovim configuration](docs/neovim.md) — features, plugin audit, language support
- [Post-installation](docs/post-install.md) — verification, Nix profile maintenance, health checks, Copilot, troubleshooting

## License

See [LICENSE](LICENSE).
