# GNOME login keyring: locked, then reset

**Date:** 2026-08-03
**Machine:** nixos (branch `main-edge`)
**Outcome:** login keyring reset; old file backed up, not deleted
**Related config:** `modules/system/fingerprint.nix`, commit `8c2b1db`

---

## Symptom

Launching a desktop application produced a GNOME dialog:

> **Authentication required**
> The password you use to log in to your computer no longer matches that of your login keyring.

Typing the current account password did not dismiss it.

## Background: the previous session

This was the second of two related failures. Earlier the same day, commit `8c2b1db`
("Drop login/gdm fprintAuth so the greeter accepts a password") fixed a *different*
keyring problem with the same outward appearance.

In that first failure, `modules/system/fingerprint.nix` set `login.fprintAuth` and
`gdm.fprintAuth`. Logging in by fingerprint meant PAM never received a password, so
`pam_gnome_keyring` had nothing to unlock the keyring with, and it stayed locked for the
whole session — a reboot did not help, because the next login was also by swipe.

That surfaced as RedisInsight hanging with no window at all: it calls
`keytar.getPassword('redisinsight', 'app')` in `LocalInitService.onModuleInit`, which
Nest runs *inside* `await app.listen()`. Since the window is only created after
`listen()` resolves, a blocked keyring read means zero UI. The tell was a final log line
of `[Server] Environment: production` where a healthy start reaches `Nest application
successfully started`; the wedged process then held the Electron singleton lock, so
relaunching only printed `Didn't get the lock. Quiting...`.

`8c2b1db` dropped both fprintAuth options. `services.fprintd.enable` on its own still
generates a working `gdm-fingerprint` PAM stack that GNOME offers next to the password
prompt, and `sudo.fprintAuth` is deliberately kept.

## Investigation

**1. Keyring file predates the current password.**

```console
$ ls -la ~/.local/share/keyrings/
-rw------- 1 alexander users 2605 Jun  6 14:58 login.keyring
-rw------- 1 alexander users  207 Feb  7 02:12 user.keystore
```

**2. Confirmed locked over D-Bus.**

```console
$ gdbus call --session --dest org.freedesktop.secrets \
    --object-path /org/freedesktop/secrets/collection/login \
    --method org.freedesktop.DBus.Properties.Get \
    org.freedesktop.Secret.Collection Locked
(<true>,)
```

**3. The daemon said it failed.**

```console
$ journalctl -b -t gnome-keyring-daemon
23:05:42  gnome-keyring-daemon[2344]: failed to unlock login keyring on startup
23:05:42  gnome-keyring-daemon[3086]: discover_other_daemon: 1
```

**4. The PAM plumbing was correct**, so this was not a config regression.
`/etc/pam.d/gdm-password` is `auth substack login`, and `/etc/pam.d/login` contains
`pam_gnome_keyring.so` in the auth stack (order 12200, to capture the password) and again
in the session stack with `auto_start` (order 12600).

**5. Login was by password, not fingerprint** — which rules out a repeat of the first
failure. There were no `fprintd` journal entries for the boot at all, and:

```console
23:05:38  gdm-password: gkr-pam: unable to locate daemon control file
23:05:38  gdm-password: gkr-pam: stashed password to try later in open session
23:05:39  gdm-password: gkr-pam: gnome-keyring-daemon started properly and unlocked keyring
23:05:42  gnome-keyring-daemon[2344]: failed to unlock login keyring on startup
```

**Do not trust line 3.** `gkr-pam`'s "started properly and unlocked keyring" is
optimistic — it reports that the password handoff to the daemon succeeded, not that
decryption verified. The daemon's own failure three seconds later is the authoritative
result.

**6. Not a duplicate-daemon race.** Two daemons were running, which initially looked
like the classic race where a passwordless second instance wins the D-Bus name:

```console
$ ps -eo pid,ppid,args | grep gnome-keyring-daemon
2344     1  gnome-keyring-daemon --daemonize --login                      # started by pam
3086  2295  gnome-keyring-daemon --start --foreground --components=secrets # user systemd

$ busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus GetConnectionUnixProcessID s org.freedesktop.secrets
u 2344
```

