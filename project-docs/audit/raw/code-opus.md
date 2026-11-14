# Ravel 1.0 code review (Opus seat)

Score: 7/10. The free tracker, the engines and the paywall are solid (a 133,280-plan fuzz over every design, the full measurement ranges and the full gauge adjuster ranges found no zero, negative or empty step), but no code saves a row count explicitly, an unopenable store silently becomes an in-memory one, and the frozen plan format breaks on the first field anyone adds. Each of those leads straight to a "lost my row count" or "my pattern vanished" review, and each is a small fix.

Method: read every file under Ravel/, Shared/, RavelTests/, RavelUITests/, plus project.yml, Info.plist, Ravel.storekit and scripts/testflight.sh. I compiled the pattern sources with swiftc in a scratch folder to fuzz the engines and to confirm how Codable handles defaults. I read the RevenueCat project config through the `rc` CLI without changing anything. Nothing was built with xcodebuild and no simulator was used.

## FINDINGS

### C-01 | data | P1 | No row count is ever saved explicitly; a crash or power loss reverts recent taps
Where: Ravel/Views/ProjectView.swift:94-113 (knit, jump, back), :76 (reset); Ravel/App.swift:14 (no scenePhase save). A grep for `save()` across Ravel/ and Shared/ finds nothing.
Repro: Open a project and tap 15 rows. Within a few seconds the app is killed without a clean background transition: the battery dies, jetsam kills it (for example while 20 photos import, see C-05), or some other crash happens. Relaunch.
Result: The count is back where it was at the last SwiftData autosave, which is deferred and not tied to the tap. The store listing says "the count is saved the instant you tap", so this is the exact review the product law forbids.
Fix: Inject `@Environment(\.modelContext)` into ProjectView and call `try? context.save()` at the end of knit(), back(), jump(), the reset button and toggleFinished. Also save on `scenePhase == .background` in RavelApp. One SQLite write per tap costs nothing.

### C-02 | data | P1 | A store that fails to open silently becomes an empty in-memory store, and everything made in that session is lost
Where: Shared/Services/Persistence.swift:12-16
Repro: Ship 1.1 with a model change that lightweight migration cannot handle, for example a new non-optional property without a default (`name` and `rows` already have no declared default), or launch with the disk full. Then `try? ModelContainer(...)` returns nil.
Result: The app launches with no projects and no stash, so the user believes everything is gone. Any project they make or count in that session lives in memory and vanishes on the next quit. Nothing is logged or shown, and there is no VersionedSchema or SchemaMigrationPlan to migrate with later.
Fix: Before 1.0 ships, wrap the models in `enum SchemaV1: VersionedSchema` and open the container with an empty `SchemaMigrationPlan`, so 1.1 has a base to migrate from. When the disk store fails, show a blocking "Ravel could not open your projects" screen (and leave the file alone) instead of falling back to memory. Keep the in-memory path for `-UITesting` and `-SeedDemo` only.

### C-03 | data | P1 | Any field added to Step or PatternPlan later makes every cast-on library project lose its instructions
Where: Shared/Patterns/Plan.swift:14-38 (synthesized Codable), Shared/Models/Models.swift:52 (`try?` decode), Ravel/Views/ProjectView.swift:31 and :36-61
Repro: In 1.1, add `var note = ""` (or any property) to `Step`. I confirmed with swiftc that synthesized `Decodable` ignores the default value and throws `keyNotFound` for a missing key. Open a library project cast on in 1.0.
Result: `project.plan` is nil, so ProjectView falls through to the plain counter. The guided instructions, materials and stitch counts are gone and the row cap is gone too. This breaks the rule that "a library project keeps its own frozen copy of the plan".
Fix: Write `init(from:)` for Step and PatternPlan with `decodeIfPresent ?? default` for every non-original key, or add `var version = 1` now and branch on it. Also add a test that decodes a JSON fixture checked in from the 1.0 build (see Tests).

