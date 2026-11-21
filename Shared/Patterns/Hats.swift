import Foundation

/// Hats added after the first release.
extension Engines {
    struct TopDown: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var crownRounds: Int
    }

    /// A beanie begun at the top: 8 stitches grown in 8 wedges to the hat's count, the same crown the
    /// ribbed beanie closes with, worked the other way. The knitter can try it on and stop the body
    /// wherever it fits, then work the brim and bind off.
    static func topDownBeanie(head: Double, gauge g: Gauge) -> TopDown {
        // The crown's 8 wedges want a multiple of 8. A heavy yarn on a small head can leave none inside the
        // ease band: the body then stays a multiple of 8 and the brim draws in to a count that fits.
        let stitches = hatCount(head: head, share: 0.9, spi: g.spi, multiple: 8) ?? Sizing.stitches(head * 0.95, per: g.spi, multiple: 8, minimum: 24)
        let ribs: [(multiple: Int, text: String)] = [(4, "*K2, p2; repeat from * around"), (2, "*K1, p1; repeat from * around")]
        let rib = ribs.lazy.compactMap { rib in
            (Double(stitches) / g.spi / head <= hatEase.upperBound && stitches % rib.multiple == 0 ? stitches : hatCount(head: head, share: 0.9, spi: g.spi, multiple: rib.multiple)).map { (count: $0, text: rib.text) }
        }.first ?? (count: stitches, text: ribs[0].text)
        // The crown's decreases, read from the top: each decrease round becomes an increase round.
        let down = crownRounds(wedge: stitches / 8)
        let counts = Array(([stitches] + down.map(\.stitches)).reversed())
        let crown: [(text: String, stitches: Int)] = zip(counts, counts.dropFirst()).map { before, after in
            (after > before ? "*K\(before / 8), M1L; repeat from * around" : "Knit", after)
        }
        let height = head * 0.37
        let brimRounds = Sizing.rows(head * 0.09, per: g.rpi, minimum: 4)
        let bodyRounds = max(4, Sizing.rows(height, per: g.rpi) - brimRounds - crown.count)
        let small = Double(stitches) / g.spi < 16

        var b = PlanBuilder()
        b.section = "Crown"
        b.action("Cast on 8 stitches, leaving a tail of \(Sizing.inches(8)), and divide them over double-pointed needles or a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: 8)
        var rounds = crown
        // Past 16 in around, the stitches reach around a short circular.
        if !small, let index = rounds.firstIndex(where: { Double($0.stitches) / g.spi >= 16 && $0.text != "Knit" }) {
            rounds[index].text += ". Move the stitches to the \(Sizing.cable(16)) circular needle when they crowd the double-pointed needles"
        }
        runs(&b, rounds, from: 8)
        b.section = "Body"
        b.work(["Knit"], rows: bodyRounds, stitches: stitches)
        b.section = "Brim"
        let change = "Change to the smaller needle\(small ? "s" : "")"
        if rib.count == stitches {
            b.row("\(change). \(rib.text.prefix(1).uppercased() + rib.text.dropFirst())", stitches: stitches)
        } else {
            b.row("\(change). \(adjusting(stitches, to: rib.count))", stitches: rib.count)
        }
        b.work([rib.text], rows: brimRounds - 1, stitches: rib.count)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Thread the cast-on tail through the 8 cast-on stitches and pull tight to close the top. Weave in the ends.")

        let yards = Sizing.yards(squareInches: Double(stitches) / g.spi * height, spi: g.spi)
        let needles = small
            ? ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "\(g.ribNeedle.label) double-pointed needles for the brim, or a long circular"]
            : ["\(g.needle.label) double-pointed needles, or a long circular for magic loop, for the crown", "\(g.needle.label) \(Sizing.cable(16)) circular needle", "\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the brim"]
        let plan = pattern(b, estimate: yards, tools: needles + ["Stitch marker", "Tapestry needle"], finished: "\(fits(rib.count, g, "head", head)), \(Sizing.inches(Double(crown.count + bodyRounds + brimRounds) / g.rpi)) from the top to the brim", gauge: g, round: true)
        return TopDown(plan: plan, stitches: stitches, crownRounds: crown.count)
    }
}

