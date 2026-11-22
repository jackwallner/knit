import Foundation

extension Engines {
    /// The rounds of a flat circle knit from 8 stitches at the center out to `around`: 8 stitches gained on
    /// every other round, with a note to move to the 16 in needle once the stitches reach 17 in, and to the
    /// 24 in needle at 30 in.
    static func disc(to around: Int, gauge g: Gauge) -> [(text: String, stitches: Int)] {
        var rounds: [(text: String, stitches: Int)] = []
        var count = 8
        var moved = false, longer = false
        while count < around {
            count += 8
            var text = "*K\(count / 8 - 1), M1L; repeat from * around"
            if !moved, Double(count) / g.spi >= 17 {
                text += ". Move the stitches to the \(Sizing.cable(16)) needle"
                moved = true
            } else if !longer, Double(count) / g.spi >= 30 {
                text += ". Move the stitches to the \(Sizing.cable(24)) needle"
                longer = true
            }
            rounds.append((text, count))
            rounds.append(("Knit", count))
        }
        return rounds
    }

    /// A newborn cocoon knit from the bottom up: a flat circle closes the foot end, the body is knit straight
    /// in the round, and a deep k2, p2 rib at the top folds down over the shoulders.
    static func cocoon(around wanted: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let around = max(48, Int((wanted * g.spi / 8).rounded()) * 8)
        let bottom = disc(to: around, gauge: g)
        let radius = Double(around) / g.spi / (2 * Double.pi)
        let rib = Sizing.rows(min(4, length * 0.2), per: g.rpi, minimum: 6)
        // The circle at the bottom is about as deep as its radius once it is worn.
        let body = Sizing.rows(length - radius - Double(rib) / g.rpi, per: g.rpi, minimum: 8)

        var b = PlanBuilder()
        b.section = "Base"
        b.action("Leaving a \(Sizing.inches(6)) tail, cast on 8 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 8)
        b.work(["Knit"], rows: 1, stitches: 8)
        runs(&b, bottom, from: 8)
        b.section = "Body"
        b.work(["Knit"], rows: body, stitches: around)
        b.section = "Top"
        b.work(["*K2, p2; repeat from * around"], rows: rib, stitches: around)
        b.action("Bind off loosely in pattern, so the top stretches over the shoulders.")
        b.section = "Finishing"
        b.action("Thread the cast-on tail through the first 8 stitches, pull it snug to close the bottom and weave in the ends. Fold the rib down to the outside.")

        let area = Double.pi * radius * radius + Double(around) / g.spi * (length - radius)
        return pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            yarnNote: ", soft and machine washable",
            tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop" + (Double(around) / g.spi >= 17 ? ", and a \(Sizing.cable(16)) circular needle" : ""), "Stitch marker", "Tapestry needle"],
            finished: "\(Sizing.inches(Double(around) / g.spi)) around and \(Sizing.inches(length)) long with the rib unfolded",
            gauge: g, round: true
        )
    }
}
