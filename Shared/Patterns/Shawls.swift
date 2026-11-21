import Foundation

/// Shawls, wraps and cowls added after the first release.
extension Engines {
    /// A long, shallow triangle in garter, begun at one corner. Only one edge grows, a stitch every sixth row,
    /// so the shawl ends three times as long as it is deep: it wraps around the neck and the ends hang free.
    static func asymmetricShawl(wingspan: Double, gauge g: Gauge) -> PatternPlan {
        // The long edge and the bound-off end are 3 to 1: the wingspan is the slope, the square root of 10 times the depth.
        let depth = wingspan / 10.0.squareRoot()
        let increases = max(8, Int((depth * g.spi).rounded()) - 3)
        let last = 3 + increases
        // Plain rows after the last increase bring the straight edge to its full length, three times the depth.
        let extra = max(0, Sizing.rows(depth * 3, per: g.spi * 2, even: true) - increases * 6)
        let length = Double(increases * 6 + extra) / (g.spi * 2)
        var b = PlanBuilder()
        b.section = "Shawl"
        b.action("Cast on 3 stitches.", stitches: 3)
        b.work(["K1, kfb, knit to the end"] + Array(repeating: "Knit", count: 5), rows: increases * 6, stitches: 4, delta: 1)
        b.work(["Knit"], rows: extra, stitches: last)
        b.section = "Finishing"
        b.action("Bind off all \(last) stitches loosely. Weave in the ends and block the shawl flat.")
        let yards = Sizing.yards(squareInches: length * depth / 2, spi: g.spi, factor: 1.25)
        let needle = Double(last) / g.spi > 24 ? "\(g.needle.label) \(Sizing.cable(32)) circular needle, worked flat" : "\(g.needle.label) \(Sizing.cable(24)) circular needle, worked flat"
        return pattern(b, estimate: yards, tools: [needle, "Tapestry needle"], finished: "\(Sizing.inches(length)) along the straight edge, \(Sizing.inches(Double(last) / g.spi)) deep at the end", gauge: g)
    }
}

extension Engines {
    struct Bandana: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var front: Int
    }

    /// A cowl with a bandana's point at the front: a triangle grown flat from its tip, two stitches every
    /// right-side row, then joined into a ribbed tube that pulls over the head.
    static func bandanaCowl(around: Double, height: Double, gauge g: Gauge) -> Bandana {
        let stitches = Sizing.stitches(around, per: g.spi, multiple: 4, minimum: 40)
        // The point spans a little under half the round; 5 plus pairs keeps it odd, with a k2 edge each side.
        let front = max(13, (stitches * 9 / 20 - 5) / 2 * 2 + 5)
        let back = stitches - front
        let pairs = (front - 5) / 2
        let rib = Sizing.rows(height, per: g.rpi, minimum: 8)
        var b = PlanBuilder()
        b.section = "Point"
        b.action("Cast on 5 stitches.", stitches: 5)
        b.work(["K2, M1L, knit to the last 2 stitches, M1R, k2", "K2, purl to the last 2 stitches, k2"], rows: pairs * 2, stitches: 7, delta: 2)
        b.section = "Neck"
        b.action("With the right side facing, knit across the \(front) stitches. Cast on \(back) stitches with the cable cast-on, then join in the round without twisting and place a marker.", stitches: stitches)
        b.work(["*K2, p2; repeat from * around"], rows: rib, stitches: stitches)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends, closing the corners where the point meets the neck. Wear it with the point at the front.")
        let deep = Double(pairs * 2) / g.rpi
        let yards = Sizing.yards(squareInches: around * height * 1.15 + Double(front) / g.spi * deep / 2, spi: g.spi, factor: 1.05)
        let cable = Double(stitches) / g.spi < 24 ? 16 : 24
        let plan = pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(cable)) circular needle", "Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(Double(stitches) / g.spi)) around, \(Sizing.inches(Double(rib) / g.rpi)) tall, with a point \(Sizing.inches(deep)) deep", gauge: g)
        return Bandana(plan: plan, stitches: stitches, front: front)
    }
}
