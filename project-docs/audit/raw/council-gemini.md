# Release-Readiness Score: 4.5 / 10

Ravel has an exceptionally elegant core: the custom Canvas fabric rendering, the procedural pattern sizing engine, and the offline-first SwiftData architecture are well conceived. However, the app cannot be submitted in its current state. Critical bugs exist that directly cause lost row counts, wiped PDF positions, invisible markup on advertised photo patterns, inverted garment construction on the balaclava, broken parental purchase approvals, and accidental duplicate increments during row counting. 

Below are the detailed findings, ordered from most severe to least severe.

---

### G-01 | bugs | P0 | Nested tap gestures cause double-counted rows on the counter
Where: Ravel/Views/ProjectView.swift:59-61, 145-147, 190-192
Problem: In both standard counter mode (lines 59-61) and guided library mode (lines 145-147), the outer container VStack attaches `.contentShape(Rectangle()).onTapGesture(perform: knit)`. At the same time, the `work` view representing the fabric (lines 190-192), which occupies 50% to 60% of the screen, also attaches `.contentShape(Rectangle()).onTapGesture(perform: knit)`. Because both the parent container and the child view listen for uncoordinated tap gestures, tapping the fabric causes duplicate gesture recognitions. In testing, this jumps the row count by 2 instead of 1, directly violating the app's primary promise of reliable row counting.
Fix: Remove `.contentShape(Rectangle()).onTapGesture(perform: knit)` from `work(...)`. Keep the gesture exclusively on the outer container in `ProjectView.swift`.

### G-02 | bugs | P0 | Reopening a PDF pattern resets reading position to page 0
Where: Ravel/Views/PatternView.swift:51-61
Problem: In `Coordinator.load`, `restoring` is set to `true`, `view.document = document`, and a `DispatchQueue.main.async` block calls `view.go(to: target)` before setting `restoring = false`. However, PDFKit page layout on iOS is asynchronous. Calling `view.go(to:)` in the immediate next runloop turn executes before the document view layout pass completes, causing the jump to fail silently. When PDFKit finishes its layout at page 0, the `.PDFViewPageChanged` notification fires. Because `restoring` is already `false`, `pageChanged` records `project.patternPage = 0`, permanently overwriting the knitter's saved page position back to page 0 every time the project reopens.
Fix: Force a layout pass with `view.layoutIfNeeded()` before navigating, or observe `PDFViewDocumentDidLoad` and verify `view.currentPage == target` before resetting `restoring = false`.

### G-03 | bugs | P0 | Balaclava face opening turns crown inside out into reverse stockinette
Where: Shared/Patterns/Engines.swift:346, 358-362
Problem: In `Engines.balaclava`, the face opening is worked flat across `faceRows` rows, which line 346 constrains to an even number (`even: true, minimum: 6`). Step 0 binds off `face` stitches on the right side (RS), knits to the end, and turns to the wrong side (WS). Step 1 works `["Purl, turn", "Knit, turn"]` for `faceRows` rows. Because `faceRows` is even, Row 1 is worked on WS (purl, turn to RS) and Row 2 is worked on RS (knit, turn to WS). After any even number of rows, the last row worked is "Knit, turn", leaving the knitter facing the WS. Step 2 immediately instructs: "Cast on face stitches with the backward loop method, then join in the round again", followed by "Knit" in the round. Joining and knitting in the round from the WS works the top of the balaclava inside out, putting purl bumps on the outside and ruining the finished garment.
Fix: Make `faceRows` odd so the flat opening ends on a WS purl row before turning to the RS, or remove "turn" from the final knit row before casting on and rejoining in the round.

### G-04 | bugs | P0 | SwiftData row counts are never saved to disk and drop on termination
Where: Ravel/Views/ProjectView.swift:94-99, Shared/Services/Persistence.swift:8-17
Problem: Nowhere in the application codebase is `try? context.save()` or `modelContext.save()` called. All row increments, decrements, and project edits mutate in-memory model instances and rely solely on SwiftData automatic context saving. If the knitter taps rows, sets the phone down, and swipes the app closed from the iOS app switcher, or if iOS suspends and unloads the process due to memory pressure, unflushed row count changes are lost. Furthermore, if `Persistence.container(inMemory:)` encounters a disk initialization issue, it silently falls back to an in-memory store without alerting the user, discarding all project data upon quitting.
Fix: Call `try? project.modelContext?.save()` explicitly on row increments, app backgrounding, and navigation dismissals. Display an alert if the persistent container fails and falls back to in-memory mode.

