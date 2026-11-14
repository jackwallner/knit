# Ravel 1.0 pre-release audit: findings ledger

Date: 2026-11-13. Second pass the same day: the V findings and G-10 fixed, the disputed G items settled on a simulator, 53 unit tests and the UI tests green (see each row). First pass, verification stage: every finding from the six raw reports in `raw/`, checked against the uncommitted working tree (`git diff`, `Ravel/PrivacyInfo.xcprivacy`). Nothing was built, run or simulated. The tree was still moving while this was written (the second rating trigger in `ProjectView.swift` and the `AGENTS.md` edits appeared mid-review), so line numbers are as of the working tree on 2026-11-13 and may shift.

How to read it. One table per source: C code (Opus), G council (Gemini), K tech edit, A listing, R research, T TikTok, V new findings from this review. Status is one of: fixed and verified (the code does what the finding asked, read in the file), fixed but wrong (claimed fixed, the code does not do it), partly fixed, open, deferred, declined, refuted, owner decision, needs simulator. "Fixed and verified" means verified by reading code and tests; it is not a test run. The Fixes that do not hold section has the detail behind every "fixed but wrong" and every V-NN. Judgements covers the disputed items. Not addressed anywhere lists what no disposition mentioned.

## C: code review (Opus seat)

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| C-01 | P1 | Row count never saved explicitly | fixed and verified | Models.swift:85 `persist()`, called from knit/unknit/jump/reset (:91-130); RootView.swift:23 saves when the scene leaves active; ProjectView.swift:106 and :371; ProjectsView.swift:145,154; LibraryView.swift:183 |
| C-02 | P1 | Unopenable store becomes empty in-memory store | partly fixed | Failure screen and file left alone: Persistence.swift:6-19, App.swift:26-28, RootView.swift:35. No VersionedSchema (see Judgements) |
| C-03 | P1 | New Step/PatternPlan field breaks frozen plans | fixed and verified | Plan.swift:35-44 and :82-88 `decodeIfPresent`; test at PatternTests.swift (`testPlanSavedByVersionOneStillOpens`, hand-written fixture, drops optional keys, passes an unknown key). Not generated from a 1.0 build |
| C-04 | P1 | RevenueCat lifetime typed non-renewing; real purchase never exercised | owner decision | Needs the RevenueCat product type change and a sandbox buy of all three products on a device |
| C-05 | P1 | Photo patterns at full resolution, maybe sideways | fixed and verified | PatternStore.swift:33-47 redraws at 2200 px, scale 1, orientation baked in; used by both paths (:21 and ProjectView.swift:354). `compressionQuality` not used, PDF file size unmeasured. See V-08 |
| C-06 | P2 | Undo to 0 lets the second tap knit | fixed | Same fix as V-04: the undo button stays live at row 0, checked by `CounterUITests` on a simulator |
| C-07 | P2 | Offline restore says "no purchase found" | fixed and verified | SubscriptionService.swift:200-206 three-way `Restored`; PaywallView.swift:186-197 |
| C-08 | P2 | Paid but entitlement late is shown as "waiting for approval" | fixed and verified | SubscriptionService.swift:188-197 new `.unconfirmed`, pending only from paymentPendingError; PaywallView.swift:180. See V-06 |
| C-09 | P2 | Clearing a yarn name deletes the yarn | fixed and verified | StashView.swift:115-123, draft tracked at :11-13,:103. See V-07 |
| C-10 | P2 | Remove Pattern with no confirmation | fixed and verified | ProjectView.swift:83-85, :313 destructive role |
| C-11 | P2 | Photo import finishing after project delete | fixed and verified | ProjectView.swift:356-363 guard + delete orphan file; spinner :68. Task not cancelled on disappear (guard covers it) |
| C-12 | P2 | Reset Count leaves a finished library project finished | fixed and verified | Models.swift:125-134 reopens when a plan is present. Plain projects not covered: V-02 |
| C-13 | P2 | VoiceOver gets no count or instruction | fixed and verified | ProjectView.swift:112-135 `announce()`, :219-220 value and default action |
| C-14 | P2 | Long guided instructions truncate | fixed and verified | ProjectView.swift:185-190 sets text over 140 characters at 20 pt and over 70 at 24 pt (not a scroll view). Arithmetic: a 260 character row at 1.8x needs about 0.65 scale, above the 0.4 floor |
| C-15 | P2 | No privacy manifest | fixed and verified | Ravel/PrivacyInfo.xcprivacy (UserDefaults CA92.1, no tracking); present in the generated project.pbxproj. App Privacy answers in ASC still open under A-11 |
| C-16 | P3 | Mark Active at last row cannot move | fixed and verified | ProjectView.swift:324-331 button hidden at the last tap of a library pattern |
| C-17 | P3 | Double Cast On makes two projects | fixed and verified | LibraryView.swift:178; `opened` resets on pop (:168 `navigationDestination(item:)`) |
| C-18 | P3 | Trending cache never expires | fixed and verified | Trending.swift:29-33. Breaks an existing test: V-01 |
| C-19 | P3 | Send Feedback silent without Mail account | partly fixed | ProjectsView.swift:50-53 falls back to the support page only if iOS declines the URL. With Mail installed and no account iOS normally opens Mail setup and reports success, so the fallback does not run. Confirm on a device; a `MFMailComposeViewController.canSendMail()` check is the sure fix |