### C-04 | purchase | P1 | The RevenueCat path that unlocks a real purchase has never been exercised, and the lifetime product is typed as a non-renewing subscription
Where: Shared/Services/SubscriptionService.swift:186-205; RevenueCat project projfe8bceb8 (read with `rc`)
Repro: `rc products list` shows `com.jackwallner.knit.lifetime` with `"type": "non_renewing_subscription"` and `"one_time": {"is_consumable": null}`, but in App Store Connect it is a non-consumable. StoreTests and PaywallUITests only cover `purchaseFromTestStore` and the DEBUG stand-in, and both set `isPro = true` directly. Nothing tests `Purchases.shared.purchase`, then `apply`, then the `entitlements["pro"].isActive` check.
Result: If RevenueCat treats the lifetime purchase as consumable, or as a non-renewing purchase with a duration, a $79.99 buyer gets `isPro == false`. The code then returns `.pending` and shows "Your purchase is waiting for approval" (C-08). That is the "paid and nothing unlocked" page. The entitlement attachments and packages ($rc_annual, $rc_monthly, $rc_lifetime, all three products attached to `pro`) are correct.
Fix: Set the RevenueCat product type to non-consumable (one_time, is_consumable false). Then, before submitting, buy each of the three products once in sandbox on a device running a TestFlight build, relaunch offline, and confirm the patterns stay unlocked and that Restore works.

### C-05 | data | P1 | Photo patterns are stored at full camera resolution and may come out sideways
Where: Shared/Services/PatternStore.swift:31-41, :19-21; Ravel/Views/ProjectView.swift:303-312
Repro: Use Add Photos to pick 10 to 20 portrait iPhone camera photos of a printed pattern (HEIC, 4032x3024 sensor pixels, EXIF orientation `.right`).
Result: Each `UIImage` goes into `PDFPage(image:)` unchanged. The page is 4032x3024 points and the full bitmap is embedded, so the files are huge and import holds every decoded image in memory, which risks a jetsam kill (and C-01 then loses rows). PDFPage builds from the underlying CGImage, so portrait photos are likely to render rotated 90 degrees. The unit test uses a renderer-made `.up` image, so it would not catch this. Confirm the rotation with one device import.
Fix: Before `PDFPage(image:)`, redraw each image through `UIGraphicsImageRenderer` at a capped size (for example 2400 px on the long side, scale 1). That bakes in the orientation and bounds the size. Use `PDFPage(image:options: [.compressionQuality: 0.8])` on iOS 16+. Do the decode one image at a time inside the loop.

### C-06 | logic | P2 | Tapping Back One Row quickly down to 0 adds a row back
Where: Ravel/Views/ProjectView.swift:243-256 (undo shown only when rows > 0), :57 and :43 (undo sits over the fabric)
Repro: With the count at 1, double-tap the undo button.
Result: The first tap sets the count to 0 and removes the button, so the second tap lands on the fabric under it, which knits. The count ends at 1. In PDF mode the strip behaves the same way. A knitter resting a thumb on that corner gets phantom rows.
Fix: Always render the undo button and set `.disabled(project.rows == 0)` with reduced opacity, so it keeps its hit area. Otherwise reserve the area with `.contentShape` and `.allowsHitTesting(true)` while it is hidden.

### C-07 | purchase | P2 | Restore offline tells a paying customer they have no purchase
Where: Shared/Services/SubscriptionService.swift:197-201, Ravel/Views/PaywallView.swift:185-191
Repro: Turn on airplane mode, open the paywall and tap Restore, as a lifetime buyer on a new phone.
Result: `try?` turns the network error into `isPro == false`, and the alert says "No purchase found on this Apple Account".
Fix: Return a three-way result (found, notFound, failed). On a thrown error, show "Could not reach the App Store. Try again when you are online."

