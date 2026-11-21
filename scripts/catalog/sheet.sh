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
  record=$(python3 -c "import json,sys; d=[r for r in json.load(open('Ravel/collection.json'))['designs'] if r['id']==sys.argv[1]]; print(d[0]['base'], d[0].get('stitch',''), d[0]['weights'][len(d[0]['weights'])//2]) if d else print('')" "$id")
  if [[ -n "$record" ]]; then
    read -r base stitch weight <<<"$record"
    scripts/catalog/inspect.sh "$base" $stitch "$weight" | sed "s/== [^,]*,/== $id,/" > "$out/patterns/$id.txt"
  else
    scripts/catalog/inspect.sh "$id" > "$out/patterns/$id.txt"
  fi
done
echo "patterns in $out/patterns"