## G: council review (Gemini seat)

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| G-01 | P0 | Nested tap gestures double count | refuted | Simulator, 2026-11-13: one tap took row 44 to 45. The fabric no longer counts taps of its own outside the PDF reader, and `CounterUITests` holds it |
| G-02 | P0 | PDF reopens at page 0 | refuted | Simulator, 2026-11-13: scrolled to page 3, left the project, reopened on page 3 |
| G-03 | P0 | Balaclava worked inside out | fixed and verified | Same as K-01. Engines.swift:339-341; PatternTests `testBalaclavaRejoinsWithTheRightSideFacing`. Old assertions in TrendingTests.swift:94 now fail (V-01) |
| G-04 | P0 | Counts never saved, silent in-memory fallback | fixed and verified | Same as C-01 and C-02 failure screen |
| G-05 | P0 | Row band invisible on photo pages | fixed | The claim as written is refuted: a highlight does draw over a photo (pixel check in `testCameraPhotosAreCutToReadingSize`). The real fault was size: photo pages were 2,200 points tall, so the 16 point band was a hairline. Photo pages are now letter width in points |
| G-06 | P1 | RevenueCat error cast treats Ask to Buy as failure | refuted | RevenueCat 5.x throws NSError cast to `ErrorCode`; Opus is right. See Judgements |
| G-07 | P1 | Restore offline false alert | fixed and verified | Same as C-07 |
| G-08 | P1 | Unbounded memory on 20 photos | fixed and verified | Same as C-05; residual memory in V-08 |
| G-09 | P1 | Needle editor leaks default needles | declined | Defensible; severity overstated. See Judgements |
| G-10 | P1 | Undo hit slop falls to the counting canvas | fixed | The touch area now runs 12 pt past the circle on every side (76 pt), so a near miss lands on undo, never on the counter |
| G-11 | P1 | Repeat position wrong after a hem | fixed and verified | Models.swift:21,51-52,76-79 `repeatStart`; ProjectView.swift:86-95 alert note. Rewind side effect: V-05 |
| G-12 | P1 | Go to Row trapped in section, gone when finished | fixed and verified | Plan.swift:91-99 `sections`, Models.swift:119-123, ProjectView.swift:303-307. Duplicate names: V-10 |
| G-13 | P2 | No secondary counters | deferred | Past 1.0 |
| G-14 | P2 | Stash not linked to projects | deferred | Past 1.0 |
| G-15 | P2 | Portrait only | deferred | Past 1.0 |
| G-16 | P2 | Yarn lacks yardage, fiber, dye lot | deferred | Past 1.0 |
| G-17 | P2 | Finished plain project still counts | fixed and verified | Models.swift:93 `if !isFinished`. Side effects: V-02, V-03 |
| G-18 | P2 | Free designs do not show fitted sizing | owner decision | Make ribbed beanie or cowl free; touches `Design.isFree` and the free/paid test (ModelTests `testOnlyTheLibraryIsPaid`) |
| G-19 | P2 | Paywall silent about cast-on patterns kept | fixed and verified | SubscriptionService.swift:59 disclosure sentence; PaywallUITests.swift:34,36 updated. Lifetime line has no such sentence (it says "yours for good") |
| G-20 | P3 | No savings badge or library size on paywall | owner decision | Paywall copy and pricing presentation |
| G-21 | P3 | Projects list shows taps, not rows | deferred | Past 1.0 |
| G-22 | P3 | Raglan body-only round lacks final slip marker | fixed and verified | Engines.swift:398; marker count checked (four slips) |

