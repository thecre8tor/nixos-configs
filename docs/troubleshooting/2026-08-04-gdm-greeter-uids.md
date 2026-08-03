# GDM greeter accounts: UID drift and a duplicate UID

**Date:** 2026-08-04
**Machine:** nixos (branch `main-edge`)
**Outcome:** greeter accounts recreated at their declared UIDs; no config change
**Related config:** none in this repo — the accounts come from nixpkgs
`nixos/modules/services/display-managers/gdm.nix`

---

## Symptom

Every `nixos-rebuild switch` printed three warnings during activation:

```console
warning: not applying UID change of user ‘gdm-greeter-2’ (60580 -> 60579) in /etc/passwd
warning: not applying UID change of user ‘gdm-greeter-3’ (60581 -> 60580) in /etc/passwd
warning: not applying UID change of user ‘gdm-greeter-4’ (60582 -> 60581) in /etc/passwd
```

Harmless in isolation, and easy to scroll past — but they repeat on every switch,
and they were hiding a genuine inconsistency.

## Investigation

**1. `/etc/passwd` disagreed with the evaluated config.**

| Account | `/etc/passwd` | `/var/lib/nixos/uid-map` | Config wants |
| --- | --- | --- | --- |
| `gdm-greeter` | 60578 | 60578 | 60578 ✅ |
| `gdm-greeter-1` | absent | **60579** | not declared |
| `gdm-greeter-2` | 60580 | 60580 | 60579 |
| `gdm-greeter-3` | 60581 | 60581 | 60580 |
| `gdm-greeter-4` | **60582** | **60582** | 60581 |
| `gdm-greeter-5` | **60582** | **60582** | 60582 |

**2. Two accounts shared a UID.**

```console
$ awk -F: '{print $3}' /etc/passwd | sort | uniq -d
60582
```

`gdm-greeter-4` and `gdm-greeter-5` were both 60582 — in `/etc/passwd` *and* in
the uid-map, so this was recorded state, not a stray manual edit. To the kernel
those are one identity: same `/run/user/60582`, same ownership, no separation.

**3. The greeter UIDs are static, not auto-allocated.** From the nixpkgs module:

```nix
greeterUsers = lib.genAttrs' [ null 1 2 3 4 ] (
  i:
  let
    # adding 1 to create `gdm-greeter{-2,-3,-4,-5}`
    suffix = lib.optionalString (i != null) "-${toString (i + 1)}";
  in
  lib.nameValuePair "gdm-greeter${suffix}" {
    isSystemUser = true;
    uid = 60578 + (if i == null then 0 else i);
    ...
```

The suffix is `i + 1` but the UID offset is `i`, so under the current scheme
`gdm-greeter-N = 60577 + N`.

## Root cause

Upstream renamed the greeter accounts. The old scheme was `gdm-greeter-N =
60578 + N`, which is exactly what the uid-map still recorded. After the rename
every account sat one slot high, and `gdm-greeter-1` — which the config no
longer declares — was left squatting on 60579.

The duplicate follows from the same rename. `gdm-greeter-5` did not exist under
the old scheme; when it was first created, the config asked for 60582, and the
old `gdm-greeter-4` was already sitting there. It was created anyway.

NixOS **never renumbers an existing user**: changing a UID would silently
transfer ownership of any file that user owns. So activation warns and leaves
`/etc/passwd` alone, forever, which is why the warnings never cleared on their
own.

Nothing in this repo caused it and nothing here can fix it — it is state drift
across a nixpkgs rename.

## Resolution

The accounts turned out to be disposable, which is what made the fix safe:

```console
$ for u in 60579 60580 60581 60582; do echo "$u: $(find /var /home /etc -uid $u 2>/dev/null | wc -l)"; done
60579: 0
60580: 0
60581: 0
60582: 0
```

Zero files owned by any of them, and no `/run/user/605*` runtime dirs. Only
`gdm-greeter` (60578) owns anything — `/var/lib/gdm/seat0/{state,config}` — and
its UID is correct under both schemes, so it was left untouched.

So: delete accounts 2–5, prune the `gdm-greeter-N` entries (including the
orphaned `-1`) from the uid-map, and let activation recreate them from the
module's declared UIDs.

```console
# userdel gdm-greeter-2; userdel gdm-greeter-3
# userdel gdm-greeter-4; userdel gdm-greeter-5
# sed -E -e 's/"gdm-greeter-[0-9]+":[0-9]+,//g' \
#        -e 's/,"gdm-greeter-[0-9]+":[0-9]+//g' /var/lib/nixos/uid-map
# nixos-rebuild switch --flake ~/nixos-configs
```

**Do not delete the whole uid-map** to force a clean slate. It would
re-allocate every auto-assigned UID on the system, including accounts that do
own files.

The edit was made with `sed` because this machine has neither `jq` nor
`python3`. To verify it anyway, the transformation was first run against a copy
and the result parsed with the one JSON parser that *is* installed:

```console
$ nix eval --impure --raw --expr 'let m = builtins.fromJSON (builtins.readFile /tmp/uid-map.new); in ...'
parsed OK: 54 keys, gdm-greeter=60578, has gdm-greeter-4: no
```

59 keys before, 54 after — the five `gdm-greeter-N` entries and nothing else.

## Result

```console
$ grep -E '^gdm' /etc/passwd
gdm-greeter:x:60578:132::/run/gdm/home/gdm-greeter:...
gdm-greeter-2:x:60579:132::/run/gdm/home/gdm-greeter-2:...
gdm-greeter-3:x:60580:132::/run/gdm/home/gdm-greeter-3:...
gdm-greeter-4:x:60581:132::/run/gdm/home/gdm-greeter-4:...
gdm-greeter-5:x:60582:132::/run/gdm/home/gdm-greeter-5:...

$ awk -F: '{print $3}' /etc/passwd | sort | uniq -d    # no output
```

Sequential, no duplicate, and the switch warnings are gone.

## Notes for next time

- **Timing matters.** Between the `userdel`s and the switch those accounts do
  not exist. The active desktop runs as `gdm-greeter` (60578) and is unaffected,
  but GDM would fail to start a *second* greeter in that window — user
  switching, or a lock screen on another seat. Run the two steps back to back.
- **This can recur.** Any future upstream rename of the greeter accounts will
  reproduce the same drift, with the same warnings and the same fix.
- **Check for real damage before assuming a UID warning is cosmetic.** The
  warning itself is benign; `awk -F: '{print $3}' /etc/passwd | sort | uniq -d`
  is what shows whether the drift has collided two accounts. Then check whether
  the affected UIDs own files — if they do, deleting the accounts is not safe
  and the files need `chown` first.