extension Engines {
    /// A garter strip knit flat, its ends folded and hooked through each other at the front, then sewn:
    /// the twist shows both sides of the fabric, so it is garter, the same on each.
    static func twistedHeadband(head: Double, width: Double, gauge g: Gauge) -> PatternPlan {
        let stitches = Sizing.stitches(width, per: g.spi, minimum: 8)
        // Garter stretches around the head; the twist takes up about an inch of each end.
        let length = head * 0.85 + 1
        let rows = Sizing.rows(length, per: g.spi * 2, even: true, minimum: 20)
        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(stitches) stitches, leaving a tail of \(Sizing.inches(12)) for sewing.", stitches: stitches)
        b.work(["Knit"], rows: rows, stitches: stitches)
        b.action("Bind off loosely, leaving a tail of \(Sizing.inches(12)).")
        b.section = "Finishing"
        b.action("Lay the band flat with the two ends side by side. Fold the left end in half lengthwise, bringing its edges together.")
        b.action("Fold the right end in half the same way, hooking it through the fold of the left end, so the two folded ends interlock.")
        b.action("Bring the four layers of cast-on and bound-off edges together and sew through all of them with one tail. Turn the band so the seam is inside, and the twist sits at the front. Weave in the ends.")
        let yards = Sizing.yards(squareInches: length * width, spi: g.spi, factor: 1.25)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) needles", "Tapestry needle"], finished: "\(Sizing.inches(width)) wide and \(Sizing.inches(Double(rows) / (g.spi * 2))) long before the twist, to fit a \(Sizing.inches(head)) head", gauge: g)
    }
}

extension Engines {
    struct Knot: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var tube: Int
    }

    /// A baby's hat with no crown to shape: a ribbed brim, a straight body, a few rounds that halve it, then
    /// a narrow tube that is tied in a knot on top. The knot is the crown, so it fits a growing head loosely.
    static func knotHat(head: Double, gauge g: Gauge) -> Knot {
        let stitches = hatCount(head: head, share: 0.9, spi: g.spi, multiple: 8) ?? Sizing.stitches(head * 0.95, per: g.spi, multiple: 8, minimum: 24)
        // The tube: half the hat, kept to 8 sections so every decrease round takes one from each.
        let tube = max(16, stitches / 16 * 8)
        let brimRounds = Sizing.rows(head * 0.07, per: g.rpi, minimum: 4)
        let bodyRounds = max(4, Sizing.rows(head * 0.33, per: g.rpi) - brimRounds - 1)
        var taper: [(text: String, stitches: Int)] = []
        var count = stitches
        while count > tube {
            count -= 8
            taper.append(("*K\(count / 8 - 1), k2tog; repeat from * around", count))
            if count > tube { taper.append(("Knit", count)) }
        }
        let tubeRounds = Sizing.rows(head * 0.3, per: g.rpi, minimum: 8)
        let small = Double(stitches) / g.spi < 16

        var b = PlanBuilder()
        b.section = "Brim"
        b.action("Cast on \(stitches) stitches with the smaller needle\(small ? "s" : ""). Join in the round without twisting and place a marker.", stitches: stitches)
        b.work(["*K2, p2; repeat from * around"], rows: brimRounds, stitches: stitches)
        b.section = "Body"
        b.row("Change to the larger needle\(small ? "s" : "") and knit", stitches: stitches)
        b.work(["Knit"], rows: bodyRounds, stitches: stitches)
        b.section = "Crown"
        if !taper.isEmpty { taper[0].text += small ? "" : ". Change to double-pointed needles when the stitches no longer reach around" }
        runs(&b, taper, from: stitches)
        b.work(["Knit"], rows: tubeRounds, stitches: tube)
        b.action("Bind off loosely. Weave in the ends.")
        b.section = "Finishing"
        b.action("Tie the tube in a loose overhand knot, snug against the top of the hat.")

        let tall = Double(brimRounds + 1 + bodyRounds + taper.count + tubeRounds) / g.rpi
        let yards = Sizing.yards(squareInches: Double(stitches) / g.spi * tall, spi: g.spi)
        let needles = small
            ? ["\(g.ribNeedle.label) double-pointed needles for the brim, or a long circular for magic loop", "\(g.needle.label) double-pointed needles, or a long circular"]
            : ["\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the brim", "\(g.needle.label) \(Sizing.cable(16)) circular needle", "\(g.needle.label) double-pointed needles, or a long circular for magic loop, for the top"]
        let plan = pattern(b, estimate: yards, tools: needles + ["Stitch marker", "Tapestry needle"], finished: "\(fits(stitches, g, "head", head)), \(Sizing.inches(Double(brimRounds + 1 + bodyRounds + taper.count) / g.rpi)) from the brim to the knot", gauge: g, round: true)
        return Knot(plan: plan, stitches: stitches, tube: tube)
    }
}
