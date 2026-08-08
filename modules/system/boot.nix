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
  # Fallback is amdgpu.dcdebugmask, a bitmask of DC_DEBUG_MASK. Values verified
  # against v6.18 drivers/gpu/drm/amd/include/amd_shared.h:
  #
  #   DC_DISABLE_PSR     = 0x10   Panel Self Refresh (v1 and PSR-SU)
  #   DC_DISABLE_STUTTER = 0x2    stutter/MALL memory self-refresh
  #
  # 0x10 alone was applied 2026-07-11 and measurably helped but did not cure it.
  # Measured 2026-08-08 over the journal since 2026-07-28: 292 `PM: suspend
  # entry (s2idle)` against 287 `Restarting tasks: Done` — 5 hard hangs, ~1.7%,
  # about 1 wake in 60. So 0x2 is added here as the next candidate.
  #
  # DC_DISABLE_IPS (0x800) was considered and rejected: this APU reports
  # `Display Core v3.2.351 initialized on DCN 2.1`, and Idle Power States only
  # exist on DCN 3.5 and newer, so 0x810 would have been identical to 0x10.
  # Check the DCN version in the boot log before reaching for IPS bits here.
  #
  # Both bits cost a little idle power and neither is visible in use. If hangs
  # persist, the next things to try are amdgpu.abmlevel=0 and amdgpu.runpm=0,
  # which are separate params rather than more dcdebugmask bits — the remaining
  # DC_DEBUG_MASK entries are either DCN3.5+ only or unrelated to wake.
  #
  # Verify a change took effect with:
  #   cat /sys/module/amdgpu/parameters/dcdebugmask
  # and re-measure the ratio above rather than trusting a handful of good wakes;
  # at ~1 in 60 the failure hides easily in a small sample.
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "amdgpu.dcdebugmask=0x12"
  ];
}