## K: tech edit

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| K-01 | P0 | Balaclava face opening ends on a turn | fixed and verified | Engines.swift:337-341: bind-off row, odd block ending on a purl row, a "Do not turn" knit row, cast on with RS facing. Parity worked by hand: flat rows are faceRows+1, odd, last is RS |
| K-02 | P1 | Garter yardage has no reserve | fixed and verified | Engines.swift:26-29 `pattern()` takes the larger of the area estimate and Plan.swift:177-184 `yards(worked:)` (4.3 loop constant, plus 15 percent). All 15 return sites go through it. Test is tautological: V-09 |
| K-03 | P1 | Neck scarf yardage short | fixed and verified | Same mechanism; Classic DK now about 250 yd against the reviewer's 193 to 207 |
| K-04 | P1 | Chest read as finished chest, zero ease | fixed and verified | Design.swift:176-177 range 26 to 62, :206 sizes shifted to XS 30 to 5X 62, :212 ease 3 in, :250; Engines.swift:375-376,461-465 finished line states wearer, finished and ease. Test `testSweaterIsKnitWithRoomOverTheChestGiven` (rounding checked: 40.89 in prints as 41 in) |
| K-05 | P2 | No front neck drop | deferred | Past 1.0 |
| K-06 | P2 | Neck cast-on has no stretchy method | fixed and verified | Engines.swift:333,403 |
| K-07 | P2 | Needle changes never instructed | fixed and verified | Hats and balaclava: Engines.swift:78-85 note on the first crown round under 14 in. Raglan: note sits on the first yoke row (:407), not on the round where stitches crowd; acceptable |
| K-08 | P2 | Plus-size arms tight, cuffs loose | fixed and verified | Engines.swift:379 (the rule only changes results above a finished chest of 53.3 in) and :439 cuff capped at 10.5 in |
| K-09 | P2 | Short sleeves still taper, packed decreases | fixed and verified | Engines.swift:437-442 decreases at least 4 rounds apart (arithmetic holds); `testSleeveDecreasesAreNeverPacked`. Cuff interpolation by length not done: a 10 in sleeve at M worsted now ends at about 11 in, fine |
| K-10 | P2 | Gauge line and yarn line vague | fixed and verified | Engines.swift:11-23. Wording nit: V-11 |
| K-11 | P2 | Thumb slit wording and edges | fixed and verified | Engines.swift:228-232 |
| K-12 | P2 | Shawl size needs 25 percent stretch | fixed and verified | Engines.swift:262 factor 1.3 |
| K-13 | P2 | Headband width stepper does nothing | fixed and verified | Engines.swift:301-310. Stitch arithmetic checked for 1 to 7 cables and 0 to 3 side stitches: all three row texts total the cast-on, and the WS row mirrors the RS row. Widths 4.0 and 4.5 at aran still both give 20 sts |
| K-14 | P2 | Hat ease swings at heavy gauges | deferred | Past 1.0 |
| K-15 | P2 | Baby hats on a 16 in circular | fixed and verified | Engines.swift:75 (materials line only) |
| K-16 | P2 | Raglan run-on sentences | deferred | Past 1.0 |
| K-17 | P2 | Glossary misses beginner terms | fixed and verified | Plan.swift:109-117, :125 single-letter regex `\bk\d`. Regex checked on K2, k34, K2tog. Breaks ModelTests.swift:199 (V-01) |
| K-18 | P3 | Seed cowl odd count | fixed and verified | Engines.swift:139-141; PatternTests.swift:112 updated |
| K-19 | P3 | Chunky cowl jog and name | deferred | Past 1.0 |
| K-20 | P3 | Face edging yarn, partial first Top round | fixed | Join-new-yarn text, and the rejoin now says to move the marker to the new start of the round |
| K-21 | P3 | Rib brim on body needle | deferred | Past 1.0 |
| K-22 | P3 | Level labels off by one | fixed and verified | Design.swift:91-93 |
| K-23 | P3 | No finished circumference stated | fixed and verified | `fits()` Engines.swift:32-34, used for hats, ear warmer, handwarmers, leg warmers, balaclava |
| K-24 | P3 | Neck scarf longer than asked | fixed and verified | Engines.swift:280; within the design ranges tapers cannot exceed the length (4 x width <= 2 x length holds for 28 to 60 by 3 to 9) |
| K-25 | P3 | Sleeve cap front-loaded | deferred | Past 1.0 |
| K-26 | P3 | Cowl needle length rule coarse | fixed and verified | Engines.swift:154 |
| K-27 | P3 | Slouch increases bunch | fixed and verified | Engines.swift:37-43; counts check (rest x (gap+1) + (count-rest) x gap = stitches) |
| K-28 | P3 | Headband negative ease and seam | fixed and verified | Engines.swift:306 factor 0.92. Provisional cast-on suggestion not added |
| K-29 | P3 | "Row" used for rounds | deferred | Past 1.0 |
| K-30 | P3 | Leg warmers slide down | deferred | Past 1.0 |

