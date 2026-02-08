{ config, pkgs, ... }:

let
  # dotfiles = "${config.home.homeDirectory}/nixos-configs/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

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
  programs.git.enable = true;
  home.stateVersion = "25.05";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo I use nixos, btw";
    };
  };

  # xdg.configFile = builtins.mapAttrs (name: subpath: {
  #   source = create_symlink "${dotfiles}/${subpath}";
  #   recursive = true;
  # }) configs;

  programs.git = {
    userName = "Alexander Nitiola";
    userEmail = "cre8tor.alexander@gmail.com";

    # other settings...
    extraConfig = {
      init.defaultBranch = "main";   # equivalent to git config --global init.defaultBranch main
      pull.rebase       = false;   # equivalent to git config --global pull.rebase false
    };
  };

  programs.zsh = {
    enable = true;
    plugins = [
      {
        name = "spaceship";
        src = pkgs.spaceship-prompt;
        file = "share/zsh/site-functions/prompt_spaceship_setup";
      }
    ];
  };
  
  home.packages = with pkgs; [
    neovim
    ripgrep
    nil
    nixpkgs-fmt
    nodejs
    gcc
    # rofi
    postman
  ];
}
