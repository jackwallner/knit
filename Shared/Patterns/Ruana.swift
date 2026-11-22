import Foundation

extension Engines {
    struct Ruana: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var front: Int
        var backRows: Int
    }

    /// A ruana knit in one piece in seed stitch, which looks the same on both sides: the back from the hem up
    /// to the shoulders, then a stitch bound off at the middle and each half worked on as a front, so it opens
    /// down the front. `width` is across the back; `length` is from the shoulder line to the hem.
    static func ruana(width: Double, length: Double, gauge g: Gauge) -> Ruana {
        // Each front an odd count, so every seed row starts and ends with a knit stitch.
        let front = 2 * Int((width / 2 * g.spi / 2).rounded(.down)) + 1
        let stitches = 2 * front + 1
        // Seed stitch packs about a tenth more rows into an inch than stockinette. An even count, so the split
        // starts on a right-side row.
        let rate = g.rpi * 1.1
        let rows = max(10, Sizing.rows(length, per: rate, even: true))
        let seed = "K1, *p1, k1; repeat from * to the end"

        var b = PlanBuilder()
        b.section = "Back"
        b.action("Cast on \(stitches) stitches loosely.", stitches: stitches)
        b.work([seed], rows: rows, stitches: stitches)
        b.section = "First Front"
        b.row("With the right side facing, k1, *p1, k1; repeat from * until \(front) stitches are on the right needle, and slip them to waste yarn for the second front. P1, k1, pass the purl stitch over to bind it off, then *p1, k1; repeat from * to the end", stitches: front)
        b.work([seed], rows: rows - 1, stitches: front)
        b.action("Bind off loosely in pattern.")
        b.section = "Second Front"
        b.action("Return the \(front) stitches of the second front to the needle. With the wrong side facing, join new yarn at the opening.", stitches: front)
        b.work([seed], rows: rows - 1, stitches: front)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends and block flat. Worn with the opening at the front, the back falls from the shoulders and the fronts hang down each side.")

        let finishedWidth = Double(stitches) / g.spi
        let finishedLength = Double(rows) / rate
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: finishedWidth * finishedLength * 2, spi: g.spi, factor: 1.15),
            yarnNote: ", soft wool or a wool blend",
            tools: [longCircular(stitches, g, flat: true), "Waste yarn", "Tapestry needle"],
            finished: "\(Sizing.inches(finishedWidth)) across the back and \(Sizing.inches(finishedLength)) from the shoulders to the hem, front and back",
            gauge: g
        )
        return Ruana(plan: plan, stitches: stitches, front: front, backRows: rows)
    }
}
