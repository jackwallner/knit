# Ravel pattern library: tech edit

Reviewer stance: knitting tech editor, hats, accessories and top-down raglans. Read-only review of `Shared/Patterns/Engines.swift`, `Design.swift`, `Plan.swift` and the guided view in `Ravel/Views/ProjectView.swift`, plus scratch harnesses that generate and check every plan.

## Verdict

Not publishable as it stands. One P0 and three P1s must be fixed first. After those, I would sign off: the stitch arithmetic is the cleanest I have seen in a generated library.

| Severity | Count |
|---|---|
| P0 (cannot be followed / counts do not work) | 1 |
| P1 (will not fit / yarn runs out) | 3 |
| P2 (confusing or non-standard) | 13 |
| P3 (polish) | 13 |

### How it was checked

- **Arithmetic.** I generated 61,560 plans: all 20 designs, every measure stepped across its full range (a 4-step grid for two-measure designs), at all 8 yarn weights plus 22 off-table gauges from 8 to 40 sts/4 in. Every knitted row was checked against the stitch count before it and the count after it. The checks covered rib multiples (4n in the round, 4n+2 flat, 2n for k1p1), odd counts for seed, crown wedges (count divisible by k+2, 8 taken per round), slouch spread wording (k x count + remainder = stitches), raglan setup and divide sums, shawl 4n+1 with a centre stitch, cable panel (n - 6) divisible by 8, and the dishcloth, neck scarf, face opening and sleeve decreases. Result: **0 failures.**
- **Yardage.** For every design at every named size, at its own weight plus fingering, worsted and bulky, I counted every stitch worked and multiplied by the loop length of plain knitting. That loop length is K / stitches per inch, with K = 4.0 to 4.3, the Munden constant for relaxed wool. Cast-on and bind-off cost 1.5 loops per stitch, and each end costs 15 in. I compared the result with `PatternPlan.yards`.
- **Fit.** I swept hats, raglans (every size and weight), cabled headband widths, neck scarf lengths, shawl geometry, balaclava openings and circular needle lengths.

## Per design

| Design | Result |
|---|---|
| Ribbed Beanie | Arithmetic PASS. K-07 (no DPN switch), K-14 (ease swings at bulky), K-15 (baby size on a 16 in circular), K-21, K-23 |
| Slouch Hat | Arithmetic PASS. K-14 (brim ease reaches -20% at super bulky), K-15, K-27, K-07 |
| Rolled Brim Hat | Arithmetic PASS. K-14, K-15, K-07 |
| Garter Scarf (free) | Arithmetic PASS. **K-02 (P1 yardage)**, K-10 |
| Ribbed Scarf | PASS. K-10 (gauge stitch not named) |
| Seed Stitch Scarf | PASS. K-10 |
| Ribbed Cowl | PASS. K-26 |
| Seed Stitch Cowl | Arithmetic PASS. K-18 (odd count in the round), K-26 |
| Chunky Cowl | Arithmetic PASS. **K-02 (P1 yardage)**, K-19, K-26 |
| Bordered Blanket | PASS. Yardage margin +17 to +31% |
| Garter Blanket | Arithmetic PASS. **K-02 (P1 yardage)** |
| Diagonal Dishcloth (free) | PASS. Classic Grandmother's Favorite construction, counts exact. K-22 (level) |
| Ear Warmer | PASS. K-23 |
| Handwarmers | Arithmetic PASS. K-11 (thumb slit), K-22 (level), K-23 |
| Leg Warmers | PASS. K-30 |
| Triangle Shawl | Arithmetic PASS. K-12 (finished size overstated) |
| Raglan Pullover | Arithmetic PASS at every size and gauge. **K-04 (P1 ease)**, K-05, K-06, K-07, K-08, K-09, K-16, K-25 |
| Neck Scarf | Arithmetic PASS. **K-03 (P1 yardage)**, K-24 |
| Cabled Headband | Arithmetic PASS (RS/WS rows and C6F placement correct). K-13, K-28 |
| Balaclava | **K-01 (P0, top worked inside out)**, K-06, K-07, K-20 |

