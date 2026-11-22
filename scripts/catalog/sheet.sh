#!/bin/bash
# Draws a batch contact sheet and writes each design's printed pattern at its default size.
#   scripts/catalog/sheet.sh <batch number> <id>...
# An id is a Design raw value or a bundled collection record id. Output: project-docs/catalog/batches/.
set -euo pipefail
cd "$(dirname "$0")/../.."
build="${TMPDIR:-/tmp}/ravel-sheet"
mkdir -p "$build"
sources=(Shared/Patterns/*.swift Shared/Models/Models.swift Shared/Utilities/Loc.swift scripts/topical-check/Stubs.swift scripts/catalog/Sheet.swift)
binary="$build/sheet"
if [[ ! -x "$binary" ]] || [[ -n "$(find "${sources[@]}" -newer "$binary" 2>/dev/null)" ]]; then
  swiftc -swift-version 6 -parse-as-library -o "$binary" "${sources[@]}"
fi
batch="$1"; shift
out="project-docs/catalog/batches/batch-$(printf %02d "$batch")"
mkdir -p "$out/patterns"
LANG=en_US.UTF-8 "$binary" "$out/contact-sheet.png" "$@"
for id in "$@"; do
  one="$build/record-$id.json"
  python3 -c "import json,sys; d=[r for r in json.load(open('Ravel/collection.json'))['designs'] if r['id']==sys.argv[1]]; d and json.dump({'designs': d}, open(sys.argv[2], 'w'))" "$id" "$one"
  if [[ -s "$one" ]]; then
    # A record prints in its own colors and stitch, at its smallest and largest size.
    PREVIEWS="$build" scripts/topical-check.sh --print "$id" "$one" | grep -v "^ *preview \|checked, all pass" > "$out/patterns/$id.txt"
    rm -f "$one"
  else
    scripts/catalog/inspect.sh "$id" > "$out/patterns/$id.txt"
  fi
done
echo "patterns in $out/patterns"
