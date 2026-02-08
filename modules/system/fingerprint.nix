# Fingerprint configuration
{ config, lib, pkgs, ... }:

{
  services.fprintd.enable = true;
  
  security.pam.services = {
    login.fprintAuth = lib.mkForce true;
    # For sudo authentication
    sudo.fprintAuth = lib.mkForce true;
    # For display manager (if using GDM, SDDM, etc.)
    gdm.fprintAuth = lib.mkForce true;
  };
}


