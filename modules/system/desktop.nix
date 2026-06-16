# Desktop environment configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable the X11 windowing system
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;

    # windowManager.qtile.enable = true;
  };

  # GNOME Desktop Setup
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Sway Desktop Enviroment
  # programs.sway.enable = true;

  # Recommended extra for Sway
  # security.polkit.enable = true;
  # services.dbus.enable = true;
  # programs.light.enable = true;

  # Alternative display manager
  # services.displayManager.ly.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable touchpad support (enabled default in most desktopManager)
  # services.libinput.enable = true;
}
