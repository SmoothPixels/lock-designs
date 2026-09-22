#!/bin/bash
# Installs (or removes) the Lock Designs login screen for SDDM. Run it with
# sudo from your own account; it needs root once, to place the theme under
# /usr/share/sddm/themes and select it in /etc/sddm.conf.d. Run it again after
# updating the plugin so the login screen gets the new designs.
#
#   sudo tools/install-login-theme.sh
#   sudo tools/install-login-theme.sh --remove
#   tools/install-login-theme.sh --stage <dir>     # build only, no root, for previewing
#
# What root ends up owning: the greeter's QML, the stand-in shell modules,
# and a snapshot of every design with its imports pointed at those stand-ins.
# What your account ends up owning: theme.conf.user and the current/ folder
# inside the theme, which the plugin rewrites with the live theme colors,
# font, wallpaper copy, the chosen design's name, and a copy of its assets.
# The greeter reads those as data only, so nothing running as your user can
# put code into the login screen; a new design only reaches it through this
# installer.
set -euo pipefail

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$PLUGIN_DIR/sddm/lock-designs"
DEST=/usr/share/sddm/themes/lock-designs
CONF=/etc/sddm.conf.d/99-zz-lock-designs.conf

for f in Main.qml metadata.desktop theme.conf; do
  [[ -f $SRC/$f ]] || { echo "Missing $SRC/$f" >&2; exit 1; }
done

# Lays the theme out under $1. Files come out owned by whoever runs this.
build() {
  local dest="$1"
  mkdir -p "$dest/designs" "$dest/shim" "$dest/current/assets"
  install -m 644 -- "$SRC/Main.qml" "$SRC/metadata.desktop" "$SRC/theme.conf" "$dest/"
  cp -r -- "$SRC/shim/." "$dest/shim/"
  # Every design, with the shell imports pointed at the stand-ins.
  local f
  for f in "$PLUGIN_DIR"/designs/*.qml; do
    sed -e 's#^import qs\.Commons$#import "../shim/Commons"#' \
        -e 's#^import qs\.Ui$#import "../shim/Ui"#' \
        -e 's#^import Quickshell\.Io$#import "../shim/QuickshellIo"#' \
        -e 's#^import Quickshell$#import "../shim/Quickshell"#' \
        -- "$f" > "$dest/designs/$(basename -- "$f")"
  done
  # Designs load their media relative to themselves; each asset folder name
  # becomes a link into the user-owned current/assets, where the plugin
  # copies the chosen design's files.
  grep -h -o -E 'resolvedUrl\("[A-Za-z0-9._-]+-assets/?"\)' "$PLUGIN_DIR"/designs/*.qml \
    | sed -E 's/.*"([^"]+-assets)\/?".*/\1/' | sort -u | while read -r a; do
      ln -sfn -- "../current/assets/$a" "$dest/designs/$a"
    done
  # Fingerprint of the plugin files this snapshot was built from. The plugin
  # computes the same value from its own files and shows an "out of date"
  # notice when they differ, so the installer only needs re-running then.
  fingerprint > "$dest/snapshot.sha256"
  find "$dest" -type d -exec chmod 755 -- {} +
  find "$dest" -type f -exec chmod 644 -- {} +
}

fingerprint() {
  { cat -- "$SRC/Main.qml" "$SRC/theme.conf" "$SRC/metadata.desktop"
    find "$SRC/shim" -type f | LC_ALL=C sort | xargs cat --
    ls "$PLUGIN_DIR"/designs/*.qml | LC_ALL=C sort | xargs cat --
  } | sha256sum | cut -d" " -f1
}

if [[ ${1:-} == "--stage" ]]; then
  STAGE="${2:-}"
  [[ -n $STAGE ]] || { echo "usage: $0 --stage <dir>" >&2; exit 1; }
  build "$STAGE"
  [[ -f $STAGE/theme.conf.user ]] || : > "$STAGE/theme.conf.user"
  echo "Staged at $STAGE. Preview with: sddm-greeter-qt6 --test-mode --theme $STAGE"
  exit 0
fi

if (( EUID != 0 )); then
  echo "Run this with sudo: sudo $0 ${1:-}" >&2
  exit 1
fi
OWNER="${SUDO_USER:-}"
if [[ -z $OWNER || $OWNER == root ]]; then
  echo "Run it with sudo from your own account, so the plugin can keep the theme in sync as you." >&2
  exit 1
fi

if [[ ${1:-} == "--remove" ]]; then
  rm -rf -- "$DEST"
  rm -f -- "$CONF"
  echo "Removed the Lock Designs login screen. SDDM is back on Omarchy's own theme."
  exit 0
fi

# Rebuild the root-owned part from scratch; keep the user's config and data.
mkdir -p -- "$DEST"
find "$DEST" -mindepth 1 -maxdepth 1 ! -name current ! -name theme.conf.user -exec rm -rf -- {} +
build "$DEST"
chown -R root:root -- "$DEST/Main.qml" "$DEST/metadata.desktop" "$DEST/theme.conf" "$DEST/shim" "$DEST/designs"
chown -R "$OWNER:$OWNER" -- "$DEST/current"
chmod 755 -- "$DEST/current" "$DEST/current/assets"
if [[ ! -f $DEST/theme.conf.user ]]; then
  install -o "$OWNER" -g "$OWNER" -m 644 -- /dev/null "$DEST/theme.conf.user"
else
  chown "$OWNER:$OWNER" -- "$DEST/theme.conf.user"
  chmod 644 -- "$DEST/theme.conf.user"
fi

# Sorts after Omarchy's 99-omarchy-login.conf, which is what makes it win.
printf '[Theme]\nCurrent=lock-designs\n' > "$CONF"
chmod 644 -- "$CONF"

echo "Installed the Lock Designs login screen at $DEST ($(ls "$DEST/designs"/*.qml | wc -l) designs) and selected it in $CONF."
sudo -u "$OWNER" -- omarchy-shell -q lock syncLogin || true
echo "Choose what it shows in the picker's Login screen tab. Remove with: sudo $0 --remove"
