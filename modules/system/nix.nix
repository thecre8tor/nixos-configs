# Nix-specific configuration
{ config, lib, pkgs, ... }:

{
  # Enable experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable store optimization
  nix.settings.auto-optimise-store = true;
}