### G-05 | bugs | P0 | Invisible row band marker on imported photo patterns
Where: Ravel/Views/PatternView.swift:86-93, Shared/Services/PatternStore.swift:30-41
Problem: The App Store listing explicitly advertises: "add any PDF or photos of a printed pattern, tap a line to mark your place". When photos are attached via `PatternStore.save(pages:)`, each photo is converted to a PDF page using `PDFPage(image:)`. These pages contain no text glyphs or character quadpoints. In `PatternView.tapped`, `selectionForLine(at:)` returns `nil`, and the fallback creates a `PDFAnnotation(..., forType: .highlight)`. Under iOS PDFKit, `.highlight` annotations are text markup annotations; without quadpoints and text glyphs, PDFKit does not render highlight annotations over bitmap images. When a user taps a photo pattern, no highlight band appears.
Fix: For pages without text, use a `.square` annotation type with `color = .clear` and `interiorColor = project.color.uiColor.withAlphaComponent(0.3)`, or implement a custom `PDFAnnotation` subclass that draws a filled rectangle directly in `draw(with:in:)`.

### G-06 | bugs | P1 | RevenueCat error casting bug treats Ask to Buy approval requests as failed purchases
Where: Shared/Services/SubscriptionService.swift:191-193
Problem: In `SubscriptionService.purchase(_:)`, the catch block checks: `return (error as? ErrorCode) == .paymentPendingError ? .pending : .failed`. In RevenueCat iOS SDK 5.x, the thrown error type is `PurchasesError`, not `ErrorCode`. The conditional cast `error as? ErrorCode` always evaluates to `nil`. When a family member or minor triggers an Ask to Buy flow requiring parental approval (`paymentPendingError`), the outcome is classified as `.failed`. `PaywallView` then displays "The purchase did not go through" instead of "Your purchase is waiting for approval", resulting in abandoned purchases and customer confusion.
Fix: Check `(error as? PurchasesError)?.errorCode == .paymentPendingError` or inspect `(error as NSError).code == ErrorCode.paymentPendingError.rawValue`.

### G-07 | bugs | P1 | Restore purchases shows false "No purchase found" alert on network failure
Where: Shared/Services/SubscriptionService.swift:198-201, Ravel/Views/PaywallView.swift:188-191
Problem: In `SubscriptionService.restore()`, `try? await Purchases.shared.restorePurchases()` silently catches all thrown errors and returns `isPro` (which is `false` when not yet restored). In `PaywallView.restore()`, receiving `false` triggers `message = "No purchase found on this Apple Account"`. If an existing subscriber has a spotty cellular connection or cancels the Apple ID authentication dialog, the app falsely informs them they do not own a subscription, violating App Store Review Guideline 3.1.1.
Fix: Return a Result type or rethrow from `restore()` so `PaywallView` can distinguish between an empty entitlement, network connection failure, and user cancellation.

### G-08 | bugs | P1 | Unbounded memory allocation during multi-photo pattern import crashes the app
Where: Ravel/Views/ProjectView.swift:303-312, Shared/Services/PatternStore.swift:31-41
Problem: `photosPicker` allows selecting up to 20 images (`maxSelectionCount: 20`). `attach(_ picked:)` loads all selected images sequentially via `item.loadTransferable(type: Data.self)` and creates full-resolution `UIImage` instances stored in an in-memory array. Modern iPhone photos are 24MP to 48MP, decompressing to 96MB to 192MB of uncompressed bitmap memory per image. Loading 10 to 20 full-resolution images into `pages` before writing to `PDFDocument` exceeds the iOS memory ceiling (~1.4GB), causing an immediate Out Of Memory (OOM) jetsam termination.
Fix: Downsample camera photos to a reasonable maximum reading resolution (such as 2000px on the longest edge) using `CGImageSourceCreateThumbnailAtIndex` before adding them to the PDF.

### G-09 | bugs | P1 | Needle editor leaks duplicate default needles when dismissed
Where: Ravel/Views/StashView.swift:99-103
Problem: When tapping "Needle or Hook" in the Stash tab, `addNeedle()` immediately calls `context.insert(Needle())` before presenting `NeedleEditor`. While `YarnEditor` has an `onDismiss: dropUnnamed` cleanup handler that purges blank yarns, `NeedleEditor` has no dismiss cleanup. If a knitter taps "Needle or Hook" and swipes the sheet away without saving changes, a duplicate "US 7 · 4.5 mm Circular" needle is permanently saved in the database.
Fix: Do not insert the new needle into the model context until the user confirms by tapping "Done", or add an `onDismiss` check that deletes unconfirmed additions.