### The coordinator's balaclava question: CONFIRMED

The other reviewer is right: as written, the knitter rejoins with the wrong side facing. Medium worsted, `Engines.balaclava`:

1. The first flat row, "Bind off 26 stitches, knit to the end, turn", is a RS row.
2. Next comes `b.work(["Purl, turn", "Knit, turn"], rows: faceRows)` with `faceRows` = 26. `Sizing.rows(..., even: true)` always makes this even. Index 0 is a WS purl and index 25 is a RS knit, so the section ends on "Knit, turn".
3. That gives 1 + 26 = 27 flat rows. Row 27 is RS, and it ends in **turn**. After the turn, the **wrong side** faces.
4. The next action is "Cast on 26 stitches with the backward loop method, then join in the round again".

Done literally, the knitter casts on and joins with the WS out. All 17 "Top" rounds and the crown are then knit with the purl side outward (reverse stockinette), and the rounds travel in the opposite direction. The knitter only notices at the crown.

Compare the handwarmer thumb slit, which is correct. It has an even count starting on "Knit…, turn", so the last row is "Purl…, turn" and the RS faces when the instruction says "Knit to the marker and join". The balaclava has one more flat row (the bind-off row), and that row flips the parity.

The exact fix is in K-01.

---

## FINDINGS

### K-01 | Balaclava | P0 | Face opening ends with "turn", so the top and crown are worked inside out
Evidence: Medium, worsted 18/24. The flat rows are "Bind off 26 stitches, knit to the end, turn" (RS), then 26 rows of "Purl, turn / Knit, turn". The last is row 27, "Knit, turn", which is RS and then turns, so the WS faces. The next step is "Cast on 26 stitches with the backward loop method, then join in the round again." Every gauge and head size has this parity: `faceRows` is forced even, and 1 + even is odd.
Fix: in `Engines.balaclava`, replace the face block with:
```swift
b.row("Bind off \(face) stitches, knit to the end, turn", stitches: around - face)
b.work(["Purl to the end, turn", "Knit to the end, turn"], rows: faceRows - 1, stitches: around - face)
b.row("Knit to the end. Do not turn", stitches: around - face)
b.action("With the right side still facing, cast on \(face) stitches with the cable or backward loop method, then join in the round again.", stitches: around)
```
`faceRows - 1` is odd, so the alternating block ends on "Purl to the end, turn" and the next row is RS. Height is unchanged, at 1 + faceRows rows. Add a `PatternTests` case: count the flat rows from the bind-off row to the rejoin, and assert the total is odd and the last flat row has no "turn".

### K-02 | Garter Scarf, Garter Blanket, Chunky Cowl | P1 | Garter yardage has no reserve; knitters will run out
Evidence: in `scarf(.garter)`, `blanket(bordered: false)` and `cowl(.garter)`, the stitch count is set at the garter row gauge of 2 x spi, but `Sizing.yards` uses factor 1.25. Garter has 1.5x the rows of stockinette per inch at the same loop length, so it needs about 1.5x the yarn. Physical counts (stitches worked x 4.0 to 4.3 / spi):

| Item | App | Needed |
|---|---|---|
| Garter Scarf Classic, worsted | 480 yd | 458 to 493 yd |
| Garter Blanket Crib, aran | 1,520 yd | 1,453 to 1,562 yd |
| Garter Blanket Throw, aran | 2,700 yd | 2,577 to 2,770 yd |
| Chunky Cowl Infinity, super bulky | 280 yd | 284 to 305 yd |

Margins run from -8% to +5%. Stockinette and rib designs, measured the same way, sit at +15 to +45%. So the "tenth held back for swatching" comment in `Sizing.yards` is false for garter. The Garter Scarf is a free design, so this is the first pattern most users knit.
Fix: set the garter factor to 1.6 in `Engines.scarf`, `Engines.blanket` (unbordered) and `Engines.cowl` (`.garter`). That matches the +25 to +30% margin the other designs carry. Better still, compute yards from the plan itself (Σ stitches x rows x 4.3 / spi / 36, x 1.15) in one helper, so no design can drift. Add a test that `plan.yards` is at least 1.1x that physical count for every design.

