import Foundation

/// Mitts and gloves added after the first release.
extension Engines {
    struct Mitts: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var increases: Int
        var gusset: Int
        var thumb: Int
    }

    /// Fingerless mitts worked as a pair from the cuff up, fitted with a thumb gusset like a mitten's: the
    /// gusset grows from a single stitch, waits on waste yarn while the hand is knit to the knuckles, and is
    /// picked up for a short ribbed thumb. The thumb sits at the side, so either mitt fits either hand.
    static func fingerlessMitts(hand: Double, gauge g: Gauge) -> Mitts {
        // Snug: a little under the hand, so the mitt hugs the palm.
        let stitches = Sizing.stitches(hand * 0.95, per: g.spi, multiple: 4, minimum: 16)
        let increases = max(2, Int(((Double(stitches) * 0.36 - 2) / 2).rounded()))
        let gusset = 1 + 2 * increases
        let thumb = gusset + 1
        let cuff = Sizing.rows(min(2.5, hand * 0.33), per: g.rpi, minimum: 4)
        let before = Sizing.rows(0.25, per: g.rpi, minimum: 1)
        let gussetRounds = max(2 * increases, Sizing.rows(hand * 0.3, per: g.rpi))
        let spacing = min(4, max(2, gussetRounds / increases))
        let extra = max(0, gussetRounds - spacing * increases)
        let handRounds = Sizing.rows(hand * 0.17, per: g.rpi, minimum: 2)
        let top = Sizing.rows(hand * 0.08, per: g.rpi, minimum: 3)
        let thumbRib = Sizing.rows(0.5, per: g.rpi, minimum: 3)

        var b = PlanBuilder()
        for mitt in 1...2 {
            let name = "Mitt \(mitt)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(stitches) stitches with the smaller needles. Join in the round without twisting and place a marker.", stitches: stitches)
            b.work(["*K2, p2; repeat from * around"], rows: cuff, stitches: stitches)
            b.section = "\(name) · Thumb Gusset"
            b.row("Change to the larger needles and knit", stitches: stitches)
            b.work(["Knit"], rows: before - 1, stitches: stitches)
            b.row("K1, place a thumb marker, knit to the end. The stitch before the thumb marker is the gusset", stitches: stitches)
            b.work(["M1L, knit to the thumb marker, M1R, slip the marker, knit to the end"] + Array(repeating: "Knit", count: spacing - 1), rows: spacing * increases, stitches: stitches + 2, delta: 2)
            b.work(["Knit"], rows: extra, stitches: stitches + 2 * increases)
            b.row("Slip the \(gusset) gusset stitches to waste yarn and take out the thumb marker. Cast on 1 stitch over the gap with the backward loop method, then knit to the end", stitches: stitches)
            b.section = "\(name) · Hand"
            b.work(["Knit"], rows: handRounds, stitches: stitches)
            b.section = "\(name) · Top"
            b.row("Change to the smaller needles and work *k2, p2; repeat from * around", stitches: stitches)
            b.work(["*K2, p2; repeat from * around"], rows: top - 1, stitches: stitches)
            b.action("Bind off loosely in pattern.")
            b.section = "\(name) · Thumb"
            // Three picked up at the gap, then two taken away, so the base of the thumb closes without a hole.
            b.action("Return the \(gusset) held thumb stitches to the larger needles. Join new yarn at the gap and pick up and knit 3 stitches: one in the corner, one in the stitch cast on over the gap, and one in the other corner. Place a marker for the start of the round.", stitches: thumb + 2)
            b.row("Knit to the last 4 stitches, k2tog, k2tog", stitches: thumb)
            b.work(["*K1, p1; repeat from * around"], rows: thumbRib, stitches: thumb)
            b.action("Bind off loosely in pattern. Weave in the ends, closing any gap at the base of the thumb.")
        }
        let long = Double(cuff + before + 1 + spacing * increases + extra + 1 + handRounds + top) / g.rpi
        let yards = Sizing.yards(squareInches: hand * 0.95 * long * 1.2 * 2, spi: g.spi, factor: 1.1)
        let plan = pattern(b, estimate: yards, tools: ["\(g.ribNeedle.label) double-pointed needles for the ribbing, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the hand, or a long circular", "2 stitch markers, waste yarn", "Tapestry needle"], finished: "\(fits(stitches, g, "hand", hand)), \(Sizing.inches(long)) from the cuff to the knuckles", gauge: g, round: true)
        return Mitts(plan: plan, stitches: stitches, increases: increases, gusset: gusset, thumb: thumb)
    }
}

extension Engines {
    struct ArmWarmers: Equatable, Sendable {
        var plan: PatternPlan
        var hand: Int
        var top: Int
    }