## A: App Store listing and ASO

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| A-01 | P1 | Subtitle repeats Patterns | fixed and verified | subtitle.txt "Row Counter & Yarn Stash" (24). Not uploaded |
| A-02 | P1 | Keyword field wastes characters | fixed and verified | keywords.txt identical to the proposal, 100 characters. Not uploaded |
| A-03 | P2 | Keep the name | fixed and verified | No change was the recommendation; name.txt unchanged. Not in the manager's dispositions |
| A-04 | P1 | Description leads with a label | fixed and verified | description.txt. Differs from the proposal: adds "calculated" and "checked at every size" wording (from R-01) and "Jump to any section". Length 2,399 bytes. Not uploaded |
| A-05 | P2 | Promotional text under-used | fixed and verified | promotional_text.txt identical, 132 characters. Not uploaded |
| A-06 | P3 | Release notes | fixed and verified | Leave as is; release_notes.txt unchanged. Not in dispositions |
| A-07 | P1 | Hero idea is in frame 3 | owner decision | Screenshot order and re-upload from `~/ios/appstore-screenshots` |
| A-08 | P2 | Empty gauge section, tiny proof | owner decision | Recapture |
| A-09 | P2 | Cut-off label, tab bar over content | owner decision | Recapture |
| A-10 | P1 | Paid designs unmarked in screenshots | owner decision | Footer pill or lead with free designs |
| A-11 | P1 | ASC-only fields unauditable from repo | owner decision | Category, age rating, privacy labels (Purchases), review notes, copyright, IAP attachment |
| A-12 | P2 | Paywall footnote lacks charge and renewal sentences | declined | The footnote states price, trial length and renewal next to the button, and the description carries the full charge and renewal sentences. More words under the button would be helper text |
| A-13 | P2 | Site has no screenshot, link, social tags | partly fixed | Privacy policy sentence done (docs/privacy-policy.html). Home page link, screenshot and og tags not done (reviewer said after approval) |
| A-14 | P2 | en-GB, en-AU, en-CA | deferred | Past 1.0 |
| A-15 | P3 | es-MX keyword locale | deferred | Past 1.0 |
| A-16 | P3 | Translate app before listing | deferred | Past 1.0 |
| A-17 | P2 | Keep Ravelry and competitor names out | fixed and verified | The keyword field names no competitor or trademark (fastlane/metadata/en-US/keywords.txt) |
| A-18 | P3 | Category and age rating | open | Not in dispositions. Confirm Lifestyle, Productivity, 4+ in ASC with A-11 |
| A-19 | P2 | Plan keyword validation after launch | deferred | Post-launch: read search-term data in the first two weeks |
| A-20 | P3 | Test high-contrast first frame with PPO | deferred | Post-launch: product page test of the first frame |

