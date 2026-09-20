#!/bin/bash
# Installs the Lock Screen Explorer plugin (if it is not already present)
# and puts these designs where that plugin auto-discovers them.
set -euo pipefail

PLUGIN_ID="io.github.sirjul1337.lock-explorer"
PLUGIN_URL="https://github.com/SirJul1337/omarchy-lock-explorer.git"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
DESIGNS_DIR="$HOME/.config/omarchy/lock-designs"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$PLUGINS_DIR/$PLUGIN_ID" ]]; then
  echo "Lock Screen Explorer is not installed, adding it first."
  omarchy plugin add "$PLUGIN_URL" --enable
else
  echo "Lock Screen Explorer already installed, skipping."
fi

if [[ "$SELF_DIR" != "$DESIGNS_DIR" ]]; then
  mkdir -p "$DESIGNS_DIR"
  rsync -a --exclude ".git" "$SELF_DIR/" "$DESIGNS_DIR/"
  echo "Copied designs into $DESIGNS_DIR"
fi

omarchy-shell lock rescanDesigns >/dev/null 2>&1 || true
echo "Done. Open the lock screen picker and check the Third Party tab."
