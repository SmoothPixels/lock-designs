# Marketplace submission

Pre-filled answers for the submission issue at
https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml

Do not file this until the plugin has been installed and tested on a real
Omarchy machine: the checklist below asserts things that need to be true,
not aspirational.

**Repository URL**
```
https://github.com/SmoothPixels/lock-designs
```

**Category**
```
Appearance
```

**Tags** (max 3)
```
Quickshell, Media, System
```

**Suggest a missing tag**
```
Lock Screen
```

**Maintainer notes**
```
A lock screen for Omarchy with 66 designs and a picker: twenty-one originals
that follow the active Omarchy theme and need nothing downloaded, 38 QML
ports of themes from Darkkal44/qylock (GPL-3.0), and 7 designs built on
wallsflow.com live wallpapers. Every video, image and font downloads on
demand; the repository holds only QML, thumbnails and the catalog, so a
clone is about 40 MB.

The plugin is a standalone lock screen. It is a clone of omarchy.lock
(manifest `omarchy.clonedFrom`), so the session lock, PAM password and
fingerprint flows, blanking and stranded-lock recovery are Omarchy's own
code; only the drawn design changes. `service` kind for the lock, `overlay`
kind for the picker, opened with `omarchy-shell lock explore`. The picker
names the active Omarchy theme in its header and lists every key along its
bottom edge.

Writes only to ~/.config/omarchy/lock-designs/ (designs, previews, the asset
catalog, downloaded assets, settings.json). Nothing in the plugin runs as
root or asks for a password, and no file it ships is meant to be run with
elevated rights. One opt-in script exists for the user to run:
tools/install-menu-entries.sh adds an Omarchy menu row, user files only,
and `--remove` undoes it. Version 2.0.0 had an optional SDDM login screen
whose installer ran as root from the plugin checkout; the security review
flagged that boundary and 2.1.0 removes the feature entirely (the sddm/
folder, tools/install-login-theme.sh, the picker's Login screen tab, its
settings and its commands).

Network access: on-demand downloads only, when the user clicks Download.
Every entry in designs/thirdparty-assets.json carries a repository-owned
SHA-256 and byte size and points at an immutable source: a full commit of
Darkkal44/qylock (f6561e2ceae33f26e5e660742a5df2f725cbe514) for the qylock
ports, or the media-1 GitHub release of this repository for the seven
wallsflow videos. The downloader (Service.qml, fetchScript) fetches to a
.part file, verifies the digest, and only then moves the file into place;
entries without a digest are refused and mismatches are discarded and
reported on the card. Optional mirrors are tried after the primary URL and
must match the same digest. tools/pin-assets.sh regenerates the catalog,
tools/verify-assets.sh checks an installation, and
.github/workflows/catalog.yml checks the catalog on every change and can
download and verify every file.

A failed design never strands a locked screen: it falls back to the shipped
Omarchy default design, then to a plain password field.

MIT licensed. The QML is original work; the ported designs are written
fresh against this plugin's own DesignBase and PasswordField, and qylock's
assets are linked to, not redistributed. Credits and the licensing picture
are in README.md and NOTICE.md; version history is in CHANGELOG.md.
```

**Submission checklist**
- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
