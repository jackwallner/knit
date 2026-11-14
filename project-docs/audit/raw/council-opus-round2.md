Round 2 review (Opus seat): the 1.0 fixes hold. I found one new P2 on the counter and six P3s, and nothing at P0 or P1. I worked read-only: no edits, builds or simulators.

## Fixes that hold

- **Counter rules** (Models.swift:87-134): `knit`, `unknit`, `jump`, `jump(toTap:)` and `resetCount` all end in `persist()`. `rowLimit` caps every path. The library finish/reopen logic is right. `repeatStart` keeps the repeat counting from the next row, and Set Row no longer moves it.
- **One tap source per mode**: the fabric has `allowsHitTesting(false)` outside the PDF reader, so the screen-wide gesture is the only counter there. The PDF strip counts on its own, and the count pill does not take taps. The undo button fades inside its label and keeps a 76 pt touch area, so it stays tappable at row 0.
- **Rest of ProjectView**: the finished mark and the PDF checkmark show. Go to Section goes through `jump(toTap:)` and reopens a finished project. Photos are shrunk off the main actor, and the import checks the project still exists before attaching. The review moment is recorded on disappear, and the ask comes back at the list.
- **PatternStore**: `page(from:)` bakes in orientation and writes JPEG at 2200 px. `save(pages:)` makes letter-width pages and flips the image upright. Empty or corrupt input throws and deletes the half-written file.
- **Store**: a store that will not open now shows the failure screen with no in-memory fallback, and the app saves whenever the scene leaves active.
- **Frozen plans**: every field added to `Step` and `PatternPlan` after 1.0 is read with `decodeIfPresent`, and an empty `texts` array cannot cause a divide by zero.
- **Engines**:
  - Balaclava parity is right: faceRows+1 flat rows, ending on a right-side "Do not turn" row.
  - The raglan stitch counts add up.
  - Sleeve decreases are at least 4 rounds apart.
  - Both cabled headband rows add up to the cast-on, and the wrong-side row mirrors the right-side row.
  - Every pattern goes through `pattern(...)`, which never states less yarn than the written rows use plus 15 percent.
- **Purchases**: I checked against the RevenueCat 5.x source. The async `purchase` returns `userCancelled` and does not throw. `.unconfirmed` and `.pending` are told apart correctly. Restore has four outcomes, and `syncPurchases` is gone.
- **Stash**: `dropUnnamed` puts back the name of only the yarn that was opened.

## Findings

**R2-01 · P2 · Models.swift:101-105, ProjectView.swift:284-299 (undo shown at :47 and :61)**
On a finished plain project, a tap on the screen does nothing, but undo still takes a row off.
- Steps: a plain project at row 240, marked finished. Open it, in counter or PDF mode, and touch undo by accident.
- Wrong result: the count drops to 239 and is saved. Tapping the screen cannot put it back, because `knit` ignores finished plain projects. The list now shows 239 under Finished.
- This breaks the "a row count must never be lost" rule. The test comment calls a finished project "a record", but only half of it is protected.
- Fix: add `guard plan != nil || !isFinished else { return }` at the top of `unknit`, or hide undo when `plan == nil && isFinished`. Then add an `unknit` check to `testCounterRulesForAPlainProject`.

**R2-02 · P3 · ProjectView.swift:211 with Fabric.swift:67**
The row tags on the fabric no longer line up with the repeat once a repeat starts after a hem.
- Steps: knit 12 rows of hem, then set a repeat of 8.
- Wrong result: the dots finish repeats at rows 20 and 28, but the fabric tags rows 8, 16 and 24, counted from the cast-on. This came in with the G-11 fix.
- Fix: count the tags from where the repeat began: `number > repeatStart && (number - repeatStart) % markEvery == 0`.

**R2-03 · P3 · PatternStore.swift:35**
Capping the longest side at 2200 px makes long images unreadable. This is a regression from the C-05 fix; before it, images kept full resolution.
- Steps: import a stitched long screenshot of a web pattern, 1179 x 12000 px.
- Wrong result: it is stored at 216 x 2200 px, so 40 px text shrinks to about 7 px.
- Fix: cap by area instead: `scale = min(1, sqrt(4_800_000 / (w * h)))`.

**R2-04 · P3 · Engines.swift:70 and :76-78**
Small hats get two needle instructions that contradict each other. V-11 fixed the materials list but not the crown note.
- Steps: ribbed beanie, Baby (16 in), worsted.
- Wrong result: the brim is 64 stitches, 14.2 in, so materials say double-pointed needles or magic loop throughout. But `switching` still adds "Change to double-pointed needles when the stitches no longer reach around" to the first crown round.
- Fix: call `switching` only when `Double(brim) / g.spi >= 16`.

**R2-05 · P3 · ProjectView.swift:349-352 via PatternStore.swift:20-22**
An image picked from Files is still decoded and redrawn on the main actor, with no spinner. V-08 moved only the Photos path off it.
- Steps: use Add Pattern to pick a 48 MP HEIC in Files.
- Expected result: a hang of a few hundred ms and a memory spike near 200 MB. I did not measure this on a device.
- Fix: send this path through the same detached task and `bindingPhotos` spinner as photos.

**R2-06 · P3 · ProjectView.swift:318-323, :355-373**
The pattern menu stays live while photos are being bound, so whichever import finishes last silently wins.
- Steps: start Add Photos with 20 photos. While the spinner shows, use Add Pattern to attach a PDF.
- Wrong result: the PDF attaches at once. When the photos finish, `setPattern` deletes that PDF and puts the photos in its place.
- Fix: `.disabled(bindingPhotos)` on Add Pattern, Add Photos and Replace Pattern.

**R2-07 · P3 (test reliability) · CounterUITests.swift:42**
The UI test taps at fractions of the screen, not at fixed points.
- Wrong result: the undo touch area runs from x 8 to 84 pt. On a 440 pt wide device (Pro Max), the "near miss" tap at dx 0.19 lands at x 83.6, only 0.4 pt inside. That test is close to flaky there.
- Fix: work out the tap points in points from `app.windows.firstMatch.frame`, for example undo's center at (46, height - 38).

## Still untested

- **One tap is one row in guided and PDF modes.** The UI test covers only the plain counter. The PDF strip is a different tap setup and has no test.
- **Deleted project during photo import.** Nothing checks that `modelContext == nil || isDeleted` holds after `context.delete` and `save()` on iOS 17. The C-11 guard depends on it. A three-line unit test would settle it.
- **Photo pages after the first.** The orientation check reads only page 0. Pages 1 and 2 should also be checked to be upright.
- **Smaller gaps:** `dropUnnamed`, the ask on return to the list, and plans at custom gauges (tests use only the 8 standard weights; nothing crashes, by reading).
- **Real RevenueCat purchase and restore** remain C-04 (owner decision).

Score: 7/10

Fixing R2-01 and adding a one-tap-one-row UI test for the guided and PDF modes would raise it to 8, and a sandbox purchase of all three products on a device (C-04) would raise it further.
