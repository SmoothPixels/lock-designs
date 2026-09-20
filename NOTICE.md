# Third-party notices

The QML in `designs/` is original work written against Omarchy's own
`DesignBase`/`PasswordField` components, none of it is copied from any
third-party source.

Most of the ported designs are inspired by themes from
[Darkkal44/qylock](https://github.com/Darkkal44/qylock) (GPL-3.0-or-later).
Their video, image, and font assets are fetched on demand at runtime
straight from Darkkal44's own hosted copies (see `designs/thirdparty-assets.json`),
never copied into or redistributed from this repository, so this plugin
stays MIT despite the inspiration. Full credit for those assets, and the
original wallpaper artists behind them, is in `README.md`.

The `designs/*-assets/` folders bundled directly in this repo (the wallsflow
car and cat designs) are original video wallpapers from
[wallsflow.com](https://wallsflow.com), bundled because that site blocks
scripted downloads, so there is no URL for this plugin to fetch them from
later. See `README.md` for per-design credit links.

This plugin does nothing on its own: every design it ships requires
[Lock Screen Explorer](https://github.com/SirJul1337/omarchy-lock-explorer)
(MIT, by SirJul1337) to be installed, that plugin is what renders the lock
screen and its `DesignBase`/`PasswordField` components are imported by every
design here at runtime. This repository does not vendor or fork any of its
code.
