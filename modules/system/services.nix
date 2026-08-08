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

  # On critical battery, power off rather than attempt a hibernate that cannot
  # work on this machine.
  #
  # upower's criticalPowerAction defaults to "HybridSleep" in nixpkgs, and that
  # default fired on 2026-08-05 at 04:08: logind logged `hybrid-sleep requested
  # from client PID 2166 ('upowerd')`, the journal ends there, and the session
  # was lost. It could never have succeeded — hibernation is not set up here
  # (no boot.resumeDevice, no resume= on the cmdline) and the 4G swap partition
  # cannot hold a 15G image in any case. See the hibernation note in
  # memory-pressure.nix.
  #
  # nixpkgs only guards "Suspend" and "Ignore" behind
  # allowRiskyCriticalPowerAction, because Hibernate/HybridSleep are normally
  # safe — they just are not safe *here*. So the stock default is the bug.
  #
  # PowerOff loses unsaved work too, but it does so predictably at a known
  # threshold instead of hanging with the battery still draining. If
  # hibernation is ever set up properly (needs a swap device >= RAM, which
  # means repartitioning — / is 89% full), revisit this and set it back to
  # HybridSleep, which is the better behaviour when it actually works.
  services.upower.criticalPowerAction = "PowerOff";

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
