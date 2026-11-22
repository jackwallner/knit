import Foundation

extension Engines {
    /// A bucket hat knit from the top down: a flat crown circle from the center out, a purl ridge that folds
    /// it into the sides, straight sides, a second ridge, then a brim that widens by half in three increase
    /// rounds and ends in a garter edge so it does not roll.
    static func bucketHat(head: Double, gauge g: Gauge) -> PatternPlan {
        // A bucket hat sits on the head without stretching: its band is the head around.
        let around = max(48, Int((head * g.spi / 8).rounded()) * 8)
        let crown = disc(to: around, gauge: g)

        var b = PlanBuilder()
        b.section = "Crown"
        b.action("Leaving a \(Sizing.inches(6)) tail, cast on 8 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 8)
        b.work(["Knit"], rows: 1, stitches: 8)
        runs(&b, crown, from: 8)
        b.row("Purl. The ridge turns the crown down into the sides", stitches: around)

        let side = head * 0.15 + 0.25
        b.section = "Sides"
        b.work(["Knit"], rows: Sizing.rows(side, per: g.rpi, minimum: 6), stitches: around)
        b.row("Purl. The ridge turns the sides out into the brim", stitches: around)

        // The brim widens by half, in three rounds spread through it, so it flares without rippling.
        let brim = min(2.5, head * 0.11)
        let rounds = Sizing.rows(brim, per: g.rpi, minimum: 7)
        let steps = [around + even(Double(around) / 6), around + even(Double(around) / 3), around + even(Double(around) / 2)]
        let at = [0, rounds / 3, 2 * rounds / 3]
        b.section = "Brim"
        var stitches = around, done = 0, longer = false
        for (round, target) in zip(at, steps) {
            if round > done { b.work(["Knit"], rows: round - done, stitches: stitches) }
            var text = adjusting(stitches, to: target)
            if !longer, Double(target) / g.spi > 30 {
                text += ". Move the stitches to the \(Sizing.cable(24)) needle"
                longer = true
            }
            b.row(text, stitches: target)
            stitches = target
            done = round + 1
        }
        b.work(["Knit"], rows: max(1, rounds - done), stitches: stitches)
        b.section = "Edge"
        b.work(["Purl", "Knit"], rows: 3, stitches: stitches)
        b.action("Bind off loosely purlwise.")
        b.section = "Finishing"
        b.action("Thread the cast-on tail through the first 8 stitches, pull it snug to close the center of the crown and weave in the ends. Steam the brim flat.")

        let radius = Double(around) / g.spi / (2 * Double.pi)
        let outer = Double(stitches) / g.spi / (2 * Double.pi)
        let area = Double.pi * radius * radius + Double(around) / g.spi * side + Double.pi * (outer * outer - radius * radius) * 1.1
        let needles = Double(stitches) / g.spi > 30 ? "\(Sizing.cable(16)) and \(Sizing.cable(24)) circular needles" : "a \(Sizing.cable(16)) circular needle"
        return pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop, and \(needles)", "Stitch marker", "Tapestry needle"],
            finished: "\(Sizing.inches(Double(around) / g.spi)) around the band, to fit a \(Sizing.inches(head)) head, with a \(Sizing.inches(brim)) brim",
            gauge: g, round: true
        )
    }
}
