import Foundation

// Home pieces added after the first release.
extension Engines {
    /// A round coaster worked in the round from the center out, eight increases every other round so it
    /// lies flat, finished with a garter edge. Written for one; the materials cover a set of four.
    static func coaster(diameter: Double, gauge g: Gauge) -> PatternPlan {
        let target = max(24, Int((Double.pi * diameter * g.spi / 8).rounded()) * 8)
        var center: [(text: String, stitches: Int)] = []
        var count = 8
        while count < target - 8 {
            count += 8
            center.append(("*K\(count / 8 - 1), M1L; repeat from * around", count))
            center.append(("Knit", count))
        }
        var b = PlanBuilder()
        b.section = "Center"
        b.action("Leaving a \(Sizing.inches(6)) tail, cast on 8 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 8)
        b.work(["Knit"], rows: 1, stitches: 8)
        runs(&b, center, from: 8)
        b.section = "Edge"
        b.work(["Purl"], rows: 1, stitches: target - 8)
        runs(&b, [("*K\(target / 8 - 1), M1L; repeat from * around", target)], from: target - 8)
        b.work(["Purl"], rows: 1, stitches: target)
        b.action("Bind off loosely knitwise.")
        b.section = "Finishing"
        b.action("Thread the cast-on tail through the first 8 stitches, pull it snug to close the center and weave in the ends. Block the coaster flat. Make three more the same way for a set of four.")
        let across = Double(target) / (Double.pi * g.spi)
        let one = Sizing.yards(squareInches: Double.pi * across * across / 4, spi: g.spi, factor: 1.2)
        return pattern(b, estimate: one * 4, yarnNote: ", enough for four. Cotton stands up to a hot mug", tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(across)) across", gauge: g, round: true)
    }
}
