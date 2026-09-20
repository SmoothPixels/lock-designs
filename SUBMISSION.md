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
Adds 45 extra lock screen designs to Lock Screen Explorer's Third Party
tab: 38 fresh QML ports of themes from Darkkal44/qylock (GPL-3.0), plus 7
original video wallpaper designs built from wallsflow.com live wallpapers.

Ships as a `service`-kind plugin with no UI of its own. It only copies its
own designs/ folder into ~/.config/omarchy/lock-designs/, the folder Lock
Screen Explorer already watches for user-supplied designs, so a fresh
install or `omarchy plugin update` picks up new or fixed designs without a
manual step. Nothing outside that folder is touched, no other config, no
sudo.

Requires Lock Screen Explorer (io.github.sirjul1337.lock-explorer) to be
installed separately, this plugin supplies content only and does not
render anything on its own. The service logs a one-line reminder if that
plugin is missing.

Most designs fetch their video/font assets on demand (a Download button
per design in the picker) straight from Darkkal44's own hosted files, so
this repo stays small, that is the only network access this plugin ever
makes, and only when the user clicks Download. The 7 wallsflow-sourced
designs bundle their video directly since wallsflow's CDN blocks scripted
downloads.

MIT licensed. The qylock-inspired designs are written fresh against Omarchy's
own DesignBase/PasswordField, not copied from qylock's GPL source, and their
assets are only ever linked to, not redistributed. See NOTICE.md.
```

**Submission checklist**
- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
