# Tracks whether the intermittent s2idle wake hang is still happening.
#
# The hang documented in boot.nix leaves nothing behind: the journal stops
# mid-line with no flush, so there is no error to grep for. The only way to
# detect it after the fact is to count suspend attempts against successful
# resumes and look at the gap. That is a tedious pair of journalctl
# incantations to remember, and it only means anything once several hundred
# cycles have accumulated — so it is worth having the machine keep the tally
# itself rather than relying on someone running it by hand.
{ config, lib, pkgs, ... }:

let
  # Count from here forward. This is the boot at which amdgpu.dcdebugmask=0x12
  # became active; cycles before it belong to the old 0x10 configuration and
  # would poison the numbers. Move this anchor whenever a new suspend-related
  # change is activated, and note the old figures somewhere first — resetting
  # it silently discards the sample you already paid for.
  since = "2026-08-08 11:05";

  # Failure rate measured under 0x10, for comparison in the output.
  baselineHangs = 5;
  baselineTotal = 292;

  # Below this many cycles the numbers are not worth acting on. At the observed
  # ~1.7% rate a clean run of 100 is roughly an even-odds coin flip, so a small
  # clean sample says almost nothing.
  minSample = 300;

  s2idle-wake-count = pkgs.writeShellApplication {
    name = "s2idle-wake-count";
    runtimeInputs = with pkgs; [ systemd gnugrep gawk coreutils ];
    text = ''
      since=${lib.escapeShellArg since}
      state=/var/lib/s2idle-wake-audit
      history="$state/history.tsv"

      # NOTE: every phrase below is chosen to avoid the two strings this script
      # greps for. Emitting "suspend entry" or the resume-completion marker into
      # the journal would make the audit count its own output and inflate the
      # tally on every later run. Keep that in mind before rewording anything.
      attempts=$(journalctl --since "$since" -o cat -g "suspend entry" \
        | grep -cF s2idle || true)
      completions=$(journalctl --since "$since" -o cat -g "Restarting tasks: Done" \
        | grep -c . || true)
      missed=$(( attempts - completions ))

      rate=$(awk -v m="$missed" -v a="$attempts" \
        'BEGIN { if (a > 0) printf "%.2f", (m / a) * 100; else printf "0.00" }')
      baseline=$(awk -v m=${toString baselineHangs} -v a=${toString baselineTotal} \
        'BEGIN { printf "%.2f", (m / a) * 100 }')

      printf 's2idle wake audit (counting from %s)\n' "$since"
      printf '  suspend attempts    : %s\n' "$attempts"
      printf '  resumes completed   : %s\n' "$completions"
      printf '  missed wakes        : %s (%s%%)\n' "$missed" "$rate"
      printf '  baseline under 0x10 : %s of %s (%s%%)\n' \
        ${toString baselineHangs} ${toString baselineTotal} "$baseline"

      if [ "$attempts" -lt ${toString minSample} ]; then
        printf '  verdict             : sample too small (%s of %s cycles)\n' \
          "$attempts" ${toString minSample}
      elif [ "$missed" -eq 0 ]; then
        printf '  verdict             : clean over %s cycles — 0x12 looks effective\n' \
          "$attempts"
      else
        printf '  verdict             : still failing — next candidates are\n'
        printf '                        amdgpu.abmlevel=0, then amdgpu.runpm=0\n'
      fi

      # Append a datapoint so the trend is visible, not just the latest total.
      # Skipped rather than fatal when run as a normal user, so the command
      # stays useful interactively without sudo.
      if [ -w "$state" ]; then
        printf '%s\t%s\t%s\t%s\n' \
          "$(date -Is)" "$attempts" "$completions" "$missed" >> "$history"
      fi
    '';
  };
in

{
  # Also exposed as a command so the tally can be checked on demand.
  environment.systemPackages = [ s2idle-wake-count ];

  systemd.services.s2idle-wake-audit = {
    description = "Record s2idle suspend-vs-resume counts";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe s2idle-wake-count;
      StateDirectory = "s2idle-wake-audit";
      # Keep the summary out of the journal entirely. Belt and braces alongside
      # the careful wording above: what this service prints must never be
      # visible to the greps it performs.
      StandardOutput = "null";
    };
  };

  systemd.timers.s2idle-wake-audit = {
    description = "Daily s2idle wake-failure tally";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # The laptop is asleep or off at most fixed times, so a missed run has to
      # catch up on the next boot rather than being skipped.
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