### C-08 | purchase | P2 | A successful purchase whose entitlement is not active yet is reported as "waiting for approval"
Where: Shared/Services/SubscriptionService.swift:189-190
Repro: Make any purchase where StoreKit succeeds but `customerInfo` does not yet show `pro` as active: the RevenueCat backend is slow, a product is misconfigured (C-04), or the receipt posts late.
Result: The user paid but sees "Your purchase is waiting for approval", which is wrong, and gets no way forward except Restore.
Fix: When `result.transaction != nil && !isPro`, call `try? await Purchases.shared.syncPurchases()` and re-apply. If `pro` is still inactive, show "Purchase received. Tap Restore if patterns do not unlock". Map `.pending` only from `paymentPendingError`.

### C-09 | data | P2 | Clearing a yarn's name while editing it silently deletes the yarn
Where: Ravel/Views/StashView.swift:65, :105-108
Repro: Open an existing yarn ("Merino, 6 skeins"), clear the Name field intending to retype it, and swipe the sheet down.
Result: `dropUnnamed` deletes every yarn with an empty name, including this existing one with its brand, colorway and skeins. There is no undo.
Fix: Only drop the yarn that `addYarn()` just created. Keep its id in `@State var draftYarn`, and on dismiss delete it only if it is still unnamed. If an existing yarn's name is cleared, restore the old name.

### C-10 | data | P2 | Remove Pattern deletes the imported file with one tap and no confirmation
Where: Ravel/Views/ProjectView.swift:274, :314-319
Repro: Open the project menu and tap "Remove Pattern", which sits right under "Replace Pattern".
Result: The PDF or photo-bound PDF is removed from disk at once, along with the saved page and row band. It cannot be undone, while project delete does ask first.
Fix: Add a confirmationDialog ("Remove the pattern from this project?") with a destructive button, and give the menu item `role: .destructive`.

### C-11 | concurrency | P2 | A photo import that finishes after the project is deleted writes to a deleted model and orphans a file
Where: Ravel/Views/ProjectView.swift:303-312
Repro: Pick 20 iCloud photos (slow to download), go back at once, swipe-delete the project and confirm.
Result: The Task keeps running. `PatternStore.save(pages:)` writes a PDF, then `setPattern` assigns to a deleted `Project`. SwiftData can trap on a deleted model's backing data, and if it does not, the PDF is orphaned in Application Support forever. There is also no progress indicator while it loads, so users pick again.
Fix: After loading, `guard project.modelContext != nil, !project.isDeleted else { PatternStore.delete(file); return }`. Show a ProgressView while `importingPhotos` is true, and keep the Task in `@State` so onDisappear can cancel it.

### C-12 | logic | P2 | Reset Count on a finished library project leaves it marked Finished at row 0
Where: Ravel/Views/ProjectView.swift:76, :98, :112
Repro: Finish a guided pattern (it auto-marks Finished), then choose Reset Count.
Result: The count is 0 and the instructions restart, but `finishedAt` stays set. The project sits in the Finished section at row 0, and knitting to the end never re-celebrates, because knit() only marks it finished when it is not finished already.
Fix: In the reset action, `if plan != nil, project.isFinished { project.toggleFinished() }`, matching back().

### C-13 | a11y | P2 | VoiceOver users get no count or instruction feedback after adding a row
Where: Ravel/Views/ProjectView.swift:184-196, :163-167
Repro: With VoiceOver on, focus "Add a row" and double-tap it several times.
Result: VoiceOver repeats only "Add a row". The count and, in guided mode, the next instruction are separate elements and are not announced, so a blind knitter has to swipe away and back after every row. The button also relies on the activation point landing on the tap gesture instead of an explicit action.
Fix: Add `.accessibilityValue("Row \(project.rows)")` (in guided mode, the instruction text) and `.accessibilityAction { knit() }` to the work element. After knit and back, post `AccessibilityNotification.Announcement` with the new row and instruction.

