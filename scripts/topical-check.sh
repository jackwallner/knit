#!/bin/bash
# Checks every topical design record at every size and allowed yarn weight, with the same rules the
# app's tests use, and draws a preview of each. Exits 1 on any bad record.
#   scripts/topical-check.sh                      published list and every draft
#   scripts/topical-check.sh file.json ...        just these files
#   PREVIEWS=dir scripts/topical-check.sh         previews somewhere else (default project-docs/topical/previews)
#   scripts/topical-check.sh --print <id> ...     also print that design's pattern at its default size
set -euo pipefail
cd "$(dirname "$0")/.."

build="${TMPDIR:-/tmp}/ravel-topical-check"
mkdir -p "$build"
sources=(Shared/Patterns/*.swift Shared/Models/Models.swift Shared/Utilities/Loc.swift scripts/topical-check/*.swift)
binary="$build/topical-check"
if [[ ! -x "$binary" ]] || [[ -n "$(find "${sources[@]}" -newer "$binary" 2>/dev/null)" ]]; then
  swiftc -swift-version 6 -o "$binary" "${sources[@]}"
fi

args=()
files=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --print) args+=(--print "$2"); shift 2 ;;
    *) files+=("$1"); shift ;;
  esac
done
if [[ ${#files[@]} -eq 0 ]]; then
  [[ -f docs/designs.json ]] && files+=(docs/designs.json)
  for draft in project-docs/topical/drafts/*.json; do [[ -f "$draft" ]] && files+=("$draft"); done
fi
exec "$binary" --previews "${PREVIEWS:-project-docs/topical/previews}" "${args[@]+"${args[@]}"}" "${files[@]}"
