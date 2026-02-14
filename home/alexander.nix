# Home Manager configuration for alexander
{ config, pkgs, ... }:

let
  # dotfiles = "${config.home.homeDirectory}/nixos-configs/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Uncomment and configure when you want to use dotfiles
  configs = {
    # qtile = "qtile";
    # nvim = "nvim";
    # alacritty = "alacritty";
    # rofi = "rofi";
  };
in

{
  home.username = "alexander";
  home.homeDirectory = "/home/alexander";
  home.stateVersion = "25.05";

  # Enable Git
  programs.git = {
    enable = true;
    userName = "Alexander Nitiola";
    userEmail = "cre8tor.alexander@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";   # equivalent to git config --global init.defaultBranch main
      pull.rebase = false;            # equivalent to git config --global pull.rebase false
    };
  };

  # Enable and configure Zsh
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;    
    plugins = [
      {
        name = "spaceship";
        src = pkgs.spaceship-prompt;
        file = "share/zsh/site-functions/prompt_spaceship_setup";
      }
    ];
    initContent = ''
      autoload -Uz compinit
      compinit

      SPACESHIP_PROMPT_ADD_NEWLINE=true
      SPACESHIP_RUST_SHOW=true

      # Better history search: up/down only search commands starting with typed text
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward
    '';
  };

  # User packages
  home.packages = with pkgs; [
    neovim
    ripgrep
    nil
    nixpkgs-fmt
    nodejs
    gcc
    postman
    lmstudio
    zstd
    jq
    antares
    # rofi
  ];

  # XDG config files - uncomment when ready to use
  # xdg.configFile = builtins.mapAttrs (name: subpath: {
  #   source = create_symlink "${dotfiles}/${subpath}";
  #   recursive = true;
  # }) configs;
}