## R: market research

All sixteen are the owner's call. One line each on the decision asked.

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| R-01 | P0 | State calculated, tested, not AI-written | owner decision | Approve the exact "calculated and checked, no AI" claim for listing, paywall and pattern header. The description now carries a version of it |
| R-02 | P0 | Build the offer around fit-critical garments, add per-pattern unlock | owner decision | Whether to add a single-pattern unlock for the raglan ($6.99 to $9.99) and make one more beginner design free |
| R-03 | P0 | Lead with free tracker, no account, no ads, offline, frozen patterns | owner decision | Whether the subtitle and first screenshot lines change to those proof points |
| R-04 | P1 | Make trial and billing impossible to misread, add trial reminder | owner decision | Billing start date, Manage Subscription link, opt-in day-5 reminder, 14-day yearly trial test |
| R-05 | P1 | Free iCloud sync and export | owner decision | Whether to build sync and export (needs migration testing on real data) and amend the local-only privacy copy |
| R-06 | P1 | Count without unlocking: widget, Live Activity, Watch | owner decision | Whether and when to build a Live Activity first, then a Watch counter |
| R-07 | P1 | Second and third fit-critical design | owner decision | Which garments come next (child sweater, cardigan, socks, mittens) and whether to hold the subscription push until then |
| R-08 | P1 | Abbreviation help inside each step | owner decision | Whether to build tap-a-term help beyond the Materials glossary |
| R-09 | P2 | Guided next instruction as the pay trigger, row notes for PDFs | owner decision | Paywall and screenshot emphasis, and whether free row reminders ship |
| R-10 | P2 | Re-test the price ladder | owner decision | Hold $39.99 yearly; whether to A/B $4.99 to $5.99 monthly and $49.99 to $59.99 lifetime |
| R-11 | P2 | Register as PDF handler | owner decision | Whether to add document types so Safari and Files can Open in Ravel |
| R-12 | P2 | Stay knit-first, crochet-friendly counter | owner decision | Confirm the line. The description and keywords already say the counter and stash work for crochet |
| R-13 | P2 | Rating ask at a happy early moment | owner decision | Already implemented in the working tree (ProjectView.swift:29,108,115, ProjectsView.swift:38,132-140: prompt on returning to the list after 20 rows). Owner to confirm or revert |
| R-14 | P2 | Use the gift-season window now | owner decision | Gift-first screenshots and trial timing; promotional text already seasonal |
| R-15 | P3 | Check the name Ravel against Ravelry | owner decision | Whether to run a trademark and App Review check |
| R-16 | P3 | Do not lead with the growing fabric | owner decision | Screenshot order; overlaps A-07 |

## T: TikTok warm-up

