import Foundation

extension Engines {
    struct Tote: Equatable, Sendable {
        var plan: PatternPlan
        var base: Int
        var side: Int
        var around: Int
        var strap: Int
        var strapRows: Int
    }

    /// A solid tote knit from the bottom up: a garter base knit flat, stitches picked up around it with a
    /// marker at each corner, a stockinette body whose corner stitches are slipped every other round so the
    /// bag creases into a box, a garter band at the top and two garter straps sewn to the outside.
    static func tote(width: Double, height: Double, handle: Double, gauge g: Gauge) -> Tote {
        let base = Sizing.stitches(width, per: g.spi, minimum: 16)
        // A base about a third as deep as the bag is wide, in garter ridges, one picked-up stitch per ridge.
        let baseRows = Sizing.rows(width * 0.33, per: g.spi * 2, even: true, minimum: 8)
        let side = baseRows / 2
        let around = 2 * base + 2 * side
        let band = Sizing.rows(1, per: g.spi * 2, even: true, minimum: 4)
        let body = Sizing.rows(height - Double(band) / (g.spi * 2), per: g.rpi, even: true, minimum: 12)
        let strap = max(4, Int((1.25 * g.spi).rounded()))
        // Each strap runs its handle length plus the two ends sewn over the band; garter stretches, so a tenth short.
        let overlap = 2.0
        let strapRows = Sizing.rows((handle + 2 * overlap) * 0.9, per: g.spi * 2, even: true, minimum: 12)

        var b = PlanBuilder()
        b.section = "Base"
        b.action("Cast on \(base) stitches.", stitches: base)
        b.work(["Knit"], rows: baseRows, stitches: base)
        b.section = "Body"
        b.action("Do not turn. Place a marker, pick up and knit \(side) stitches along the side of the base, one in each garter ridge, place a marker, pick up and knit \(base) along the cast-on edge, place a marker, pick up and knit \(side) along the other side, and place the marker in a different color for the start of the round. Join in the round. A marker now sits at each corner.", stitches: around)
        b.work(["*Slip 1 purlwise with the yarn in back, knit to the next marker; repeat from * around. The slipped stitches crease the corners", "Knit"], rows: 2, stitches: around)
        b.work(["*Slip 1 purlwise with the yarn in back, knit to the next marker; repeat from * around", "Knit"], rows: body - 2, stitches: around)
        b.section = "Band"
        b.work(["Purl", "Knit"], rows: band, stitches: around)
        b.action("Bind off loosely purlwise.")
        for name in ["First Handle", "Second Handle"] {
            b.section = name
            b.action("Cast on \(strap) stitches.", stitches: strap)
            b.work(["Knit"], rows: strapRows, stitches: strap)
            b.action("Bind off, leaving a long tail to sew with.")
        }
        b.section = "Finishing"
        b.action("Flatten the bag so the creases sit at its sides. Lay the last \(Sizing.inches(overlap)) of each end of one handle flat on the outside of the front, from the top edge down over the band, each end \(Sizing.inches(width * 0.22)) from a side. Sew around the edges of each end, through both layers. Sew the other handle to the back the same way. Weave in the ends.")

        let baseWidth = Double(base) / g.spi
        let baseDepth = Double(baseRows) / (g.spi * 2)
        let tall = Double(body) / g.rpi + Double(band) / (g.spi * 2)
        let handleLength = Double(strapRows) / (g.spi * 2) - 2 * overlap
        let area = 2 * (baseWidth + baseDepth) * tall + baseWidth * baseDepth + 2 * Double(strapRows) / (g.spi * 2) * Double(strap) / g.spi
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi, factor: 1.1),
            yarnNote: ", cotton or linen so the bag holds its shape",
            tools: ["\(g.needle.label) \(Sizing.cable(Double(around) / g.spi < 22 ? 16 : 24)) circular needle", "4 stitch markers, one in a different color", "Tapestry needle"],
            finished: "A base \(Sizing.inches(baseWidth)) wide and \(Sizing.inches(baseDepth)) deep, \(Sizing.inches(tall)) tall, with handles \(Sizing.inches(handleLength)) long between the ends sewn on, stretching to about \(Sizing.inches(handle))",
            gauge: g
        )
        return Tote(plan: plan, base: base, side: side, around: around, strap: strap, strapRows: strapRows)
    }
}
