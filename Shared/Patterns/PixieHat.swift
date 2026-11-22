import Foundation

extension Engines {
    struct PixieHat: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var decreases: Int
        var spacing: Int
    }

    /// A pixie hat knit in the round from a ribbed brim: straight to the tops of the ears, then narrowed
    /// slowly in four lines to a long point with a tassel. `head` is around the head.
    static func pixieHat(head: Double, gauge g: Gauge) -> PixieHat {
        let stitches = hatCount(head: head, share: 0.9, spi: g.spi, multiple: 4) ?? Sizing.stitches(head * 0.9, per: g.spi, multiple: 4, minimum: 24)
        let quarter = stitches / 4
        let brim = Sizing.rows(head * 0.07, per: g.rpi, minimum: 4)
        let body = Sizing.rows(head * 0.22, per: g.rpi, minimum: 6)
        // The point is about half the head long: 4 stitches lost on each shaping round, evenly spaced.
        let decreases = quarter - 1
        let spacing = max(2, Sizing.rows(head * 0.5, per: g.rpi) / decreases)
        let small = Double(stitches) / g.spi < 16

        var b = PlanBuilder()
        b.section = "Brim"
        b.action("Cast on \(stitches) stitches\(small ? " and divide them over double-pointed needles, or use a long circular for magic loop" : " on the circular needle"). Join in the round without twisting and place a marker.", stitches: stitches)
        b.work(["*K2, p2; repeat from * around"], rows: brim, stitches: stitches)
        b.section = "Body"
        b.work(["Knit"], rows: body - 1, stitches: stitches)
        b.row("*K\(quarter), place a marker; repeat from * 2 more times, and knit to the end. The start of the round marker is the fourth", stitches: stitches)
        b.section = "Point"
        b.work(["*Knit to 2 stitches before the next marker, k2tog; repeat from * around"] + Array(repeating: "Knit", count: spacing - 1), rows: decreases * spacing, stitches: stitches - 4, delta: -4)
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 4 stitches, pull it snug and fasten off. Make a tassel about \(Sizing.inches(head < 17 ? 2 : 3)) long and sew it to the tip. Weave in the ends.")

        let wide = Double(stitches) / g.spi
        let tall = Double(brim + body + decreases * spacing) / g.rpi
        let point = Double(decreases * spacing) / g.rpi
        let area = wide * (Double(brim + body) / g.rpi) + wide * point / 2
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi, factor: 1.15),
            yarnNote: ", soft and machine washable",
            tools: [small ? "\(g.needle.label) double-pointed needles, or a long circular for magic loop" : "\(g.needle.label) \(Sizing.cable(16)) circular needle, and double-pointed needles for the point", "4 stitch markers, one a different color", "A piece of card for the tassel", "Tapestry needle"],
            finished: "\(Sizing.inches(wide)) around and \(Sizing.inches(tall)) from the brim to the tip, to fit a \(Sizing.inches(head)) head",
            gauge: g, round: true
        )
        return PixieHat(plan: plan, stitches: stitches, decreases: decreases, spacing: spacing)
    }
}
