#!/bin/bash
# Turns the generated sample photos in project-docs/sample-photos/raw/<design>.png into the app's
# asset catalog (Ravel/Assets.xcassets/Samples/sample-<design>.imageset), 1000 px HEIC.
set -euo pipefail
cd "$(dirname "$0")/.."
out=Ravel/Assets.xcassets/Samples
mkdir -p "$out"
printf '{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' > "$out/Contents.json"
for raw in project-docs/sample-photos/raw/*.png; do
  id=$(basename "$raw" .png)
  set_dir="$out/sample-$id.imageset"
  mkdir -p "$set_dir"
  sips -s format heic -s formatOptions 60 -Z 1000 "$raw" --out "$set_dir/sample-$id.heic" >/dev/null
  printf '{\n  "images" : [ { "filename" : "sample-%s.heic", "idiom" : "universal" } ],\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' "$id" > "$set_dir/Contents.json"
done
du -sh "$out"
