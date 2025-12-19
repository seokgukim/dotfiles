{ config, pkgs, lib, ... }:

let
  # Ruby environment with bundler for gem management
  rubyEnv = pkgs.ruby.withPackages (ps: with ps; [
    ruby-lsp
    rubocop
  ]);
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "seokgukim";
  home.homeDirectory = "/home/seokgukim";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Essentials
    wget
    git
    vim
    neovim
    nushell
    ripgrep
    fd
    xclip
    
    # Languages & Runtimes
    python3
    rubyEnv  # Ruby with gems (ruby-lsp, rubocop)
    nodejs
    gcc
    gnumake
    pkg-config  # Needed for native gem extensions
    
    # Libraries (often needed for building native extensions)
    openssl
    openssl.dev
    readline
    zlib
    autoconf
    bison
    ncurses
    libffi
    gdbm
    libyaml  # Required for psych gem

    # Tools
    docker
    zellij
    zoxide
    yazi
    uutils-coreutils
    lazygit
    jujutsu  # Provides 'jj' command - do NOT install 'jj' package (same thing, causes conflict)
    lazydocker
    harlequin
    btop
    fzf

    # LSPs & Formatters
    nodePackages.typescript-language-server
    vscode-langservers-extracted
    nodePackages.bash-language-server
    pyright
    nodePackages.prettier
    nodePackages.eslint
    black
    isort
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # Symlink .vimrc
    ".vimrc".source = ./vim/.vimrc;

    # Symlink nvim config recursively
    ".config/nvim".source = ./nvim;
    
    # SSH Config (Basic)
    ".ssh/config".text = ''
      Host github.com
        HostName github.com
        User git
        AddKeysToAgent yes
        IdentityFile ~/.ssh/seokgukim.pem
        IdentitiesOnly yes
    '';
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    # Ruby gem native extension build support
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig:${pkgs.libyaml.dev}/lib/pkgconfig";
    # Ensure gem can find headers
    CPATH = "${pkgs.openssl.dev}/include:${pkgs.zlib.dev}/include:${pkgs.libyaml}/include";
    LIBRARY_PATH = "${pkgs.openssl.out}/lib:${pkgs.zlib}/lib:${pkgs.libyaml}/lib";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Shell configuration
  programs.bash = {
    enable = true;
    initExtra = ''
      # Source Nix
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      elif [ -f ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
      fi
    '';
  };
}
