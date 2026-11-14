# Council Review, Round 2: Ravel 1.0

This is the Round 2 Council Review for Ravel. In accordance with council instructions, this inspection is strictly read-only: no code was edited, no commits or pushes were made, and no builds were run.

---

## Part 1: Review of Fixed Code

### 1. Counter
**Status: The fix holds (with one edge-case defect noted below in New Defects).**
- **Every count change persists:** In [Models.swift](Shared/Models/Models.swift#L82-L131), the `Project` counter extension routes every change to disk via `persist()` (`try? modelContext?.save()`). Specifically, `knit` uses `defer { persist() }` ([line 90](Shared/Models/Models.swift#L90)), `unknit` calls `persist()` ([line 105](Shared/Models/Models.swift#L105)), `jump(to:following:)` uses `defer { persist() }` ([line 109](Shared/Models/Models.swift#L109)), `jump(toTap:following:)` calls `persist()` ([line 121](Shared/Models/Models.swift#L121)), and `resetCount` calls `persist()` ([line 130](Shared/Models/Models.swift#L130)). Furthermore, [ProjectView.swift](Ravel/Views/ProjectView.swift#L106) persists in `onDisappear` ([line 106](Ravel/Views/ProjectView.swift#L106)), [RootView.swift](Ravel/Views/RootView.swift#L23) persists when the scene leaves active ([line 23](Ravel/Views/RootView.swift#L23)), and raw `.rows = ...` mutations were completely removed from the views.
- **Undo hit area and row 0 behavior:** In [ProjectView.swift](Ravel/Views/ProjectView.swift#L284-L299), the undo button remains in the view hierarchy rather than conditionally vanishing at row 0. The fade `.opacity(project.rows == 0 ? 0 : 1)` ([line 291](Ravel/Views/ProjectView.swift#L291)) is placed on the inner circle image inside `.padding(12).contentShape(Rectangle())` ([lines 292-293](Ravel/Views/ProjectView.swift#L292-L293)). The 76x76 pt target stays live and hit-testable at row 0, preventing accidental double taps from falling through to the counting canvas underneath.
- **One tap source per mode:** In [ProjectView.swift](Ravel/Views/ProjectView.swift#L42-L65):
  - *Counter mode:* The tap gesture is attached solely to the outer container ([line 64](Ravel/Views/ProjectView.swift#L64)). `work(height: nil, tags: true)` defaults to `taps: false`, setting `.allowsHitTesting(false)` on the fabric ([line 218](Ravel/Views/ProjectView.swift#L218)).
  - *Guided mode:* The tap gesture is attached solely to the outer container ([line 168](Ravel/Views/ProjectView.swift#L168)), with `work(...)` hit-testing disabled.
  - *PDF mode:* The outer container has no gesture; counting is explicitly delegated to the strip via `work(height: 112, tags: false, taps: true)` ([line 45](Ravel/Views/ProjectView.swift#L45)). No mode has competing or nested tap recognizers.
- **Finished state & Reset:** In [ProjectView.swift](Ravel/Views/ProjectView.swift#L80-L82), "Reset Count" calls `project.resetCount(following: plan)`, which sets `rows = 0`, resets `repeatStart = 0`, reopens the project if finished (`if isFinished { toggleFinished() }`), and persists ([Models.swift:125-131](Shared/Models/Models.swift#L125-L131)). For library projects, finished projects show `Text("Finished")` ([ProjectView.swift:202](Ravel/Views/ProjectView.swift#L202)), hide "Mark Active" at the final row ([line 334](Ravel/Views/ProjectView.swift#L334)), and unknitting or resetting puts them back on the needles.

---

### 2. Store That Will Not Open
**Status: The fix holds.**
- In [Persistence.swift](Shared/Services/Persistence.swift#L10-L19), `Persistence.container(inMemory:at:)` returns `ModelContainer?` instead of falling back to an in-memory store.
- In [App.swift](Ravel/App.swift#L24-L30), if `container` is `nil`, the window displays `StoreUnavailableView()` without initializing `RootView` or attempting any destructive file operations.
- In [RootView.swift](Ravel/Views/RootView.swift#L35-L53), `StoreUnavailableView` explains that projects are still safe on the device, suggests restarting, and provides a direct support link via `Links.support`. The file on disk is left intact for future recovery or migration.

---

### 3. Plan Decoding Compatibility and Pattern Engines
**Status: The fix holds.**
- **Plan decoding compatibility:** In [Plan.swift](Shared/Patterns/Plan.swift#L35-L44), `Step.init(from:)` decodes non-essential or newer fields using `decodeIfPresent` (`delta ?? 0`, `isAction ?? false`, `stitches`). Similarly, `PatternPlan.init(from:)` ([lines 80-87](Shared/Patterns/Plan.swift#L80-L87)) decodes `materials ?? []`, `finished ?? ""`, and `yards ?? 0`. Verified by [PatternTests.swift:236-248](RavelTests/PatternTests.swift#L236-L248) (`testPlanSavedByVersionOneStillOpens`), which validates decoding against a 1.0 JSON fixture with omitted optional keys and extra unknown keys.
- **Balaclava face opening:** In [Engines.swift](Shared/Patterns/Engines.swift#L341-L345), the face opening is constructed with `faceRows - 1` (odd) flat rows ending on a WS purl row (`"Purl to the end, turn"`), followed by a RS row `"Knit to the end. Do not turn"` ([line 344](Shared/Patterns/Engines.swift#L344)). Knitter rejoins in the round facing the right side outward. Verified across all head sizes and gauges in [PatternTests.swift:199-212](RavelTests/PatternTests.swift#L199-L212).
- **Yardage floor:** In [Plan.swift](Shared/Patterns/Plan.swift#L175-L184), `Sizing.yards(worked:spi:)` sums every stitch across every non-action row, applies the 4.3 loop constant, and adds a 15% reserve. In [Engines.swift](Shared/Patterns/Engines.swift#L25-L29), `Engines.pattern(...)` takes `max(estimate, Sizing.yards(worked: b.steps, spi: g.spi))`, guaranteeing no pattern states less yarn than its rows consume. Verified by [PatternTests.swift:215-233](RavelTests/PatternTests.swift#L215-L233).
- **Sweater ease:** In [Design.swift](Shared/Patterns/Design.swift#L212), `Design.sweaterEase = 3.0` is added to wearer chest measurements ([line 250](Shared/Patterns/Design.swift#L250)). Sizes in [line 206](Shared/Patterns/Design.swift#L206) represent CYC wearer measurements (XS 30 to 5X 62), and the finished line in [Engines.swift:465-470](Shared/Patterns/Engines.swift#L465-L470) explicitly notes both the finished chest and the wearer's fit. Verified by [PatternTests.swift:251-255](RavelTests/PatternTests.swift#L251-L255).
- **Sleeve decreases:** In [Engines.swift](Shared/Patterns/Engines.swift#L438-L442), `decreases` is capped at `(sleeveRounds - straight) / 4`, bounding cuff width at 10.5 in and guaranteeing decrease rounds are at least 4 rounds apart ([line 452](Shared/Patterns/Engines.swift#L452)). Verified by [PatternTests.swift:257-266](RavelTests/PatternTests.swift#L257-L266).

---

### 4. Purchase and Restore Outcomes
**Status: The fix holds.**
- In [SubscriptionService.swift](Shared/Services/SubscriptionService.swift#L73-L75), `Outcome` introduces `.unconfirmed`, and `restore()` returns a 4-way `Restored` enum (`.found`, `.notFound`, `.cancelled`, `.failed`).
- In [SubscriptionService.swift:189-197](Shared/Services/SubscriptionService.swift#L189-L197), if a purchase succeeds but `pro` is not active, it queries `customerInfo(fetchPolicy: .fetchCurrent)`. If still inactive, it returns `.unconfirmed` rather than `.pending`. Only `paymentPendingError` maps to `.pending`.
- In [PaywallView.swift](Ravel/Views/PaywallView.swift#L180-L197), `.unconfirmed` informs the knitter the purchase went through and suggests tapping Restore ([line 180](Ravel/Views/PaywallView.swift#L180)). In `restore()`, network errors show *"The App Store could not be reached. Try again when you are online"* ([line 194](Ravel/Views/PaywallView.swift#L194)), cancellations exit silently without false alerts ([line 192](Ravel/Views/PaywallView.swift#L192)), and `.notFound` accurately indicates no purchase was found.

---

### 5. Photo Import
**Status: The fix holds.**
- **Memory:** In [ProjectView.swift](Ravel/Views/ProjectView.swift#L354-L375), photos are loaded sequentially off the main actor via `Task.detached` running `PatternStore.page(from: data)` ([line 363](Ravel/Views/ProjectView.swift#L363)). Images are downscaled to max 2200px and converted to JPEG Data buffers immediately ([PatternStore.swift:33-46](Shared/Services/PatternStore.swift#L33-L46)). Full-resolution bitmap buffers are never accumulated in memory simultaneously.
- **Page size:** In [PatternStore.swift](Shared/Services/PatternStore.swift#L55-L68), `save(pages: [Data])` standardizes PDF pages to US Letter width (612 pt) with proportional height (`612 * height / width`).
- **Row band:** Because page width is constrained to 612 pt, the 16 pt highlight band drawn by [PatternView.swift:74-93](Ravel/Views/PatternView.swift#L74-L93) renders as a distinct, readable bar rather than a hairline. Verified by pixel color analysis in [ModelTests.swift:171-180](RavelTests/ModelTests.swift#L171-L180).

---

### 6. Stash Editor
**Status: The fix holds.**
- In [StashView.swift](Ravel/Views/StashView.swift#L22-L26), opening an existing yarn records `opened = yarn` and `nameBefore = yarn.name`.
- In [StashView.swift:117-126](Ravel/Views/StashView.swift#L117-L126), `dropUnnamed()` inspects unnamed yarns on dismiss: if `yarn === opened` and `!nameBefore.isEmpty`, it restores `yarn.name = nameBefore` instead of deleting the yarn record. Unsaved newly drafted yarns are cleanly deleted via `context.delete(yarn)`, and deletions persist via `try? context.save()`.

---

### 7. Listing Copy
**Status: The fix holds.**
- Subtitle in [subtitle.txt](fastlane/metadata/en-US/subtitle.txt#L1) is `"Row Counter & Yarn Stash"` (24 characters, within the 30-character limit, avoiding repetition of "Patterns").
- Keywords in [keywords.txt](fastlane/metadata/en-US/keywords.txt#L1) total exactly 100 bytes and contain no trademarks or competitor names.
- Description in [description.txt](fastlane/metadata/en-US/description.txt#L1-L24) accurately leads with the free, offline, accountless features (counter, custom PDFs, stash), describes procedural pattern sizing and section jumping, explicitly details subscription terms and pricing ($6.99/mo, $39.99/yr with 7-day trials, $79.99 lifetime), and contains zero em dashes.

---

## Part 2: New Defects Introduced by the Fixes

### Defect 1 (Severity: High) | Deadlocked Counter on Finished Plain Projects
- **Where:** [Shared/Models/Models.swift:92-95, 102-106, 134-136](Shared/Models/Models.swift#L92-L136)
- **Concrete Failing Scenario:**
  1. A knitter working on a plain counter project (or a PDF pattern project) marks the project finished in the menu (or reaches their goal). `project.isFinished` is now `true`.
  2. The knitter accidentally or intentionally taps the undo button ("Back one row").
  3. `Project.unknit(following: nil)` executes: `decrement()` decreases `rows` (e.g., from 50 to 49). It then calls `reopenIfUnfinished(nil)`.
  4. In `reopenIfUnfinished`:
     ```swift
     private func reopenIfUnfinished(_ plan: PatternPlan?) {
         if let plan, isFinished, rows < plan.totalTaps { toggleFinished() }
     }
     ```
     Because `plan` is `nil`, `if let plan` fails. `toggleFinished()` is never called, leaving `project.isFinished == true` at row 49.
  5. The knitter taps the screen (or the PDF strip) to knit back to row 50.
  6. `Project.knit(following: nil)` executes:
     ```swift
     guard let plan else {
         if !isFinished { increment() }
         return
     }
     ```
     Because `isFinished` is `true`, `increment()` is bypassed.
  7. **Result:** The counter is deadlocked. Tapping the canvas produces no response. Even using "Set Row" from the menu calls `jump(to:following:)` which only runs `setRows(...)` and also leaves `isFinished == true`. The user is stuck at row 49 with an unresponsive counter, and their only recovery path is knowing to locate and tap "Mark Active" inside the menu.
- **Suggested Fix:**
  Make `reopenIfUnfinished` support plain projects so that stepping back or adjusting rows automatically reopens the project on the needles:
  ```swift
  private func reopenIfUnfinished(_ plan: PatternPlan?) {
      if isFinished, plan.map({ rows < $0.totalTaps }) ?? true {
          toggleFinished()
      }
  }
  ```

---

### Defect 2 (Severity: Medium) | Test Suite Failure in `TrendingTests` After December 15, 2026
- **Where:** [RavelTests/TrendingTests.swift:35-36](RavelTests/TrendingTests.swift#L35-L36)
- **Concrete Failing Scenario:**
  1. In `TrendingTests.swift`, `date(month: 11)` generates a date of `2026-11-15`.
  2. Line 35 sets this date as the cache timestamp: `defaults.set(date(month: 11), forKey: "trending.fetched")`.
  3. Line 36 initializes `Trending(defaults: defaults)` without specifying `now:`, which defaults to `Date.now`:
     ```swift
     XCTAssertEqual(Trending(defaults: defaults).items, [Trend(design: .seedCowl, tag: "Hot")])
     ```
  4. In `Trending.init` ([Trending.swift:31](Shared/Services/Trending.swift#L31)), `isCurrent` is calculated as `now.timeIntervalSince($0) < 30 * 86_400`.
  5. When tests run on or after December 16, 2026 (>30 days after Nov 15, 2026), `now.timeIntervalSince(fetched)` exceeds 30 days. `isCurrent` evaluates to `false`, the cached trend item is discarded, and `items` falls back to `Trending.bundled(for: .now)`.
  6. **Result:** `testCachedListIsUsedWhenFresh()` will fail assertion on line 36 on any CI or local build run starting in mid-December 2026.
- **Suggested Fix:**
  Pass `now: date(month: 11)` explicitly into `Trending(defaults: defaults, now: date(month: 11))` on line 36 of `TrendingTests.swift`:
  ```swift
  XCTAssertEqual(Trending(defaults: defaults, now: date(month: 11)).items, [Trend(design: .seedCowl, tag: "Hot")])
  ```

---

### Defect 3 (Severity: Low) | Dead State in `StashView.draft` Leaves Uncommitted Draft Deletion Vulnerable
- **Where:** [Ravel/Views/StashView.swift:11, 105, 118-125](Ravel/Views/StashView.swift#L11-L125)
- **Concrete Failing Scenario:**
  1. In [StashView.swift](Ravel/Views/StashView.swift#L11), `@State private var draft: Yarn?` was added to hold the freshly created yarn. In `addYarn()` ([line 105](Ravel/Views/StashView.swift#L105)), `draft = yarn`.
  2. However, in `dropUnnamed()` ([lines 123-125](Ravel/Views/StashView.swift#L123-L125)), `draft` is never inspected. The method iterates strictly over `for yarn in yarns where yarn.name.trimmingCharacters(in: .whitespaces).isEmpty`.
  3. If a user opens "Add Yarn" and immediately dismisses the sheet via interactive swipe before SwiftData updates `@Query private var yarns`, `yarns` may not yet contain the uncommitted draft instance.
  4. **Result:** The unnamed yarn is never purged and remains inserted in the context.
- **Suggested Fix:**
  Check `draft` directly in `dropUnnamed()`:
  ```swift
  if let draft, draft.name.trimmingCharacters(in: .whitespaces).isEmpty {
      context.delete(draft)
  }
  ```

---

Score: 8.5/10
Single most important thing left: Testing the RevenueCat sandbox purchase and restore flow for all three products (specifically the non-consumable lifetime product) on a physical iOS device to verify that `pro` entitlements unlock reliably.
