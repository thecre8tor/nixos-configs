# System services configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable CUPS to print documents
  # services.printing.enable = true;

  # Enable Flatpak
  services.flatpak.enable = true;

  # Enable VPN
  services.tailscale.enable = true;

  # Set up Flatpak repository and install apps using system activation script
  # This runs after the system is fully up, avoiding boot-time failures
  # system.activationScripts.flatpak-setup = lib.stringAfter [ "etc" ] ''
  #   # Add Flathub repository if not already added
  #   if ! ${pkgs.flatpak}/bin/flatpak remotes | grep -q flathub; then
  #     ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  #   fi

  #   # Install DBeaver if not already installed (runs in background to not block boot)
  #   if ! ${pkgs.flatpak}/bin/flatpak list | grep -q io.dbeaver.DBeaverCommunity; then
  #     (${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub io.dbeaver.DBeaverCommunity &)
  #   fi

  #   # Install Spotify if not already installed (runs in background to not block boot)
  #   if ! ${pkgs.flatpak}/bin/flatpak list | grep -q com.spotify.Client; then
  #     (${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub com.spotify.Client &)
  #   fi

  #   # Install Zen Browser if not already installed (runs in background to not block boot)
  #   if ! ${pkgs.flatpak}/bin/flatpak list | grep -q app.zen_browser.zen; then
  #     (${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub app.zen_browser.zen &)
  #   fi
  # '';

  # Critical-battery action. Set explicitly to HybridSleep — which is also the
  # nixpkgs default — so that it is a recorded decision rather than an
  # oversight, and so it survives any future change to that default.
  #
  # Known caveat: hibernation is not set up on this machine (no
  # boot.resumeDevice, no resume= on the cmdline) and the 4G swap partition
  # cannot hold a 15G image, so the hibernate half of hybrid-sleep cannot
  # currently succeed. This has already bitten once — on 2026-08-05 at 04:08
  # logind logged `hybrid-sleep requested from client PID 2166 ('upowerd')`,
  # the journal ends there, and the session was lost. See the hibernation note
  # in memory-pressure.nix.
  #
  # It was briefly switched to PowerOff on 2026-08-08 for that reason and then
  # switched back, deliberately: HybridSleep is the setting that preserves the
  # session once hibernation works, so it is left in place ready rather than
  # being something to remember later. Making it work needs a swap device >=
  # RAM, which means repartitioning — / is 89% full.
  #
  # nixpkgs only gates "Suspend" and "Ignore" behind
  # allowRiskyCriticalPowerAction; Hibernate and HybridSleep are assumed safe,
  # so nothing here will warn if this silently stops working.
  services.upower.criticalPowerAction = "HybridSleep";

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
