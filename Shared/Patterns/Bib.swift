import Foundation

extension Engines {
    struct Bib: Equatable, Sendable {
        var plan: PatternPlan
        var width: Int
        var strap: Int
        var strapRows: Int
        var neckDecreases: Int
    }

    /// A garter baby bib knit from the hem up: rounded bottom corners from increases at both edges, a straight
    /// body, then the middle bound off for the neck and each side worked on as a strap, narrowed at the neck
    /// and buttoned behind it. `width` is across the bib; `length` is from the hem to the front of the neck.
    static func babyBib(width: Double, length: Double, gauge g: Gauge) -> Bib {
        let garter = g.spi * 2
        let wide = max(14, Sizing.stitches(width, per: g.spi))
        // The corners round over about half an inch: a stitch gained at each edge every other row.
        let corner = max(2, Int((0.6 * g.spi).rounded()))
        // The neck takes about a third of the width; what is left either side is even.
        var center = max(4, Int((width * 0.35 * g.spi).rounded()))
        if (wide - center) % 2 == 1 { center += 1 }
        let side = (wide - center) / 2
        // Straps stay at least 4 stitches wide, room for the buttonhole.
        let decreases = max(0, min(Int((Double(side) * 0.25).rounded()), side - 4))
        let strap = side - decreases
        let body = max(2, Sizing.rows(length, per: garter, even: true) - 2 * corner)
        // The straps meet behind a neck about 4.5 in more than the bib's width, overlapping by an inch.
        let neck = width + 4.5
        let front = Double(center + 2 * decreases) / g.spi * 1.3
        let reach = max(2, (neck - front) / 2 + 1)
        let straight = max(4, Sizing.rows(reach, per: garter, even: true) - 2 * decreases - 4)
        let hole = (strap - 2) / 2

        var b = PlanBuilder()
        b.section = "Bottom"
        b.action("Cast on \(wide - 2 * corner) stitches.", stitches: wide - 2 * corner)
        b.work(["K1, kfb, knit to the last 2 stitches, kfb, k1", "Knit"], rows: 2 * corner, stitches: wide - 2 * corner + 2, delta: 2)
        b.section = "Body"
        b.work(["Knit"], rows: body, stitches: wide)
        b.row("With the right side facing, k\(side), bind off the next \(center) stitches for the neck, and knit to the end. Work the \(side) stitches after the gap first, leaving the others on the needle", stitches: side)
        b.section = "First Strap"
        b.work(["Knit", "K1, k2tog, knit to the end"], rows: 2 * decreases, stitches: side, delta: -1, offsets: [0, -1])
        b.work(["Knit"], rows: straight, stitches: strap)
        b.row(hole > 0 ? "K\(hole), yo, k2tog, knit to the end. This is the buttonhole" : "Yo, k2tog, knit to the end. This is the buttonhole", stitches: strap)
        b.work(["Knit"], rows: 3, stitches: strap)
        b.action("Bind off.")
        b.section = "Second Strap"
        b.action("With the wrong side facing, join the yarn at the neck edge of the other \(side) stitches.", stitches: side)
        b.work(["Knit", "Knit to the last 3 stitches, ssk, k1"], rows: 2 * decreases, stitches: side, delta: -1, offsets: [0, -1])
        b.work(["Knit"], rows: straight + 4, stitches: strap)
        b.action("Bind off.")
        b.section = "Finishing"
        b.action("Weave in the ends. Sew the button to the end of the second strap, so the straps overlap behind the neck and the button meets the buttonhole.")

        let finishedWidth = Double(wide) / g.spi
        let strapRows = 2 * decreases + straight + 4
        let area = finishedWidth * length + 2 * Double(side) / g.spi * Double(strapRows) / garter
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi, factor: 1.15),
            yarnNote: ", cotton, which soaks up spills and washes well",
            tools: ["\(g.needle.label) needles", "A button about \(Sizing.inches(0.5)) across", "Tapestry needle"],
            finished: "\(Sizing.inches(finishedWidth)) wide and \(Sizing.inches(length)) from the hem to the neck, with straps that button behind the neck",
            gauge: g
        )
        return Bib(plan: plan, width: wide, strap: strap, strapRows: strapRows, neckDecreases: decreases)
    }
}
