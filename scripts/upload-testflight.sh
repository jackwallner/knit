#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 1
exec "$HOME/ios/release/testflight.sh" --project Ravel.xcodeproj --scheme Ravel --upload-only "$@"
