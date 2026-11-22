import Foundation

extension Engines {
    struct CowlHood: Equatable, Sendable {
        var plan: PatternPlan
        var around: Int
        var front: Int
        var hood: Int
        var hoodRows: Int
    }

    /// A hood joined to a ribbed cowl: the cowl knit in the round from the bottom, a few stitches bound off
    /// at the center front, then the hood worked flat with garter edges framing the face, folded and joined
    /// across the top. `head` is around the head; `height` is the hood from the top of the cowl to the crown.
    static func cowlHood(head: Double, height: Double, gauge g: Gauge) -> CowlHood {
        // The cowl goes on over the head, so it is a little bigger than the head. A multiple of 4 for the rib.
        let around = max(48, Int(((head + 2) * g.spi / 4).rounded()) * 4)
        var front = max(4, Int((2.5 * g.spi).rounded()))
        if front % 2 == 1 { front += 1 }
        let hood = around - front
        let edge = max(3, Int((0.6 * g.spi).rounded()))
        let cowl = Sizing.rows(min(5, head * 0.2), per: g.rpi, minimum: 8)
        let rows = max(8, Sizing.rows(height, per: g.rpi, even: true))

        var b = PlanBuilder()
        b.section = "Cowl"
        b.action("Cast on \(around) stitches loosely. Join in the round without twisting and place a marker. The marker is the center front.", stitches: around)
        b.work(["*K2, p2; repeat from * around"], rows: cowl - 1, stitches: around)
        b.row("Work in rib until \(front / 2) stitches remain in the round, bind off the next \(front) stitches for the front opening, removing the marker as you pass it, and knit to the gap. Turn", stitches: hood)
        b.section = "Hood"
        b.work(["K\(edge), purl to the last \(edge) stitches, k\(edge)", "Knit"], rows: rows, stitches: hood)
        b.action("Fold the hood in half with the right sides together, so the two face edges meet, \(hood / 2) stitches on each needle. Join the top with a three-needle bind off, starting at the face edge.")
        b.section = "Finishing"
        b.action("Turn the hood right side out and weave in the ends.")

        let wide = Double(around) / g.spi
        let tall = Double(rows) / g.rpi + Double(cowl) / g.rpi
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: wide * tall, spi: g.spi, factor: 1.15),
            yarnNote: ", soft wool or a wool blend",
            tools: ["\(g.needle.label) \(Sizing.cable(16)) circular needle, and a spare needle in the same size for the bind off", "Stitch marker", "Tapestry needle"],
            finished: "A cowl \(Sizing.inches(wide)) around, and a hood \(Sizing.inches(Double(rows) / g.rpi)) from the cowl to the crown, to fit a \(Sizing.inches(head)) head",
            gauge: g, round: true
        )
        return CowlHood(plan: plan, around: around, front: front, hood: hood, hoodRows: rows)
    }
}