### K-03 | Neck Scarf | P1 | Yardage is below what the pattern consumes
Evidence: `neckScarf` charges `width * length * 0.6 * 1.25`. With the middle section and the 1-stitch-per-interval taper, though, the knitted area is more than 0.6 of the bounding rectangle. Classic DK 42 x 5.5 in: the app says 180 yd, and the physical count is 193 to 207 yd (-7 to -13%). Fingering Small is 160 yd against 177 to 190 yd (-10 to -16%). Bulky Small is 80 yd against 86 to 93 yd.
Fix: in `Engines.neckScarf`, derive area from the rows actually written: `Double(taper) * Double(widest + 3) / 2 * 2 + Double(middle * widest)` stitch-rows. Convert to yards with the garter rate from K-02, or use the shared stitch-count helper proposed there.

### K-04 | Raglan Pullover | P1 | "Chest" is used as finished chest with zero ease, but reads as a body measurement
Evidence: `raglan` sets `body = chest x spi`, and the finished line reads "Chest 40 in". The measure is labelled "Chest", the same way Head, Hand and Calf are body measurements elsewhere (where the engine adds negative ease). A knitter who measures a 40 in chest and enters 40 gets a 40 in sweater: 0 in ease, where a standard fit is +2 to +4 in.

The sleeves follow the chest: 14.0 in for 40. A body with a 40 in bust has an upper arm of about 13.5 in (Craft Yarn Council L), which leaves 0.5 in of ease in worsted stockinette. The named sizes (XS 32 ... 5X 64) only make sense as finished sizes. For example, CYC body M is 36 to 38 in, not 40.
Fix: in `Design.measures` for `.raglanPullover`, relabel the measure "Finished Chest", and show "Your chest plus 2 to 4 in" in the DesignView. Alternatively, keep "Chest" as a body measurement, add `ease = 3` in `Engines.raglan` (`body = Sizing.stitches(chest + ease, …)`, `arm = (chest + ease) * 0.31 + 1.6`), and shift the size table down to body sizes (XS 30 ... 5X 62). Whichever you choose, state "to fit chest X in" and "finished chest Y in" separately in `finished`.

### K-05 | Raglan Pullover | P2 | No front neck drop, so the front rides up against the throat
Evidence: the setup round reads "k34 for the front … k34 for the back". Front and back neck are identical and there are no short rows. On a top-down crew neck, this pulls the front neckline up to the throat and the sweater tips backward.
Fix: in `Engines.raglan`, after the setup round, add 2 to 3 pairs of back-neck short rows (German short rows) worked across the back and sleeves. Their depth should be about `Sizing.rows(1.5, per: g.rpi)`. Spell out the method in the glossary.

### K-06 | Raglan Pullover, Balaclava | P2 | The cast-on that must stretch over the head has no method
Evidence: "With the smaller 16 in needle, cast on 88 stitches" (raglan neck) and "Cast on 88 stitches" (balaclava neck). Both edges have to pass over a 22 to 23.5 in head. A tight long-tail cast-on is the most common reason a top-down neck will not go on.
Fix: in both functions, change the cast-on text to "Loosely cast on N stitches with a stretchy method (long-tail over two needles or German twisted)".

### K-07 | Hats, Balaclava, Raglan | P2 | Needle changes are listed in materials but never instructed
Evidence: the hats and the balaclava list "Double-pointed needles in the same size for the crown", but no step says when to switch to them. On the raglan, the yoke starts with 88 stitches on the 16 in needle and ends with 260, and no step moves them to the 32 in needle.
Fix: in `crownRounds`, append " (change to double-pointed needles or magic loop when the stitches no longer reach around)" to the first decrease round whose stitch count drops below 16 in x spi. In `Engines.raglan`, add the same note to the yoke round where `onNeedle / g.spi` passes 24 in: "change to the 32 in needle when the stitches crowd".

