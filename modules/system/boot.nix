# Boot configuration
{ config, lib, pkgs, ... }:

let
  # TEMPORARY DEBUGGING TOGGLE — flip to true to hunt the s2idle wake hang
  # documented below, and back to false once a magic number has been captured.
  #
  # pm_trace writes a hash of the last-executed device resume callback into the
  # RTC, where it survives a hard power cycle. That is the only way to identify
  # this particular failure: the hang leaves nothing in the journal, which stops
  # mid-line with no flush, so amd-s2idle (see packages.nix) reports beautifully
  # on every successful cycle and says nothing at all about the one that broke.
  #
  # Procedure once enabled: use the machine normally. At ~26 suspends a day the
  # hang lands roughly every 2 days. When the screen stays black, hard power off,
  # boot, and *promptly* run:
  #
  #   sudo dmesg | grep -iA5 "Magic number"
  #   cat /sys/power/pm_trace_dev_match
  #
  # The output names the device whose resume callback hung — attach that to the
  # drm/amd gitlab report.
  #
  # Three caveats, all real:
  #   - It scrambles the system clock. Harmless here: systemd-timesyncd is
  #     active and synchronised, so the clock self-corrects after boot.
  #   - Read it promptly. The RTC keeps ticking and corrupts the value.
  #   - It disables asynchronous suspend. If the underlying bug is a timing
  #     race this may *hide* it — so a quiet week with this on is not a fix,
  #     it is evidence pointing at a race. Record that outcome rather than
  #     concluding the problem went away.
  # Enabled 2026-08-08 to hunt the wake hang. Turn back off once a magic number
  # has been captured — this is not a setting to leave on indefinitely.
  pmTraceDebugging = true;
in

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

  # Applies the toggle defined at the top of this file. Kept as tmpfiles rather
  # than a service so it is a single declarative line with nothing to order;
  # /sys is mounted well before systemd-tmpfiles-setup runs, and pm_trace is a
  # persistent flag, so writing it once at boot covers every later suspend.
  systemd.tmpfiles.rules = lib.mkIf pmTraceDebugging [
    "w /sys/power/pm_trace - - - - 1"
  ];
}
