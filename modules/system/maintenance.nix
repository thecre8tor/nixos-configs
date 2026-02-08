# System maintenance and updates configuration
{ config, lib, pkgs, ... }:

{
  # Automatic updating
  system.autoUpgrade.enable = true;
  system.autoUpgrade.dates = "weekly";

  # Automatic cleanup
  nix.gc.automatic = true;
  nix.gc.dates = "daily";
  nix.gc.options = "--delete-older-than 10d";

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
}