### K-08 | Raglan Pullover | P2 | Plus sizes get tight upper arms and loose cuffs
Evidence (worsted): read as finished sizes against CYC body upper arms (2X 17, 3X 18.5, 4X 19.5 in), the sleeve tops are 2X 17.8, 3X 19.1, 4X 20.0 in. That is 0.5 to 0.8 in of ease, where at least 1.5 to 2 in is normal. At the other end, the 5X cuff is 54 sts = 12.0 in, and the 4X cuff is 11.6 in. Finished cuffs of 9 to 10.5 in are usual, so these cuffs bell.
Fix: in `Engines.raglan`, change `arm = chest * 0.31 + 1.6` to `max(chest * 0.31 + 1.6, chest * 0.34)` for chest above 48. Change the cuff target from `chest * 0.14 * spi + 3 * spi` to `min(chest * 0.14 + 3, 10.5)` in inches.

### K-09 | Raglan Pullover | P2 | Short sleeves still taper to a wrist cuff
Evidence: the cuff target ignores `sleeveLength`. At M worsted with a 10 in sleeve, the sleeve still decreases to 38 sts = 8.4 in and ends near the elbow, where the forearm measures 10 to 11 in. At the extremes, `spacing < 1` makes the code decrease every round: chest 66, fingering, 10 in sleeve gives 34 consecutive decrease rounds, 154 down to 86 sts in 3.8 in. That is a funnel.
Fix: in `Engines.raglan`, interpolate the cuff target by length: `wristCuff + (sleeve - wristCuff) * max(0, (18 - sleeveLength) / 18)`. Cap the taper so decreases are spaced at least 4 rounds apart. When they cannot be, keep the extra stitches rather than packing decreases.

### K-10 | All designs | P2 | The gauge line does not name the stitch, and the yarn line does not name the weight
Evidence: `gaugeLine` prints "Gauge: 18 stitches and 24 rows over 4 in" for the Garter Scarf, the Ribbed Scarf and the Seed Cowl. The engines take that as stockinette gauge and then assume 36 garter rows, 1.1x seed rows, and so on. A knitter who swatches in garter or rib will "match" the wrong number. `yarnLine` prints "About 480 yd of yarn" without "worsted weight", so the knitter cannot shop from it.
Fix: change `gaugeLine` to "Gauge: 18 sts and 24 rows = 4 in in stockinette, after blocking. Use any needle that gives this gauge". Change `yarnLine` to "About 480 yd of worsted weight yarn". Map the label from `YarnWeight`, nearest by stitches.

### K-11 | Handwarmers | P2 | The thumb slit has no edge stitches and the wording is circular
Evidence: "Knit to the marker, turn / Purl to the marker, turn", 12 rows at medium worsted. The marker sits in the gap, so "to the marker" means a whole row, which confuses people. All stitches are stockinette, so both slit edges roll inward and the thumb hole looks ragged.
Fix: in `Engines.handwarmers`, change the texts to "K2, knit to the last 2 stitches, k2, turn" and "K2, purl to the last 2 stitches, k2, turn", which gives garter edges. Change the next row to "Knit to the end of the round and join in the round again".

### K-12 | Triangle Shawl | P2 | The stated finished size needs about 25% blocking stretch
Evidence: `pairs = (wingspan * spi * 1.13 - 5) / 4`. Top-down garter geometry (4 increases every 2 rows, 2 rows per stitch) needs about 1.414 x wingspan x spi live stitches at the end. Classic DK binds off 373 sts, which is about 48 in of wingspan and 24 in of depth unblocked. "60 in across, 30 in deep after blocking" needs 25% stretch in both directions. Garter rarely gives more than 10 to 15%.
Fix: in `Engines.shawl`, either use 1.3 in place of 1.13 and recompute yards, or keep 1.13 and print "About 48 in across unblocked, up to 55 in blocked".

