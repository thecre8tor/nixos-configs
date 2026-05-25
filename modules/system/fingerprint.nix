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
    login.fprintAuth = lib.mkForce true;
    # For sudo authentication
    sudo.fprintAuth = lib.mkForce true;
    # For display manager (if using GDM, SDDM, etc.)
    gdm.fprintAuth = lib.mkForce true;
  };
}


