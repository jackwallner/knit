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

    /// A tea cozy: two sides worked flat from the bottom, so the gaps between them clear the spout and the
    /// handle, then joined in the round above them and closed in a crown of 8 wedges over the lid.
    static func teaCozy(around: Double, height: Double, gauge g: Gauge) -> PatternPlan {
        // A little smaller than the pot, so it hugs; halves of a multiple of 4 keep the rib whole.
        let stitches = Sizing.stitches(around * 0.95, per: g.spi, multiple: 8, minimum: 40)
        let half = stitches / 2
        let rib = "*K2, p2; repeat from * to the end"
        let band = Sizing.rows(0.75, per: g.rpi, even: true, minimum: 4)
        let sides = Sizing.rows(height * 0.65, per: g.rpi, even: true, minimum: band + 4)
        let crown = crownRounds(wedge: stitches / 8)
        let top = max(2, Sizing.rows(height + 0.5, per: g.rpi) - sides - crown.count)
        var b = PlanBuilder()
        for (index, name) in ["First Side", "Second Side"].enumerated() {
            b.section = name
            b.action("Cast on \(half) stitches.", stitches: half)
            b.work([rib], rows: band, stitches: half)
            b.work(["Knit", "Purl"], rows: sides - band, stitches: half)
            b.action(index == 0 ? "Cut the yarn and leave the stitches on the needle." : "Leave the stitches on the needle and keep the yarn attached.")
        }
        b.section = "Top"
        b.row("Knit across the second side, then across the first side. Join in the round and place a marker", stitches: stitches)
        b.work(["Knit"], rows: top - 1, stitches: stitches)
        b.section = "Crown"
        var rounds = crown
        // The first round too small for a 16 in circular says to change.
        if Double(stitches) / g.spi >= 16, let short = rounds.firstIndex(where: { Double($0.stitches) / g.spi < 16 }) {
            rounds[short].text += ". Change to double-pointed needles"
        }
        runs(&b, rounds, from: stitches)
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 8 stitches and pull tight. Weave in the ends. The gap at one side is for the spout, the other for the handle.")
        let tall = Double(sides + top + crown.count) / g.rpi
        let yards = Sizing.yards(squareInches: around * tall, spi: g.spi, factor: 1.15)
        let needles = Double(stitches) / g.spi < 16
            ? ["\(g.needle.label) double-pointed needles, or a long circular for magic loop"]
            : ["\(g.needle.label) \(Sizing.cable(16)) circular needle", "\(g.needle.label) double-pointed needles, or a long circular for magic loop, for the crown"]
        return pattern(b, estimate: yards, tools: needles + ["Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(Double(stitches) / g.spi)) around, to fit a \(Sizing.inches(around)) teapot, \(Sizing.inches(tall)) tall", gauge: g)
    }

    /// A seed stitch band that wraps a mug: worked flat across its height, with a buttonhole at each corner
    /// of the end, so it buttons over the other end with the handle between the two buttons.
    static func mugCozy(around: Double, height: Double, gauge g: Gauge) -> PatternPlan {
        let stitches = Sizing.stitches(height, per: g.spi, multiple: 2, extra: 1, minimum: 11)
        let seed = "*K1, p1; repeat from * to the last stitch, k1"
        let rate = g.rpi * 1.1
        // Around the mug, and the ends overlap by the buttons' width.
        let rows = Sizing.rows(around + 0.75, per: rate, even: true, minimum: 12)
        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(stitches) stitches.", stitches: stitches)
        b.work([seed], rows: rows - 3, stitches: stitches)
        b.row("K1, p1, yo, k2tog, work in seed stitch to the last 4 stitches, yo, k2tog, p1, k1", stitches: stitches)
        b.work([seed], rows: 2, stitches: stitches)
        b.action("Bind off in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends. Wrap the band around the mug with the handle between the two buttonholes, the buttonhole end over the cast-on end, and sew a button to the cast-on end under each buttonhole.")
        let long = Double(rows) / rate
        let yards = Sizing.yards(squareInches: height * long, spi: g.spi, factor: 1.3)
        return pattern(b, estimate: yards, yarnNote: ", cotton or wool", tools: ["\(g.needle.label) needles", "2 buttons, about \(Sizing.inches(0.5)) across", "Tapestry needle"], finished: "\(Sizing.inches(Double(stitches) / g.spi)) tall, \(Sizing.inches(long)) long, to wrap a \(Sizing.inches(around)) mug", gauge: g)
    }

    /// A placemat in seed stitch, which lies flat and stands up to washing, inside a garter border.
    /// Worked flat from one short edge to the other.
    static func placemat(width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let border = max(3, Int((0.6 * g.spi).rounded()))
        // An odd count inside the border, so every seed stitch row starts and ends with a knit.
        let inside = Sizing.stitches(width - 2 * Double(border) / g.spi, per: g.spi, multiple: 2, extra: 1, minimum: 11)
        let caston = inside + 2 * border
        let rate = g.rpi * 1.1
        let body = Sizing.rows(length - 4 * Double(border) / (g.spi * 2), per: rate, even: true, minimum: 4)
        var b = PlanBuilder()
        b.section = "Bottom Border"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work(["Knit"], rows: border * 2, stitches: caston)
        b.section = "Body"
        b.work(["K\(border), *k1, p1; repeat from * to the last \(border + 1) stitches, k\(border + 1)"], rows: body, stitches: caston)
        b.section = "Top Border"
        b.work(["Knit"], rows: border * 2, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely. Weave in the ends and block the placemat flat.")
        let long = 4 * Double(border) / (g.spi * 2) + Double(body) / rate
        let yards = Sizing.yards(squareInches: width * long, spi: g.spi, factor: 1.25)
        return pattern(b, estimate: yards, yarnNote: ", cotton so it washes well", tools: [Double(caston) / g.spi > 14 ? "\(g.needle.label) \(Sizing.cable(24)) circular needle, worked flat" : "\(g.needle.label) needles", "Tapestry needle"], finished: "\(Sizing.inches(Double(caston) / g.spi)) by \(Sizing.inches(long))", gauge: g)
    }
}
