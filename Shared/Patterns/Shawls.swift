import Foundation

/// Shawls, wraps and cowls added after the first release.
extension Engines {
    /// A long, shallow triangle in garter, begun at one corner. Only one edge grows, a stitch every sixth row,
    /// so the shawl ends three times as long as it is deep: it wraps around the neck and the ends hang free.
    static func asymmetricShawl(wingspan: Double, gauge g: Gauge) -> PatternPlan {
        // The long edge and the bound-off end are 3 to 1: the wingspan is the slope, the square root of 10 times the depth.
        let depth = wingspan / 10.0.squareRoot()
        let increases = max(8, Int((depth * g.spi).rounded()) - 3)
        let last = 3 + increases
        // Plain rows after the last increase bring the straight edge to its full length, three times the depth.
        let extra = max(0, Sizing.rows(depth * 3, per: g.spi * 2, even: true) - increases * 6)
        let length = Double(increases * 6 + extra) / (g.spi * 2)
        var b = PlanBuilder()
        b.section = "Shawl"
        b.action("Cast on 3 stitches.", stitches: 3)
        b.work(["K1, kfb, knit to the end"] + Array(repeating: "Knit", count: 5), rows: increases * 6, stitches: 4, delta: 1)
        b.work(["Knit"], rows: extra, stitches: last)
        b.section = "Finishing"
        b.action("Bind off all \(last) stitches loosely. Weave in the ends and block the shawl flat.")
        let yards = Sizing.yards(squareInches: length * depth / 2, spi: g.spi, factor: 1.25)
        let needle = Double(last) / g.spi > 24 ? "\(g.needle.label) \(Sizing.cable(32)) circular needle, worked flat" : "\(g.needle.label) \(Sizing.cable(24)) circular needle, worked flat"
        return pattern(b, estimate: yards, tools: [needle, "Tapestry needle"], finished: "\(Sizing.inches(length)) along the straight edge, \(Sizing.inches(Double(last) / g.spi)) deep at the end", gauge: g)
    }
}

extension Engines {
    struct Bandana: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var front: Int
    }

    /// A cowl with a bandana's point at the front: a triangle grown flat from its tip, two stitches every
    /// right-side row, then joined into a ribbed tube that pulls over the head.
    static func bandanaCowl(around: Double, height: Double, gauge g: Gauge) -> Bandana {
        let stitches = Sizing.stitches(around, per: g.spi, multiple: 4, minimum: 40)
        // The point spans a little under half the round; 5 plus pairs keeps it odd, with a k2 edge each side.
        let front = max(13, (stitches * 9 / 20 - 5) / 2 * 2 + 5)
        let back = stitches - front
        let pairs = (front - 5) / 2
        let rib = Sizing.rows(height, per: g.rpi, minimum: 8)
        var b = PlanBuilder()
        b.section = "Point"
        b.action("Cast on 5 stitches.", stitches: 5)
        b.work(["K2, M1L, knit to the last 2 stitches, M1R, k2", "K2, purl to the last 2 stitches, k2"], rows: pairs * 2, stitches: 7, delta: 2)
        b.section = "Neck"
        b.action("With the right side facing, knit across the \(front) stitches. Cast on \(back) stitches with the cable cast-on, then join in the round without twisting and place a marker.", stitches: stitches)
        b.work(["*K2, p2; repeat from * around"], rows: rib, stitches: stitches)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends, closing the corners where the point meets the neck. Wear it with the point at the front.")
        let deep = Double(pairs * 2) / g.rpi
        let yards = Sizing.yards(squareInches: around * height * 1.15 + Double(front) / g.spi * deep / 2, spi: g.spi, factor: 1.05)
        let cable = Double(stitches) / g.spi < 24 ? 16 : 24
        let plan = pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(cable)) circular needle", "Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(Double(stitches) / g.spi)) around, \(Sizing.inches(Double(rib) / g.rpi)) tall, with a point \(Sizing.inches(deep)) deep", gauge: g)
        return Bandana(plan: plan, stitches: stitches, front: front)
    }
}

extension Engines {
    struct HoodedScarf: Equatable, Sendable {
        var plan: PatternPlan
        var end: Int
        var hood: Int
        var seam: Double
    }

