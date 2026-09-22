#!/bin/bash
# Optional: publish the pinned asset set as a GitHub release on this repo and
# add each file's release URL to the catalog as a mirror. The downloader tries
# `url` first and then each entry in `mirrors`, and the SHA-256 in the catalog
# has to match whichever source answered, so a mirror never weakens
# verification. It only removes the dependency on the upstream repository
# staying online.
#
# Read before running: this makes you the redistributor of every video, image
# and font in the catalog. The qylock repository is GPL-3.0 but most of those
# files are game and anime footage and a few proprietary fonts that Darkkal44
# does not own either. Mirroring them is a licensing decision, not a technical
# one. Fonts under the SIL Open Font License (Outfit, Orbitron, Figtree, Itim,
# Pixelify Sans, Cinzel, Tektur, DejaVu) are safe to mirror; Google Sans and
# Nothing's NDot55/NType82 are not freely redistributable.
#
#   tools/mirror-assets.sh <release-tag> [--fonts-only]
#
# Requires the pin cache from tools/pin-assets.sh for the commit the catalog is
# pinned to, and an authenticated `gh`.
set -euo pipefail

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$PLUGIN_DIR/designs/thirdparty-assets.json"
TAG="${1:-}"
FONTS_ONLY=0
[[ ${2:-} == "--fonts-only" ]] && FONTS_ONLY=1
[[ -n $TAG ]] || { echo "usage: tools/mirror-assets.sh <release-tag> [--fonts-only]" >&2; exit 1; }
for tool in jq gh sha256sum; do command -v "$tool" >/dev/null || { echo "missing $tool" >&2; exit 1; }; done

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
COMMIT=$(jq -r '[.[] | .files[] | .url] | map(capture("qylock/(?<c>[0-9a-f]{40})/").c) | first' "$CATALOG")
[[ $COMMIT =~ ^[0-9a-f]{40}$ ]] || { echo "catalog is not pinned to a commit, run tools/pin-assets.sh first" >&2; exit 1; }
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lock-designs/pin/$COMMIT"
[[ -d $CACHE ]] || { echo "no pin cache at $CACHE, run tools/pin-assets.sh $COMMIT" >&2; exit 1; }

gh release view "$TAG" >/dev/null 2>&1 || gh release create "$TAG" --title "Assets $TAG" --notes "Verified asset mirror for designs/thirdparty-assets.json. Every file's SHA-256 is recorded in the catalog." --latest=false

results="$(mktemp)"
trap 'rm -f "$results"' EXIT
while IFS=$'\t' read -r id path sha; do
  if (( FONTS_ONLY )) && [[ ! ${path,,} =~ \.(ttf|otf)$ ]]; then continue; fi
  src="$CACHE/$id/$path"
  [[ -f $src ]] || { echo "missing from cache: $src" >&2; exit 1; }
  got=$(sha256sum "$src" | cut -d' ' -f1)
  [[ $got == "$sha" ]] || { echo "cache file does not match catalog digest: $id/$path" >&2; exit 1; }
  # Release asset names are flat; keep them unique and readable.
  asset="${id#my-}--${path//\//__}"
  echo "uploading $asset"
  gh release upload "$TAG" "$src#$asset" --clobber >/dev/null
  printf '%s\t%s\t%s\n' "$id" "$path" "https://github.com/$REPO/releases/download/$TAG/$asset" >> "$results"
done < <(jq -r 'to_entries[] | .key as $id | .value.files[] | [$id, .path, .sha256] | @tsv' "$CATALOG")

merged=$(jq -Rs 'split("\n") | map(select(length > 0) | split("\t")) | map({ key: (.[0] + "\t" + .[1]), value: .[2] }) | from_entries' "$results")
jq --argjson m "$merged" '
  to_entries
  | map(.key as $id | .value.files |= map(. as $f | ($m[$id + "\t" + $f.path]) as $url
      | if $url == null then $f else $f + { mirrors: ((($f.mirrors // []) | map(select(. != $url))) + [$url]) } end))
  | from_entries' "$CATALOG" > "$CATALOG.tmp"
mv -f "$CATALOG.tmp" "$CATALOG"
echo "Added release mirrors to designs/thirdparty-assets.json (release $TAG on $REPO)"
