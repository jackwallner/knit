# Ravel Project Guide

Knitting companion: projects, row counter, pattern PDF reader and yarn stash, with a paid pattern library planned. XcodeGen project/scheme: `Ravel`, sim lease owner `knit`.

## Tech Stack
- Swift 6 / SwiftUI (strict concurrency)
- SwiftData (local only, no account, works offline), PDFKit
- XcodeGen (`project.yml`). Targets: iOS 17+
- RevenueCat not added yet. It arrives with the pattern library, entitlement `pro`.

## Targets / bundle IDs
- `Ravel`: `com.jackwallner.knit`
- `RavelTests`: `com.jackwallner.knit.tests`

## Architecture
- `Shared/Models/Models.swift`: `Project` (row count, pattern file, notes) and `Yarn` (stash item), both SwiftData models.
- `Shared/Services/Persistence.swift`: the model container, plus the DEBUG demo seed.
- `Shared/Services/PatternStore.swift`: imported PDFs, copied into Application Support/Patterns.
- `Ravel/Views`: `RootView` (Projects and Stash tabs), `ProjectsView` (list), `ProjectView` (counter, or pattern with a counter bar), `PatternView` (PDFKit), `StashView`.

## Rules that hold everywhere
- The tracker stays free: projects, row counter, your own PDFs and stash never go behind the paywall, never need an account and never need a network. The closest competitor (Knit&Note) sank to 3.9 stars by paywalling exactly these.
- Only the pattern library and extras are paid, billed through Apple, with the price shown before any setup.
- A row count must never be lost. Counts write straight to the SwiftData model; do not add a sync layer that can drop them.
- `Project.patternFile` is a file name, never a full path (the container path changes between installs).

## Launch arguments (DEBUG)
- `-SeedDemo`: in-memory store with three projects, a sample pattern and three yarns.
- `-UITesting`: empty in-memory store.

## App-specific notes
- Store name: "Ravel: Knitting Patterns". No App Store Connect record yet.
- Rating ask not wired yet. Positive moment: marking a project finished.
- `scripts/draw-icon.swift` redraws the app icon.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing, ratings ask, gotchas):
the global agent rules + the `ios-dev` skill.
