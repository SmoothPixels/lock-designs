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
A lock screen for Omarchy with 58 designs and a picker: thirteen originals
that follow the active Omarchy theme with nothing to download, 38 fresh QML
ports of themes from Darkkal44/qylock (GPL-3.0), and 7 original video
wallpaper designs built from wallsflow.com live wallpapers.

It is a clone of omarchy.lock (manifest `omarchy.clonedFrom`), so the
session lock, PAM password and fingerprint flows, blanking and stranded-lock
recovery are the stock ones; only the drawn design changes. `service` kind
for the lock, `overlay` kind for the picker, summoned with
`omarchy-shell shell toggle io.github.smoothpixels.lock-designs '{}'`.

Writes only to ~/.config/omarchy/lock-designs/ (designs, previews, the asset
catalog, downloaded assets, settings.json). The plugin itself never escalates.
Two opt-in scripts exist for the user to run: tools/install-menu-entries.sh
(adds an Omarchy menu row, user files only) and tools/install-login-theme.sh
(run with sudo once; installs an SDDM greeter theme under
/usr/share/sddm/themes/lock-designs and selects it in /etc/sddm.conf.d; root
owns the greeter QML, shell-module stand-ins and a snapshot of the designs,
the user owns only a config file and a data folder the greeter reads as data,
with media paths accepted only inside that folder). The picker can launch the latter through Omarchy's floating
terminal, where sudo asks for the password; nothing is installed without it.

Network access: on-demand asset downloads only, when the user clicks
Download. Every URL in designs/thirdparty-assets.json is pinned to a full
commit of Darkkal44/qylock and carries a repository-owned SHA-256 and size.
The downloader fetches to a .part file, verifies the digest, and only then
publishes the file; entries without a digest are refused and mismatches are
discarded and reported. tools/pin-assets.sh regenerates the catalog,
tools/verify-assets.sh checks an installation.

A failed design never strands a locked screen: it falls back to the shipped
Classic design, then to a dependency-free password field.

MIT licensed. The QML is original; asset credits and the licensing picture
are in README.md and NOTICE.md.
```

**Submission checklist**
- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
