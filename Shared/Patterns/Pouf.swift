import Foundation

extension Engines {
    struct Pouf: Equatable, Sendable {
        var plan: PatternPlan
        var around: Int
        var sideRounds: Int
        var bottom: [(text: String, stitches: Int)]

        static func == (a: Pouf, b: Pouf) -> Bool {
            a.plan == b.plan && a.around == b.around && a.sideRounds == b.sideRounds
                && a.bottom.map(\.text) == b.bottom.map(\.text) && a.bottom.map(\.stitches) == b.bottom.map(\.stitches)
        }
    }

    /// A round floor pouf knit in one piece: a flat circle for the top, a purl ridge that turns it down into
    /// ribbed sides, a second ridge, and a circle for the bottom that narrows back to 8 stitches over the
    /// insert. `diameter` is across the top; `height` is the side from ridge to ridge.
    static func pouf(diameter: Double, height: Double, gauge g: Gauge) -> Pouf {
        let around = max(48, Int((diameter * Double.pi * g.spi / 8).rounded()) * 8)
        let top = disc(to: around, gauge: g)
        let sides = max(6, Sizing.rows(height, per: g.rpi) - 2)

        // The bottom loses 8 stitches every other round. The stuffing goes in at about half, while the opening is
        // still wide enough for a hand.
        var bottom: [(text: String, stitches: Int)] = []
        var count = around
        var stuffed = false
        while count > 8 {
            let wedge = count / 8
            var text = wedge > 2 ? "*K\(wedge - 2), k2tog; repeat from * around" : "K2tog around"
            count -= 8
            if !stuffed, count <= around / 2 {
                text += ". Stuff the pouf firmly through the opening now, and keep adding stuffing as it closes"
                stuffed = true
            }
            bottom.append((text, count))
            if count > 8 { bottom.append(("Knit", count)) }
        }

        var b = PlanBuilder()
        b.section = "Top"
        b.action("Leaving a \(Sizing.inches(6)) tail, cast on 8 stitches and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 8)
        b.work(["Knit"], rows: 1, stitches: 8)
        runs(&b, top, from: 8)
        b.section = "Sides"
        b.row("Purl. The ridge turns the top down into the sides", stitches: around)
        b.work(["*K3, p1; repeat from * around"], rows: sides, stitches: around)
        b.row("Purl. The ridge turns the sides under into the bottom", stitches: around)
        b.section = "Bottom"
        b.action("The bottom narrows as you go: move the stitches to shorter circular needles, then to double-pointed needles, as they stop reaching around.")
        runs(&b, bottom, from: around)
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 8 stitches, push in a last handful of stuffing, pull it snug and fasten off. Close the center of the top with the cast-on tail the same way, and weave in the ends.")

        let wide = Double(around) / g.spi
        let radius = wide / (2 * Double.pi)
        let tall = Double(sides + 2) / g.rpi
        let area = 2 * Double.pi * radius * radius + wide * tall * 1.15
        let needles = discNeedles(around, g)
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            yarnNote: ", a hard-wearing wool or cotton blend",
            tools: [
                "\(g.needle.label) double-pointed needles, or a long circular for magic loop" + (needles.isEmpty ? "" : ", and \(needles)"),
                "Stitch marker", "Tapestry needle",
                "Polyester fiberfill or soft fabric scraps, enough to fill \(Sizing.inches(wide / Double.pi)) across and \(Sizing.inches(tall)) tall firmly",
            ],
            finished: "\(Sizing.inches(wide / Double.pi)) across and \(Sizing.inches(tall)) tall, filled",
            gauge: g, round: true
        )
        return Pouf(plan: plan, around: around, sideRounds: sides, bottom: bottom)
    }
}
