import Foundation

extension Engines {
    struct TubeSocks: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var spiralRounds: Int
        var toeRounds: Int
        var left: Int
    }

    /// Socks with no heel, knit from the cuff down: a straight k3, p3 cuff, then the same rib that moves one stitch every
    /// four rounds so it spirals and hugs any heel, and a wedge toe grafted shut. `foot` is the foot around.
    static func tubeSocks(foot: Double, length: Double, gauge g: Gauge) -> TubeSocks {
        // A tenth smaller than the foot so the rib hugs it, in sixes for the k3, p3 rib.
        let stitches = max(24, Int((foot * 0.9 * g.spi / 6).rounded()) * 6)
        let half = stitches / 2
        // The toe narrows on every other round to about half its stitches, then on every round to about a quarter.
        let slow = stitches / 8
        let fast = max(0, (stitches - 4 * slow - max(8, stitches / 4)) / 4)
        let left = stitches - 4 * slow - 4 * fast
        let toeRounds = 2 * slow + fast
        let cuff = Sizing.rows(min(2, length * 0.12), per: g.rpi, minimum: 6)
        let spiral = max(24, Sizing.rows(length - Double(toeRounds) / g.rpi, per: g.rpi) - cuff)

        // Moving the start of the round one stitch every fourth round walks the rib around the leg.
        let rib = "*K3, p3; repeat from * around"
        let spiralRows = [rib, rib, rib, rib + ". Remove the marker, k1 and place the marker again, so the rib moves one stitch to the left"]

        var b = PlanBuilder()
        b.section = "Cuff"
        b.action("Cast on \(stitches) stitches loosely and divide them over double-pointed needles, or use a long circular for magic loop. Join in the round without twisting and place a marker.", stitches: stitches)
        b.work([rib], rows: cuff, stitches: stitches)
        b.section = "Spiral Rib"
        b.work(spiralRows, rows: spiral, stitches: stitches)
        b.section = "Toe"
        b.row("Knit \(half) stitches for the top of the foot and place a marker. Knit the last \(half) for the sole", stitches: stitches)
        let decrease = "*K1, ssk, knit to 3 stitches before the marker, k2tog, k1, slip the marker; repeat from * once more"
        b.work([decrease, "Knit"], rows: 2 * slow, stitches: stitches - 4, delta: -4)
        b.work([decrease], rows: fast, stitches: stitches - 4 * slow - 4, delta: -4)
        b.action("Put the \(left / 2) stitches of the top on one needle and the \(left / 2) of the sole on another, removing the markers. Cut the yarn, leaving a \(Sizing.inches(12)) tail, and graft the toe shut with Kitchener stitch.")
        b.section = "Finishing"
        b.action("Weave in the ends and make a second sock the same way. The socks have no heel: the spiral rib settles around the heel as they are worn.")

        let around = Double(stitches) / g.spi
        let knitLength = Double(cuff + 1 + spiral + toeRounds) / g.rpi
        let area = 2 * around * knitLength
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi, factor: 1.1),
            tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "2 stitch markers", "Tapestry needle"],
            finished: "\(Sizing.inches(around)) around unstretched, to fit a \(Sizing.inches(foot)) foot, and \(Sizing.inches(knitLength)) from the cuff to the toe",
            gauge: g, round: true
        )
        return TubeSocks(plan: plan, stitches: stitches, spiralRounds: spiral, toeRounds: toeRounds, left: left)
    }
}
