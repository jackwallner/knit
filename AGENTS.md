# Ravel Project Guide

Knitting companion: projects, a row counter drawn as growing fabric, a pattern PDF reader, a yarn and needle stash, and a paid library of patterns that write themselves to the knitter's size. XcodeGen project/scheme: `Ravel`, sim lease owner `knit`. Public repo: `jackwallner/knit`.

## Tech Stack
- Swift 6 / SwiftUI (strict concurrency)
- SwiftData (local only, no account, works offline), PDFKit
- XcodeGen (`project.yml`). Targets: iOS 17+, iPhone (portrait) and iPad (every orientation)
- RevenueCat, entitlement `pro` (project `projfe8bceb8`, app `app5988b53b74`, offering `default`)

## Targets / bundle IDs
- `Ravel`: `com.jackwallner.knit`, App Store ID `6834244566`
- `RavelWidgets`: `com.jackwallner.knit.widgets`, the Lock Screen row counter (a Live Activity). No store, no strings of its own.
- `RavelTests`: `com.jackwallner.knit.tests`
- Subscriptions (group "Ravel Patterns"): `com.jackwallner.knit.monthly` $6.99, `com.jackwallner.knit.yearly` $39.99, each with a 1-week free trial
- Lifetime (non-consumable): `com.jackwallner.knit.lifetime` $79.99. All three unlock `pro`.

## Architecture
- `Shared/Models/Models.swift`: `Project` (row count, pattern file, repeat, row band, and for library projects `designRaw` + `planData`; an optional stash yarn and one optional second counter), `Yarn` (with yardage per skein, fiber, dye lot), `Needle`, the US/metric size charts. `Shared/Models/Schema.swift`: `SchemaV1` and `SchemaV2` (frozen copies of earlier shapes, never edit), `SchemaV3` (the live models) and the migration plan. Before changing a stored property, freeze the live models as the next `SchemaVn` snapshot and add a stage.
- `Shared/Patterns`: the library. `Design.swift` lists every design with its sizes and measurements, `Engines.swift` holds the stitch math per design, `Plan.swift` is the row-by-row output (`PatternPlan`, `Step`) plus `Sizing` helpers. `Colorwork.swift` paints stripes and charts over a plan, `Topical.swift` reads topical designs published as data, `PlanCheck.swift` holds the checks every plan must pass, `GarmentShape.swift` the outlines.
- `Shared/Services`: `Persistence` (container, DEBUG demo seed), `PatternStore` (imported PDFs in Application Support/Patterns), `SubscriptionService` (RevenueCat, `Offer`, `Links`), `ReviewPrompt`, `Trending` (the Trending shelf: a month-aware list bundled in the app, replaced by `docs/trending.json` from the site at most once a day), `TopicalStore` (topical designs from `docs/designs.json`, the bundled colorwork collection in `Ravel/collection.json`, and `LibraryItem`, a built-in or topical design), `Backup` (one `.ravelbackup` file of everything; restoring only adds), `Search` (`LibrarySearch`: how a typed search finds designs), `Taste` (the two onboarding answers, kept in UserDefaults: the shelf asked for leads the library, and a new knitter sees each shelf easiest first; they never hide a design).
- `Shared/Counting` + `Ravel/LockCounter.swift` + `RavelWidgets`: counting from the Lock Screen. `CountRowIntent` is a `LiveActivityIntent`, so it runs in the app's process and counts through `LockCounter.count` on the app's own container.
- `Ravel/Views`: `RootView` (Projects, Patterns, Stash tabs), `ProjectsView`, `ProjectView` (three modes: counter, PDF reader with a work strip, guided library pattern), `Fabric` (the knitted canvas), `Garment` (a design cut from fabric), `LibraryView` + `DesignView`, `PaywallView`, `PatternView` (PDFKit), `StashView`.

