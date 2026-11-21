import Foundation

/// Mitts and gloves added after the first release.
extension Engines {
    struct Mitts: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var increases: Int
        var gusset: Int
        var thumb: Int
    }

    /// Fingerless mitts worked as a pair from the cuff up, fitted with a thumb gusset like a mitten's: the
    /// gusset grows from a single stitch, waits on waste yarn while the hand is knit to the knuckles, and is
    /// picked up for a short ribbed thumb. The thumb sits at the side, so either mitt fits either hand.
    static func fingerlessMitts(hand: Double, gauge g: Gauge) -> Mitts {
        // Snug: a little under the hand, so the mitt hugs the palm.
        let stitches = Sizing.stitches(hand * 0.95, per: g.spi, multiple: 4, minimum: 16)
        let increases = max(2, Int(((Double(stitches) * 0.36 - 2) / 2).rounded()))
        let gusset = 1 + 2 * increases
        let thumb = gusset + 1
        let cuff = Sizing.rows(min(2.5, hand * 0.33), per: g.rpi, minimum: 4)
        let before = Sizing.rows(0.25, per: g.rpi, minimum: 1)
        let gussetRounds = max(2 * increases, Sizing.rows(hand * 0.3, per: g.rpi))
        let spacing = min(4, max(2, gussetRounds / increases))
        let extra = max(0, gussetRounds - spacing * increases)
        let handRounds = Sizing.rows(hand * 0.17, per: g.rpi, minimum: 2)
        let top = Sizing.rows(hand * 0.08, per: g.rpi, minimum: 3)
        let thumbRib = Sizing.rows(0.5, per: g.rpi, minimum: 3)

        var b = PlanBuilder()
        for mitt in 1...2 {
            let name = "Mitt \(mitt)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(stitches) stitches with the smaller needles. Join in the round without twisting and place a marker.", stitches: stitches)
            b.work(["*K2, p2; repeat from * around"], rows: cuff, stitches: stitches)
            b.section = "\(name) · Thumb Gusset"
            b.row("Change to the larger needles and knit", stitches: stitches)
            b.work(["Knit"], rows: before - 1, stitches: stitches)
            b.row("K1, place a thumb marker, knit to the end. The stitch before the thumb marker is the gusset", stitches: stitches)
            b.work(["M1L, knit to the thumb marker, M1R, slip the marker, knit to the end"] + Array(repeating: "Knit", count: spacing - 1), rows: spacing * increases, stitches: stitches + 2, delta: 2)
            b.work(["Knit"], rows: extra, stitches: stitches + 2 * increases)
            b.row("Slip the \(gusset) gusset stitches to waste yarn and take out the thumb marker. Cast on 1 stitch over the gap with the backward loop method, then knit to the end", stitches: stitches)
            b.section = "\(name) · Hand"
            b.work(["Knit"], rows: handRounds, stitches: stitches)
            b.section = "\(name) · Top"
            b.row("Change to the smaller needles and work *k2, p2; repeat from * around", stitches: stitches)
            b.work(["*K2, p2; repeat from * around"], rows: top - 1, stitches: stitches)
            b.action("Bind off loosely in pattern.")
            b.section = "\(name) · Thumb"
            // Three picked up at the gap, then two taken away, so the base of the thumb closes without a hole.
            b.action("Return the \(gusset) held thumb stitches to the larger needles. Join new yarn at the gap and pick up and knit 3 stitches: one in the corner, one in the stitch cast on over the gap, and one in the other corner. Place a marker for the start of the round.", stitches: thumb + 2)
            b.row("Knit to the last 4 stitches, k2tog, k2tog", stitches: thumb)
            b.work(["*K1, p1; repeat from * around"], rows: thumbRib, stitches: thumb)
            b.action("Bind off loosely in pattern. Weave in the ends, closing any gap at the base of the thumb.")
        }
        let long = Double(cuff + before + 1 + spacing * increases + extra + 1 + handRounds + top) / g.rpi
        let yards = Sizing.yards(squareInches: hand * 0.95 * long * 1.2 * 2, spi: g.spi, factor: 1.1)
        let plan = pattern(b, estimate: yards, tools: ["\(g.ribNeedle.label) double-pointed needles for the ribbing, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the hand, or a long circular", "2 stitch markers, waste yarn", "Tapestry needle"], finished: "\(fits(stitches, g, "hand", hand)), \(Sizing.inches(long)) from the cuff to the knuckles", gauge: g, round: true)
        return Mitts(plan: plan, stitches: stitches, increases: increases, gusset: gusset, thumb: thumb)
    }
}
