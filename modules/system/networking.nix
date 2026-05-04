# Network configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui
  networking.networkmanager.enable = true;

  # Improves the wifi speed
  networking.networkmanager.wifi.powersave = false;

  # Allow and install proprietary (non-open-source) firmware needed for hardware to work properly.
  hardware.enableRedistributableFirmware = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether
  # networking.firewall.enable = false;
}
