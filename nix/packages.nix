{ pkgs ? import <nixpkgs> { } }:

let
  nodejs = pkgs.nodejs_22 or pkgs.nodejs;
in
pkgs.buildEnv {
  name = "seokgukim-dotfiles-tools";

  paths = with pkgs; [
    black
    clang-tools
    curl
    fd
    fzf
    gcc
    git
    gnumake
    gnutar
    isort
    jq
    lazygit
    lua-language-server
    neovim
    nil
    nixpkgs-fmt
    nodejs
    bash-language-server
    prettier
    pyright
    tree-sitter
    typescript
    typescript-language-server
    vscode-langservers-extracted
    nushell
    ripgrep
    ruby
    rubyPackages.rubocop
    rubyPackages."ruby-lsp"
    shfmt
    stylua
    vim
    zellij
  ];
}
