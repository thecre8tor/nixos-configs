# Virtualization configuration
{ config, lib, pkgs, ... }:

{
  # Enable Docker
  virtualisation.docker.enable = true;
}