## Rules that hold everywhere
- The tracker stays free: projects, row counter, your own PDFs and stash never go behind the paywall, never need an account and never need a network. The closest competitor (Knit&Note) sank to 3.9 stars by paywalling exactly these.
- Only the pattern library is paid, billed through Apple, with the price on the paywall before anything else. `Design.isFree` marks the two free designs.
- A row count must never be lost. Every change to a count goes through the counter rules in the `Project` extension (`knit`, `unknit`, `jump`, `resetCount`), which end in `persist()`, a save to disk; never change `rows` from a view. Do not add a sync layer that can drop counts. A store that will not open shows `StoreUnavailableView` and is left alone; never fall back to an in-memory store.
- The Lock Screen counter never opens a store of its own and never writes `rows`: it calls `knit` and `unknit` on the app's container (`LockCounter.container`). Keep it a `LiveActivityIntent`; a plain `AppIntent` would run in the widget's process and be a second writer. The pool's slim simulators cannot run its button (`linkd` is off) and a hosted simulator is too slow for it: prove it on a `--widgets` lease restored to stock (`simslim off <udid>`, boot with `AGENT_SIM_SLIM=0`) with `GH_SIM_OVERFLOW=0 xcodebuild test -only-testing:RavelUITests/LockCounterUITests`, and read the result for passed, not skipped.
- A backup restore only adds projects, yarns and needles it does not already find (name plus creation date), so it can never set a count back.
- The second counter (`tally*`) has its own rules in the `Project` extension and never reads or writes `rows`. Deleting a stash yarn only empties `Project.stashYarn`.
- A library project keeps its own frozen copy of the plan (`Project.planData`), so an engine change or a lapsed subscription never alters or removes a pattern someone has cast on. A plan saved by any shipped version must keep decoding: read every key added to `Step` or `PatternPlan` after 1.0 with `decodeIfPresent` in their `init(from:)` (`testPlanSavedByVersionOneStillOpens`).
- Every engine change must keep `PatternTests` green: they run every design at every size and yarn weight and check that stitch counts carry from step to step. Engines close with `Engines.pattern`, which never states less yarn than the written rows use plus 15 percent. Body measurements are the wearer's; the pullover adds `Design.sweaterEase`. Flat sections worked inside a piece in the round must end with the right side facing.
- Patterns carry no designer name. Never add invented people, bylines or bios to the library or the store listing.
- `Project.patternFile` is a file name, never a full path (the container path changes between installs).
- `Purchases.configure` never runs on a simulator. Use `-MockProducts`, `-Pro` or `SubscriptionService.shared.setLocalOverride(isPro:)`.
- Patterns are sized in inches and yards underneath. Every length a person reads goes through `Sizing.inches`, `Sizing.cable`, `Sizing.yardage` or `Sizing.swatch`, which print centimeters and meters outside the United States (`Units.current`). Never hardcode "in" or "yd".
- A knitter's pattern report is believed until the rebuilt plan proves otherwise. Report code, triage, regression tests and offering a corrected pattern to cast-on projects: `.claude/rules/pattern-reports.md`.
- Topical designs: records in `docs/designs.json` are published only with Jack's yes, and every record must pass `scripts/topical-check.sh`. Loop, format and rules: `.claude/rules/topical-loop.md`.
- `docs/trending.json` names `Design` raw values or colorwork ids (collection or published). A design the installed build does not know is skipped, so add a new built-in design to the list only after the build that carries it is live. `TrendingTests.testPublishedListDecodes` reads the file. Edit it, `docs/designs.json` and the onboarding trial plan remotely with `scripts/remote.py` (`.claude/rules/topical-loop.md`).
- The interface is translated into every listing language (`Ravel/Localizable.xcstrings`, generated from `scripts/l10n`). New UI text needs a key in every language. Generated pattern instructions stay English on purpose. Rules, source files and the build step: `.claude/rules/localization.md`.
- The first-run onboarding ends on a trial page built to the fleet spec: the trial button in the exact frame of Continue, a "Get Started" soft exit, legal footer space on every page, the monthly plan keeping its free-trial intro. Spec and how Ravel does it: `.claude/rules/onboarding-trial.md`.
- No em dashes in copy, comments or commits.
- iPad layouts switch on the space a view has, never on the device: `Ravel/Views/Layout.swift`. Thresholds, per-screen layouts, why iPhone stays portrait, and the capture test: `.claude/rules/ipad-layout.md`.

## Launch arguments (DEBUG)
- `-Onboarding`: show first-launch onboarding (a fresh install sees it once; `-SeedDemo`, `-UITesting` and `-PaywallSnapshot` skip it otherwise).
- `-SeedDemo`: in-memory store with three projects (one PDF, one library pattern), yarns and needles. `-NoPattern` drops the PDF. Seeded and `-UITesting` runs never fetch the trending list.
- `-UITesting`: empty in-memory store.
- `-OpenFirst`, `-OpenProject <name>`: land inside a project.
- `-OpenDetails`: open the project's details sheet. `-OpenYarn`: open the first yarn's editor.
- `-Tab <0|1|2>`, `-OpenDesign <Design raw value>`: land on a tab or a design page. `-DesignSize <name>` opens it at a named size.
- `-OnboardingPlan yearly`: the onboarding trial sells yearly, as RevenueCat's `onboarding_plan` metadata would.
- `-TopicalFile <path>`: load topical records from a file on disk (drafts) instead of the site.
- `-MockProducts`: sample offers on the paywall. `-Pro`: entitlement on. `-PaywallSnapshot yearly|monthly|lifetime`: open the paywall on that plan. With none of these, a DEBUG simulator build sells the products in `Ravel.storekit` through StoreKit Testing when the scheme runs it (Xcode run or `xcodebuild test`).

## App-specific notes
- Store name: "Ravel: Knitting Patterns". Metadata in `fastlane/metadata/en-US`. Site (GitHub Pages, `/docs`): `https://jackwallner.github.io/knit/`.
- Rating ask: `ReviewPrompt`, fired 3 seconds after a project is marked finished, or back at the project list after a visit of 20 or more rows, from the second launch on, 30-day cooldown. "Rate Ravel" and "Send Feedback" live in the Projects tab's menu.
- `scripts/asc-register-identifiers.py`, `asc-pricing-availability.py`, `asc-setup-subscriptions.py`, `asc-setup-lifetime-iap.py` set up App Store Connect and are safe to rerun. `scripts/draw-icon.swift` redraws the app icon (stockinette in mixed oranges). `AppIcon-Ball`, `AppIcon-Beanie` and `AppIcon-Needles` are in the build only so the store can test them against it (Product Page Optimization); they are pictures, not drawn by the script, and nothing in the app switches icons.
- Non-site docs go in `project-docs/<category>/`, because `docs/` is the published site. The 2026-11-13 pre-release audit and its findings ledger are in `project-docs/audit/`.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing, ratings ask, gotchas):
the global agent rules + the `ios-dev` skill.
