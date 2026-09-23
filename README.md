# Lock Designs

![preview](preview.png)

A lock screen for Omarchy with 58 designs and a picker to switch between them: thirteen originals that follow your active Omarchy theme and need nothing downloaded, starting with the stock Omarchy lock screen itself, 38 fresh QML ports of themes from [Darkkal44/qylock](https://github.com/Darkkal44/qylock), and 7 original video wallpaper designs built from [wallsflow.com](https://wallsflow.com) live wallpapers.

It replaces the stock lock screen as a clone of Omarchy's own `omarchy.lock`, so the session lock, the PAM password and fingerprint flows, display blanking and stranded-lock recovery are exactly the stock ones. Only what is drawn on the lock surface changes.

Two of the qylock ports, **Genshin Impact** and **Terraria**, change their background by the time of day. Both are marked "time-based" in the picker.

[Install](#install) • [The picker](#the-picker) • [Assets and verification](#assets-and-verification) • [Settings and commands](#settings-and-commands) • [Remove](#remove) • [Gallery](#gallery) • [Acknowledgements](#acknowledgements) • [Development](#development)

## Install

```sh
omarchy plugin add https://github.com/SmoothPixels/lock-designs.git --enable
```

Only one lock screen plugin can be active at a time, so disable any other lock plugin first (`omarchy plugin list` shows what is enabled). Then open the picker:

```sh
omarchy-shell lock explore
```

Bind that command to a key in your Hyprland bindings, or add a **Style > Lock Designs** row to the Omarchy menu with the bundled, opt-in script (run it again after an update if the snippet changes):

```sh
~/.config/omarchy/plugins/io.github.smoothpixels.lock-designs/tools/install-menu-entries.sh
```

Nothing outside `~/.config/omarchy/lock-designs/` is written. No sudo.

## The picker

A grid of every design with a still preview, its source, and whether it is ready. The **Originals** filter shows only the theme-following designs, **Third party** only the ports. A click selects a design; apply it with the **Use design** button, the check button on the card, Enter, or a double-click. For a design that still needs its video or fonts, the same action downloads them first. Space or the eye button shows a design full screen without locking. While previewing, the arrow keys, Page Up and Page Down step through every ready design; Enter adopts the one on screen, Esc closes.

| Key | Action |
|---|---|
| Arrows, Home, End | Move |
| Click | Select a design |
| Enter, double-click | Use the selected design, or start its download |
| Space, P | Preview full screen |
| D | Download, cancel, or remove a design's assets |
| L | Lock now |
| Page Up, Page Down | Move two rows |
| Wheel | Scroll the grid |
| / or any letter | Search |
| Esc | Close |

The footer switches every clock between 24-hour and 12-hour, previews the current design, and locks the screen. The **Font** dropdown in the header lists every font installed on the machine; the originals draw their clocks and captions in the one you pick, and "Theme font" puts them back on Omarchy's own. Third-party ports keep their bundled fonts.

Browsing is cheap on purpose: cards show a small JPEG, so scrolling never starts a video decoder. Only designs without a shipped still (the originals and your own files) are rendered live, paused. At most one design ever plays for real, in the preview or on the lock screen itself.

## Assets and verification

Every design with a video, image or font fetches it on demand, so a clone of this repository stays small. Each entry in `designs/thirdparty-assets.json` carries the file's SHA-256 and size and points at an immutable source: a full commit of `Darkkal44/qylock` for the qylock ports, or a GitHub release of this repository for the wallsflow videos:

```json
"my-forest": {
  "assetsDir": "forest-assets",
  "files": [
    {
      "path": "bg.mp4",
      "url": "https://raw.githubusercontent.com/Darkkal44/qylock/f6561e2c…/themes/forest/bg.mp4",
      "sha256": "97d54ce5…",
      "size": 53320657,
      "mirrors": []
    }
  ]
}
```

The downloader fetches each file to a `.part` file, hashes it, and only moves it into place when the digest matches. A catalog entry without a digest is refused outright, and a mismatch is reported on the card and the file discarded. Optional `mirrors` are tried in order after `url`; the digest has to match whichever source answered, so a mirror can never weaken the check. The only network access this plugin ever makes is these downloads, and only when you ask for one.

Downloaded assets live in `~/.config/omarchy/lock-designs/<design>-assets/`. The 7 wallsflow videos are served from the `media-1` release of this repository, because wallsflow's own CDN blocks scripted downloads and offers nothing that could be pinned; their digests sit in the same catalog and go through the same check.

Maintainer tools:

| Tool | Purpose |
|---|---|
| `tools/pin-assets.sh <commit>` | Re-point every qylock URL at a commit and record fresh digests and sizes for every file, release-hosted ones included |
| `tools/verify-assets.sh` | Check every downloaded asset on this machine against the catalog |
| `tools/mirror-assets.sh <tag>` | Optional: publish the pinned set as a GitHub release and add the URLs as mirrors (read the licensing note in the script first) |

A GitHub Actions workflow (`.github/workflows/catalog.yml`) checks on every change to the catalog that each entry points at a qylock commit or a release of this repository and carries a digest and size; run it by hand to download every file and verify the digests too.

## Settings and commands

Settings are kept in `~/.config/omarchy/lock-designs/settings.json`:

| Key | Meaning |
|---|---|
| `design` | Id of the selected design, for example `my-forest` |
| `twelveHour` | `true` for 12-hour clocks |
| `font` | Family the originals use for text, for example `Adwaita Sans`; empty follows the theme font |

Everything the picker does is also reachable from the command line through the stock `lock` target, which this plugin answers as the active lock:

```sh
omarchy-shell lock explore                   # open or close the picker
omarchy-shell lock designs                   # JSON list with ids, names and readiness
omarchy-shell lock design                    # id of the design in use
omarchy-shell lock setDesign my-forest
omarchy-shell lock previewDesign my-forest   # full screen, no lock; hidePreview closes it
omarchy-shell lock previewDesignOn my-forest DP-2   # same, on a named monitor
omarchy-shell lock previewStep 1             # next ready design in the preview (-1 for previous)
omarchy-shell lock download my-forest        # verified download of its assets
omarchy-shell lock removeAssets my-forest
omarchy-shell lock setClockFormat 12         # or 24
omarchy-shell lock setFont "Adwaita Sans"     # font for the originals; empty string follows the theme
omarchy-shell lock lock                      # same as the stock lock
omarchy-shell lock status
```

Locking is as quick as the stock lock: a design compiles and instantiates in a few milliseconds, and Qt's multimedia module, which costs about 700 ms the first time it loads, is warmed up a few seconds after the shell starts so the first video lock does not pay for it. A design that needs assets you have not downloaded, or one that fails to load, is never left on a locked screen: the lock falls back to the Omarchy default design, and if even that fails, to a bare password field with no dependencies at all.

## Remove

If you added the menu row, drop it with:

```sh
~/.config/omarchy/plugins/io.github.smoothpixels.lock-designs/tools/install-menu-entries.sh --remove
```

Then remove the plugin and hand the lock back to Omarchy:

```sh
omarchy plugin remove io.github.smoothpixels.lock-designs
omarchy plugin enable omarchy.lock
```

The second line matters: removing the active clone leaves the stock lock disabled until you enable it again. Files already copied into `~/.config/omarchy/lock-designs/` are left in place, including downloaded assets and any designs of your own; delete the folder yourself if you want it gone.

## Gallery

### Originals

Written from scratch for this plugin. Every color comes from the active Omarchy theme, so they change with it; these captures use the Miasma theme, at night. Nothing to download.

| | |
|:---:|:---:|
| **Omarchy default**, the stock lock screen<br><img src="assets/originals/Classic.jpg" width="380"/> | **Bento**, frosted tiles over your wallpaper<br><img src="assets/originals/Bento.jpg" width="380"/> |
| **Horizon** *(time-based)*, sun and moon follow the hour<br><img src="assets/originals/Horizon.jpg" width="380"/> | **Dot Matrix**, the time on an LED board<br><img src="assets/originals/DotMatrix.jpg" width="380"/> |
| **Tide**, slow waves in your theme's colors<br><img src="assets/originals/Tide.jpg" width="380"/> | **Fireflies**, drifting points of accent light<br><img src="assets/originals/Fireflies.jpg" width="380"/> |
| **Spotlight**, your wallpaper lit around the sign-in<br><img src="assets/originals/Spotlight.jpg" width="380"/> | **Starry City**, a pixel skyline whose windows come on and go out<br><img src="assets/originals/StarryCity.jpg" width="380"/> |
| **Word Clock**, the time spelled out in a letter grid<br><img src="assets/originals/WordClock.jpg" width="380"/> | **Nixie**, glass tubes with the digits glowing inside<br><img src="assets/originals/Nixie.jpg" width="380"/> |
| **Pixel Pet**, a cat that blinks, watches you type and sulks at a wrong password<br><img src="assets/originals/PixelPet.jpg" width="380"/> | **Binary**, the time in binary-coded decimal<br><img src="assets/originals/Binary.jpg" width="380"/> |
| **Circuit**, a chip carrying the time, pulses running along the traces<br><img src="assets/originals/Circuit.jpg" width="380"/> | |

Horizon, Tide, Fireflies, Spotlight, Starry City, Pixel Pet and Circuit animate; their motion is tied to the display being awake, so nothing runs behind a blanked screen or inside the picker's paused thumbnails.

### Wallsflow originals

| | |
|:---:|:---:|
| **Anime Girl GTR**<br><img src="assets/AnimeGirlGTR.gif" width="380"/> | **Black Cat Water**<br><img src="assets/BlackCatWater.gif" width="380"/> |
| **Moonlit Roof Cat**<br><img src="assets/MoonlitRoofCat.gif" width="380"/> | **Nissan 350Z Night**<br><img src="assets/Nissan350zNight.gif" width="380"/> |
| **Porsche 911 Darkness**<br><img src="assets/Porsche911Darkness.gif" width="380"/> | **Supercar Sakura**<br><img src="assets/SupercarSakura.gif" width="380"/> |
| **Skyline R34 Rain**<br><img src="assets/SkylineR34Rain.gif" width="380"/> | |

`SkylineR34Rain.qml`'s video is a 1080p re-encode of the 4K original, made when the videos still lived in git and had to fit under GitHub's per-file limit; it has no visible quality loss as a lock screen background. The other six are the 4K originals.

### Qylock ports

| | |
|:---:|:---:|
| **Clockwork Orbital**<br><img src="designs/thirdparty-previews/my-clockworkorbital.jpg" width="380"/> | **Clockwork Neo Orbital**<br><img src="designs/thirdparty-previews/my-clockworkneoorbital.jpg" width="380"/> |
| **Clockwork Tape**<br><img src="designs/thirdparty-previews/my-clockworktape.jpg" width="380"/> | **Dog Samurai**<br><img src="assets/DogSamurai.gif" width="380"/> |
| **Enfield**<br><img src="assets/Enfield.gif" width="380"/> | **Field**<br><img src="designs/thirdparty-previews/my-field.jpg" width="380"/> |
| **Forest**<br><img src="assets/Forest.gif" width="380"/> | **Genshin Impact** *(time-based)*<br><img src="assets/Genshin.gif" width="380"/> |
| **Girl Coffee**<br><img src="designs/thirdparty-previews/my-girlcoffee.jpg" width="380"/> | **Girl Pillow**<br><img src="designs/thirdparty-previews/my-girlpillow.jpg" width="380"/> |
| **The Last of Us**<br><img src="assets/LastOfUs.gif" width="380"/> | **Man Bicycle**<br><img src="designs/thirdparty-previews/my-manbicycle.jpg" width="380"/> |
| **Material You**<br><img src="designs/thirdparty-previews/my-materialyou.jpg" width="380"/> | **Material You Dark**<br><img src="designs/thirdparty-previews/my-materialyoudark.jpg" width="380"/> |
| **Minecraft**<br><img src="designs/thirdparty-previews/my-minecraft.jpg" width="380"/> | **NieR: Automata**<br><img src="designs/thirdparty-previews/my-nierautomata.jpg" width="380"/> |
| **Nine Sols**<br><img src="designs/thirdparty-previews/my-ninesols.jpg" width="380"/> | **Ninja Gaiden**<br><img src="designs/thirdparty-previews/my-ninjagaiden.jpg" width="380"/> |
| **Nothing**<br><img src="designs/thirdparty-previews/my-nothing.jpg" width="380"/> | **Pixel Coffee**<br><img src="assets/PixelCoffee.gif" width="380"/> |
| **Pixel Cyberpunk**<br><img src="assets/PixelCyberpunk.gif" width="380"/> | **Pixel Dusk City**<br><img src="assets/PixelDuskCity.gif" width="380"/> |
| **Pixel Emerald**<br><img src="assets/PixelEmerald.gif" width="380"/> | **Pixel Hollow Knight**<br><img src="assets/PixelHollowknight.gif" width="380"/> |
| **Pixel Munchlax**<br><img src="assets/PixelMunchlax.gif" width="380"/> | **Pixel Night City**<br><img src="assets/PixelNightCity.gif" width="380"/> |
| **Pixel Rainy Room**<br><img src="assets/PixelRainyroom.gif" width="380"/> | **Pixel Sakura**<br><img src="assets/PixelSakura.gif" width="380"/> |
| **Pixel Skyscrapers**<br><img src="assets/PixelSkyscrapers.gif" width="380"/> | **Pixel Waterfall**<br><img src="assets/PixelWaterfall.gif" width="380"/> |
| **Reverse: 1999 - I**<br><img src="assets/Reverse1999First.gif" width="380"/> | **Reverse: 1999 - II**<br><img src="assets/Reverse1999Second.gif" width="380"/> |
| **Honkai: Star Rail**<br><img src="assets/StarRail.gif" width="380"/> | **Sword**<br><img src="assets/Sword.gif" width="380"/> |
| **Terraria** *(time-based)*<br><img src="designs/thirdparty-previews/my-terraria.jpg" width="380"/> | **Winter**<br><img src="assets/Winter.gif" width="380"/> |
| **Women Umbrella**<br><img src="designs/thirdparty-previews/my-womenumbrella.jpg" width="380"/> | **Wuthering Waves**<br><img src="assets/Wuwa.gif" width="380"/> |

## Acknowledgements

The QML in this repo is written from scratch, none of it is copy-pasted from qylock's GPL-3.0 source. The video/image/font assets are a different matter, those are fetched on demand straight from Darkkal44's own hosted copies at a pinned commit, so full credit for them (and the original wallpaper artists behind them) belongs there.

| Design | Wallpaper source | Bundled font |
|---|---|---|
| Clockwork (Orbital / Neo Orbital / Tape) | [WallsFlow](https://wallsflow.com/live-wallpapers/abstract/321-clock-mechanism-live-wallpaper.html) | Outfit |
| Dog Samurai | [MoeWalls](https://moewalls.com/others/doge-samurai-crying-live-wallpaper/) | Orbitron |
| Enfield | [WallsFlow](https://wallsflow.com/live-wallpapers/games/777-arknights-endfield-sakura-sanctuary-live-wallpaper.html) | Orbitron |
| Field | [MoeWalls](https://moewalls.com/anime/fading-away-live-wallpaper/) | Orbitron |
| Forest | [MoeWalls](https://moewalls.com/landscape/in-the-early-morning-forest-live-wallpaper/) | Figtree |
| Genshin Impact | [YouTube](https://www.youtube.com/watch?v=XG3vTgitBLE) | - |
| Girl Coffee | [MoeWalls](https://moewalls.com/anime/chill-afternoon-girl-live-wallpaper/) | Itim |
| Girl Pillow | [MoeWalls](https://moewalls.com/anime/lazy-afternoon-girl-live-wallpaper/) | Itim |
| The Last of Us | [MoeWalls](https://moewalls.com/games/the-last-of-us-sunset-live-wallpaper/) | Outfit |
| Man Bicycle | [MoeWalls](https://moewalls.com/landscape/traveling-with-the-bicycle-live-wallpaper/) | Itim |
| Material You / Dark | - | Google Sans |
| Minecraft | Minecraft Wiki | - |
| NieR: Automata | [Reddit](https://www.reddit.com/r/nier/comments/7nqcy7/the_final_nier_automata_title_screen_made_into/) | - |
| Nine Sols | - | DejaVu Sans |
| Ninja Gaiden | [Noisy Pixel](https://noisypixel.net/ninja-gaiden-4-wallpapers-art-team/) | Tektur |
| Nothing | - | NDot55 / NType82 |
| Pixel Coffee | [MoeWalls](https://moewalls.com/pixel-art/cyberpunk-coffee-pixel-live-wallpaper/) | Pixelify Sans |
| Pixel Cyberpunk | [Pixiv](https://www.pixiv.net/en/artworks/84120766) | Pixelify Sans |
| Pixel Dusk City | [WallsFlow](https://wallsflow.com/live-wallpapers/pixel-art/505-pixel-dusk-city-retro-anime-streets-live-wallpaper.html) | Pixelify Sans |
| Pixel Emerald | - | Pixelify Sans |
| Pixel Hollow Knight | [MoeWalls](https://moewalls.com/pixel-art/hollow-knight-3-live-wallpaper/) | Pixelify Sans |
| Pixel Munchlax | [MoeWalls](https://moewalls.com/pixel-art/munchlax-sleeping-on-the-field-pixel-live-wallpaper/) | Pixelify Sans |
| Pixel Night City | [WallsFlow](https://wallsflow.com/live-wallpapers/pixel-art/400-night-city-pixel-art-cyberpunk-live-wallpaper.html) | Pixelify Sans |
| Pixel Rainy Room | [MoeWalls](https://moewalls.com/pixel-art/pixel-room-rainy-night-live-wallpaper/) | Pixelify Sans |
| Pixel Sakura | - | Pixelify Sans |
| Pixel Skyscrapers | [WallsFlow](https://wallsflow.com/live-wallpapers/pixel-art/61-pixel-city.html) | Pixelify Sans |
| Pixel Waterfall | - | Pixelify Sans |
| Reverse: 1999 (I / II) | [Taptap](https://www.taptap.com/topic/21175628) | Cinzel |
| Honkai: Star Rail | [YouTube](https://www.youtube.com/watch?v=Pz7Tu25EyXI) | - |
| Sword | [WallsFlow](https://wallsflow.com/live-wallpapers/anime/761-silent-katana-forest-samurai-live-wallpaper.html) | The Last Shuriken |
| Terraria | [Terraria Forums](https://forums.terraria.org/index.php?threads/terraria-desktop-wallpapers.12644/) | - |
| Winter | [MoeWalls](https://moewalls.com/landscape/winter-forest-snow-live-wallpaper/) | Orbitron |
| Women Umbrella | [MoeWalls](https://moewalls.com/anime/women-with-umbrella-live-wallpaper/) | Itim |
| Wuthering Waves | [YouTube](https://www.youtube.com/watch?v=xKKqi1zLrZ4) | Orbitron |

### Wallsflow originals

Downloaded on demand from the `media-1` release of this repository and verified against the catalog, since wallsflow's CDN blocks scripted downloads and has nothing that could be pinned.

| Design | Wallpaper source |
|---|---|
| Black Cat Water | [WallsFlow](https://wallsflow.com/live-wallpapers/animals/886-black-cat-emerald-water-ripples-live-wallpaper.html) |
| Moonlit Roof Cat | [WallsFlow](https://wallsflow.com/live-wallpapers/animals/1075-moonlit-rooftop-cat-live-wallpaper.html) |
| Anime Girl GTR | [WallsFlow](https://wallsflow.com/live-wallpapers/anime/1048-anime-girl-nissan-skyline-gtr-live-wallpaper.html) |
| Nissan 350Z Night | [WallsFlow](https://wallsflow.com/live-wallpapers/cars/1083-nissan-350z-japanese-night-streets-live-wallpaper.html) |
| Skyline R34 Rain | [WallsFlow](https://wallsflow.com/live-wallpapers/cars/870-pink-flower-field-nissan-skyline-r34-rain-live-wallpaper.html) |
| Supercar Sakura | [WallsFlow](https://wallsflow.com/live-wallpapers/cars/495-supercar-dreamscape-under-sakura-blossoms.html) |
| Porsche 911 Darkness | [WallsFlow](https://wallsflow.com/live-wallpapers/cars/756-porsche-911-timeless-performance-in-darkness-live-wallpaper.html) |

The design components (`DesignBase`, `PasswordField`, `LockInput`, `Avatar`) and every design are this plugin's own work.

## Development

Changes by version are in [CHANGELOG.md](CHANGELOG.md).

Designs are plain QML files in `designs/`, each with a `DesignBase` root. They sit next to `DesignBase.qml`, `PasswordField.qml`, `LockInput.qml` and `Avatar.qml`, so no import line is needed. The service mirrors that folder into `~/.config/omarchy/lock-designs/` on every shell start, and a design dropped straight into that folder shows up in the picker too.

Originals draw text in `lock.displayFont` (the user's Font choice, defaulting to the theme font) and give large clocks `renderType: Text.CurveRendering` so they stay sharp at any size. For depth they shade the theme background with `lock.deepen(color, factor)`, which darkens on dark themes and lightens on light ones so panels always move away from the text color, and `lock.raise()` for the opposite; plain `Qt.darker` is kept only for things that are dark on any theme, such as shadows and silhouettes. Marker comments in the first lines of a file describe it to the picker:

```qml
// source: qylock          third-party badge (or wallsflow, or anything)
// timebased: 1            "time-based" badge
// name: Honkai: Star Rail  overrides the name derived from the file name
// description: Video from YouTube
```

A design that fetches assets needs an entry in `designs/thirdparty-assets.json`; run `tools/pin-assets.sh <commit>` afterwards to fill in the URLs, digests and sizes. Designs are compiled from their file contents each time the lock or preview loads them, so edits are picked up without restarting the shell; the picker's live thumbnails re-render when you reopen it. The shared components (`DesignBase`, `PasswordField`, `LockInput`, `Avatar`) are cached by the QML engine, so after editing those run `omarchy restart shell`.

Validate before publishing:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.smoothpixels.lock-designs
/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell -I /usr/lib/qt6/qml Service.qml LockHost.qml Picker.qml designs/*.qml
tools/verify-assets.sh
```

If a lock screen change ever leaves you unable to unlock, switch to a TTY (Ctrl+Alt+F3), log in, and run `omarchy plugin disable io.github.smoothpixels.lock-designs && omarchy plugin enable omarchy.lock`, then `omarchy restart shell`.

See [NOTICE.md](NOTICE.md) for the full licensing picture.
