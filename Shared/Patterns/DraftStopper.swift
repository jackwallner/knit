import Foundation

extension Engines {
    struct DraftStopper: Equatable, Sendable {
        var plan: PatternPlan
        var around: Int
        var bodyRounds: Int
        var endRounds: Int
    }

    /// A draft stopper to lie along the bottom of a door: a long tube knit in the round from one rounded end to
    /// the other, a purl ridge every inch or so, stuffed and weighted before the second end closes. `length` is
    /// tip to tip; `around` is around the tube.
    static func draftStopper(length: Double, around: Double, gauge g: Gauge) -> DraftStopper {
        let stitches = max(24, Int((around * g.spi / 6).rounded()) * 6)
        // The rounded ends: 6 stitches gained or lost every other round between 6 and the full count.
        let steps = stitches / 6 - 1
        let endRounds = 2 * steps
        let ridge = max(4, Int(g.rpi.rounded()))
        let cycle = Array(repeating: "Knit", count: ridge) + ["Purl"]
        let ends = 2 * Double(endRounds) / g.rpi
        let body = max(cycle.count, Int(((length - ends) * g.rpi / Double(cycle.count)).rounded()) * cycle.count)

        var first: [(text: String, stitches: Int)] = []
        var second: [(text: String, stitches: Int)] = []
        for step in 1...steps {
            first.append(("*K\(step), M1L; repeat from * around", 6 + 6 * step))
            first.append(("Knit", 6 + 6 * step))
            let left = stitches - 6 * step
            let wedge = left / 6 + 1
            var text = wedge > 2 ? "*K\(wedge - 2), k2tog; repeat from * around" : "K2tog around"
            if step == 1 { text += ". Stuff the tube firmly, with a bag of rice or dried beans in the middle to weigh it down, and keep adding stuffing as the end closes" }
            second.append((text, left))
            if left > 6 { second.append(("Knit", left)) }
        }

        var b = PlanBuilder()
        b.section = "First End"
        b.action("Leaving a \(Sizing.inches(10)) tail, cast on 6 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 6)
        runs(&b, first, from: 6)
        b.section = "Body"
        b.work(cycle, rows: body, stitches: stitches)
        b.section = "Second End"
        runs(&b, second, from: stitches)
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 6 stitches, pull it snug and fasten off. Thread the cast-on tail through the cast-on stitches and pull it snug to close the first end. Weave in the ends.")

        let wide = Double(stitches) / g.spi
        let long = Double(body) / g.rpi + ends
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: wide * long, spi: g.spi, factor: 1.15),
            yarnNote: ", a hard-wearing wool or acrylic",
            tools: [
                "\(g.needle.label) double-pointed needles, or a long circular for magic loop",
                "Stitch marker", "Polyester fiberfill, and a small bag of rice or dried beans for weight", "Tapestry needle",
            ],
            finished: "\(Sizing.inches(long)) long and \(Sizing.inches(wide)) around, stuffed",
            gauge: g, round: true
        )
        return DraftStopper(plan: plan, around: stitches, bodyRounds: body, endRounds: endRounds)
    }
}
