# Memory pressure handling
#
# Linux overcommits by default (vm.overcommit_memory = 0) and the kernel OOM
# killer only fires once reclaim has failed outright — by which point the
# desktop has already evicted its page cache and spent minutes thrashing swap.
# The kernel is optimising for "never kill unnecessarily", not for staying
# responsive.
#
# Nothing here changes overcommit. It adds the userspace layers that act
# *before* the kernel's last resort, plus a cap on the one local process most
# able to exhaust RAM on a NixOS machine.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # systemd-oomd is enabled by the NixOS default but supervises nothing: every
  # slice reports ManagedOOMMemoryPressure=auto ("not opted in"), so `oomctl`
  # lists zero monitored cgroups. Opting the user slices in was tried and
  # reverted — deliberately left off now.
  #
  # enableUserSlices = true was set 2026-08-06 on the assumption that "under
  # GNOME each application gets its own app-*.scope, so oomd kills the offending
  # app rather than the whole session". That assumption is false on this
  # machine. `oomctl` shows /user.slice holding 8.2G under real pressure
  # (Avg300 5.80, Pgscan 236M) while user@1000.service/app.slice holds 337.8M at
  # zero pressure — the browser, Electron apps and editor live under the shell's
  # own unit, not under app.slice. So the only substantial kill candidate inside
  # the monitored /user.slice is gnome-shell itself.
  #
  # The result was oomd killing org.gnome.Shell@user.service outright, taking
  # the entire desktop with it (457 processes in one event) and dropping the
  # user back to the GDM greeter. Twice on 2026-08-08, at 03:24 and 09:48. The
  # machine never rebooted — uptime was continuous — but it is indistinguishable
  # from a reboot in use.
  #
  # Scoping the kill to app.slice instead of user.slice would be a no-op here,
  # since app.slice is where the memory *isn't*. earlyoom below already covers
  # this case correctly, so oomd stays opted out until GNOME actually places
  # apps in their own scopes. Re-check with `oomctl` before re-enabling.
  #
  # enableSystemSlice and enableRootSlice remain off for the original reason:
  # there oomd would be free to kill system services, and on a laptop the
  # failure mode (losing NetworkManager or the display manager) is worse than
  # the stall.
  systemd.oomd.enableUserSlices = false;

  # With oomd opted out above, this is the only userspace layer acting before
  # the kernel OOM killer. It watches MemAvailable and free swap directly
  # rather than PSI stall ratios, and — the reason it is the one kept — it
  # SIGTERMs individual processes instead of whole cgroups, so a kill costs one
  # app rather than the session. Confirmed in practice: it took out single
  # electron and rust-analyzer processes on 2026-08-06 and 2026-08-07 with the
  # desktop left running.
  services.earlyoom = {
    enable = true;
    # Defaults: SIGTERM under 10% available memory, SIGKILL under 5%. On 15G
    # that is ~1.5G, which is late but not too late given zram below.
    enableNotifications = true;
  };

  # Compressed swap in RAM, zstd, 50% of memory at priority 5 — above the 4G
  # NVMe partition (priority -2), so it is used first. Roughly 2-3x compression
  # in practice, so it absorbs bursts that would otherwise mean disk thrashing.
  # The disk partition stays as the slower tier beneath it.
  #
  # This does not affect hibernation, which is not set up on this machine: no
  # boot.resumeDevice, no resume= on the kernel cmdline, and 4G of swap could
  # not hold 15G of RAM in any case. If it is ever wanted, the target has to be
  # the disk partition — a zram device cannot be resumed from.
  zramSwap.enable = true;

  # Local nix builds are the most common way to exhaust RAM here: max-jobs is
  # "auto" and cores is 0, so a rebuild can run one build per thread, each
  # using every core. Builds are children of nix-daemon and share its cgroup,
  # so this caps them in aggregate.
  #
  # MemoryHigh throttles first by forcing reclaim; MemoryMax is the hard stop,
  # where the cgroup OOM killer fails the build instead of the desktop. If a
  # genuinely large build (chromium, rust) starts dying here, raise MemoryMax
  # rather than removing it.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "8G";
    MemoryMax = "11G";
  };
}
