import Foundation

extension Engines {
    struct Yoke: Equatable, Sendable {
        var plan: PatternPlan
        var neck: Int
        /// The stitch count after each increase round, the last one the count at the underarm.
        var rings: [Int]
        var body: Int
        var sleeveTop: Int
        var underarm: Int
    }

    /// A pullover knit from the neck down with a round yoke: no raglan lines, the yoke grows in four
    /// increase rounds spread evenly around, each followed by a purl ridge, and divides into the body and
    /// sleeves at the raglan pullover's own underarm numbers. `chest` is the finished chest.
    static func yokeSweater(chest: Double, wearer: Double, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> Yoke {
        let shape = raglanFit(chest: chest, wearer: wearer, child: false, gauge: g)
        let neck = shape.neck, panel = shape.panel, sleeveTop = shape.sleeveTop, underarm = shape.underarm, body = shape.body
        let top = 2 * panel + 2 * sleeveTop
        // Each ring grows by the same share, so the yoke widens the way a shoulder does.
        let ratio = pow(Double(top) / Double(neck), 0.25)
        var rings = (1...3).map { even(Double(neck) * pow(ratio, Double($0))) }
        rings.append(top)
        // A yoke a little deeper than a raglan's, the increase rounds spread down it, the last near the underarm.
        let yokeRounds = max(16, Sizing.rows(shape.depth + 0.5, per: g.rpi))
        let at = [0.14, 0.36, 0.58, 0.8].map { Int((Double(yokeRounds) * $0).rounded()) }

        var b = PlanBuilder()
        b.section = "Neckband"
        b.action("With the smaller \(Sizing.cable(16)) needle, loosely cast on \(neck) stitches, so the neck stretches over the head. Join in the round without twisting and place a marker for the start of the round, at the center back.", stitches: neck)
        b.work(["*K1, p1; repeat from * around"], rows: Sizing.rows(1, per: g.rpi, minimum: 4), stitches: neck)

        // Short rows across the back raise it, so the front sits lower at the throat.
        b.section = "Back Neck"
        let half = shape.backAtNeck / 2 + shape.sleeveAtNeck
        let pairs = min(4, max(2, Sizing.rows(1, per: g.rpi) / 2))
        let reach = max(1, min(Int((0.5 * g.spi).rounded()), (shape.backAtNeck / 2 - 1) / (pairs - 1)))
        b.row("Change to the larger needle. Short row: k\(half), turn", stitches: neck)
        b.row("Make a double stitch, then purl back past the marker and \(half) stitches more, turn", stitches: neck)
        b.work(["Make a double stitch, knit to the double stitch, knit it as one stitch, k\(reach), turn", "Make a double stitch, purl to the double stitch, purl it as one stitch, p\(reach), turn"], rows: 2 * (pairs - 1), stitches: neck)
        b.row("Make a double stitch, then knit to the marker", stitches: neck)
        b.row("Knit 1 round, knitting each double stitch as one stitch", stitches: neck)

        b.section = "Yoke"
        var stitches = neck, round = 0, moved = false
        for (ring, target) in zip(at, rings) {
            if ring > round { b.work(["Knit"], rows: ring - round, stitches: stitches) }
            var text = adjusting(stitches, to: target)
            stitches = target
            if !moved, Double(stitches) / g.spi > 24 {
                text += ". Move the stitches to the \(Sizing.cable(32)) needle"
                moved = true
            }
            b.row(text, stitches: stitches)
            b.row("Purl", stitches: stitches)
            round = ring + 2
        }
        b.work(["Knit"], rows: max(2, yokeRounds - round), stitches: stitches)

        b.section = "Divide"
        b.row("K\(panel / 2) back stitches. Slip the next \(sleeveTop) stitches to waste yarn for the first sleeve and cast on \(underarm) stitches under the arm with the backward loop method. K\(panel) front stitches. Slip the next \(sleeveTop) stitches to waste yarn for the second sleeve and cast on \(underarm) more. Knit the last \(panel / 2) back stitches", stitches: body)

        let hem = Sizing.rows(min(2, length * 0.2), per: g.rpi, minimum: 4)
        b.section = "Body"
        b.work(["Knit"], rows: max(2, Sizing.rows(length, per: g.rpi) - hem), stitches: body)
        b.section = "Hem"
        b.row("Change to the smaller needle. *K1, p1; repeat from * around", stitches: body)
        b.work(["*K1, p1; repeat from * around"], rows: hem - 1, stitches: body)
        b.action("Bind off loosely in pattern.")

        let cuff = raglanSleeves(&b, shape, chest: chest, length: sleeveLength, gauge: g)
        b.section = "Finishing"
        b.action("Weave in the ends, closing any gaps at the underarms. Block to the finished measurements.")

        let finishedChest = Double(body) / g.spi
        let depth = Double(yokeRounds) / g.rpi
        let area = finishedChest * (length + depth) + (shape.arm + Double(cuff) / g.spi) * sleeveLength + shape.arm * depth
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: ["\(g.needle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(32))", "\(g.ribNeedle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(32)), for the ribbing", "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop", "Stitch marker, waste yarn, tapestry needle"],
            finished: "Finished chest \(Sizing.inches(finishedChest)), to fit a \(Sizing.inches(wearer)) chest with \(Sizing.inches(finishedChest - wearer)) of ease. Body \(Sizing.inches(length)) and sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            gauge: g, round: true
        )
        return Yoke(plan: plan, neck: neck, rings: rings, body: body, sleeveTop: sleeveTop, underarm: underarm)
    }
}
