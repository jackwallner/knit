import Foundation

extension Engines {
    struct Runner: Equatable, Sendable {
        var plan: PatternPlan
        var width: Int
        var pointRows: Int
        var straightRows: Int
    }

    /// A garter table runner knit from point to point: it widens from 3 stitches to its full width, runs
    /// straight, then narrows back to a point. Garter lies flat on a table, and its two stitches gained every
    /// other row make each point a right angle. A tassel hangs from each point. `length` is tip to tip.
    static func runner(width: Double, length: Double, gauge g: Gauge) -> Runner {
        // An odd count, so the point grows from 3 stitches in steps of 2.
        let wide = max(15, 2 * Int((width * g.spi / 2).rounded()) + 1)
        let pointRows = wide - 3
        // Garter: about two rows for every stitch's width.
        let garter = g.spi * 2
        let point = Double(pointRows + 1) / garter
        let straight = max(4, Sizing.rows(length - 2 * point, per: garter, even: true))

        var b = PlanBuilder()
        b.section = "First Point"
        b.action("Cast on 3 stitches.", stitches: 3)
        b.row("Knit", stitches: 3)
        b.work(["K1, kfb, knit to the last 2 stitches, kfb, k1", "Knit"], rows: pointRows, stitches: 5, delta: 2)
        b.section = "Body"
        b.work(["Knit"], rows: straight, stitches: wide)
        b.section = "Second Point"
        b.work(["K1, k2tog, knit to the last 3 stitches, ssk, k1", "Knit"], rows: pointRows, stitches: wide - 2, delta: -2)
        b.row("Slip 1, k2tog, pass the slipped stitch over", stitches: 1)
        b.action("Cut the yarn and pull it through the last stitch.")
        b.section = "Finishing"
        b.action("Weave in the ends. Make two tassels about \(Sizing.inches(min(4, width * 0.3))) long and sew one to each point. Block flat, pinning the points.")

        let finishedWidth = Double(wide) / g.spi
        let finishedLength = Double(1 + 2 * pointRows + straight + 1) / garter
        let area = finishedWidth * (finishedLength - point)
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi, factor: 1.15),
            yarnNote: ", cotton or linen washes best",
            tools: [finishedWidth > 14 ? "\(g.needle.label) \(Sizing.cable(24)) circular needle, worked flat" : "\(g.needle.label) needles", "Tapestry needle", "A piece of card for the tassels"],
            finished: "\(Sizing.inches(finishedWidth)) wide and \(Sizing.inches(finishedLength)) from point to point, after blocking",
            gauge: g
        )
        return Runner(plan: plan, width: wide, pointRows: pointRows, straightRows: straight)
    }
}