All twelve are the owner's call (accounts, phone, filming, posting are owner-only).

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| T-01 | P0 | Generated-only account will fail, add real hands | owner decision | Approve one 25 minute hands-only filming session and the 5 hands / 9 drawn mix |
| T-02 | P1 | Lead with "Knitting math, drawn out" | owner decision | Approve the format |
| T-03 | P0 | Hold the line on AI signals | owner decision | Adopt the rule: no TTS, stock footage, photoreal yarn or people, invented persona |
| T-04 | P1 | Use the handle the report recommends | owner decision | Register it on TikTok, Instagram and YouTube the same day (signup is owner-only) |
| T-05 | P1 | Decide the bio disclosure | owner decision | No app mention for 14 days, or one factual "From the maker of Ravel" line |
| T-06 | P1 | Isolate from other brands | owner decision | Provide own email, phone and a device no other account is signed in on |
| T-07 | P2 | Test the two visuals unbranded | owner decision | Approve days 11 and 12 showing the fabric and size slider with no app name |
| T-08 | P2 | Keep video numbers aligned with the engine | owner decision | Approve generating video numbers from a script that states the engine rule. Engine ease and sizes changed in this audit (K-04, K-14 still deferred), so earlier numbers need regenerating |
| T-09 | P2 | No pre-launch capture, link plan | owner decision | No link for 14 days, then a static cast-on calculator page or the App Store link |
| T-10 | P2 | 14 days is a signal, not growth | owner decision | Accept the continue, change, stop thresholds |
| T-11 | P2 | Gift window is now | owner decision | Start by 2026-11-16 or lose the seasonal posts |
| T-12 | P3 | Needle chart numbers are guidelines | owner decision | Approve the "typical" caption on day 3 |

## V: new findings from this review

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| V-01 | P1 | Four existing tests now fail | fixed | All four tests rewritten for the new behavior; a fifth check added for thick yarn, where one cable sets the narrowest band |
| V-02 | P2 | Reset Count on a finished plain project leaves a dead counter | fixed | `resetCount` always puts the project back on the needles and counts any repeat from row 1 (`testCounterRulesForAPlainProject`) |
| V-03 | P2 | Finished plain project in the PDF reader ignores taps silently | fixed | Checkmark beside the count in the PDF reader when the project is finished |
| V-04 | P2 | Undo at row 0 may not swallow the second tap | fixed | First fix failed on the simulator: a view at zero opacity takes no taps, so the tap fell through and knitted a row. The fade is now inside the touch area, which stays live at row 0 (`CounterUITests`) |
| V-05 | P3 | Set Row backwards moves the repeat start | fixed | Set Row no longer moves where the repeat began (`testRepeatStartsWithTheNextRow`) |
| V-06 | P3 | syncPurchases after purchase, restore cancel message | fixed | Fresh `customerInfo` fetch in place of `syncPurchases`; a cancelled restore says nothing; the bare NSError code check is gone. The RevenueCat paths still have no test (C-04) |
| V-07 | P3 | dropUnnamed can rename an unrelated blank yarn | fixed | Only the yarn whose editor was open gets its name back; any other blank yarn is removed |
| V-08 | P3 | Photo import blocks the main actor and holds all pages | fixed | Photos are cut down off the main actor and kept as JPEG data, written into the PDF one page at a time (`testCameraPhotosAreCutToReadingSize`) |
| V-09 | P3 | Yardage test cannot fail on a bad constant | fixed | Golden bounds: garter scarf 570 yd, aran throw above 2,770 yd, DK neck scarf above 207 yd |
| V-10 | P3 | Go to Section lists duplicate names | fixed | Second handwarmer section is "Upper Hand" |
| V-11 | P3 | Copy nits in gauge line and materials | fixed | "over 4 in of stockinette"; small hats list one set of needles |

## R2: council round 2 (2026-11-13, fixed 2026-11-14)

