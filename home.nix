{ config, pkgs, ... }:

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
    ruby
    nodejs
    gcc
    gnumake
    
    # Libraries (often needed for building native extensions)
    openssl
    readline
    zlib
    autoconf
    bison
    ncurses
    libffi
    gdbm

    # Tools
    docker
    zellij
    zoxide
    yazi
    uutils-coreutils
    lazygit
    jujutsu
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
    ruby-lsp
    rubocop
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

      # Launch Nushell if available
      if command -v nu >/dev/null 2>&1; then
          exec nu
      fi
    '';
  };
}
