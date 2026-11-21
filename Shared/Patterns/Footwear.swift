import Foundation

/// Socks and slippers added after the first release.
extension Engines {
    struct ToeUp: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var toe: Int
        var footRounds: Int
        var heelRounds: Int
    }

    /// A pair of socks worked from the toe up: a toe grown from Judy's magic cast-on, a foot with a line of
    /// waste yarn where the heel goes, a leg and a ribbed cuff, then an afterthought heel knit into that line
    /// like a second toe and grafted shut. Trying the sock on as it grows tells the knitter where to stop.
    static func toeUpSocks(foot around: Double, length footLength: Double, leg: Double, gauge g: Gauge) -> ToeUp {
        // A tenth smaller than the foot, so the sock stays up and does not bag.
        let stitches = Sizing.stitches(around * 0.9, per: g.spi, multiple: 4, minimum: 16)
        let half = stitches / 2
        let toeStart = wedgeEnd(stitches)
        let toe = toeIncreases(from: toeStart, to: stitches)
        let heel = wedge(from: stitches, to: toeStart)
        let cuff = Sizing.rows(min(1.5, leg * 0.3), per: g.rpi, minimum: 4)
        let legRounds = max(2, Sizing.rows(leg, per: g.rpi) - cuff)
        // The foot is knit 5 percent short and stretches to fit. The heel adds its own depth behind the
        // waste yarn line, as deep as the toe, with one more round that closes its corners.
        let heelDepth = heel.count + 1
        let footRounds = max(2, Sizing.rows(footLength * 0.95, per: g.rpi) - 1 - toe.count - heelDepth)

        var b = PlanBuilder()
        for sock in 1...2 {
            let name = "Sock \(sock)"
            b.section = "\(name) · Toe"
            b.action("Cast on \(toeStart) stitches with Judy's magic cast-on, \(toeStart / 2) on each of two needles. The first needle holds the top of the foot, the second the sole. Work in the round from here, each round starting at the top of the foot.", stitches: toeStart)
            b.work(["Knit the top of the foot, place a marker, then knit the sole"], rows: 1, stitches: toeStart)
            runs(&b, toe, from: toeStart)
            b.section = "\(name) · Foot"
            b.work(["Knit"], rows: footRounds, stitches: stitches)
            b.work(["Knit to the marker. With a smooth waste yarn in a contrasting color, knit the \(half) sole stitches, slip them back to the left needle and knit them again with the sock yarn"], rows: 1, stitches: stitches)
            b.section = "\(name) · Leg"
            b.work(["Knit"], rows: legRounds, stitches: stitches)
            b.section = "\(name) · Cuff"
            b.work(["*K2, p2; repeat from * around"], rows: cuff, stitches: stitches)
            b.action("Bind off very loosely in rib, with a needle 2 sizes larger, so the cuff stretches over the heel.")
            b.section = "\(name) · Heel"
            b.action("Pick out the waste yarn and catch the live stitches on two needles: \(half) from the foot below the gap and \(half) from the leg above it. If the leg side shows one short, pick up the half stitch at its end.")
            b.action("Join the yarn at the right edge of the foot needle. Knit the \(half) foot stitches, pick up and knit 1 stitch in the corner of the gap and place a marker. Knit the \(half) leg stitches, pick up and knit 1 stitch in the other corner, and place a marker for the start of the round.", stitches: stitches + 2)
            b.work(["Knit to 2 stitches before the marker, k2tog, slip the marker, knit to the last 2 stitches, k2tog"], rows: 1, stitches: stitches)
            runs(&b, heel, from: stitches)
            b.action("Cut the yarn, leaving a \(Sizing.inches(12)) tail. Put the \(toeStart / 2) stitches on each side of the marker on their own needle and graft them together with Kitchener stitch. Close any gap left at the corners with the tail, and weave in the ends.")
        }
        let length = Double(1 + toe.count + footRounds + 1 + heelDepth) / g.rpi
        let yards = Sizing.yards(squareInches: around * 0.9 * (leg + footLength + 2) * 2, spi: g.spi, factor: 1.1)
        var plan = pattern(b, estimate: yards, yarnNote: ", wool with a little nylon wears longest", tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "A needle 2 sizes larger for the bind off", "2 stitch markers", "Smooth waste yarn in a contrasting color", "Tapestry needle"], finished: "\(fits(stitches, g, "foot", around)). The foot is \(Sizing.inches(length)) from the back of the heel to the tip of the toe, and the leg \(Sizing.inches(Double(legRounds + cuff) / g.rpi)) from the heel to the cuff", gauge: g, round: true)
        // Socks are knit firmer than the label says, so the yarn to buy is fingering, not the lace its gauge suggests.
        if g == Design.toeUpSocks.gauge(for: .fingering) {
            plan.materials[0] = "About \(Sizing.yardage(plan.yards)) of fingering weight yarn, wool with a little nylon wears longest"
        }
        return ToeUp(plan: plan, stitches: stitches, toe: toeStart, footRounds: footRounds, heelRounds: heel.count)
    }

    /// A wedge toe worked the other way, the mirror of `wedge`: 4 stitches added every round while the toe
    /// is narrow, then every other round, until it holds `last`.
    static func toeIncreases(from start: Int, to last: Int) -> [(text: String, stitches: Int)] {
        let increase = "K1, M1L, knit to 1 stitch before the marker, M1R, k1, slip the marker, k1, M1L, knit to the last stitch, M1R, k1"
        var rounds: [(text: String, stitches: Int)] = []
        var count = start
        while count < last {
            if count > last / 2, count > start { rounds.append(("Knit", count)) }
            count += 4
            rounds.append((increase, count))
        }
        return rounds
    }
}

