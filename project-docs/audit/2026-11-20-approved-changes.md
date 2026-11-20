# Approved changes from the 2026-11-20 audits

Jack, 2026-11-20, replying to this list: "yeah do all, but do all the 'first update' now instead of later". Everything here goes into the next build after 29. Item 5 was put to him as "needs your yes to publish" and is covered by the same reply.

Sources: [fableaudit1120.html](fableaudit1120.html) (evidence in `raw/2026-11-20-fable/`) and [audit 1120.html](audit%201120.html) (source of items 1, 2a and 7). Each item has a card there with the reproduction.

## Defects

1. **Chart fit check before any purchase button.** `LibraryView.swift` line 392 skips `fits` when `!subscription.canOpen(item)`, so a free user sees "Try Free for 7 Days" at a size and gauge where a subscriber gets a disabled "Chart Does Not Fit This Gauge" (Fir Tree Hat, head 13 in, 24 stitches). Show the fit problem to everyone and say which number to change.
2. **Stash.** (a) `dropUnnamed` in `StashView` deletes a new yarn with an empty name even when fiber, skeins or dye lot were typed: keep any yarn with a field filled in and name it from fiber or weight; drop only an untouched draft. (b) Swipe to delete a yarn or needle asks first. (c) `addNeedle()` saves a default needle the moment the editor opens: drop it if the sheet is dismissed untouched.
3. **Round or row number within the section on every guided step** ("Body · Round 5"), including single-round steps. Go to Round works across the whole section, not only inside a multi-row step.
4. **"Whole Pattern" in the project menu**: the full written pattern as a scrolling list with the current step marked. The design page preview already renders this text. Paid designs keep the preview limit before purchase.
5. **Round Raccoon Beanie** (`docs/designs.json`, through `scripts/remote.py` and `scripts/topical-check.sh`): cast-on and round 1 loops drawn in the stated gray, not the default green (if that is drawing code and not data, fix it for every design whose first color is named); a finishing line telling the knitter to line the ears up with the face; the eyes worked in duplicate stitch after knitting, not stranded across about 60 black stitches; a one-line description naming the techniques.
6. **Launch screen background in the paper color**, light and dark. `UILaunchScreen` in `Info.plist` is an empty dict today, so launch is white.
7. **Largest text size and Reduce Motion.** In German at the largest accessibility size the guided stitch count cuts off ("5 von 21 · 88…"): let the instruction and count wrap, shrinking the fabric first. Onboarding uses a cut or a short fade, not a slide, with Reduce Motion on.
8. **Site and listing copy.** `docs/index.html` line 723 "tested" becomes "checked"; line 34 "32 designs" becomes 45; the free designs named the same way in `promotional_text.txt`, `description.txt` and the site (the app shows three free: Raccoon Beanie, Garter Scarf, Diagonal Dishcloth).

## Formerly "first update", now the same build

9. **Backup.** "Save a Backup" to Files and "Restore": projects with counts, frozen plans, PDFs, markers, second counter, notes, stash. No live sync. A failed save in the counter path must be visible, not discarded.
10. **PDF reader.** Remember zoom and scroll position per project; an option for the band to step with the count; accept PDFs from other apps (document types, "Open in Ravel"); an Import Pattern entry on the empty Projects screen.
11. **Finish screen.** Add a Photo, Share, Knit Again (another size or recipient). `castHere` in `DesignView` ignores finished projects so the button says Cast On again.
12. **Guided screen.** The next instruction in small grey type under the current one; house terms ("Inc across", "double stitch", k2tog, ssk) open their definition without counting a row; an instruction change no longer draws old and new text on top of each other (about 0.2 s today); the picture and section label stop shifting when the text length changes; the size is not cut off in the title; needle sizes at cast on are readable.
13. **Project list.** "row 18" instead of a bare number (for a library project the section and the next round), sorted by last worked, finished date shown. A plain counter's Set Row says "Rows completed", not "Row in This Section".
14. **Search.** "Holiday" and the other shelf tags are searched; christmas, gift, toque and jumper are mapped; a garment word outranks a size word ("cardigan for baby"); "3 year old" maps to child sizes; no silent wrong matches for dog or crochet.
15. **Count from the Lock Screen with a Live Activity.** The riskiest item, do it last. The count still goes only through the `Project` counter rules (`knit`, `unknit`) and ends in `persist()`. A `LiveActivityIntent` runs in the app's process, which avoids a second writer on the store. If it cannot be made safe, leave it out and say so.

Small, from the same audits: the onboarding primary button no longer fades out on each page change; the trial page's price line no longer overlaps the outgoing page for two frames; the Raccoon Beanie is not first in both Trending and Free; the "Gauge" heading over the yarn weight chips is renamed; one line on where to measure the head and why the hat is smaller than the head.

## Not changing

Prices, the trial page and paywall structure, the "Get Started" label. No design name in the paywall heading, no "Cast-on complete" button, no Watch, Ravelry import or timer. The sample photos stay (Jack, 2026-11-20).

## Free and paid

Nothing new goes behind the paywall. Items 2, 9, 10, 13 and 15 are tracker and stay free. Items 3, 4, 11 and 12 come with whatever pattern is open, so they are free on the free designs.

## Repo rules these touch

Freeze a `SchemaVn` snapshot and add a migration stage before any new stored property (zoom, last worked, finish photo). Every new UI string in every language through `scripts/l10n`. `PatternTests` green, and saved plans still decoding (`decodeIfPresent` for any new `Step` or `PatternPlan` key). No em dashes. Release gate before submitting.
