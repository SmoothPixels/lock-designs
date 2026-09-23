# Changelog

## 2.1.0 (2026-09-23)

The marketplace security review of 2.0.0 found that the optional login
screen crossed a privilege boundary: its installer ran as root from the
plugin checkout, a folder the user account can write to, and installed QML
and designs from that same folder. The plugin is now unprivileged end to
end. Nothing it ships runs as root or asks for a password, and it writes
nowhere outside `~/.config/omarchy/lock-designs/`. The same release adds
eight originals in everyday layouts, the kind you leave on.

### Added

- Eight original designs, all following the active theme and needing
  nothing downloaded: Postcard (clock, avatar and greeting on one frosted
  card), Masthead (a big clock bottom left, editorial style), Hush (no box
  at all, a dot per typed letter), Sidecar (wallpaper left, sign-in panel
  right), TTY (a console login prompt with a blinking cursor and "Login
  incorrect" on a miss), Halo (a ring around the clock that fills as you
  type and spins while checking), Billboard (huge stacked hours and
  minutes) and Shelf (everything on a slim bar along the bottom). That makes
  66 designs, 21 of them originals.
- The picker header names the active Omarchy theme, and a legend of every
  key runs along the bottom of the picker.
- The hint pill in the full-screen preview fades out a few seconds after
  the last key or wheel step and comes back on the next one.
- The picker can be opened on a named monitor:
  `omarchy-shell shell toggle io.github.smoothpixels.lock-designs '{"screen":"DP-2"}'`.

### Removed

- The login screen. Gone are the Login screen tab, the SDDM greeter theme
  under `sddm/`, `tools/install-login-theme.sh`, the `loginSource` and
  `loginFollow` settings, and the `syncLogin`, `loginStatus`,
  `setLoginSource` and `previewLogin` commands. A login screen installed
  from 2.0.0 keeps showing whatever it last synced but no longer follows the
  theme or the lock design. Take it down with that version's installer and
  `--remove`, or delete `/usr/share/sddm/themes/lock-designs` and
  `/etc/sddm.conf.d/99-zz-lock-designs.conf` as root.
- The Tab key in the picker, which switched between the two tabs.

### Changed

- The design grid moved up into the space the tab strip used.
- The chosen filter chip and the Use design button sit on a solid accent
  pill with their label in the background color, so the selection reads on
  any theme; the kit's own selected state was a faint wash that looked like
  a hover on monochrome themes. The header line names the theme and the
  design in use and no longer counts the designs.

## 2.0.0 (2026-09-22)

Lock Designs became a lock screen. Version 1 was a pack of designs for a
separate lock screen picker plugin: nothing in it could lock a screen on its
own, and the marketplace review pointed out that its assets came from a
moving branch with no way to verify them. Version 2 removes both problems.
The plugin locks the screen itself, keeps the same design ids so a saved
choice carries over, and every download is pinned and checked.

### Added

- A lock screen service cloned from Omarchy's own (`omarchy.clonedFrom`), so
  the session lock, PAM password and fingerprint flows, blanking and
  stranded-lock recovery are the stock ones. Only the drawn design changes.
  A design that fails to load falls back to the Omarchy default design, then
  to a plain password field, so the screen is never left without a way in.
- A picker overlay with two tabs. Lock screen: filters for originals, third
  party, video and not downloaded, search, a font dropdown listing the
  machine's fonts, a 24 or 12 hour switch, preview on the focused monitor,
  keyboard navigation, and select-then-apply. Login screen: three choices for
  what SDDM shows before sign-in.
- Thirteen original designs that follow the active Omarchy theme and need
  nothing downloaded: Omarchy default, Bento, Binary, Circuit, Dot Matrix,
  Fireflies, Horizon, Nixie, Pixel Pet, Spotlight, Starry City, Tide and Word
  Clock. They read the theme's light or dark background and shade
  accordingly.
- Design components written from scratch (`DesignBase`, `PasswordField`,
  `LockInput`, `Avatar`) that keep the property and signal names the ported
  designs already used, so all 45 ports load unchanged apart from one
  dropped import line.
- A login screen theme for SDDM with three modes: Omarchy default, Omarchy
  default in theme colors, and the lock design itself running live in the
  greeter. Setup needs sudo once through an installer that leaves root
  owning the QML and the user owning only data. The Login screen tab shows a
  notice when the files on disk no longer match what was installed, and has
  buttons to set up, preview, update and remove it.
- Verified downloads. `designs/thirdparty-assets.json` pins every file to a
  full commit of Darkkal44/qylock, or to a GitHub release of this
  repository, with a SHA-256 digest and byte size. The downloader fetches to
  a temporary file, verifies, and only then publishes it; entries without a
  digest are refused and mismatches discarded. Optional mirrors never weaken
  the check. Tools to re-pin, verify and mirror, and a GitHub Actions
  workflow that checks the catalog on every change and can download and
  verify every file on demand.
- An opt-in Omarchy menu row, Style > Lock Designs, with a remove flag, and
  `omarchy-shell lock` commands for locking, status, previews, choosing a
  design, downloads, the font, and the login screen.
- Warm-up of the video stack shortly after startup and prefetching of the
  active design's media, so a video lock screen appears as fast as a still.

### Changed

- The seven wallsflow videos moved out of git to the `media-1` release of
  this repository and download on demand like everything else. The
  repository history was rewritten to drop them, which took a fresh clone
  from about half a gigabyte to about 40 MB.
- The Clockwork Orbital and Clockwork Tape ports were rescaled and
  brightened so they read on high-resolution displays.
- Preview image and gallery refreshed for the new picker and the originals.

### Removed

- The dependency on any other lock screen plugin.

## 1.0.0 (2026-09-20)

- 45 designs for a separate lock screen picker: 38 QML ports of themes from
  Darkkal44/qylock with on-demand asset downloads, and 7 designs built on
  wallsflow.com live wallpapers with the videos committed to the
  repository. Static previews, a gallery with looping GIFs, credits and the
  marketplace submission notes.
