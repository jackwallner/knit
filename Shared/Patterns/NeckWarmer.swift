import Foundation

extension Engines {
    struct NeckWarmer: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var rows: Int
        var holes: Int
        var hole: Int
        var gap: Int
        var edge: Int
    }

    /// A neck warmer knit sideways in seed stitch, which lies flat and looks the same on both sides: a band
    /// long enough to wrap the neck and overlap, with buttonholes across its last end. `neck` is around the
    /// neck; `height` is the band's height.
    static func buttonNeckWarmer(neck: Double, height: Double, gauge g: Gauge) -> NeckWarmer {
        // An odd count, so every seed row starts and ends with a knit stitch.
        let stitches = max(11, 2 * Int((height * g.spi / 2).rounded(.down)) + 1)
        let rate = g.rpi * 1.1
        // An inch of ease and two and a half inches of overlap for the buttons.
        let overlap = 2.5
        let rows = max(20, Sizing.rows(neck + 1 + overlap, per: rate, even: true))
        let tip = max(3, Sizing.rows(0.75, per: rate))
        let hole = max(2, Int((0.5 * g.spi).rounded()))
        let holes = height >= 5 ? 3 : 2
        // The buttonholes spread evenly, at least half an inch in from each side.
        let margin = max(2, Int((0.6 * g.spi).rounded()))
        let gap = max(2, (stitches - 2 * margin - holes * hole) / (holes - 1))
        let sides = stitches - holes * hole - (holes - 1) * gap
        let edge = sides / 2
        let last = sides - edge
        let seed = "K1, *p1, k1; repeat from * to the end"

        var buttonholes = "Work \(edge) stitches in pattern, bind off the next \(hole) stitches"
        for _ in 1..<holes { buttonholes += ", work until there are \(gap) stitches after the gap, bind off the next \(hole) stitches" }
        buttonholes += " and work the last \(last) stitches in pattern"

        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(stitches) stitches. This edge is the button end.", stitches: stitches)
        b.work([seed], rows: rows - tip - 2, stitches: stitches)
        b.section = "Buttonholes"
        b.row(buttonholes, stitches: stitches - holes * hole)
        b.row("Work in pattern, casting on \(hole) stitches over each gap with the backward loop method", stitches: stitches)
        b.work([seed], rows: tip, stitches: stitches)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends. Wrap the band around the neck with the buttonhole end on top, mark where each buttonhole falls on the cast-on end, and sew a button at each mark.")

        let wide = Double(stitches) / g.spi
        let long = Double(rows) / rate
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: wide * long, spi: g.spi, factor: 1.2),
            yarnNote: ", soft wool or a wool blend",
            tools: ["\(g.needle.label) needles", "\(holes) buttons, about \(Sizing.inches(Double(hole) / g.spi + 0.25)) across", "Tapestry needle"],
            finished: "\(Sizing.inches(wide)) tall and \(Sizing.inches(long)) long, buttoning into a ring \(Sizing.inches(long - overlap)) around",
            gauge: g
        )
        return NeckWarmer(plan: plan, stitches: stitches, rows: rows, holes: holes, hole: hole, gap: gap, edge: edge)
    }
}