A second full review of the fixed tree at `807e184` by the same two seats, read-only. Scores out of 10: Opus 7 then 7, Gemini 4.5 then 8.5. Two providers (Anthropic and Google); the Codex seats were out of usage. Nothing at P0 or P1. Reports: `raw/council-opus-round2.md`, `raw/council-gemini-round2.md`. Both seats name the device sandbox purchase (C-04) as the most important thing left.

| ID | Sev | Title | Status | Note |
|---|---|---|---|---|
| R2-01 | P2 | Undo on a finished project with no pattern drops a row the counter will not give back | fixed | `unknit` leaves a finished plain project alone and the undo button hides there (`canUndo`). `testCounterRulesForAPlainProject`. Gemini defect 1 is the same fault |
| R2-02 | P3 | Fabric row numbers count from row 0, the repeat dots from where the repeat began | fixed | `Fabric.tagged(_:every:from:)` counts from `repeatStart`. `testFabricNumbersCountFromTheStartOfTheRepeat` |
| R2-03 | P3 | A long screenshot is cut to 2,200 px on its long side and cannot be read | fixed | `PatternStore.page(from:pixels:)` cuts by area; a camera photo comes out the same size as before. `testATallScreenshotKeepsAReadableWidth` |
| R2-04 | P3 | A small hat lists short needles only, then is told to change to them at the crown | fixed | The note is written only for a hat that starts on a 16 in circular. `testASmallHatIsNeverToldToChangeNeedles`, every style, head and yarn weight |
| R2-05 | P3 | A picture from Files is shrunk on the main thread | fixed | Same path as photos: off the main actor, spinner up, and the project is checked before the pattern is attached |
| R2-06 | P3 | A second import can start while the first is binding | fixed | Add Pattern, Add Photos, Replace and Remove are disabled while an import runs |
| R2-07 | P3 | Counter UI test taps by share of the screen and covers one mode | fixed | Taps are in points from the window, undo is found from its own frame, and guided and PDF modes each have a one tap is one row test. The photo test checks the last page is upright |
| R2-08 | P2 | `testCachedListWinsOverTheBundledOne` fails after 2026-12-15 | fixed | Gemini defect 2. The cached date is now a day before the test runs |
| R2-09 | P3 | `StashView.draft` is written and never read | fixed | Gemini defect 3. Removed; a new yarn closed without a name is still dropped by `dropUnnamed` |

## Judgements

**G-01 (double count): refuted by SwiftUI semantics, believe Opus.** The fabric `onTapGesture` (ProjectView.swift:215) is on a descendant of the container `onTapGesture` (:64, :168). In SwiftUI the deeper view's tap takes the touch and the ancestor's does not also fire (that needs `simultaneousGesture`). Gemini's "in testing" has no evidence behind it. There is no UI test that taps the counter, so add one (tap `counter.plus` once, expect `counter.value` 1). Removing the inner gesture in counter and guided mode (Opus simplification 2) is optional hygiene.

**G-02 (PDF page restore): not proven; the stated mechanism is wrong, the risk is real.** If `go(to:)` at PatternView.swift:51-53 were a no-op the view would stay on page 0 and no later page-changed notification would fire, so nothing overwrites `patternPage` until the knitter scrolls. The overwrite Gemini describes needs the view to move back to page 0 after `restoring` flips false (for example an auto-scale pass). The one-runloop hop was written deliberately (comment "Jump after layout") and may well work. Treat as P1 until a simulator run: seed a 5 page PDF, `patternPage` 3, open, wait one second, expect page 3. Defensive fix if it fails: clear `restoring` only once `view.currentPage` is the target, or after about 0.5 s.

**G-05 (row band on photo pages): probably refuted, believe neither seat fully.** `place(on:)` (PatternView.swift:79-86) builds a highlight with explicit bounds and does not depend on text under it; the same path already serves chart pages with no text. Annotations draw over page content regardless of what it is. Gemini's claim that PDFKit does not render a highlight over a bitmap has no supporting detail. The real risk is low contrast: highlight is a multiply blend at 30 percent alpha over a dark photo. Check on the simulator with a photo pattern; if faint, use a `.square` annotation with an interior colour.

