#!/bin/bash
# Weekly topical scout for Ravel, run by a systemd user timer on the iMac. It drafts 1 to 3 topical
# design records and opens a draft PR with them. It never edits docs/, never merges and never publishes:
# CI checks the drafts and uploads previews, and Jack decides.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

repo="$HOME/knit-scout"
[[ -d "$repo/.git" ]] || git clone -q https://github.com/jackwallner/knit "$repo"
cd "$repo"
git fetch -q origin
git reset -q --hard
git clean -qfd
branch="topical/$(date +%F)"
git checkout -q -B "$branch" origin/main

# Until the topical loop is on main there is nothing to scout for.
[[ -f scripts/topical-scout/prompt.md ]] || { echo "No topical loop on main yet."; exit 0; }

notes="$(mktemp)"
# The model only reads, searches the web and writes draft files. Git and GitHub stay in this script.
claude -p "$(cat scripts/topical-scout/prompt.md)" \
  --model sonnet --effort high \
  --allowedTools "Read" "Glob" "Grep" "WebSearch" "WebFetch" "Write(project-docs/topical/drafts/**)" "Edit(project-docs/topical/drafts/**)" \
  --permission-mode dontAsk \
  --output-format text > "$notes"

# Anything outside the drafts folder is thrown away.
changed="$(git status --porcelain)"
if [[ -z "$changed" ]]; then
  echo "No drafts this week."
  exit 0
fi
if grep -qv ' project-docs/topical/drafts/' <<<"$changed"; then
  echo "The scout touched files outside the drafts folder; discarding:"
  echo "$changed"
  git reset -q --hard
  git clean -qfd
  exit 1
fi

git add project-docs/topical/drafts
git commit -q -m "feat: topical drafts for the week of $(date +%F)"
git push -q -f origin "$branch"
gh pr create --draft --base main --head "$branch" \
  --title "Topical drafts, week of $(date +%F)" \
  --body-file "$notes" 2>/dev/null || gh pr edit "$branch" --body-file "$notes"
rm -f "$notes"