### C-14 | edge | P2 | Long guided instructions truncate at large text sizes
Where: Ravel/Views/ProjectView.swift:132 (fixed 46% height), :163-166 (`minimumScaleFactor(0.4)`), Shared/Utilities/Theme.swift:13-15
Repro: Set Text Size to an accessibility size on an iPhone SE, cast on the Raglan Pullover and step to the Divide row (about 230 characters) or a body-only increase row (about 260 characters).
Result: At a 1.8x display size the text needs about a 0.37 scale to fit, which is below the 0.4 floor, so the instruction ends in an ellipsis. The knitter cannot read the stitch counts they need.
Fix: Put the instruction VStack in a `ScrollView` (with `.scrollBounceBehavior(.basedOnSize)`) inside the 46% frame, or let the instruction region grow and the fabric shrink at accessibility sizes.

### C-15 | review-risk | P2 | No app privacy manifest
Where: Ravel/ (no PrivacyInfo.xcprivacy in the app target). The app calls UserDefaults in ReviewPrompt.swift:17 and Trending.swift:29-42.
Repro: Upload a build and submit it.
Result: UserDefaults is a required-reason API. Builds 1 to 4 uploaded, but App Review can send ITMS-91053 or reject for a missing declaration. RevenueCat's own manifest covers only the SDK.
Fix: Add `Ravel/PrivacyInfo.xcprivacy` with NSPrivacyAccessedAPICategoryUserDefaults reason `CA92.1`, `NSPrivacyTracking` false and no tracking domains, then rerun `xcodegen generate`. Make sure the App Privacy answers in App Store Connect declare Purchases (RevenueCat), not linked to identity and not used for tracking.

### C-16 | logic | P3 | Mark Active at the last row leaves a guided project that cannot move
Where: Ravel/Views/ProjectView.swift:96, :285-287
Repro: Finish a guided pattern, then choose Mark Active.
Result: The screen still says "Finished" and taps do nothing, because the `guard project.rows < plan.totalTaps` check fails silently. Marking it finished again re-runs the celebration.
Fix: In guided mode, hide Mark Active when `rows == totalTaps`, or step the count back one row when unfinishing at the end.

### C-17 | logic | P3 | Two quick Cast On taps create two identical library projects
Where: Ravel/Views/LibraryView.swift:172-182
Repro: Double-tap Cast On on a design.
Result: Two projects are inserted, and one is pushed.
Fix: `guard opened == nil` at the start of castOn().

### C-18 | edge | P3 | The cached Trending list never expires
Where: Shared/Services/Trending.swift:29, :35
Repro: Fetch the list in November, then stay offline until July.
Result: The shelf still says "Gift season" all summer, because the cached list beats the month-aware bundled one forever.
Fix: Ignore a cache older than 30 days (`fetchedKey`) and fall back to `bundled(for: now)`.

### C-19 | edge | P3 | Send Feedback does nothing without a Mail account
Where: Ravel/Views/ProjectsView.swift:47
Repro: Tap Send Feedback on a phone with no Mail account set up.
Result: `openURL` fails silently.
Fix: Use the `openURL` completion. On failure, copy the address to the pasteboard and show "Email address copied", or open the support page.

