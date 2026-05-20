# Network configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.hostName = "nixos"; # Define your hostname.

  # NetworkManager with its default wpa_supplicant backend (works reliably
  # with the Qualcomm ath11k_pci card; iwd does not).
  networking.networkmanager = {
    enable = true;

    # Disable driver-level wifi powersave — improves throughput and avoids
    # the brief dropouts that powersave causes on ath11k.
    wifi.powersave = false;

    # Don't randomize the MAC during scans. Some APs (notably MTN mobile
    # hotspots) treat the changing MAC as an unknown client and slow down
    # or refuse association.
    wifi.scanRandMacAddress = false;
  };

  # Allow and install proprietary (non-open-source) firmware needed for hardware to work properly.
  hardware.enableRedistributableFirmware = true;

  # ath11k_pci firmware does not recover cleanly through suspend — wifi stays
  # broken until the driver is reloaded. Stop NM so it releases the interface,
  # unload+reload the module, then bring NM back up.
  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl stop NetworkManager.service || true
    ${pkgs.kmod}/bin/modprobe -r ath11k_pci || true
    ${pkgs.kmod}/bin/modprobe ath11k_pci
    ${pkgs.systemd}/bin/systemctl start NetworkManager.service
  '';

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether
  # networking.firewall.enable = false;
}
