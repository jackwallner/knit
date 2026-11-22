import Foundation

extension Engines {
    struct BathMat: Equatable, Sendable {
        var plan: PatternPlan
        var middle: Int
        var increaseRounds: Int
        var finalStitches: Int
    }

    /// A garter bath mat knit in the round from a line at its middle out to its edges: a ring cast on in four
    /// sections, two long and two short, each gaining a stitch at both ends every other round, so the mat grows
    /// as a rectangle with mitered corners. The cast-on ring is sewn flat at the end. `width` and `length` are
    /// the finished mat's.
    static func bathMat(width: Double, length: Double, gauge g: Gauge) -> BathMat {
        // Garter: about two rounds for every stitch's width, so the corners grow 8 stitches every other round.
        let increases = max(3, Int((width * g.spi / 2).rounded()) - 1)
        let middle = max(4, Sizing.stitches(length, per: g.spi) - 2 - 2 * increases)
        let start = 2 * middle + 4
        let final = start + 8 * increases
        // Circular needles the round moves onto as it grows, each once the stitches reach the inches given.
        let cables: [(inches: Double, cable: Int)] = [(17, 16), (30, 24), (45, 32), (65, 40), (95, 60)]
        let moves = cables.filter { Double(start) / g.spi < $0.inches }

        var rounds: [(text: String, stitches: Int)] = []
        var count = start
        var next = 0
        for _ in 0..<increases {
            count += 8
            var text = "*M1L, knit to the next marker, M1R, slip the marker; repeat from * around"
            if next < moves.count, Double(count) / g.spi >= moves[next].inches {
                text += ". Move the stitches to the \(Sizing.cable(moves[next].cable)) needle"
                next += 1
            }
            rounds.append((text, count))
            rounds.append(("Purl", count))
        }

        var b = PlanBuilder()
        b.section = "Middle"
        b.action("Leaving a \(Sizing.inches(length * 0.6)) tail, cast on \(start) stitches. Join in the round without twisting and place markers to divide the round into 4 sections of \(middle), 2, \(middle) and 2 stitches, a different color marker at the start of the round.", stitches: start)
        b.section = "Body"
        runs(&b, rounds, from: start)
        b.row("Knit", stitches: final)
        b.action("Bind off loosely purlwise.")
        b.section = "Finishing"
        b.action("Flatten the cast-on ring into a straight line down the middle of the mat, with the two short sections at its ends, and sew its two halves together with the cast-on tail. Weave in the ends and block the mat flat.")

        let finishedWidth = Double(2 + 2 * increases) / g.spi
        let finishedLength = Double(middle + 2 + 2 * increases) / g.spi
        let first = cables.last { Double(start) / g.spi >= $0.inches }.map { "\(g.needle.label) \(Sizing.cable($0.cable)) circular needle" } ?? "\(g.needle.label) double-pointed needles, or a long circular for magic loop"
        let later = moves.filter { Double(final) / g.spi >= $0.inches }.map { Sizing.cable($0.cable) }
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: finishedWidth * finishedLength, spi: g.spi, factor: 1.25),
            yarnNote: ", cotton, which soaks up water and washes hot",
            tools: [first + (later.isEmpty ? "" : ", and \(later.count == 1 ? "a \(later[0]) circular needle" : later.dropLast().joined(separator: ", ") + " and \(later.last ?? "") circular needles") as the mat grows"), "4 stitch markers, one a different color", "Tapestry needle"],
            finished: "\(Sizing.inches(finishedWidth)) by \(Sizing.inches(finishedLength))",
            gauge: g, round: true
        )
        return BathMat(plan: plan, middle: middle, increaseRounds: increases, finalStitches: final)
    }
}
