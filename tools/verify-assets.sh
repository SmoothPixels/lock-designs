#!/bin/bash
# Checks every downloaded asset in ~/.config/omarchy/lock-designs against the
# SHA-256 digests in the catalog. Files that are not downloaded are reported
# as missing, not as failures; a mismatch is a failure and makes this exit 1.
#
#   tools/verify-assets.sh [designs-dir]
set -euo pipefail

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DESIGNS_DIR="${1:-$HOME/.config/omarchy/lock-designs}"
CATALOG="$DESIGNS_DIR/thirdparty-assets.json"
[[ -f $CATALOG ]] || CATALOG="$PLUGIN_DIR/designs/thirdparty-assets.json"
command -v jq >/dev/null || { echo "missing jq" >&2; exit 1; }

ok=0; missing=0; bad=0; unpinned=0
while IFS=$'\t' read -r id dir path sha; do
  file="$DESIGNS_DIR/$dir/$path"
  if [[ -z $sha || $sha == null ]]; then
    echo "UNPINNED  $id/$path (no digest in catalog)"; unpinned=$((unpinned + 1)); continue
  fi
  if [[ ! -f $file ]]; then
    missing=$((missing + 1)); continue
  fi
  got=$(sha256sum "$file" | cut -d' ' -f1)
  if [[ $got == "$sha" ]]; then
    ok=$((ok + 1))
  else
    echo "MISMATCH  $id/$path"
    echo "          expected $sha"
    echo "          got      $got"
    bad=$((bad + 1))
  fi
done < <(jq -r 'to_entries[] | .key as $id | .value.assetsDir as $dir | .value.files[] | [$id, $dir, .path, (.sha256 // "")] | @tsv' "$CATALOG")

echo "verified: $ok  not downloaded: $missing  mismatched: $bad  unpinned: $unpinned"
[[ $bad -eq 0 && $unpinned -eq 0 ]]