### K-13 | Cabled Headband | P2 | The width stepper does nothing over most of its range
Evidence: at aran, widths 2.5, 3.0 and 3.5 all give 14 sts (3 in), and 4.0 to 5.0 all give 22 sts (4.5 in). At super bulky, every width from 2.5 to 5 gives 14 sts at 4.75 in. A knitter sets 3.5 and reads "3 in wide".
Fix: in `Engines.cableHeadband`, add 0 to 3 extra reverse stockinette stitches to each side panel ("K2, p\(side), …") so the width tracks the request within half an inch. Alternatively, clamp the Width measure per gauge and show the achievable width on the stepper.

### K-14 | Ribbed Beanie, Slouch Hat, Rolled Brim Hat | P2 | Rounding to multiples of 8 swings ease from 0% to -20% at heavy gauges
Evidence: from `Sizing.stitches(..., multiple: 8)`:

| Hat | Head | Cast-on | Ease |
|---|---|---|---|
| Super bulky slouch | 16 in | 12.8 in | -20% |
| Super bulky slouch | 23.5 in | 19.2 in | -18% |
| Super bulky ribbed | 16 in | 16.0 in | 0% (loose) |
| Worsted slouch | 13 in | 10.7 in | -18% |

At worsted and finer, the ease stays between -7% and -12%, which is fine.
Fix: in `Engines.hat`, cast on to a multiple of 4 for the rib. Add 1 to 7 stitches on the last body round ("knit, increasing N evenly") or remove them, so the crown keeps a multiple of 8. Alternatively, use 6 or 7 wedges when spi is below 4. Target 0.9 x head within ±4%.

### K-15 | Hats | P2 | Baby sizes do not fit a 16 in circular
Evidence: Baby (16 in head) casts on 13.7 to 14.9 in of fabric at every weight except super bulky, all on "16 in circular needle". Toddler is exactly 16.0 in, which is tight but workable.
Fix: in `Engines.hat`, when `Double(brim) / g.spi < 16`, list "12 in circular, or double-pointed needles or magic loop" instead.

### K-16 | Raglan Pullover | P2 | Increase, divide and pick-up instructions are run-on sentences
Evidence: the body-only increase round is 231 characters ("Knit to the marker, slip marker, k1, M1L, … M1R, k1"). The divide is 260 characters, and the sleeve pick-up is about 230. At 30 pt with `minimumScaleFactor(0.4)`, these shrink to about 22 to 24 pt, and they are hard to keep your place in while working a 260-stitch round.
Fix: in `Engines.raglan`, define the move once ("Inc: k1, M1L … M1R, k1") and write "Sleeve, knit across. Front, inc. Sleeve, knit across. Back, inc". Split the divide into four short actions (first sleeve to waste yarn, cast on, front, second sleeve), each with its own count.

### K-17 | All designs | P2 | The glossary misses terms beginners meet on the first screen
Evidence: `PatternPlan.glossary` covers k2tog, ssk, yo, M1, M1L, M1R and C6F. Instructions also use k, p, "*…; repeat from *", "place marker", "slip marker", "backward loop method", "pick up and knit", "bind off in pattern", "join in the round without twisting" and "turn". Beginner-rated designs (both scarves, the dishcloth) use k, p and repeats.
Fix: add those entries to `PatternPlan.glossary`. Note that the `\b…\b` match needs to cover phrases such as "pick up and knit" and the "*" repeat notation.

### K-18 | Seed Stitch Cowl | P3 | An odd count in the round leaves a seam column
Evidence: 117 sts with "*K1, p1 … k1" / "*P1, k1 … p1". The last and first stitch are always the same, which breaks the seed for 2 stitches at the start of the round.
Fix: in `Engines.cowl(.seed)`, use `multiple: 2, extra: 0` and the texts "*K1, p1; repeat from * around" / "*P1, k1; repeat from * around".

