# Fingerprint configuration
{ config, lib, pkgs, ... }:

{
  services.fprintd.enable = true;
  
  security.pam.services = {
    login.fprintAuth = true;
    # For sudo authentication
    sudo.fprintAuth = true;
    # For display manager (if using GDM, SDDM, etc.)
    gdm.fprintAuth = true;  # or sddm, lightdm, etc.
  };
}


