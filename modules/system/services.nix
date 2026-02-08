# System services configuration
{ config, lib, pkgs, ... }:

{
  # Enable CUPS to print documents
  # services.printing.enable = true;

  # Enable Flatpak
  services.flatpak.enable = true;

  # Set up Flatpak repository and install apps using system activation script
  # This runs after the system is fully up, avoiding boot-time failures
  system.activationScripts.flatpak-setup = lib.stringAfter [ "etc" ] ''
    # Add Flathub repository if not already added
    if ! ${pkgs.flatpak}/bin/flatpak remotes | grep -q flathub; then
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    # Install DBeaver if not already installed (runs in background to not block boot)
    if ! ${pkgs.flatpak}/bin/flatpak list | grep -q io.dbeaver.DBeaverCommunity; then
      (${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub io.dbeaver.DBeaverCommunity &)
    fi
    
    # Install Spotify if not already installed (runs in background to not block boot)
    if ! ${pkgs.flatpak}/bin/flatpak list | grep -q com.spotify.Client; then
      (${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub com.spotify.Client &)
    fi
  '';

  # Enable the OpenSSH daemon
  # services.openssh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}

