import Foundation

extension Engines {
    struct Bunting: Equatable, Sendable {
        var plan: PatternPlan
        var flags: Int
        var width: Int
        var decreases: Int
        var spacing: Int
    }

    /// Bunting: garter triangle flags, each knit from its top edge down to a point with a row of eyelets
    /// along the top, strung on a twisted cord. `width` is across one flag's top; `length` is the strung flags
    /// from end to end, before the ties.
    static func bunting(width: Double, length: Double, gauge g: Gauge) -> Bunting {
        let garter = g.spi * 2
        // An odd count: the eyelet row pairs off after a first knit stitch, and the point ends on 3.
        let wide = max(9, 2 * Int((width * g.spi / 2).rounded()) + 1)
        let top = 4
        let decreases = (wide - 3) / 2
        // The flag is about as tall as it is wide; decreases fall on right side rows, an even number apart.
        let shaping = max(2 * decreases, Sizing.rows(width * 1.1, per: garter) - top - 4)
        var spacing = max(2, shaping / decreases)
        if spacing % 2 == 1 { spacing -= 1 }
        let gap = 1.0
        let flags = max(3, Int((length + gap) / (Double(wide) / g.spi + gap)))
        let cord = length + 2 * 15

        var b = PlanBuilder()
        b.section = "Flag"
        b.action("Cast on \(wide) stitches.", stitches: wide)
        b.work(["Knit"], rows: 2, stitches: wide)
        b.row("K1, *yo, k2tog; repeat from * to the end. These eyelets carry the cord", stitches: wide)
        b.work(["Knit"], rows: top - 1, stitches: wide)
        b.work(["K1, ssk, knit to the last 3 stitches, k2tog, k1"] + Array(repeating: "Knit", count: spacing - 1), rows: decreases * spacing, stitches: wide - 2, delta: -2)
        b.row("Slip 1, k2tog, pass the slipped stitch over", stitches: 1)
        b.action("Cut the yarn and pull it through the last stitch. Weave in the ends.")
        b.action("Make \(flags - 1) more flags the same way, \(flags) in all.")
        b.section = "Cord"
        b.action("Cut two strands of yarn, each \(Sizing.inches(cord * 3)) long. Knot them together at both ends, anchor one end and twist the other until the strands kink back on themselves.")
        b.action("Fold the twisted strands in half and let them twist around each other into a cord about \(Sizing.inches(cord)) long. Knot the loose end.")
        b.section = "Finishing"
        b.action("Block the flags flat. Leaving \(Sizing.inches(15)) of cord free at each end for tying, weave the cord in and out through the eyelets of each flag in turn, about \(Sizing.inches(gap)) apart.")

        let flagWidth = Double(wide) / g.spi
        let flagHeight = Double(top + 3 + decreases * spacing + 1) / garter
        let flagArea = flagWidth * Double(top + 3) / garter + flagWidth * (flagHeight - Double(top + 3) / garter) / 2
        // Every flag, plus the six cord lengths the twisted cord takes.
        let raw = Sizing.yards(squareInches: flagArea * Double(flags), spi: g.spi, factor: 1.25) + Int((6 * cord / 36).rounded(.up))
        let yards = Int((Double(raw) / 10).rounded(.up)) * 10
        let plan = pattern(
            b, estimate: yards,
            yarnNote: ", cotton or wool, in one color or several",
            tools: ["\(g.needle.label) needles", "Tapestry needle"],
            finished: "\(flags) flags, each \(Sizing.inches(flagWidth)) wide and \(Sizing.inches(flagHeight)) long, on a cord with ties at both ends",
            gauge: g
        )
        return Bunting(plan: plan, flags: flags, width: wide, decreases: decreases, spacing: spacing)
    }
}