### G-10 | bugs | P1 | Undo button touch slop conflicts with background tap-to-count canvas
Where: Ravel/Views/ProjectView.swift:57-60, 244-256
Problem: The Undo button is placed as an overlay in the bottom leading corner (`undo.padding(.leading, 20).padding(.bottom, 8)`). The entire underlying screen is a tap-to-count canvas. When a knitter holding needles reaches down with one hand to tap the 52x52 circle, any touch falling slightly outside the circle hit target registers on the parent canvas, executing `knit()` instead of `back()`. This increments the counter by 1 when the knitter was attempting to undo a mistaken row.
Fix: Surround the bottom control strip with a dedicated non-tappable container, or expand the Undo button's hit-testing padding to absorb adjacent touches.

### G-11 | ux | P1 | Hardcoded repeat calculation desynchronizes when patterns have a brim or cuff
Where: Shared/Models/Models.swift:47-50, Ravel/Views/ProjectView.swift:78-82
Problem: `repeatPosition` is computed as `(rows - 1) % repeatLength + 1`. In almost all real knitting patterns, a repeat (such as a 6-row cable or 12-row lace repeat) starts after a ribbing cuff, brim, or setup section (such as 10 rows of ribbing). On Row 11 (the true first row of the cable repeat), Ravel computes `(11 - 1) % 6 + 1 = 5` and indicates "Row 5 of 6 in the repeat". Because there is no way to set a repeat start offset, the repeat dots and repeat position are incorrect for virtually all multi-section patterns.
Fix: Add a `repeatStartRow` property to `Project` (defaulting to 1), and compute repeat position as `((rows - repeatStartRow) % repeatLength) + 1` for rows at or above `repeatStartRow`.

### G-12 | ux | P1 | Library pattern "Go to Row" is trapped within the current section and vanishes when finished
Where: Ravel/Views/ProjectView.swift:102-107, 263-268
Problem: In `jump(to:)`, the calculation `start + min(max(row, 1), plan.steps[spot.step].rows) - 1` clamps input rows to the current step. A knitter who makes a mistake cannot jump back to a previous section (such as from Body back to Yoke). Additionally, once a pattern is marked finished, `plan.position(at: project.rows)` returns `nil`, causing `jump(to:)` to exit without performing any action. Furthermore, for single-row sections (such as "Divide" on the raglan), the "Go to Row" button is completely removed from the menu.
Fix: Replace the single-section text alert with a section and row navigation picker that allows moving to any step across the entire plan at any time.

### G-13 | ux | P2 | Lack of secondary counters is the primary week-one complaint for knitters
Where: Ravel/Views/ProjectView.swift:47-62
Problem: Knitting projects almost always involve concurrent tracking: total rows, pattern repeat rows, sleeve shaping decrease intervals, and buttonholes. Ravel supports only a single counter. When knitting garments from their own imported PDFs, knitters are forced to keep scrap paper beside their phone to track decrease intervals.
Fix: Allow adding optional named sub-counters inside `Project` (such as "Shaping", "Decrease Interval", "Buttonhole") with independent increment/reset buttons.

### G-14 | ux | P2 | Stash tab is completely isolated with no connection to Projects
Where: Ravel/Views/StashView.swift, Ravel/Views/ProjectView.swift:346-350
Problem: The app features a dedicated "Stash" tab for yarns and needles. However, inside `ProjectDetailsView`, "Yarn" and "Needles" are plain, disconnected free-text strings. A knitter cannot select a yarn or needle from their stash, cannot view which active projects use a specific yarn, and cannot deduct skeins upon casting on. The Stash tab functions as an isolated digital notepad rather than an integrated tool.
Fix: Add a link in `ProjectDetailsView` allowing the knitter to choose a `Yarn` and `Needle` directly from their stored Stash items.

### G-15 | ux | P2 | Portrait-only restriction prevents reading horizontal knitting charts
Where: Ravel/Info.plist:28-31
Problem: `UISupportedInterfaceOrientations` is locked strictly to `UIInterfaceOrientationPortrait`. Knitting charts for colorwork, lace, and cables are wide horizontal grids. Propping an iPhone horizontally in a stand or case next to knitting needles is standard practice. Locking the app to portrait forces knitters to read wide PDF charts in a cramped vertical strip with continuous horizontal scrolling.
Fix: Add `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight` to `UISupportedInterfaceOrientations`.

