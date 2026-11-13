# Ravel Project Guide

Knitting companion: projects, a row counter drawn as growing fabric, a pattern PDF reader, a yarn and needle stash, and a paid library of patterns that write themselves to the knitter's size. XcodeGen project/scheme: `Ravel`, sim lease owner `knit`. Public repo: `jackwallner/knit`.

## Tech Stack
- Swift 6 / SwiftUI (strict concurrency)
- SwiftData (local only, no account, works offline), PDFKit
- XcodeGen (`project.yml`). Targets: iOS 17+
- RevenueCat, entitlement `pro` (project `projfe8bceb8`, app `app5988b53b74`, offering `default`)

## Targets / bundle IDs
- `Ravel`: `com.jackwallner.knit`, App Store ID `6834244566`
- `RavelTests`: `com.jackwallner.knit.tests`
- Subscriptions (group "Ravel Patterns"): `com.jackwallner.knit.monthly` $6.99, `com.jackwallner.knit.yearly` $39.99, each with a 1-week free trial
- Lifetime (non-consumable): `com.jackwallner.knit.lifetime` $79.99. All three unlock `pro`.

## Architecture
- `Shared/Models/Models.swift`: `Project` (row count, pattern file, repeat, row band, and for library projects `designRaw` + `planData`), `Yarn`, `Needle`, the US/metric size charts.
- `Shared/Patterns`: the library. `Design.swift` lists every design with its sizes and measurements, `Engines.swift` holds the stitch math per design, `Plan.swift` is the row-by-row output (`PatternPlan`, `Step`) plus `Sizing` helpers.
- `Shared/Services`: `Persistence` (container, DEBUG demo seed), `PatternStore` (imported PDFs in Application Support/Patterns), `SubscriptionService` (RevenueCat, `Offer`, `Links`), `ReviewPrompt`.
- `Ravel/Views`: `RootView` (Projects, Patterns, Stash tabs), `ProjectsView`, `ProjectView` (three modes: counter, PDF reader with a work strip, guided library pattern), `Fabric` (the knitted canvas), `Garment` (a design cut from fabric), `LibraryView` + `DesignView`, `PaywallView`, `PatternView` (PDFKit), `StashView`.

## Rules that hold everywhere
- The tracker stays free: projects, row counter, your own PDFs and stash never go behind the paywall, never need an account and never need a network. The closest competitor (Knit&Note) sank to 3.9 stars by paywalling exactly these.
- Only the pattern library is paid, billed through Apple, with the price on the paywall before anything else. `Design.isFree` marks the two free designs.
- A row count must never be lost. Counts write straight to the SwiftData model; do not add a sync layer that can drop them.
- A library project keeps its own frozen copy of the plan (`Project.planData`), so an engine change or a lapsed subscription never alters or removes a pattern someone has cast on.
- Every engine change must keep `PatternTests` green: they run every design at every size and yarn weight and check that stitch counts carry from step to step.
- Patterns carry no designer name. Never add invented people, bylines or bios to the library or the store listing.
- `Project.patternFile` is a file name, never a full path (the container path changes between installs).
- `Purchases.configure` never runs on a simulator. Use `-MockProducts`, `-Pro` or `SubscriptionService.shared.setLocalOverride(isPro:)`.
- No em dashes in copy, comments or commits.

## Launch arguments (DEBUG)
- `-SeedDemo`: in-memory store with three projects (one PDF, one library pattern), yarns and needles. `-NoPattern` drops the PDF.
- `-UITesting`: empty in-memory store.
- `-OpenFirst`, `-OpenProject <name>`: land inside a project.
- `-Tab <0|1|2>`, `-OpenDesign <Design raw value>`: land on a tab or a design page.
- `-MockProducts`: sample offers on the paywall. `-Pro`: entitlement on. `-PaywallSnapshot yearly|monthly|lifetime`: open the paywall on that plan. With none of these, a DEBUG simulator build sells the products in `Ravel.storekit` through StoreKit Testing when the scheme runs it (Xcode run or `xcodebuild test`).

## App-specific notes
- Store name: "Ravel: Knitting Patterns". Metadata in `fastlane/metadata/en-US`. Site (GitHub Pages, `/docs`): `https://jackwallner.github.io/knit/`.
- Rating ask: `ReviewPrompt`, fired 3 seconds after a project is marked finished, from the second launch on, 30-day cooldown. "Rate Ravel" and "Send Feedback" live in the Projects tab's menu.
- `scripts/asc-register-identifiers.py`, `asc-pricing-availability.py`, `asc-setup-subscriptions.py`, `asc-setup-lifetime-iap.py` set up App Store Connect and are safe to rerun. `scripts/draw-icon.swift` redraws the app icon.
- Non-site docs go in `project-docs/<category>/`, because `docs/` is the published site.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing, ratings ask, gotchas):
the global agent rules + the `ios-dev` skill.
