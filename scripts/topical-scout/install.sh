#!/bin/bash
# Installs the weekly scout on the iMac. Run from this repo on the Air: scripts/topical-scout/install.sh
set -euo pipefail
cd "$(dirname "$0")"
ssh imac 'mkdir -p ~/knit-scout-runner ~/.config/systemd/user'
scp -q scout.sh imac:knit-scout-runner/scout.sh
scp -q ravel-topical-scout.service ravel-topical-scout.timer imac:.config/systemd/user/
ssh imac 'chmod +x ~/knit-scout-runner/scout.sh && systemctl --user daemon-reload && systemctl --user enable --now ravel-topical-scout.timer && systemctl --user list-timers --no-pager | grep ravel-topical'
