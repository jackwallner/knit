import Foundation

extension Engines {
    struct Bauble: Equatable, Sendable {
        var plan: PatternPlan
        var around: Int
        var rounds: [Int]

        static func == (a: Bauble, b: Bauble) -> Bool { a.plan == b.plan && a.around == b.around && a.rounds == b.rounds }
    }

    /// A round bauble for the tree knit in the round from top to bottom: six wedges that widen to the middle
    /// and narrow again along a sphere's curve, stuffed before it closes, with a loop to hang it by.
    static func bauble(diameter: Double, gauge g: Gauge) -> Bauble {
        let around = max(24, Int((diameter * Double.pi * g.spi / 6).rounded()) * 6)
        let total = max(10, Int((Double.pi * diameter / 2 * g.rpi).rounded()))
        // Each round's count follows the circle at that height on the sphere, 6 stitches at most at a time.
        var rounds: [(text: String, stitches: Int)] = []
        var count = 6
        var stuffed = false
        for k in 0..<total {
            let curve = sin(Double.pi * (Double(k) + 0.5) / Double(total))
            let target = max(6, min(around, Int((Double(around) * curve / 6).rounded()) * 6))
            let wedge = count / 6
            let rising = 2 * k < total
            // No plain rounds on 6 stitches at the top or bottom, so the ends stay round, not pointed.
            if rising, target > count || count == 6 {
                rounds.append(("*K\(wedge), M1L; repeat from * around", count + 6))
                count += 6
            } else if !rising, target < count {
                var text = wedge > 2 ? "*K\(wedge - 2), k2tog; repeat from * around" : "K2tog around"
                if !stuffed, count - 6 <= around / 2 {
                    text += ". Stuff the bauble firmly, and keep adding stuffing as it closes"
                    stuffed = true
                }
                rounds.append((text, count - 6))
                count -= 6
            } else if count > 6 {
                rounds.append(("Knit", count))
            }
        }
        while count > 6 {
            let wedge = count / 6
            rounds.append((wedge > 2 ? "*K\(wedge - 2), k2tog; repeat from * around" : "K2tog around", count - 6))
            count -= 6
        }

        var b = PlanBuilder()
        b.section = "Top"
        b.action("Leaving a \(Sizing.inches(10)) tail, cast on 6 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 6)
        let middle = (rounds.firstIndex { $0.stitches == around } ?? rounds.count / 2) + 1
        runs(&b, Array(rounds[..<middle]), from: 6)
        b.section = "Bottom"
        runs(&b, Array(rounds[middle...]), from: rounds[middle - 1].stitches)
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 6 stitches, pull it snug and fasten off. Thread the cast-on tail through the cast-on stitches and pull it snug to close the top, then bring it out at the top and tie it into a loop about \(Sizing.inches(2)) long to hang the bauble by. Weave in the other end.")

        let radius = diameter / 2
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: 4 * Double.pi * radius * radius, spi: g.spi, factor: 1.2),
            yarnNote: ", wool or a wool blend, in a bright color",
            tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "A handful of polyester fiberfill", "Tapestry needle"],
            finished: "About \(Sizing.inches(Double(around) / g.spi / Double.pi)) across, stuffed",
            gauge: g, round: true
        )
        return Bauble(plan: plan, around: around, rounds: rounds.map(\.stitches))
    }
}