### G-16 | ux | P2 | Yarn stash lacks vital fields for yardage, fiber, and dye lot
Where: Shared/Models/Models.swift:70-85, Ravel/Views/StashView.swift:120-132
Problem: The `Yarn` model records name, brand, colorway, weight, and skeins, but omits yardage per skein, fiber content (such as 100% Merino, Cotton), and dye lot number. In knitting, knowing total available yardage is required to determine whether there is enough yarn to complete a pattern, and dye lot matching is essential to prevent horizontal line mismatches across garments.
Fix: Add `metersOrYardsPerSkein`, `fiber`, and `dyeLot` fields to the `Yarn` entity and `YarnEditor` form.

### G-17 | ux | P2 | Finished regular projects still increment when brushed
Where: Ravel/Views/ProjectView.swift:94-96
Problem: For projects without a library plan, tapping the screen increments the row counter indefinitely even after the project has been marked finished via the menu. If a knitter opens a finished project to reference notes or needles, accidental screen touches increment the count, corrupting the final finished row record.
Fix: In `knit()`, guard against increments if `project.isFinished` is true, or display an overlay stating "Project Finished" with an explicit button to reopen.

### G-18 | conversion | P2 | The two free library designs fail to demonstrate custom garment sizing
Where: Shared/Patterns/Design.swift:98, Ravel/Views/LibraryView.swift:156-163
Problem: The only free designs are `garterScarf` and `dishcloth`. Both are flat beginner items where custom fit does not matter. The core value proposition of Ravel, writing fitted garments to custom measurements from baby to 5X, cannot be experienced on a scarf or dishcloth. A knitter browsing the library cannot test the guided counter on a fitted item without hitting the paywall.
Fix: Make `ribbedBeanie` or `ribbedCowl` one of the free designs. Experiencing a custom-fitted hat or cowl that adapts to personal gauge creates the immediate value demonstration needed to convert users to subscribers for sweaters.

### G-19 | conversion | P2 | Paywall fails to state that cast-on patterns are kept forever
Where: Ravel/Views/PaywallView.swift:54-79
Problem: One of Ravel's strongest competitive advantages (mandated in AGENTS.md) is that a library pattern keeps its frozen plan data inside the project, so a lapsed subscription never alters or revokes a pattern someone has cast on. This directly resolves the primary objection knitters have toward subscription pattern apps (the fear of losing access to a pattern midway through knitting a multi-month project). Yet this guarantee is completely absent from the paywall headline and feature list.
Fix: Add a clear reassurance bullet to `PaywallView.pitch`: "Keep What You Cast On: Every project you start stays on your needles forever, even if your subscription ends."

### G-20 | conversion | P3 | Paywall options lack savings badge and catalog sizing context
Where: Ravel/Views/PaywallView.swift:85-112
Problem: The yearly subscription ($39.99/year) provides a 52% savings over the monthly plan ($6.99/month, or $83.88/year), but no savings callout or "Best Value" indicator is shown. Additionally, the paywall does not state the size of the library (20 designs and growing), giving users insufficient context to evaluate the price point.
Fix: Add a "Save 52%" badge to the Yearly option and mention "Unlimited access to all 20+ customizable patterns" in the pitch.

### G-21 | bugs | P3 | Projects list displays total taps instead of knitted rows for library designs
Where: Ravel/Views/ProjectsView.swift:106-110
Problem: For library projects, `project.rows` records total taps, which includes setup actions (such as cast on, join in round, divide). In `ProjectsView`, the row column displays raw `project.rows`. For a sweater with multiple setup steps, the list displays "Row 4" when the user is actually on Row 1 of knitting, creating confusing discrepancies.
Fix: In `ProjectsView`, if `project.plan` is present, display `project.plan?.knitRows(upTo: project.rows)` instead of raw `project.rows`.

### G-22 | engine | P3 | Missing BOR marker slip instruction on raglan body-only increases
Where: Shared/Patterns/Engines.swift:424
Problem: In `Engines.raglan`, `bodyOnly` reads: `"...k1, M1L, knit to 1 stitch before the marker, M1R, k1"`. Unlike `all` and `sleevesOnly`, it omits `slip marker` at the end of the round. When this round finishes, the knitter is positioned immediately before the beginning-of-round marker without an explicit instruction to slip it, causing confusion on whether the next round starts before or after the marker.
Fix: Append `, slip marker` to the end of `bodyOnly` in `Shared/Patterns/Engines.swift`.