    /// Long fingerless warmers from the knuckles to the upper arm: a ribbed edge, a slit for the thumb
    /// worked flat, then a tube that widens evenly from the wrist to the arm and ends in a deep rib.
    static func armWarmers(wrist: Double, arm: Double, length: Double, gauge g: Gauge) -> ArmWarmers {
        // Over the knuckles the hand is about an inch more than the wrist; the warmer hugs it a little.
        let hand = Sizing.stitches((wrist + 1) * 0.9, per: g.spi, multiple: 4, minimum: 20)
        let top = max(hand, Sizing.stitches(max(arm, wrist + 1) * 0.9, per: g.spi, multiple: 4, minimum: 20))
        let edge = Sizing.rows(0.75, per: g.rpi, minimum: 3)
        let below = Sizing.rows(0.5, per: g.rpi, minimum: 2)
        let slit = Sizing.rows(1.75, per: g.rpi, even: true, minimum: 4)
        let above = Sizing.rows(1, per: g.rpi, minimum: 2)
        let rib = Sizing.rows(min(2.5, length * 0.15), per: g.rpi, minimum: 4)
        let rest = max(2, Sizing.rows(length, per: g.rpi) - edge - below - slit - above - rib)
        let increases = (top - hand) / 2
        let spacing = increases > 0 ? max(1, rest / increases) : 0
        let straight = rest - spacing * increases

        var b = PlanBuilder()
        for warmer in 1...2 {
            let name = "Arm Warmer \(warmer)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(hand) stitches. Join in the round without twisting and place a marker.", stitches: hand)
            b.work(["*K2, p2; repeat from * around"], rows: edge, stitches: hand)
            b.section = "\(name) · Hand"
            b.work(["Knit"], rows: below, stitches: hand)
            b.section = "\(name) · Thumb Opening"
            // Two knit stitches at each edge keep the sides of the slit from rolling.
            b.work(["Knit to the end of the round, turn", "K2, purl to the last 2 stitches, k2, turn"], rows: slit, stitches: hand)
            b.section = "\(name) · Arm"
            b.row("Knit to the end of the round and join in the round again", stitches: hand)
            b.work(["Knit"], rows: above - 1 + straight, stitches: hand)
            if increases > 0 {
                b.work(["K1, M1L, knit to the last stitch, M1R, k1"] + Array(repeating: "Knit", count: spacing - 1), rows: spacing * increases, stitches: hand + 2, delta: 2)
            }
            b.section = "\(name) · Top"
            b.work(["*K2, p2; repeat from * around"], rows: rib, stitches: top)
            b.action("Bind off loosely in pattern. Weave in the ends.")
        }
        let long = Double(edge + below + slit + above + rest + rib) / g.rpi
        let yards = Sizing.yards(squareInches: (wrist + arm) / 2 * long * 2, spi: g.spi, factor: 1.15)
        let plan = pattern(b, estimate: yards, tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(Double(hand) / g.spi)) around the hand, widening to \(Sizing.inches(Double(top) / g.spi)) at the top, \(Sizing.inches(long)) long", gauge: g, round: true)
        return ArmWarmers(plan: plan, hand: hand, top: top)
    }

    /// Thumbless mittens for a baby, as a pair: a long rib cuff that stays on, a plain hand and a gathered top
    /// with nothing to graft. A multiple of 4 so the top closes in three even rounds.
    static func babyMittens(hand: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let stitches = Sizing.stitches(hand + 0.5, per: g.spi, multiple: 4, minimum: 16)
        let cuff = Sizing.rows(hand * 0.4, per: g.rpi, minimum: 6)
        let top: [(text: String, stitches: Int)] = [
            ("*K2, k2tog; repeat from * around", stitches * 3 / 4),
            ("Knit", stitches * 3 / 4),
            ("*K1, k2tog; repeat from * around", stitches / 2),
            ("*K2tog; repeat from * around", stitches / 4),
        ]
        // From the top of the cuff, at the wrist, to the fingertips, with a quarter inch to spare.
        let handRounds = max(2, Sizing.rows(length + 0.25, per: g.rpi) - top.count)
        var b = PlanBuilder()
        for mitten in 1...2 {
            let name = "Mitten \(mitten)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(stitches) stitches with the smaller needles. Join in the round without twisting and place a marker.", stitches: stitches)
            b.work(["*K1, p1; repeat from * around"], rows: cuff, stitches: stitches)
            b.section = "\(name) · Hand"
            b.row("Change to the larger needles and knit", stitches: stitches)
            b.work(["Knit"], rows: handRounds - 1, stitches: stitches)
            b.section = "\(name) · Top"
            runs(&b, top, from: stitches)
            b.action("Cut the yarn, thread it through the last \(stitches / 4) stitches and pull tight. Weave in the ends.")
        }
        let long = Double(cuff + handRounds + top.count) / g.rpi
        let yards = Sizing.yards(squareInches: (hand + 0.5) * long * 2, spi: g.spi, factor: 1.15)
        return pattern(b, estimate: yards, tools: ["\(g.ribNeedle.label) double-pointed needles for the cuff, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the hand, or a long circular", "Stitch marker", "Tapestry needle"], finished: "\(fits(stitches, g, "hand", hand)), \(Sizing.inches(long)) from the cuff to the tip", gauge: g, round: true)
    }

    /// Boot cuffs, worked in the round: a rib that sits inside the boot, then seed stitch that shows above it,
    /// or folds down over the top, since seed stitch looks the same from both sides. Written for one.
    static func bootCuff(calf: Double, height: Double, gauge g: Gauge) -> PatternPlan {
        let stitches = Sizing.stitches(calf * 0.9, per: g.spi, multiple: 4, minimum: 32)
        let edge = Sizing.rows(0.5, per: g.rpi, minimum: 3)
        let leg = Sizing.rows(height * 0.45, per: g.rpi, minimum: 4)
        let cuff = Sizing.rows(height, per: g.rpi, even: true, minimum: 8) - leg - edge
        let rib = "*K2, p2; repeat from * around"
        var b = PlanBuilder()
        b.section = "Leg"
        b.action("Cast on \(stitches) stitches loosely. Join in the round without twisting and place a marker.", stitches: stitches)
        b.work([rib], rows: leg, stitches: stitches)
        b.section = "Cuff"
        b.work(["*K1, p1; repeat from * around", "*P1, k1; repeat from * around"], rows: max(2, cuff), stitches: stitches)
        b.section = "Edge"
        b.work([rib], rows: edge, stitches: stitches)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends. Make a second cuff the same way. Wear the rib inside the boot, with the seed stitch above it or folded down over the top.")
        let tall = Double(leg + max(2, cuff) + edge) / g.rpi
        let yards = Sizing.yards(squareInches: calf * 0.9 * tall * 2, spi: g.spi, factor: 1.25)
        return pattern(b, estimate: yards, tools: [Double(stitches) / g.spi < 16 ? "\(g.needle.label) double-pointed needles, or a long circular for magic loop" : "\(g.needle.label) \(Sizing.cable(16)) circular needle", "Stitch marker", "Tapestry needle"], finished: "\(fits(stitches, g, "calf", calf)) with the rib stretched a little, \(Sizing.inches(tall)) tall", gauge: g, round: true)
    }
}