**G-06 (Ask to Buy cast): refuted, Opus and RevenueCat's docs are right.** In `purchases-ios-spm` the public async `purchase(package:)` throws `PublicError`, a typealias for `NSError` (Sources/Error Handling/PurchasesError.swift:18). `PurchasesError` is `internal` (:33). `ErrorCode` is a public `@objc enum` conforming to `Error` and `CustomNSError` (Sources/Generated/ErrorCode.swift:17,250), so `error as? ErrorCode` bridges and works; the file's own doc comment shows exactly that cast (PurchasesError.swift:46-47). `paymentPendingError` is raised as `ErrorUtils.paymentDeferredError().asPublicError` (PurchasesOrchestrator.swift:1459, StoreKit2TransactionListener.swift:132) with customerInfo nil, so it throws. The added NSError check (SubscriptionService.swift:196) is redundant and has no domain test; harmless.

**G-09 (needle editor): declined is acceptable.** Tapping "Needle or Hook" shows a real needle row in the list immediately; swipe dismiss equals Done; the yarn case differs only because a blank name is invalid. Severity P3.

**C-02 and SwiftData migration: the reasoning holds for additive changes, with one discipline risk and one new dead end.**
- Holds: with no `SchemaMigrationPlan`, SwiftData opens the store and Core Data infers a lightweight mapping when the model changed additively (new property with an inline default, new optional, new model, removed property, rename with `@Attribute(originalName:)`). The new `repeatStart: Int = 0` migrates builds 1 to 4 this way.
- Risk 1: a custom migration later needs a `VersionedSchema` for the version on disk. Declaring `SchemaV1` afterwards works only if it is a verbatim copy of the models 1.0 shipped (the store is matched by model hash). If the models are edited in place first, the only source is git history. Not tested here. Wrapping the current models in `SchemaV1` before 1.0 ships costs nothing and removes that risk.
- Risk 2: any non-lightweight change (type change, optional to required without default, relationship change) makes `ModelContainer` throw. That used to lose data silently; it now shows StoreUnavailableView, which is correct but has no recovery path (no export, no reset). Acceptable for 1.0, plan the migration before touching the models.

## Fixes that do not hold

Empty after the second pass on 2026-11-13: G-10 and V-01 to V-11 are fixed, with the outcome in each row above. Opus simplification 2 (one tap source per mode) is done as well: outside the PDF reader the fabric no longer counts taps of its own, which also closes the mechanism behind G-01.

## Not addressed anywhere

No disposition mentioned these.

Findings: A-03 and A-06 (nothing to do, consistent with the files), A-17 (pre-submit keyword check), A-18 (category and age rating), A-19 (post-launch keyword review), A-20 (PPO test), and the site half of A-13.

Parts of fixed findings left undone: K-28 provisional cast-on suggestion, K-09 cuff interpolation by sleeve length, C-05 `compressionQuality`, C-11 task cancellation on disappear, C-03's fixture generated from a real 1.0 build.

Opus items without an ID: 4 (regenerate a plan from `designRaw` when decode fails, so a library project never falls back to a raw counter; `Project.plan` still uses `try?`), 9 (the `Tab`, `OpenDesign` and `PaywallSnapshot` reads in RootView.swift:7-8 and LibraryView are still outside `#if DEBUG`). Tech-edit "cheap adds" (watch cap, crescent shawl, baby set) are not on any list; the five missing designs are deferred.

In the listing: description, promotional text, subtitle and keywords are edited in `fastlane/metadata` but not uploaded; screenshots A-07 to A-10 and the ASC-only fields A-11 are not done.

Process: R-13 was implemented in the tree although the manager listed every R-NN as an owner decision.
