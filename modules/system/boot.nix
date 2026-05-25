# Boot configuration
{ config, lib, pkgs, ... }:

{
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use deep S3 sleep instead of s2idle. The amdgpu DMUB firmware on Cezanne
  # APUs fails to resume reliably from s2idle, especially after an external
  # monitor has been attached — display stays black on wake. Deep sleep
  # bypasses the broken path.
  boot.kernelParams = [ "mem_sleep_default=deep" ];
}
