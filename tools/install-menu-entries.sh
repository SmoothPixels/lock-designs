#!/bin/bash
# Opt-in: adds (or refreshes) a "Style > Lock Designs" row in the Omarchy menu
# that opens the Lock Designs picker, by splicing
# extensions/omarchy-menu.snippet.jsonc into your own
# ~/.config/omarchy/extensions/omarchy-menu.jsonc. Nothing in the plugin runs
# this for you; run it yourself, and again after an update if the snippet
# changes.
#
# The row uses the `style.lockscreen` key, the one earlier lock screen picker
# rows used, so an existing row with that key is replaced, not duplicated. It
# runs `omarchy-shell lock explore`, which this plugin answers.
#
#   tools/install-menu-entries.sh            # add or refresh the row
#   tools/install-menu-entries.sh --remove   # drop it again
set -euo pipefail

REMOVE=0
[[ ${1:-} == "--remove" ]] && REMOVE=1

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SNIPPET="$PLUGIN_DIR/extensions/omarchy-menu.snippet.jsonc"
TARGET="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

[[ -f $SNIPPET ]] || { echo "Missing $SNIPPET" >&2; exit 1; }

if (( REMOVE )); then
  [[ -f $TARGET ]] || { echo "No $TARGET, nothing to remove"; exit 0; }
else
  mkdir -p "$(dirname "$TARGET")"
  if [[ ! -f $TARGET ]]; then
    printf '{\n}\n' > "$TARGET"
  fi
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Drop the rows this plugin owns or supersedes (its own key, and the key from
# earlier versions of this installer), then splice the snippet in before the
# closing brace. The row before the splice point gets a trailing comma if it
# lacks one; JSONC tolerates a trailing comma on the last row, never a
# missing one between rows.
awk -v snippet="$SNIPPET" -v remove="$REMOVE" '
  /^[[:space:]]*"style\.lockscreen"[[:space:]]*:/ { next }
  /^[[:space:]]*"style\.lock-designs"[[:space:]]*:/ { next }
  { lines[++n] = $0 }
  END {
    close_at = 0
    for (i = n; i >= 1; i--) if (lines[i] ~ /^}[[:space:]]*$/) { close_at = i; break }
    if (close_at == 0) { for (k = 1; k <= n; k++) print lines[k]; exit }
    if (remove) {
      # The row that is now last must not end with a comma.
      for (j = close_at - 1; j >= 1; j--) {
        if (lines[j] ~ /^[[:space:]]*$/ || lines[j] ~ /^[[:space:]]*\/\//) continue
        sub(/,[[:space:]]*$/, "", lines[j])
        break
      }
      for (k = 1; k <= n; k++) print lines[k]
      exit
    }
    for (j = close_at - 1; j >= 1; j--) {
      if (lines[j] ~ /^[[:space:]]*$/ || lines[j] ~ /^[[:space:]]*\/\//) continue
      if (lines[j] !~ /[,{][[:space:]]*$/) lines[j] = lines[j] ","
      break
    }
    for (k = 1; k < close_at; k++) print lines[k]
    while ((getline line < snippet) > 0) if (line !~ /^[[:space:]]*\/\//) print line
    for (k = close_at; k <= n; k++) print lines[k]
  }
' "$TARGET" > "$tmp"
mv "$tmp" "$TARGET"
trap - EXIT

if (( REMOVE )); then
  echo "Removed the Style > Lock Designs row from $TARGET"
else
  echo "Added Style > Lock Designs to $TARGET"
fi
echo "The shell watches this file, so the menu should update within a second or two."
