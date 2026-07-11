# Boot configuration
{ config, lib, pkgs, ... }:

{
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Cezanne s2idle wake failure workaround.
  #
  # The amdgpu DMUB firmware on Cezanne APUs fails to resume reliably from
  # s2idle — display stays black on wake, requiring a hard reboot. Original
  # workaround was to force deep S3 (mem_sleep_default=deep), which worked
  # until BIOS T82 01.22.00 (2025-09-15) stopped advertising S3 entirely
  # (`ACPI: PM: (supports S0 S4 S5)`) and HP removed the setup toggle. That
  # param is kept in case a future firmware re-exposes S3.
  #
  # Fallback: amdgpu.dcdebugmask=0x10 = DC_DISABLE_PSR (verified against
  # v6.18 drivers/gpu/drm/amd/include/amd_shared.h) — disables Panel Self
  # Refresh, the feature most commonly implicated in the wake bug. Small
  # power cost, no visible impact.
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "amdgpu.dcdebugmask=0x10"
  ];
}