## Questions answered with no defect found
- One tap never counts two rows. The inner fabric tap gesture takes precedence over the outer container gesture, and Buttons win over both. The undo button cannot also knit, except in the C-06 case after it disappears. Scrolling or tapping the PDF never adds rows, because the PDF tap only moves the band.
- Lapsed subscribers keep their cast-on projects. ProjectView never checks `isPro`, and the plan is frozen.
- Cold launch offline: RevenueCat's `customerInfoStream` emits the cached CustomerInfo, so entitlements survive, apart from a brief "Unlock Patterns" flash before the first emission.
- DEBUG fallbacks (`isPro = true` stand-in, `-Pro`, `-MockProducts`, the StoreKit test store) are all behind `#if DEBUG` or `DEBUG && targetEnvironment(simulator)`. RootView and LibraryView read "Tab", "OpenDesign" and "PaywallSnapshot" from UserDefaults in release, but only the launch-argument domain sets them, so they cannot be reached from the App Store.
- RevenueCat cancel is reported as `.cancelled`, not as a failure: the SDK's `Result(value, error)` prefers the non-nil CustomerInfo. Ask to Buy maps to `.pending`.
- Paywall (guideline 3.1.2): price per period is shown before the button, trial terms and auto-renew are in the disclosure, Restore, Terms (Apple EULA) and Privacy links are present even when plans fail to load, and the description carries both links. `ITSAppUsesNonExemptEncryption` is false. PhotosPicker and fileImporter need no usage strings.
- The PatternView observer is selector-based and is removed automatically when the coordinator deallocates. The idle timer is reset in onDisappear, and the tab bar is hidden inside a project, so it cannot leak across tabs.
- Engines: the fuzz covered every design across the full measurement ranges and gauges from 8 to 40 stitches and 10 to 56 rows (133,280 plans). It found no zero-row step, empty text, or non-positive stitch count.

## Tests
What the tests prove today: counter floor at 0, finish toggling, an in-memory save round trip, repeat position math, needle charts, plan round trip in memory, the free/paid split, the review-prompt rules, abbreviations, PatternStore save, delete and refusal, photos to pages, engine invariants at named sizes and range ends for the 8 standard gauges, the StoreKit Testing purchase path on simulator, Trending decode and the published list, and paywall copy plus mock purchases.

What they do not prove: anything on disk or across launches, backward compatibility of frozen plans, ProjectView's knit, back, jump and reset rules (they live in the view), and the RevenueCat purchase path, which release actually uses.

Three most valuable missing tests:
1. Frozen-plan compatibility: check in `RavelTests/Fixtures/plan-v1.json`, generated now from each Design at its default size, and assert that it decodes into PatternPlan with equal `totalTaps` and texts. This would have caught C-03.
2. On-disk store survival: open a `ModelContainer` at a temp URL, insert a project with a plan, PDF and stash items, drop the container, reopen with the current schema and migration plan, and assert everything is intact. Also assert `Persistence.container` never returns an in-memory store for a disk request (C-02).
3. Counter rules: move knit, back, jump and reset into a small `Counter` type over `Project` plus an optional `PatternPlan`, and test the boundaries: knit stops at totalTaps and marks finished, back from totalTaps unfinishes, jump clamps within the section, reset clears a library project's finished flag (C-12), and setRows clamps to 99,999.

## Simplifications that would make the code more robust
1. Move knit, back, jump and reset out of ProjectView into a `Project` extension that takes a plan and ends with `modelContext?.save()`. That gives one tested, saving code path (C-01, C-12, test 3).
2. Remove the inner `.onTapGesture(perform: knit)` in `work()` for the counter and guided modes, where the container already knits. Keep it only for the PDF strip, so there is one tap source per mode.
3. Always render the undo button and toggle `.disabled` instead of inserting and removing it (C-06).
4. Decode the plan once into a non-optional `PatternPlan` stored with a version, or keep `planData` and `designRaw` and regenerate from them when decode fails, so a library project can never fall back to a raw counter.
5. Replace `Persistence.container`'s `try?` with `do/catch` and an explicit failure state (C-02).
6. Return a `Result` from `restore()` and `purchase()` instead of collapsing errors into `false` or `.failed` (C-07, C-08).
7. Normalize every image through one `PatternStore.page(from:)` helper that scales and orients it, used by both the Files and Photos paths (C-05).
8. Track draft stash items by id instead of sweeping all unnamed yarns on dismiss (C-09).
9. Gate the "Tab", "OpenDesign" and "PaywallSnapshot" reads in RootView and LibraryView behind `#if DEBUG`, as ProjectsView already does, so release code has no launch-argument hooks.
10. Clamp `increment()` to the same 99,999 ceiling as `setRows`, so there is one ceiling.
