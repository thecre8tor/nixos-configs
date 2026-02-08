# System services configuration
{ config, lib, pkgs, ... }:

{
  # Enable CUPS to print documents
  # services.printing.enable = true;

  # Enable Flatpak
  services.flatpak.enable = true;

  # Add Flathub repository declaratively
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Install DBeaver from Flathub
  systemd.services.flatpak-dbeaver = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-repo.service" ];
    requires = [ "flatpak-repo.service" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak install -y flathub io.dbeaver.DBeaverCommunity
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Install Spotify from Flathub
  systemd.services.flatpak-spotify = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-repo.service" ];
    requires = [ "flatpak-repo.service" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak install -y flathub com.spotify.Client
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

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
