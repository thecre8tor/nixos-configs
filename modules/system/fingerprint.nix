# Fingerprint configuration
{ config, lib, pkgs, ... }:

{
  services.fprintd.enable = true;

  # Synaptics 06cb:00f0 doesn't wake reliably from USB runtime suspend.
  # Without this, the kernel resets the device on every access, fprintd
  # spawns a new D-Bus device object per reset without retiring the old
  # ones, and pam_fprintd picks stale objects at random — causing
  # intermittent fallback to password.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00f0", TEST=="power/control", ATTR{power/control}="on"
  '';

  security.pam.services = {
    # For sudo authentication
    sudo.fprintAuth = lib.mkForce true;

    # Deliberately NOT set here:
    #
    #   login.fprintAuth — /etc/pam.d/gdm-password is `auth substack login`,
    #   so this puts pam_fprintd at the top of the greeter's *password* stack.
    #   PAM then blocks on a swipe and GDM keeps the password field disabled
    #   until it returns, making password login impossible at the greeter.
    #
    #   gdm.fprintAuth — /etc/pam.d/gdm is the legacy stack; user logins go
    #   through gdm-password / gdm-fingerprint instead, so it does nothing.
    #
    # GDM fingerprint login needs no config: services.fprintd.enable already
    # generates the separate gdm-fingerprint stack that GNOME offers alongside
    # the password prompt.
  };
}