extension Engines {
    /// Gloves as a pair, worked from the cuff up in the round. The thumb grows from a gusset at the side, as
    /// on the mitts, so either glove fits either hand. The little finger is set aside a little lower than the
    /// others, the way a hand is shaped; then the index, middle and ring fingers are worked in turn, each
    /// casting on 2 stitches toward the next finger and picking those 2 up again, so no hole opens between them.
    /// `hand` is around the knuckles, `length` from the wrist to the tip of the middle finger.
    static func gloves(hand: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let stitches = Sizing.stitches(hand * 0.95, per: g.spi, multiple: 4, minimum: 16)
        let half = stitches / 2
        // Each side of the hand shared out across the four fingers: the index widest, the little finger narrowest.
        let index = max(2, Int((Double(half) * 0.3).rounded()))
        let little = max(1, Int((Double(half) * 0.2).rounded()))
        let middle = (half - index - little + 1) / 2
        let ring = half - index - little - middle
        let upper = stitches - 2 * little + 2
        let increases = max(2, Int(((Double(stitches) * 0.36 - 2) / 2).rounded()))
        let gusset = 1 + 2 * increases
        let thumb = gusset + 1

        let cuff = Sizing.rows(min(2.5, length * 0.33), per: g.rpi, minimum: 4)
        let before = Sizing.rows(0.25, per: g.rpi, minimum: 1)
        let gussetRounds = max(2 * increases, Sizing.rows(length * 0.28, per: g.rpi))
        let spacing = min(4, max(2, gussetRounds / increases))
        let extra = max(0, gussetRounds - spacing * increases)
        // The little finger starts a quarter inch or so below the others.
        let step = Sizing.rows(max(0.25, length * 0.06), per: g.rpi, minimum: 2)
        let palm = Sizing.rows(length * 0.57, per: g.rpi)
        let below = before + 1 + spacing * increases + extra + 1
        let handRounds = max(1, palm - below - 1 - step)
        // Each finger from its base, counting the round that sets it up and the round that closes it.
        func rounds(_ share: Double) -> Int { max(4, Sizing.rows(length * share, per: g.rpi)) }
        let fingers: [(name: String, stitches: Int, rounds: Int)] = [
            ("Index Finger", 2 * index + 2, rounds(0.38)),
            ("Middle Finger", 2 * middle + 4, rounds(0.43)),
            ("Ring Finger", 2 * ring + 4, rounds(0.39)),
            ("Little Finger", 2 * little + 2, rounds(0.31)),
        ]
        let thumbRounds = rounds(0.31)

        var b = PlanBuilder()
        for glove in 1...2 {
            let name = "Glove \(glove)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(stitches) stitches with the smaller needles. Join in the round without twisting and place a marker.", stitches: stitches)
            b.work(["*K2, p2; repeat from * around"], rows: cuff, stitches: stitches)
            b.section = "\(name) · Thumb Gusset"
            b.row("Change to the larger needles and knit", stitches: stitches)
            b.work(["Knit"], rows: before - 1, stitches: stitches)
            b.row("K1, place a thumb marker, knit to the end. The stitch before the thumb marker is the gusset", stitches: stitches)
            b.work(["M1L, knit to the thumb marker, M1R, slip the marker, knit to the end"] + Array(repeating: "Knit", count: spacing - 1), rows: spacing * increases, stitches: stitches + 2, delta: 2)
            b.work(["Knit"], rows: extra, stitches: stitches + 2 * increases)
            b.row("Slip the \(gusset) gusset stitches to waste yarn and take out the thumb marker. Cast on 1 stitch over the gap with the backward loop method, then knit to the end. The round now starts at the thumb side", stitches: stitches)
            b.section = "\(name) · Hand"
            b.work(["Knit"], rows: handRounds, stitches: stitches)
            b.row("K\(half - little). Slip the next \(2 * little) stitches to waste yarn for the little finger, cast on 2 stitches over the gap with the backward loop method, then knit to the end", stitches: upper)
            b.work(["Knit"], rows: step, stitches: upper)

            for (number, finger) in fingers.enumerated() {
                b.section = "\(name) · \(finger.name)"
                switch number {
                case 0:
                    b.row("K\(index). Slip the next \(upper - 2 * index) stitches to waste yarn for the other fingers, cast on 2 stitches over the gap with the backward loop method, then knit the last \(index) stitches of the round", stitches: finger.stitches)
                case 1:
                    b.action("Return the next \(middle) stitches from the front and the \(middle) facing them on the back to the needles. Join new yarn, pick up and knit 2 stitches in the stitches cast on at the base of the index finger, knit the \(middle) front stitches, cast on 2 stitches with the backward loop method, then knit the \(middle) back stitches.", stitches: finger.stitches)
                case 2:
                    b.action("Return the last \(2 * ring + 2) held stitches to the needles: \(ring) from the front, the 2 cast on over the little finger, and \(ring) from the back. Join new yarn, pick up and knit 2 stitches in the stitches cast on at the base of the middle finger, then knit the \(2 * ring + 2) stitches.", stitches: finger.stitches)
                default:
                    b.action("Return the \(2 * little) held little finger stitches to the needles. Join new yarn, knit them, then pick up and knit 2 stitches in the stitches cast on over the gap.", stitches: finger.stitches)
                }
                b.work(["Knit"], rows: finger.rounds - 2, stitches: finger.stitches)
                b.row("*K2tog; repeat from * around", stitches: finger.stitches / 2)
                b.action("Cut the yarn, thread it through the \(finger.stitches / 2) stitches and pull tight.")
            }

            b.section = "\(name) · Thumb"
            // Three picked up at the gap, then two taken away, so the base of the thumb closes without a hole.
            b.action("Return the \(gusset) held thumb stitches to the larger needles. Join new yarn at the gap and pick up and knit 3 stitches: one in the corner, one in the stitch cast on over the gap, and one in the other corner. Place a marker for the start of the round.", stitches: thumb + 2)
            b.row("Knit to the last 4 stitches, k2tog, k2tog", stitches: thumb)
            b.work(["Knit"], rows: thumbRounds - 3, stitches: thumb)
            b.row("*K2tog; repeat from * around", stitches: thumb / 2)
            b.action("Cut the yarn, thread it through the \(thumb / 2) stitches and pull tight. Weave in the ends, closing any gaps between the fingers and at the base of the thumb.")
        }
        let tip = Double(cuff + palm + fingers[1].rounds) / g.rpi
        let yards = Sizing.yards(squareInches: hand * tip * 1.3 * 2, spi: g.spi, factor: 1.1)
        let tools = ["\(g.ribNeedle.label) double-pointed needles for the cuff, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the hand and fingers, or a long circular", "2 stitch markers, waste yarn", "Tapestry needle"]
        let finished = "\(fits(stitches, g, "hand", hand)), \(Sizing.inches(Double(palm + fingers[1].rounds) / g.rpi)) from the wrist to the tip of the middle finger, with a \(Sizing.inches(Double(cuff) / g.rpi)) cuff"
        return pattern(b, estimate: yards, tools: tools, finished: finished, gauge: g, round: true)
    }
}
