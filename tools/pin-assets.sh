#!/bin/bash
# Pin every on-demand asset in designs/thirdparty-assets.json to one full
# qylock commit and record a SHA-256 digest (and byte size) for each file.
#
# The downloader in Service.qml refuses any catalog entry without a digest
# and rejects any download whose digest does not match, so this is the one
# place the trust decision is made: run it, review the diff, commit it.
#
#   tools/pin-assets.sh <40-char-commit> [cache-dir]
#
# Files are fetched into the cache dir (default ~/.cache/lock-designs/pin/
# <commit>) and reused on later runs, so re-pinning the same commit after a
# catalog edit costs no bandwidth.
set -euo pipefail

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$PLUGIN_DIR/designs/thirdparty-assets.json"
COMMIT="${1:-}"
CACHE="${2:-${XDG_CACHE_HOME:-$HOME/.cache}/lock-designs/pin/$COMMIT}"

if [[ ! $COMMIT =~ ^[0-9a-f]{40}$ ]]; then
  echo "usage: tools/pin-assets.sh <full 40-character commit sha> [cache-dir]" >&2
  exit 1
fi
for tool in jq curl sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing $tool" >&2; exit 1; }
done
[[ -f $CATALOG ]] || { echo "no catalog at $CATALOG" >&2; exit 1; }

mkdir -p "$CACHE"
results="$(mktemp)"
trap 'rm -f "$results"' EXIT

# One line per file: design id, relative path, current url.
total=$(jq -r '[.[] | .files[]] | length' "$CATALOG")
n=0
while IFS=$'\t' read -r id path url; do
  n=$((n + 1))
  # Only qylock URLs are re-pointed; anything else (a mirror the maintainer
  # added by hand) keeps its URL and just gets hashed.
  pinned=$(sed -E "s#(raw\.githubusercontent\.com/Darkkal44/qylock/)[^/]+/#\1$COMMIT/#" <<<"$url")
  target="$CACHE/$id/$path"
  mkdir -p "$(dirname "$target")"
  if [[ ! -s $target ]]; then
    printf '[%2d/%d] %s/%s\n' "$n" "$total" "$id" "$path"
    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 20 -o "$target.part" "$pinned"
    mv -f "$target.part" "$target"
  else
    printf '[%2d/%d] %s/%s (cached)\n' "$n" "$total" "$id" "$path"
  fi
  sha=$(sha256sum "$target" | cut -d' ' -f1)
  size=$(stat -c%s "$target")
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$path" "$pinned" "$sha" "$size" >> "$results"
done < <(jq -r 'to_entries[] | .key as $id | .value.files[] | [$id, .path, .url] | @tsv' "$CATALOG")

# Merge the results back into the catalog, keeping every other field and the
# original key order.
merged=$(jq -Rs '
  split("\n") | map(select(length > 0) | split("\t"))
  | map({ key: (.[0] + "\t" + .[1]), value: { url: .[2], sha256: .[3], size: (.[4] | tonumber) } })
  | from_entries' "$results")

jq --argjson m "$merged" --arg commit "$COMMIT" '
  to_entries
  | map(.key as $id | .value.files |= map(. + $m[$id + "\t" + .path]))
  | from_entries' "$CATALOG" > "$CATALOG.tmp"
mv -f "$CATALOG.tmp" "$CATALOG"

echo
echo "Pinned $total files to $COMMIT and wrote digests to designs/thirdparty-assets.json"
echo "Cache: $CACHE"
