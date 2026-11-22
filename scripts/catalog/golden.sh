#!/bin/bash
# Proves existing designs are unchanged: every built-in design, the bundled collection and the published
# records, at every size and yarn weight, hashed. Writes the list, or with --check compares against it.
#   scripts/catalog/golden.sh            rewrite project-docs/catalog/golden.txt (only at a known-good commit)
#   scripts/catalog/golden.sh --check    exit 1 if any existing line changed or went missing
set -euo pipefail
cd "$(dirname "$0")/../.."
build="${TMPDIR:-/tmp}/ravel-golden"
mkdir -p "$build"
sources=(Shared/Patterns/*.swift Shared/Models/Models.swift Shared/Utilities/Loc.swift scripts/topical-check/Stubs.swift scripts/catalog/Golden.swift)
binary="$build/golden"
if [[ ! -x "$binary" ]] || [[ -n "$(find "${sources[@]}" -newer "$binary" 2>/dev/null)" ]]; then
  swiftc -swift-version 6 -parse-as-library -O -o "$binary" "${sources[@]}"
fi
golden=project-docs/catalog/golden.txt
records=(Ravel/collection.json)
[[ -f docs/designs.json ]] && records+=(docs/designs.json)
if [[ "${1:-}" == "--check" ]]; then
  now="$build/now.txt"
  LANG=en_US.UTF-8 "$binary" "${records[@]}" > "$now"
  # Every golden line must still be there, word for word. New designs only add lines.
  missing=$(comm -23 <(sort "$golden") <(sort "$now") | wc -l | tr -d ' ')
  total=$(wc -l < "$golden" | tr -d ' ')
  if [[ "$missing" != "0" ]]; then
    echo "FAIL: $missing of $total existing plans changed"
    comm -23 <(sort "$golden") <(sort "$now") | awk '{print $1}' | sort | uniq -c | head -40
    exit 1
  fi
  echo "ok: all $total existing plans unchanged"
else
  mkdir -p "$(dirname "$golden")"
  LANG=en_US.UTF-8 "$binary" "${records[@]}" > "$golden"
  echo "wrote $(wc -l < "$golden" | tr -d ' ') lines to $golden"
fi
