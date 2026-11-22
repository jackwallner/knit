#!/bin/bash
# Checks a built-in design at every size and weight and prints its pattern at both ends of its sizes.
#   scripts/catalog/inspect.sh <Design raw value> [weight]
set -euo pipefail
cd "$(dirname "$0")/../.."
build="${TMPDIR:-/tmp}/ravel-inspect"
mkdir -p "$build"
sources=(Shared/Patterns/*.swift Shared/Models/Models.swift Shared/Utilities/Loc.swift scripts/topical-check/Stubs.swift scripts/catalog/Inspect.swift)
binary="$build/inspect"
if [[ ! -x "$binary" ]] || [[ -n "$(find "${sources[@]}" -newer "$binary" 2>/dev/null)" ]]; then
  swiftc -swift-version 6 -parse-as-library -o "$binary" "${sources[@]}"
fi
LANG=en_US.UTF-8 exec "$binary" "$@"
