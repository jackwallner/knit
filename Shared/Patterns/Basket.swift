import Foundation

extension Engines {
    struct Basket: Equatable, Sendable {
        var plan: PatternPlan
        var around: Int
        var handle: Int
        var sideRounds: Int
    }

    /// A round basket knit from the center of the base out: a flat stockinette circle, a purl ridge that turns
    /// it up into garter sides, which stand firmer than stockinette, and two handle slots bound off and cast
    /// on again below the rim.
    static func basket(diameter: Double, height: Double, gauge g: Gauge) -> Basket {
        let around = max(48, Int((diameter * Double.pi * g.spi / 8).rounded()) * 8)
        let half = around / 2
        let base = disc(to: around, gauge: g)
        // Garter in the round takes about two rounds for every stitch's width.
        let garter = g.spi * 2
        let handle = max(3, min(half / 3, Int((2.5 * g.spi).rounded())))
        let before = (half - handle) / 2
        // The slots sit about an inch below the rim; the rounds above them end on a knit round.
        var rest = Sizing.rows(1, per: garter, minimum: 3)
        if rest % 2 == 0 { rest += 1 }
        var below = max(4, Sizing.rows(height, per: garter) - 1 - 2 - rest)
        if below % 2 == 1 { below += 1 }

        var b = PlanBuilder()
        b.section = "Base"
        b.action("Leaving a \(Sizing.inches(6)) tail, cast on 8 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 8)
        b.work(["Knit"], rows: 1, stitches: 8)
        runs(&b, base, from: 8)
        b.section = "Sides"
        b.row("Purl. The ridge turns the base up into the sides", stitches: around)
        b.work(["Knit", "Purl"], rows: below, stitches: around)
        b.row("K\(before), bind off the next \(handle) stitches, knit until there are \(half - handle) stitches after the gap, bind off the next \(handle) stitches and knit to the end", stitches: around - 2 * handle)
        b.row("Purl to the first gap, cast on \(handle) stitches over it with the backward loop method, purl to the next gap, cast on \(handle) stitches over it and purl to the end", stitches: around)
        b.work(["Knit", "Purl"], rows: rest, stitches: around)
        b.action("Bind off loosely purlwise.")
        b.section = "Finishing"
        b.action("Thread the cast-on tail through the first 8 stitches, pull it snug to close the center of the base and weave in the ends. Wet the basket, stand it over a can or box about \(Sizing.inches(diameter)) across, and let it dry in shape.")

        let wide = Double(around) / g.spi
        let radius = wide / (2 * Double.pi)
        let tall = Double(1 + below + 2 + rest) / garter
        let area = Double.pi * radius * radius + wide * tall * 1.25
        let needles = discNeedles(around, g)
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            yarnNote: ", cotton or a firm wool, knit tightly so the sides stand",
            tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop" + (needles.isEmpty ? "" : ", and \(needles)"), "Stitch marker", "Tapestry needle"],
            finished: "\(Sizing.inches(wide / Double.pi)) across the base and \(Sizing.inches(tall)) tall, with two handle slots \(Sizing.inches(Double(handle) / g.spi)) wide",
            gauge: g, round: true
        )
        return Basket(plan: plan, around: around, handle: handle, sideRounds: 1 + below + 2 + rest)
    }
}