### K-19 | Chunky Cowl | P3 | Garter in the round jogs, and "Chunky" is not super bulky
Evidence: the "Knit / Purl" rounds form a visible step at the start of the round. Also, chunky means #5 bulky to most knitters, but the design defaults to #6 super bulky.
Fix: add "To hide the jog, slip the first stitch of each purl round purlwise" to the first purl round. Either rename the design "Super Chunky Cowl" or default it to `.bulky`.

### K-20 | Balaclava | P3 | The face edging starts without fresh yarn, and the first Top round is partial
Evidence: "Cut the yarn, thread it through the last 8 stitches" is followed by "pick up and knit 92 stitches", with no new yarn joined. After the rejoin, the round marker sits before the newly cast-on stitches, so "Top 17 rows" starts mid-round.
Fix: in `Engines.balaclava`, change the edging text to "Join new yarn at the lower corner of the opening. With the smaller needles, pick up and knit…". Change the rejoin text to "…join and knit to the marker".

### K-21 | Ribbed Beanie, Slouch Hat | P3 | The brim rib is on the body needle
Evidence: the "US 7 · 4.5 mm 16 in circular" is the only needle listed, and the rib brim relaxes over time.
Fix: list `g.ribNeedle` for the brim in `Engines.hat`, and add "Change to the larger needle" to the first Body round.

### K-22 | Diagonal Dishcloth, Handwarmers | P3 | Level labels are off by one
Evidence: under CYC levels, yo and k2tog make the dishcloth Easy, not Beginner. Handwarmers are a plain tube with a slit, which is easier than the Easy-rated slouch hat, so Intermediate is overrated.
Fix: in `Design.level`, set `.dishcloth` to `.easy` and `.handwarmers` to `.easy`. The rest are right.

### K-23 | Hats, Ear Warmer, Handwarmers, Leg Warmers, Balaclava | P3 | No finished circumference is stated
Evidence: "Fits a 22 in head" is shown, but the knitter is never told the hat measures 19.5 in, which is the number they check against their swatch.
Fix: in each engine, change `finished` to "19.5 in around, to fit a 22 in head".

### K-24 | Neck Scarf | P3 | The scarf can come out longer than asked
Evidence: sport and worsted at 32 x 9 in give "34 in long". `even()` rounds the interval up to 4, so `taper * 2 > total`, and `middle` clamps to 2.
Fix: in `Engines.neckScarf`, round the interval down (`2 * Int(x / 2)`, minimum 2) so the tapers never exceed the requested length.

### K-25 | Raglan Pullover | P3 | In large sizes the sleeve cap is front-loaded
Evidence: 5X worsted has 17 consecutive every-round increases at all 8 points. The sleeves then stop increasing for the last 20 rounds (3.3 in) while the body continues.
Fix: in `Engines.raglan`, put the "packed" every-round increases on the body only, and spread the sleeve increases evenly over `yokeRounds`.

### K-26 | Cowls | P3 | The circular length rule is coarse
Evidence: the ribbed cowl at around 26 to 29 in puts 30 to 33 in of fabric on a 16 in circular. The seed and garter cowls at around 30 put 30 in on a 32 in circular, which is a stretch.
Fix: in `Engines.cowl`, choose by fabric circumference: below 20 in use 16 in, 20 to 34 in use 24 in, and above that use 32 in.

### K-27 | Slouch Hat | P3 | The increase round bunches its increases
Evidence: "Work (k3, M1) 24 times, knit the last 8" (Large, aran) leaves 8 stitches with no increase.
Fix: in `Engines.spread`, distribute the remainder: work (k(gap+1), M1) for `rest` repeats, then (k gap, M1) for the rest.

### K-28 | Cabled Headband | P3 | About 3 in of negative ease, and a seam
Evidence: 104 rows = 18.9 in for a 22 in head (factor 0.88). Lengthwise knit stretches less than widthwise. The seam is sewn cast-on to bind-off.
Fix: in `Engines.cableHeadband`, use a factor of 0.92. Suggest a provisional cast-on and three-needle bind-off or grafting.

