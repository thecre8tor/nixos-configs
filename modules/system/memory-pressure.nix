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
  # systemd-oomd is already enabled by the NixOS default, but every slice
  # reports ManagedOOMMemoryPressure=auto — "not opted in" — so `oomctl` showed
  # zero monitored cgroups: the daemon ran and supervised nothing. This opts
  # the user slices in, which is what makes it act.
  #
  # Under GNOME each application gets its own app-*.scope, so oomd kills the
  # offending app rather than the whole session.
  #
  # enableSystemSlice and enableRootSlice are deliberately left off: there oomd
  # would be free to kill system services, and on a laptop the failure mode
  # (losing NetworkManager or the display manager) is worse than the stall.
  systemd.oomd.enableUserSlices = true;

  # Second line of defence, on a different signal. oomd triggers on PSI stall
  # ratios; earlyoom watches MemAvailable and free swap directly, so it catches
  # cases where pressure never sustains long enough for oomd's 30s window.
  # Overlapping on purpose — whichever notices first acts.
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
