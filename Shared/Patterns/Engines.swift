import Foundation

/// The rules behind each design. Every function turns measurements and a gauge
/// into a row-by-row plan whose stitch counts add up.
enum Engines {
    enum HatStyle: Sendable { case ribbed, slouch, rolled }
    enum Texture: Sendable { case garter, rib, seed }

    // MARK: Wording

    private static func gaugeLine(_ g: Gauge) -> String {
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
        return "Gauge: \(g.stitches.formatted(format)) stitches and \(g.rows.formatted(format)) rows over 4 in"
    }

    private static func yarnLine(_ yards: Int) -> String { "About \(yards) yd of yarn" }

    /// Wording for `count` increases spread evenly over `stitches` stitches.
    private static func spread(_ count: Int, over stitches: Int) -> String {
        let gap = max(1, stitches / count)
        let rest = stitches - gap * count
        return "Work (k\(gap), M1) \(count) times" + (rest > 0 ? ", knit the last \(rest)" : "")
    }

    private static func even(_ value: Double, minimum: Int = 2) -> Int { max(minimum, 2 * Int((value / 2).rounded())) }

    // MARK: Hats

    static func hat(_ style: HatStyle, head: Double, gauge g: Gauge) -> PatternPlan {
        let brim = Sizing.stitches(head * (style == .slouch ? 0.88 : 0.9), per: g.spi, multiple: 8, minimum: 32)
        let body = style == .slouch ? Sizing.stitches(head * 1.08, per: g.spi, multiple: 8, minimum: brim + 8) : brim
        let crown = crownRounds(wedge: body / 8)
        let height = head * (style == .slouch ? 0.47 : 0.37) + (style == .rolled ? 1 : 0)
        let brimRounds = style == .rolled ? 0 : Sizing.rows(head * (style == .slouch ? 0.07 : 0.09), per: g.rpi, minimum: 4)
        let increase = style == .slouch ? 1 : 0
        let bodyRounds = max(4, Sizing.rows(height, per: g.rpi) - brimRounds - increase - crown.count)

        var b = PlanBuilder()
        b.section = style == .rolled ? "Body" : "Brim"
        b.action("Cast on \(brim) stitches. Join in the round without twisting and place a marker.", stitches: brim)
        switch style {
        case .ribbed: b.work(["*K2, p2; repeat from * around"], rows: brimRounds, stitches: brim)
        case .slouch: b.work(["*K1, p1; repeat from * around"], rows: brimRounds, stitches: brim)
        case .rolled: break
        }
        b.section = "Body"
        if style == .slouch { b.row(spread(body - brim, over: brim), stitches: body) }
        b.work(["Knit"], rows: bodyRounds, stitches: body)
        b.section = "Crown"
        for round in crown { b.row(round.text, stitches: round.stitches) }
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 8 stitches and pull tight. Weave in the ends.")

        let yards = Sizing.yards(squareInches: Double(body) / g.spi * height, spi: g.spi)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) 16 in circular needle", "Double-pointed needles in the same size for the crown", "Stitch marker", "Tapestry needle", gaugeLine(g)],
            finished: "Fits a \(Sizing.inches(head)) head",
            yards: yards
        )
    }

    /// Eight wedges, decreased every other round for the first half and every round after, down to 8 stitches.
    private static func crownRounds(wedge: Int) -> [(text: String, stitches: Int)] {
        var rounds: [(text: String, stitches: Int)] = []
        var width = wedge
        var spaced = wedge / 2
        while width > 1 {
            let text = width > 2 ? "*K\(width - 2), k2tog; repeat from * around" : "*K2tog; repeat from * around"
            width -= 1
            rounds.append((text, width * 8))
            if spaced > 0, width > 1 {
                rounds.append(("Knit", width * 8))
                spaced -= 1
            }
        }
        return rounds
    }

    // MARK: Scarves and cowls

    static func scarf(_ texture: Texture, width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        var b = PlanBuilder()
        b.section = "Scarf"
        let caston: Int
        let factor: Double
        switch texture {
        case .garter:
            caston = Sizing.stitches(width, per: g.spi, minimum: 6)
            factor = 1.25
            b.action("Cast on \(caston) stitches.", stitches: caston)
            b.work(["Knit"], rows: Sizing.rows(length, per: g.spi * 2, even: true), stitches: caston)
        case .rib:
            caston = Sizing.stitches(width * 1.25, per: g.spi, multiple: 4, extra: 2)
            factor = 1.3
            b.action("Cast on \(caston) stitches.", stitches: caston)
            b.work(["*K2, p2; repeat from * to the last 2 stitches, k2", "*P2, k2; repeat from * to the last 2 stitches, p2"], rows: Sizing.rows(length, per: g.rpi, even: true), stitches: caston)
        case .seed:
            caston = Sizing.stitches(width, per: g.spi, multiple: 2, extra: 1)
            factor = 1.15
            b.action("Cast on \(caston) stitches.", stitches: caston)
            b.work(["*K1, p1; repeat from * to the last stitch, k1"], rows: Sizing.rows(length, per: g.rpi * 1.1, even: true), stitches: caston)
        }
        b.section = "Finishing"
        b.action("Bind off loosely\(texture == .garter ? "" : " in pattern"). Weave in the ends.")
        let yards = Sizing.yards(squareInches: width * length, spi: g.spi, factor: factor)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) needles", "Tapestry needle", gaugeLine(g)],
            finished: "\(Sizing.inches(width)) wide, \(Sizing.inches(length)) long",
            yards: yards
        )
    }

    static func cowl(_ texture: Texture, around: Double, height: Double, gauge g: Gauge) -> PatternPlan {
        var b = PlanBuilder()
        b.section = "Cowl"
        let caston: Int
        if texture == .seed {
            caston = Sizing.stitches(around, per: g.spi, multiple: 2, extra: 1)
            b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
            b.work(["*K1, p1; repeat from * to the last stitch, k1", "*P1, k1; repeat from * to the last stitch, p1"], rows: Sizing.rows(height, per: g.rpi * 1.1, even: true), stitches: caston)
        } else {
            caston = Sizing.stitches(around * 1.15, per: g.spi, multiple: 4)
            b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
            b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(height, per: g.rpi), stitches: caston)
        }
        b.section = "Finishing"
        b.action("Bind off loosely in pattern. Weave in the ends.")
        let yards = Sizing.yards(squareInches: around * height, spi: g.spi, factor: texture == .seed ? 1.15 : 1.3)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) \(around < 30 ? 16 : 32) in circular needle", "Stitch marker", "Tapestry needle", gaugeLine(g)],
            finished: "\(Sizing.inches(around)) around, \(Sizing.inches(height)) tall",
            yards: yards
        )
    }

    // MARK: Blankets and home

    static func blanket(bordered: Bool, width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        var b = PlanBuilder()
        let caston: Int
        if bordered {
            let border = max(3, Int((1.25 * g.spi).rounded()))
            caston = Sizing.stitches(width, per: g.spi, minimum: border * 2 + 4)
            let middle = Sizing.rows(length - 2 * Double(border) / g.spi, per: g.rpi, even: true, minimum: 2)
            b.section = "Bottom Border"
            b.action("Cast on \(caston) stitches.", stitches: caston)
            b.work(["Knit"], rows: border * 2, stitches: caston)
            b.section = "Body"
            b.work(["Knit", "K\(border), purl to the last \(border) stitches, k\(border)"], rows: middle, stitches: caston)
            b.section = "Top Border"
            b.work(["Knit"], rows: border * 2, stitches: caston)
        } else {
            caston = Sizing.stitches(width, per: g.spi, minimum: 10)
            b.section = "Blanket"
            b.action("Cast on \(caston) stitches.", stitches: caston)
            b.work(["Knit"], rows: Sizing.rows(length, per: g.spi * 2, even: true), stitches: caston)
        }
        b.section = "Finishing"
        b.action("Bind off loosely. Weave in the ends.")
        let yards = Sizing.yards(squareInches: width * length, spi: g.spi, factor: bordered ? 1.05 : 1.25)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) circular needle, 32 in or longer, worked flat", "Tapestry needle", gaugeLine(g)],
            finished: "\(Sizing.inches(width)) wide, \(Sizing.inches(length)) long",
            yards: yards
        )
    }

    /// Knit corner to corner: grow by a stitch a row to the diagonal, then shrink back.
    static func dishcloth(side: Double, gauge g: Gauge) -> PatternPlan {
        let widest = max(8, Int((side * 2.0.squareRoot() * g.spi * 0.92).rounded()))
        var b = PlanBuilder()
        b.section = "Increase"
        b.action("Cast on 4 stitches.", stitches: 4)
        b.row("Knit", stitches: 4)
        b.work(["K2, yo, knit to the end"], rows: widest - 4, stitches: 5, delta: 1)
        b.section = "Decrease"
        b.work(["K1, k2tog, yo, k2tog, knit to the end"], rows: widest - 4, stitches: widest - 1, delta: -1)
        b.section = "Finishing"
        b.action("Bind off the last 4 stitches. Weave in the ends.")
        let yards = Sizing.yards(squareInches: side * side, spi: g.spi, factor: 1.25)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards) + ", cotton for a cloth that scrubs", "\(g.needle.label) needles", "Tapestry needle", gaugeLine(g)],
            finished: "\(Sizing.inches(side)) square",
            yards: yards
        )
    }

    // MARK: Accessories

    static func earWarmer(head: Double, width: Double, gauge g: Gauge) -> PatternPlan {
        let caston = Sizing.stitches(head * 0.9, per: g.spi, multiple: 4, minimum: 24)
        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
        b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(width, per: g.rpi, minimum: 6), stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely in pattern. Weave in the ends.")
        let yards = Sizing.yards(squareInches: head * width, spi: g.spi, factor: 1.3)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) 16 in circular needle", "Stitch marker", "Tapestry needle", gaugeLine(g)],
            finished: "Fits a \(Sizing.inches(head)) head, \(Sizing.inches(width)) wide",
            yards: yards
        )
    }

    /// Fingerless mitts with a slit for the thumb, worked as a pair.
    static func handwarmers(hand: Double, gauge g: Gauge) -> PatternPlan {
        let caston = Sizing.stitches(hand * 0.9, per: g.spi, multiple: 4, minimum: 16)
        var b = PlanBuilder()
        for mitt in 1...2 {
            let name = "Mitt \(mitt)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
            b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(hand * 0.33, per: g.rpi, minimum: 4), stitches: caston)
            b.section = "\(name) · Hand"
            b.work(["Knit"], rows: Sizing.rows(hand * 0.2, per: g.rpi, minimum: 2), stitches: caston)
            b.section = "\(name) · Thumb Opening"
            b.work(["Knit to the marker, turn", "Purl to the marker, turn"], rows: Sizing.rows(hand * 0.25, per: g.rpi, even: true, minimum: 4), stitches: caston)
            b.section = "\(name) · Hand"
            b.row("Knit to the marker and join in the round again", stitches: caston)
            b.work(["Knit"], rows: Sizing.rows(hand * 0.15, per: g.rpi, minimum: 2) - 1, stitches: caston)
            b.section = "\(name) · Top"
            b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(hand * 0.1, per: g.rpi, minimum: 3), stitches: caston)
            b.action("Bind off loosely in pattern. Weave in the ends.")
        }
        let yards = Sizing.yards(squareInches: hand * hand * 1.03 * 2, spi: g.spi, factor: 1.15)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "Tapestry needle", gaugeLine(g)],
            finished: "Fits a \(Sizing.inches(hand)) hand, \(Sizing.inches(hand * 1.03)) long",
            yards: yards
        )
    }

    static func legWarmers(calf: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let caston = Sizing.stitches(calf * 0.9, per: g.spi, multiple: 4, minimum: 20)
        let rib = Sizing.rows(min(2, length * 0.2), per: g.rpi, minimum: 4)
        let leg = max(2, Sizing.rows(length, per: g.rpi) - rib * 2)
        var b = PlanBuilder()
        for warmer in 1...2 {
            let name = "Leg Warmer \(warmer)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
            b.work(["*K2, p2; repeat from * around"], rows: rib, stitches: caston)
            b.section = "\(name) · Leg"
            b.work(["Knit"], rows: leg, stitches: caston)
            b.section = "\(name) · Top"
            b.work(["*K2, p2; repeat from * around"], rows: rib, stitches: caston)
            b.action("Bind off loosely in pattern. Weave in the ends.")
        }
        let yards = Sizing.yards(squareInches: calf * length * 2, spi: g.spi, factor: 1.1)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "Tapestry needle", gaugeLine(g)],
            finished: "Fits a \(Sizing.inches(calf)) calf, \(Sizing.inches(length)) long",
            yards: yards
        )
    }

    /// A garter triangle worked from the middle of the top edge down, four stitches wider every other row.
    static func shawl(wingspan: Double, gauge g: Gauge) -> PatternPlan {
        let pairs = max(8, Int(((wingspan * g.spi * 1.13 - 5) / 4).rounded()))
        let last = 5 + pairs * 4
        var b = PlanBuilder()
        b.section = "Shawl"
        b.action("Cast on 5 stitches. Mark the center stitch and move the marker up as you go.", stitches: 5)
        b.row("Knit", stitches: 5)
        b.work(["K2, yo, knit to the center stitch, yo, k1, yo, knit to the last 2 stitches, yo, k2", "Knit"], rows: pairs * 2, stitches: 9, delta: 4)
        b.section = "Finishing"
        b.action("Bind off all \(last) stitches loosely. Weave in the ends and block to open up the fabric.")
        let yards = Sizing.yards(squareInches: wingspan * wingspan / 4, spi: g.spi, factor: 0.9)
        return PatternPlan(
            steps: b.steps,
            materials: [yarnLine(yards), "\(g.needle.label) circular needle, 32 in or longer, worked flat", "Removable stitch marker", "Tapestry needle", gaugeLine(g)],
            finished: "\(Sizing.inches(wingspan)) across, \(Sizing.inches(wingspan / 2)) deep after blocking",
            yards: yards
        )
    }

    // MARK: Sweater

    struct Raglan: Equatable, Sendable {
        var plan: PatternPlan
        var neck: Int
        var body: Int
        var sleeve: Int
        var cuff: Int
        var underarm: Int
        var backAtNeck: Int
        var sleeveAtNeck: Int
        var bodyIncreases: Int
        var sleeveIncreases: Int
        var yokeRounds: Int
    }

    /// A crew-neck pullover knit from the neck down in one piece. The body and
    /// the sleeves grow at their own rates, so large sizes keep a neck that fits.
    static func raglan(chest: Double, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> Raglan {
        let body = Sizing.stitches(chest, per: g.spi, multiple: 4)
        let arm = chest * 0.31 + 1.6
        let sleeve = even(arm * g.spi, minimum: 12)
        let underarm = min(even(Double(body) * 0.07), sleeve - 8)
        let panel = (body - 2 * underarm) / 2
        let sleeveTop = sleeve - underarm
        let backAtNeck = min(even(min(chest * 0.1 + 3.5, 8.5) * g.spi, minimum: 4), panel - 2)
        let sleeveAtNeck = min(even(2 * g.spi, minimum: 4), sleeveTop - 2)
        let bodyIncreases = (panel - backAtNeck) / 2
        let sleeveIncreases = (sleeveTop - sleeveAtNeck) / 2
        let neck = 2 * backAtNeck + 2 * sleeveAtNeck

        let shared = min(bodyIncreases, sleeveIncreases)
        let total = max(bodyIncreases, sleeveIncreases)
        let depth = chest * 0.125 + 3.5
        let yokeRounds = max(Sizing.rows(depth, per: g.rpi), total)
        // Increase rounds worked back to back, when the yoke is too short to space them all out.
        let packed = max(0, 2 * total - yokeRounds)

        let all = "*K1, M1L, knit to 1 stitch before the marker, M1R, k1, slip marker; repeat from * 3 more times"
        let bodyOnly = "Knit to the marker, slip marker, k1, M1L, knit to 1 stitch before the marker, M1R, k1, slip marker, knit to the marker, slip marker, k1, M1L, knit to 1 stitch before the marker, M1R, k1"
        let sleevesOnly = "*K1, M1L, knit to 1 stitch before the marker, M1R, k1, slip marker, knit to the marker, slip marker; repeat from * once more"

        var b = PlanBuilder()
        b.section = "Neckband"
        b.action("With the smaller 16 in needle, cast on \(neck) stitches. Join in the round without twisting and place a marker.", stitches: neck)
        b.work(["*K1, p1; repeat from * around"], rows: Sizing.rows(1, per: g.rpi, minimum: 4), stitches: neck)

        b.section = "Yoke"
        b.row("Change to the larger needle. K\(sleeveAtNeck) for a sleeve, place marker, k\(backAtNeck) for the front, place marker, k\(sleeveAtNeck) for a sleeve, place marker, k\(backAtNeck) for the back", stitches: neck)
        var onNeedle = neck
        let cuts = Array(Set([0, packed, shared, total])).sorted()
        for (start, end) in zip(cuts, cuts.dropFirst()) {
            let rounds = end - start
            let gain = start < shared ? 8 : 4
            let text = start < shared ? all : bodyIncreases > sleeveIncreases ? bodyOnly : sleevesOnly
            if start < packed {
                b.work([text], rows: rounds, stitches: onNeedle + gain, delta: gain)
            } else {
                b.work([text, "Knit"], rows: rounds * 2, stitches: onNeedle + gain, delta: gain)
            }
            onNeedle += gain * rounds
        }
        b.work(["Knit"], rows: yokeRounds - (2 * total - packed), stitches: onNeedle)

        b.section = "Divide"
        b.row("Removing the markers as you go: slip \(sleeveTop) sleeve stitches to waste yarn, cast on \(underarm), knit \(panel) front stitches, slip \(sleeveTop) sleeve stitches to waste yarn, cast on \(underarm), knit \(panel) back stitches. Place a marker for the new start of the round", stitches: body)

        let hem = Sizing.rows(min(2, length * 0.2), per: g.rpi, minimum: 4)
        b.section = "Body"
        b.work(["Knit"], rows: max(2, Sizing.rows(length, per: g.rpi) - hem), stitches: body)
        b.section = "Hem"
        b.row("Change to the smaller needle. *K1, p1; repeat from * around", stitches: body)
        b.work(["*K1, p1; repeat from * around"], rows: hem - 1, stitches: body)
        b.action("Bind off loosely in pattern.")

        let cuffRounds = Sizing.rows(min(2, sleeveLength * 0.2), per: g.rpi, minimum: 4)
        let straight = Sizing.rows(1.5, per: g.rpi)
        let sleeveRounds = max(straight + 2, Sizing.rows(sleeveLength, per: g.rpi) - cuffRounds)
        var decreases = max(0, (sleeve - even(chest * 0.14 * g.spi + 3 * g.spi, minimum: 8)) / 2)
        var spacing = decreases > 0 ? (sleeveRounds - straight) / decreases : 0
        if decreases > 0, spacing < 1 {
            decreases = sleeveRounds - straight
            spacing = 1
        }
        let cuff = sleeve - 2 * decreases
        for name in ["First Sleeve", "Second Sleeve"] {
            b.section = name
            b.action("Return \(sleeveTop) held sleeve stitches to the larger needles. Starting at the middle of the underarm, pick up and knit \(underarm / 2) stitches, knit the sleeve stitches, then pick up and knit \(underarm / 2) more. Join in the round and place a marker.", stitches: sleeve)
            b.work(["Knit"], rows: straight, stitches: sleeve)
            if decreases > 0 {
                b.work(["K1, k2tog, knit to the last 3 stitches, ssk, k1"] + Array(repeating: "Knit", count: spacing - 1), rows: decreases * spacing, stitches: sleeve - 2, delta: -2)
            }
            b.work(["Knit"], rows: sleeveRounds - straight - decreases * spacing, stitches: cuff)
            b.section = "\(name) · Cuff"
            b.row("Change to the smaller needles. *K1, p1; repeat from * around", stitches: cuff)
            b.work(["*K1, p1; repeat from * around"], rows: cuffRounds - 1, stitches: cuff)
            b.action("Bind off loosely in pattern.")
        }
        b.section = "Finishing"
        b.action("Weave in the ends, closing any gaps at the underarms. Block to the finished measurements.")

        let finishedChest = Double(body) / g.spi
        let area = finishedChest * (length + depth) + (arm + Double(cuff) / g.spi) * sleeveLength + arm * depth
        let yards = Sizing.yards(squareInches: area, spi: g.spi)
        let plan = PatternPlan(
            steps: b.steps,
            materials: [
                yarnLine(yards),
                "\(g.needle.label) circular needles, 16 in and 32 in",
                "\(g.ribNeedle.label) circular needles, 16 in and 32 in, for the ribbing",
                "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop",
                "4 stitch markers, waste yarn, tapestry needle",
                gaugeLine(g),
            ],
            finished: "Chest \(Sizing.inches(finishedChest)), body \(Sizing.inches(length)) from the underarm, sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            yards: yards
        )
        return Raglan(plan: plan, neck: neck, body: body, sleeve: sleeve, cuff: cuff, underarm: underarm, backAtNeck: backAtNeck, sleeveAtNeck: sleeveAtNeck, bodyIncreases: bodyIncreases, sleeveIncreases: sleeveIncreases, yokeRounds: yokeRounds)
    }
}