### K-29 | Guided view | P3 | "Row" is used for patterns worked in rounds
Evidence: the `ProjectView` alert title "Row in This Section" and the accessibility label "Row N" appear on hats, cowls and the raglan.
Fix: use "Round" when the current step's section comes after a "Join in the round" action, or use neutral wording such as "Position in this section".

### K-30 | Leg Warmers | P3 | A straight stockinette tube slides down
Evidence: the leg is 12.4 in of stockinette around a 14 in calf, with a 2 in rib at each end and no shaping to the ankle.
Fix: in `Engines.legWarmers`, offer a rib-throughout option. Alternatively, put 4 stitches of rib at the back as a "seam", or decrease about 15% toward the ankle cuff.

---

## Fit and standards notes (no finding)

- **Hats.** Ribbed and rolled hats cast on at -7 to -12% of head at fingering to aran, which is standard. Heights are 0.37 x head (8.2 in at 22 in) for the beanie and 0.47 x head (10.3 in) for the slouch, with a 1 in roll allowance on the rolled brim. All are in normal ranges. Crowns are 8 wedges, decreased every other round, then every round, closing on 8 stitches. That is standard.
- **Raglan.** Yoke depth runs 7.5 in (XS) to 11.5 in (5X), which is CYC armhole depth plus about 1 in. Neck circumference is 17 to 21.7 in at every gauge, and back neck width is 6.5 to 8.8 in. The underarm cast-on is 2.2 to 4.8 in. Body and sleeve lengths match CYC. Increase directions (k1, M1L after the marker; M1R, k1 before it) and sleeve decreases (k1, k2tog … ssk, k1) are conventional.
- **Other items.** Cowl, scarf, blanket, dishcloth and shawl sizes match common published dimensions. The garter assumption of 2 rows per stitch is correct. The 1.1x seed row factor is reasonable.
- **Needles.** The needle table (worsted US 7, DK US 6, aran US 9, bulky US 10.5, super bulky US 13, fingering US 3) and the rib needle two sizes down are both right.
- **Yardage by family.** Hats, cowls, mitts, leg warmers, the balaclava, the raglan and the bordered blanket carry +15 to +78% over the physical count. Only the garter family (K-02) and the neck scarf (K-03) are short.

## Catalog: the five absences a paying knitter notices first

Ranked by demand:

1. **Socks** (cuff-down, heel flap and gusset, sized by foot circumference and length). This is the largest single category on Ravelry after hats. Feasible: every section is a fixed row sequence. The heel turn is a short list of distinct rows (the engine already supports per-row texts), and the gusset is a 2-stitch decrease every other round, the same mechanism as the raglan sleeve.
2. **Cardigan** (top-down raglan with picked-up button bands). Feasible by reusing `Engines.raglan`, worked flat with front edges, plus a band pick-up rate (3 of 4 rows) and evenly spaced buttonholes. The raglan arithmetic is already proven.
3. **Baby and child sweater.** The raglan stops at a 28 in chest, so there is nothing from newborn to age 10, which is the most gifted garment. Feasible: extend the raglan range down to 16 in with child proportions (upper arm, cuff, neck and yoke formulas need a child table) and add a lap or button neck for heads larger than the neck opening.
4. **Mittens with a thumb gusset.** Expected in a winter hat-and-accessory library, and the handwarmer slit does not replace them. Feasible: a gusset increase section with markers, thumb stitches to waste yarn, the same wedge-style top decreases as `crownRounds`, then the thumb picked up.
5. **Sweater vest or tank** (bottom-up, with armhole and V or crew neck shaping, finished with picked-up rib). Feasible: flat front and back sections with bind-offs and paired decreases, then a pick-up count per edge.

Cheap adds that would round out the shelves: a folded-brim watch cap (one more `HatStyle`), a crescent or asymmetric garter shawl (a different increase cadence), and a baby hat and bootie set. Colorwork yokes and lace charts are not feasible in a one-line-per-row text engine without charts.
