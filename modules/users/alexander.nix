 # User configuration for alexander
{ config, lib, pkgs, ... }:

{
  # Define user account
  users.users.alexander = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel"   # Enable 'sudo' for the user
      "docker"  # Docker access
      "git"     # Git access
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
    ];
  };
}