    /// One long garter piece: a scarf end, a wider middle for the hood, and the other end. Folded in half and
    /// seamed along one edge of the middle, the seam runs down the back of the head and the ends hang in front.
    static func hoodedScarf(head: Double, length: Double, gauge g: Gauge) -> HoodedScarf {
        let end = Sizing.stitches(min(7.5, head * 0.33), per: g.spi, minimum: 12)
        // From the face to the back of the neck, about half the head around; even, so it widens in pairs.
        let hood = max(end + 4, end + Sizing.stitches(head * 0.5 - Double(end) / g.spi, per: g.spi, multiple: 2))
        let rpi = g.spi * 2
        let seam = head * 0.55
        let ends = Sizing.rows(length, per: rpi, even: true, minimum: 20)
        let hoodRows = Sizing.rows(seam * 2, per: rpi, even: true) - (hood - end) * 2
        var b = PlanBuilder()
        b.section = "Scarf"
        b.action("Cast on \(end) stitches.", stitches: end)
        b.work(["Knit"], rows: ends, stitches: end)
        b.section = "Increase"
        b.work(["K1, kfb, knit to the last 2 stitches, kfb, k1", "Knit"], rows: hood - end, stitches: end + 2, delta: 2)
        b.section = "Hood"
        b.work(["Knit"], rows: max(4, hoodRows), stitches: hood)
        b.section = "Decrease"
        b.work(["K1, ssk, knit to the last 3 stitches, k2tog, k1", "Knit"], rows: hood - end, stitches: hood - 2, delta: -2)
        b.section = "Scarf"
        b.work(["Knit"], rows: ends, stitches: end)
        b.action("Bind off loosely.")
        b.section = "Finishing"
        b.action("Fold the piece in half across the middle of the hood. Sew the two halves together along one long edge, from the fold down \(Sizing.inches(seam)): that seam is the back of the hood, and the open edge frames the face. Weave in the ends.")
        let total = Double(2 * ends) / rpi * Double(end) / g.spi + Double(2 * (hood - end) + max(4, hoodRows)) / rpi * Double(hood) / g.spi
        let yards = Sizing.yards(squareInches: total, spi: g.spi, factor: 1.25)
        let plan = pattern(b, estimate: yards, tools: ["\(g.needle.label) needles", "Tapestry needle"], finished: "A hood \(Sizing.inches(seam)) from the top to the neck, with ends \(Sizing.inches(Double(end) / g.spi)) wide hanging \(Sizing.inches(Double(ends) / rpi)) below it", gauge: g)
        return HoodedScarf(plan: plan, end: end, hood: hood, seam: seam)
    }

    /// A capelet from the top down in the round: a rib collar wide enough to pull over the head, six
    /// increase rounds spread down the yoke out to the shoulders and arms, and a ribbed hem.
    static func capelet(chest: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let collar = Sizing.stitches(18 + (chest - 28) * 0.1, per: g.spi, multiple: 4, minimum: 48)
        let hemTarget = Sizing.stitches(chest * 1.3 + 4, per: g.spi)
        let step = max(4, Int((Double(hemTarget - collar) / 6 / 4).rounded()) * 4)
        let hem = collar + 6 * step
        let rib = "*K2, p2; repeat from * around"
        let collarRounds = Sizing.rows(min(3, length * 0.25), per: g.rpi, minimum: 6)
        let hemRounds = Sizing.rows(1, per: g.rpi, minimum: 4)
        let yoke = max(12, Sizing.rows(length, per: g.rpi) - collarRounds - hemRounds)
        let spacing = yoke / 6
        var b = PlanBuilder()
        b.section = "Collar"
        b.action("Cast on \(collar) stitches loosely. Join in the round without twisting and place a marker.", stitches: collar)
        b.work([rib], rows: collarRounds, stitches: collar)
        b.section = "Yoke"
        var count = collar
        for index in 0..<6 {
            b.row(spread(step, over: count), stitches: count + step)
            count += step
            b.work(["Knit"], rows: (index == 5 ? yoke - 5 * spacing : spacing) - 1, stitches: count)
        }
        b.section = "Hem"
        b.work([rib], rows: hemRounds, stitches: hem)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Weave in the ends and block the capelet over a towel shaped like your shoulders.")
        let tall = Double(collarRounds + yoke + hemRounds) / g.rpi
        let yards = Sizing.yards(squareInches: Double(collar + hem) / 2 / g.spi * tall, spi: g.spi, factor: 1.15)
        let needles = ["\(g.needle.label) \(Sizing.cable(16)) circular needle for the collar", "\(g.needle.label) \(Sizing.cable(32)) circular needle for when the stitches crowd the short one"]
        return pattern(b, estimate: yards, tools: needles + ["Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(Double(collar) / g.spi)) around the collar, \(Sizing.inches(Double(hem) / g.spi)) around the hem, \(Sizing.inches(tall)) long, for a \(Sizing.inches(chest)) chest", gauge: g, round: true)
    }
}
