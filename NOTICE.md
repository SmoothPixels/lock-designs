# Third-party notices

The QML in this repository is original work. None of it is copied from any
third-party source.

The lock itself (`Service.qml`) is a clone of Omarchy's first-party
`omarchy.lock` plugin, made the way Omarchy intends with the `clonedFrom`
manifest field: the session-lock, PAM and display-blanking flow follows
Omarchy's own implementation (MIT, © Omarchy) so that unlocking behaves
exactly like stock. Everything around it, the design host, the picker, the
verified downloader and the design components, is written here.

Most of the ported designs are inspired by themes from
[Darkkal44/qylock](https://github.com/Darkkal44/qylock) (GPL-3.0-or-later).
Their video, image and font assets are fetched on demand at runtime from
Darkkal44's own hosted copies at a pinned commit and verified against the
SHA-256 digests in `designs/thirdparty-assets.json`. They are never copied
into or redistributed from this repository, so this plugin stays MIT despite
the inspiration. Full credit for those assets, and the original wallpaper
artists behind them, is in `README.md`.

The seven car and cat designs marked `// source: wallsflow` use live
wallpapers from [wallsflow.com](https://wallsflow.com). That site blocks
scripted downloads and has no URL that could be pinned, so those videos are
attached to a GitHub release of this repository and fetched from there on
demand, with their SHA-256 digests in the same catalog. Nothing in git holds
them. See `README.md` for per-design credit links.