extension Engines {
    /// The classic two-rectangle poncho: two panels, each twice as long as it is wide, in stockinette with
    /// garter edges. The short end of each is sewn to the long side of the other, which makes a V at the
    /// front and back and leaves the neck open.
    static func poncho(width: Double, gauge g: Gauge) -> PatternPlan {
        let border = max(3, Int((0.75 * g.spi).rounded()))
        let stitches = Sizing.stitches(width, per: g.spi, minimum: 2 * border + 6)
        let ridges = Sizing.rows(0.75, per: g.spi, minimum: 2)
        let length = width * 2
        let edge = 2 * ridges
        let body = max(2, Sizing.rows(length, per: g.rpi, even: true) - 2 * edge)
        var b = PlanBuilder()
        for panel in 1...2 {
            b.section = "Panel \(panel)"
            b.action("Cast on \(stitches) stitches.", stitches: stitches)
            b.work(["Knit"], rows: edge, stitches: stitches)
            b.work(["Knit", "K\(border), purl to the last \(border) stitches, k\(border)"], rows: body, stitches: stitches)
            b.work(["Knit"], rows: edge, stitches: stitches)
            b.action("Bind off loosely. Weave in the ends.")
        }
        b.section = "Finishing"
        b.action("Block both panels to \(Sizing.inches(width)) by \(Sizing.inches(length)). Hold each with its right side facing you and its cast-on edge at the bottom: its left side is the long edge on your left.")
        b.action("Sew the cast-on edge of Panel 2 along the top half of Panel 1's left side, from the bound-off corner down to the middle.")
        b.action("Sew the cast-on edge of Panel 1 along the top half of Panel 2's left side the same way. Each panel's end is now sewn to the side of the other, and the two free halves of the sides frame the neck. Weave in the ends.")
        let yards = Sizing.yards(squareInches: width * length * 2, spi: g.spi, factor: 1.05)
        return pattern(b, estimate: yards, tools: [longCircular(stitches, g, flat: true), "Tapestry needle"], finished: "Two panels, each \(Sizing.inches(width)) by \(Sizing.inches(length)), sewn into a poncho that hangs about \(Sizing.inches(width * 1.4)) from the neck to the point", gauge: g)
    }
}