PID 2344 — the PAM-started one that *did* receive the password — owns
`org.freedesktop.secrets`. PID 3086 logged `discover_other_daemon: 1`, meaning it
detected 2344 and correctly stood down. So the password was delivered to the right
daemon and decryption genuinely failed.

**7. No recent `passwd` run was detectable.** `/etc/shadow` had an mtime of 23:05:11
against a boot time of 23:05:08 (`uptime -s`), i.e. NixOS activation rewriting it at
boot, not a password change. Nothing in the flake sets `users.mutableUsers`,
`hashedPassword`, or `initialPassword`, so `mutableUsers` defaults to true and the
account password is managed imperatively with `passwd`.

## Root cause

`login.keyring` was created on Jun 6 and sealed with the account password in force at
that time. The password was changed at some later point, so the current password no
longer derives the right key.

The keyring is password-**encrypted**, not password-protected: the login password is the
key material for the AES key over the file. There is therefore no root override, no
admin reset, and no master key — the June password is the only thing that can decrypt it.
`pam_gnome_keyring` had already tried the current password and failed before the dialog
ever appeared, which is why retyping it could not work.

## Resolution

The June password could not be recalled, so the keyring was reset. The old file was
**moved, not deleted**, so it stays recoverable if the password resurfaces:

```console
$ mkdir -p ~/.local/share/keyring-backup
$ sha256sum ~/.local/share/keyrings/login.keyring
6218f70bbd7d518238a06373bf5a577e2fc63478789e3d28e391b4e38e85d9c0
$ mv -n ~/.local/share/keyrings/login.keyring \
       ~/.local/share/keyring-backup/login.keyring.locked-2026-08-03
$ chmod 700 ~/.local/share/keyring-backup
$ sha256sum ~/.local/share/keyring-backup/login.keyring.locked-2026-08-03
6218f70bbd7d518238a06373bf5a577e2fc63478789e3d28e391b4e38e85d9c0   # unchanged
```

`user.keystore` was left in place — it is the certificate trust store and is unrelated to
the login password.

On the next login, `pam_gnome_keyring` finds no login keyring and creates a fresh one
sealed with the password it just received. No manual step is needed. Because `8c2b1db`
made password login reliable, the new keyring unlocks automatically from then on.

To recover the old keyring later, move it back to
`~/.local/share/keyrings/login.keyring` and unlock with the June password.

## Blast radius

Only two consumers kept secrets in the keyring on this machine:

| Path | Effect of the reset |
| --- | --- |
| `~/.config/goa-1.0` | GNOME Online Accounts must be re-added in Settings → Online Accounts |
| `~/.config/RedisInsight` | Regenerates its keytar key; saved Redis connection passwords lost |

Unaffected:

- **WiFi** — NetworkManager stores PSKs in root-owned files under
  `/etc/NetworkManager/system-connections/`, not the keyring.
- **Browser passwords** — no Chrome, Chromium, or Brave profile exists under
  `~/.config`, so nothing was wrapped by the keyring.

## Diagnosing this class of problem again

Both failures look identical from the application side (a hang, or an unlock dialog), so
read the journal rather than guessing:

1. Lock state — the `gdbus` call in step 2 above. If `false`, the keyring is not your
   problem.
2. Which login path was used — if the boot has **no** `fprintd` entries, it was a password
   login, which rules out the fingerprint cause.
3. Whether decryption actually succeeded — look for `failed to unlock login keyring on
   startup` from the daemon that owns `org.freedesktop.secrets`. Ignore `gkr-pam`'s
   cheerful "unlocked keyring" message.
4. Whether a second daemon matters — one logging `discover_other_daemon: 1` has stood
   down and is harmless.

Two notes on remedies: the unlock dialog does **not** lock out after failed attempts, so
trying candidate old passwords there is free and is the only route that preserves the
contents. And if a password *is* recovered, run `seahorse` → right-click **Login** →
*Change Password* to reseal the keyring with the current login password, otherwise the
prompt returns at every login.
