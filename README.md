# :diamond_shape_with_a_dot_inside: SeokguKim's dotfiles

Personal dotfiles, centered on **Neovim 0.12+**, **Nix**, and **Snacks**.

![Symbol_SeokguKim](https://github.com/SeokguKim/dotfiles/assets/43718966/0181c5a0-2258-4166-aea7-de9b61c296de)

## Quick install

```bash
git clone https://github.com/seokgukim/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/install-nix.sh
```

This installs the Nix tool index from `nix/packages.nix` and symlinks
`config/nvim/` and `home/unix/.vimrc` into place.

## Documentation

- [Installation](docs/installation.md) — Nix, legacy apt/pacman/Homebrew, Windows, dry-run validation
- [Repository structure](docs/structure.md) — directory layout and Neovim file responsibilities
- [Neovim configuration](docs/neovim.md) — features, plugin audit, language support
- [Post-installation](docs/post-install.md) — verification, Nix profile maintenance, health checks, Copilot, troubleshooting

## Markdown to PDF

The cross-platform wrappers use the same Chromium-based rendering approach as
VS Code's Markdown PDF extension. Node.js/npm or a global `md-to-pdf` install is
required. Run them only with Markdown files you trust because embedded HTML is
rendered by the browser.

```bash
bash ./scripts/markdown-to-pdf.sh README.md
bash ./scripts/markdown-to-pdf.sh README.md build/readme.pdf
```

```powershell
.\scripts\markdown-to-pdf.ps1 README.md
.\scripts\markdown-to-pdf.ps1 README.md build\readme.pdf
```

## License

See [LICENSE](LICENSE).
