import Foundation

/// Shawls and wraps added after the first release.
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
