import Foundation

/// The rules behind each design. Every function turns measurements and a gauge
/// into a row-by-row plan whose stitch counts add up.
enum Engines {
    enum HatStyle: Sendable { case ribbed, slouch, rolled }
    enum Texture: Sendable { case garter, rib, seed }

    /// What a colorwork design asks of a shape: a stitch count its chart repeat divides, plain
    /// stockinette rounds for a chart on a piece that is otherwise all texture, and the crown.
    struct Fit: Equatable, Sendable {
        /// The stitch count is rounded to a multiple of this, as well as the shape's own multiple.
        var multiple = 1
        /// Rounds of stockinette worked in the middle of a cowl or ear warmer, between texture edges.
        var band = 0
        /// Two small rounded ears, knit flat with a rim of their own and sewn to the crown.
        var ears = false

        static let plain = Fit()
    }

    private static func lcm(_ a: Int, _ b: Int) -> Int {
        func gcd(_ x: Int, _ y: Int) -> Int { y == 0 ? x : gcd(y, x % y) }
        return a / gcd(a, max(1, b)) * max(1, b)
    }

    // MARK: Wording

    /// A piece worked in the round counts its gauge in rounds, the way the rest of its pattern does.
    private static func gaugeLine(_ g: Gauge, round: Bool) -> String {
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
        return "Gauge: \(g.stitches.formatted(format)) stitches and \(g.rows.formatted(format)) \(round ? "rounds" : "rows") over \(Sizing.swatch()) of stockinette, after blocking. Use the needle that gives you this gauge"
    }

    /// The yarn weight a knitter would shop for at this gauge.
    static func weight(_ g: Gauge) -> YarnWeight {
        YarnWeight.allCases.min { abs($0.gauge.stitches - g.stitches) < abs($1.gauge.stitches - g.stitches) } ?? .worsted
    }

    /// The weight as it reads inside a sentence: "worsted", but "DK" and "Aran" as they are written.
    static func weightName(_ g: Gauge) -> String {
        let weight = weight(g)
        return weight == .dk || weight == .aran ? weight.label : weight.label.lowercased()
    }

    static func yarnLine(_ yards: Int, _ g: Gauge) -> String {
        "About \(Sizing.yardage(yards)) of \(weightName(g)) weight yarn"
    }

    /// A circular long enough to hold a flat piece or a wide round: 40 in once the stitches span about 45 in.
    private static func longCircular(_ stitches: Int, _ g: Gauge, flat: Bool) -> String {
        Double(stitches) / g.spi > 45 ? "\(g.needle.label) \(Sizing.cable(40)) circular needle\(flat ? ", worked flat" : "")"
            : "\(g.needle.label) circular needle, \(Sizing.cable(32)) or longer\(flat ? ", worked flat" : "")"
    }

    /// Closes a pattern. The yarn asked for is never less than what the written rows use, plus a reserve.
    /// `round` is true for a piece worked in the round.
    private static func pattern(_ b: PlanBuilder, estimate: Int, yarnNote: String = "", tools: [String], finished: String, gauge g: Gauge, round: Bool = false) -> PatternPlan {
        let yards = max(estimate, Sizing.yards(worked: b.steps, spi: g.spi))
        return PatternPlan(steps: b.steps, materials: [yarnLine(yards, g) + yarnNote] + tools + [gaugeLine(g, round: round)], finished: finished, yards: yards)
    }

    /// "19.5 in around, to fit a 22 in head": the number a knitter checks against the swatch, then who it fits.
    private static func fits(_ stitches: Int, _ g: Gauge, _ part: String, _ size: Double) -> String {
        "\(Sizing.inches(Double(stitches) / g.spi)) around, to fit a \(Sizing.inches(size)) \(part)"
    }

    /// Wording for `count` increases spread evenly over `stitches` stitches.
    private static func spread(_ count: Int, over stitches: Int) -> String {
        let gap = max(1, stitches / count)
        let rest = stitches - gap * count
        // Leftover stitches go one to a repeat, so the increases never bunch at one side.
        guard rest > 0, rest < count else { return "Work (k\(gap), M1) \(count) times" + (rest > 0 ? ", knit the last \(rest)" : "") }
        return "Work (k\(gap + 1), M1) \(rest) times, then (k\(gap), M1) \(count - rest) times"
    }

    private static func even(_ value: Double, minimum: Int = 2) -> Int { max(minimum, 2 * Int((value / 2).rounded())) }

    // MARK: Hats

    /// The negative ease a hat is cast on at: 5 to 15 percent smaller than the head, so it hugs without squeezing.
    static let hatEase = 0.85...0.95

    /// A cast-on count for `head` inches at this gauge: a multiple of `multiple` whose ease lands in
    /// `hatEase`, nearest `share` of the head. A count within 3 percent of that which also divides into
    /// the crown's 8 wedges wins, so most hats need no adjusting round. Nil when no multiple lands in the band.
    private static func hatCount(head: Double, share: Double, spi: Double, multiple: Int) -> Int? {
        let low = Int((head * hatEase.lowerBound * spi / Double(multiple)).rounded(.up))
        let high = Int((head * hatEase.upperBound * spi / Double(multiple)).rounded(.down))
        guard low <= high else { return nil }
        let counts = (low...high).map { $0 * multiple }.filter { $0 >= 24 }
        let wanted = head * share * spi
        func nearest(_ list: [Int]) -> Int? { list.min { abs(Double($0) - wanted) < abs(Double($1) - wanted) } }
        return nearest(counts.filter { $0 % 8 == 0 && abs(Double($0) - wanted) <= head * 0.03 * spi }) ?? nearest(counts)
    }

    /// The round that brings a count to a multiple of 8 for the crown, worked as the last round of the body.
    private static func adjusting(_ from: Int, to: Int) -> String {
        if to > from { return "Knit, increasing \(to - from) evenly: " + lowerFirst(spread(to - from, over: from)) }
        let count = from - to
        let gap = from / count
        let rest = from - gap * count
        func group(_ width: Int) -> String { width > 2 ? "k\(width - 2), k2tog" : "k2tog" }
        let groups = rest > 0 ? "work (\(group(gap + 1))) \(rest) times, then (\(group(gap))) \(count - rest) times" : "work (\(group(gap))) \(count) times"
        return "Knit, decreasing \(count) evenly: \(groups)"
    }

    private static func lowerFirst(_ text: String) -> String { text.prefix(1).lowercased() + text.dropFirst() }

    static func hat(_ style: HatStyle, head: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
        let share = style == .slouch ? 0.88 : 0.9
        // K2, p2 needs a multiple of 4. A heavy yarn can leave no multiple of 4 inside the ease band at a
        // small head, so the ribbed brim falls back to k1, p1 there. The slouch brim is k1, p1 throughout.
        let ribs: [(multiple: Int, text: String)] = switch style {
        case .ribbed: [(4, "*K2, p2; repeat from * around"), (2, "*K1, p1; repeat from * around")]
        case .slouch: [(2, "*K1, p1; repeat from * around")]
        case .rolled: [(1, "")]
        }
        // A chart repeat runs over the stockinette, which starts at the cast on except on the slouch hat.
        let chart = style == .slouch ? 1 : fit.multiple
        let picked = ribs.lazy.compactMap { rib in hatCount(head: head, share: share, spi: g.spi, multiple: lcm(rib.multiple, chart)).map { (count: $0, text: rib.text) } }.first
        let rib = picked?.text ?? ribs[0].text
        let brim = picked?.count ?? Sizing.stitches(head * share, per: g.spi, multiple: lcm(ribs[0].multiple, chart), minimum: 24)
        let body = style == .slouch ? Sizing.stitches(head * 1.08, per: g.spi, multiple: lcm(8, fit.multiple), minimum: brim + 8) : brim
        // The crown works in 8 wedges. A body that is not a multiple of 8 reaches the nearest one on its last round.
        let top = max(24, 8 * ((body + 3) / 8))
        // A flat top is about as tall as a crown that closes, less the dome it does not have.
        let crown = crownRounds(wedge: top / 8)
        let height = head * (style == .slouch ? 0.47 : 0.37) + (style == .rolled ? 1 : 0)
        let brimRounds = style == .rolled ? 0 : Sizing.rows(head * (style == .slouch ? 0.07 : 0.09), per: g.rpi, minimum: 4)
        let increase = style == .slouch ? 1 : 0
        let bodyRounds = max(4, Sizing.rows(height, per: g.rpi) - brimRounds - increase - crown.count)
        // A small hat does not reach around a 16 in circular, so it is knit on the short needles throughout.
        let small = Double(brim) / g.spi < 16
        let ribbed = style != .rolled

        var b = PlanBuilder()
        b.section = ribbed ? "Brim" : "Body"
        b.action("Cast on \(brim) stitches\(ribbed ? " with the smaller needle" : ""). Join in the round without twisting and place a marker." + (ribbed ? "" : " The edge rolls up on its own as you knit, so there is no brim to work."), stitches: brim)
        if ribbed { b.work([rib], rows: brimRounds, stitches: brim) }
        b.section = "Body"
        var plain = bodyRounds - (top == body ? 0 : 1)
        switch style {
        case .slouch: b.row("Change to the larger needle. " + spread(body - brim, over: brim), stitches: body)
        case .ribbed:
            b.row("Change to the larger needle and knit", stitches: body)
            plain -= 1
        case .rolled: break
        }
        b.work(["Knit"], rows: plain, stitches: body)
        if top != body { b.row(adjusting(body, to: top), stitches: top) }
        b.section = "Crown"
        for round in small ? crown : switching(crown, g) { b.row(round.text, stitches: round.stitches) }
        if fit.ears {
            b.action("Cut the yarn, thread it through the last 8 stitches and pull tight.")
            ear(&b, "First Ear", g)
            ear(&b, "Second Ear", g)
            b.section = "Finishing"
            b.action("Sew the cast-on edge of each ear to the crown, right side out, one on each side of the top and about \(Sizing.inches(head * 0.2)) apart. Weave in the ends.")
        } else {
            b.section = "Finishing"
            b.action("Cut the yarn, thread it through the last 8 stitches and pull tight. Weave in the ends.")
        }

        let yards = Sizing.yards(squareInches: Double(body) / g.spi * height, spi: g.spi)
        let needles: [String]
        switch (small, ribbed) {
        case (true, true): needles = ["\(g.ribNeedle.label) double-pointed needles for the brim, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the body, or a long circular for magic loop"]
        case (true, false): needles = ["\(g.needle.label) double-pointed needles, or a long circular for magic loop"]
        case (false, true): needles = ["\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the brim", "\(g.needle.label) \(Sizing.cable(16)) circular needle for the body", "Double-pointed needles in the larger size for the crown"]
        case (false, false): needles = ["\(g.needle.label) \(Sizing.cable(16)) circular needle", "Double-pointed needles in the same size for the crown"]
        }
        return pattern(b, estimate: yards, tools: needles + ["Stitch marker", "Tapestry needle"], finished: fits(brim, g, "head", head), gauge: g, round: true)
    }

    /// A rounded ear: stockinette narrowed at both edges to a blunt top, then a garter rim picked up
    /// around it. Its rows sit in a section ending "Ear", which colorwork reads as trim.
    private static func ear(_ b: inout PlanBuilder, _ name: String, _ g: Gauge) {
        let width = even(2.25 * g.spi, minimum: 6)
        let straight = even(0.5 * g.rpi)
        b.section = name
        b.action("Cast on \(width) stitches.", stitches: width)
        b.work(["Knit", "Purl"], rows: straight, stitches: width)
        var count = width
        while count > 4 {
            count -= 2
            b.row("K1, ssk, knit to the last 3 stitches, k2tog, k1", stitches: count)
            b.row("Purl", stitches: count)
        }
        b.action("Bind off.")
        let side = max(2, Int((Double(straight + width - 4) * 0.75).rounded()))
        b.action("Pick up and knit \(2 * side + 4) stitches around the sides and top of the ear, leaving the cast-on edge free.", stitches: 2 * side + 4)
        b.row("Knit", stitches: 2 * side + 4)
        b.action("Bind off knitwise, leaving a tail to sew the ear on with.")
    }

    /// Says once, on the round where a 16 in needle stops reaching, to move to the short needles.
    private static func switching(_ rounds: [(text: String, stitches: Int)], _ g: Gauge) -> [(text: String, stitches: Int)] {
        var rounds = rounds
        if let index = rounds.firstIndex(where: { Double($0.stitches) / g.spi < 14 && $0.text != "Knit" }) {
            rounds[index].text += ". Change to double-pointed needles when the stitches no longer reach around"
        }
        return rounds
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

    static func scarf(_ texture: Texture, width: Double, length: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
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
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) needles", "Tapestry needle"], finished: "\(Sizing.inches(width)) wide, \(Sizing.inches(length)) long", gauge: g)
    }

    static func cowl(_ texture: Texture, around: Double, height: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
        var b = PlanBuilder()
        b.section = "Cowl"
        let caston: Int
        let texts: [String]
        let rows: Int
        let rate: Double
        switch texture {
        case .seed:
            caston = Sizing.stitches(around, per: g.spi, multiple: lcm(2, fit.multiple))
            texts = ["*K1, p1; repeat from * around", "*P1, k1; repeat from * around"]
            rate = g.rpi * 1.1
            rows = Sizing.rows(height, per: rate, even: true)
        case .garter:
            caston = Sizing.stitches(around, per: g.spi, multiple: fit.multiple, minimum: 20)
            // Slipping the first stitch of each purl round hides the step garter makes at the start of the round.
            texts = ["Knit", "Slip the first stitch purlwise, then purl to the end of the round"]
            rate = g.spi * 2
            rows = Sizing.rows(height, per: rate, even: true)
        case .rib:
            caston = Sizing.stitches(around * 1.15, per: g.spi, multiple: lcm(4, fit.multiple))
            texts = ["*K2, p2; repeat from * around"]
            rate = g.rpi
            rows = Sizing.rows(height, per: rate)
        }
        b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
        if fit.band > 0 {
            // Texture at both edges, stockinette between: the band takes its own height from the edges.
            let edge = max(4, 2 * Int((Double(rows) - Double(fit.band) * rate / g.rpi) / 4))
            b.work(texts, rows: edge, stitches: caston)
            b.work(["Knit"], rows: fit.band, stitches: caston)
            b.work(texts, rows: edge, stitches: caston)
        } else {
            b.work(texts, rows: rows, stitches: caston)
        }
        b.section = "Finishing"
        b.action("Bind off loosely\(texture == .garter ? "" : " in pattern"). Weave in the ends.")
        let yards = Sizing.yards(squareInches: around * height, spi: g.spi, factor: texture == .seed ? 1.15 : texture == .garter ? 1.25 : 1.3)
        return pattern(b, estimate: yards, tools: [Double(caston) / g.spi > 45 ? longCircular(caston, g, flat: false) : "\(g.needle.label) \(Sizing.cable(Double(caston) / g.spi < 20 ? 16 : Double(caston) / g.spi < 34 ? 24 : 32)) circular needle", "Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(around)) around, \(Sizing.inches(height)) tall", gauge: g, round: true)
    }

    // MARK: Blankets and home

    static func blanket(bordered: Bool, width: Double, length: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
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
        return pattern(b, estimate: yards, tools: [longCircular(caston, g, flat: true), "Tapestry needle"], finished: "\(Sizing.inches(width)) wide, \(Sizing.inches(length)) long", gauge: g)
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
        return pattern(b, estimate: yards, yarnNote: ", cotton for a cloth that scrubs", tools: ["\(g.needle.label) needles", "Tapestry needle"], finished: "\(Sizing.inches(side)) square", gauge: g)
    }

    // MARK: Accessories

    static func earWarmer(head: Double, width: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
        let caston = Sizing.stitches(head * 0.9, per: g.spi, multiple: lcm(4, fit.multiple), minimum: 24)
        let rows = Sizing.rows(width, per: g.rpi, minimum: 6)
        let rib = "*K2, p2; repeat from * around"
        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
        if fit.band > 0 {
            let edge = max(3, (rows - fit.band) / 2)
            b.work([rib], rows: edge, stitches: caston)
            b.work(["Knit"], rows: fit.band, stitches: caston)
            b.work([rib], rows: edge, stitches: caston)
        } else {
            b.work([rib], rows: rows, stitches: caston)
        }
        b.section = "Finishing"
        b.action("Bind off loosely in pattern. Weave in the ends.")
        let yards = Sizing.yards(squareInches: head * width, spi: g.spi, factor: 1.3)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(16)) circular needle", "Stitch marker", "Tapestry needle"], finished: "\(fits(caston, g, "head", head)), \(Sizing.inches(width)) wide", gauge: g, round: true)
    }

    /// Fingerless mitts with a slit for the thumb, worked as a pair.
    static func handwarmers(hand: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
        let caston = Sizing.stitches(hand * 0.9, per: g.spi, multiple: lcm(4, fit.multiple), minimum: 16)
        var b = PlanBuilder()
        for mitt in 1...2 {
            let name = "Mitt \(mitt)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
            b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(hand * 0.33, per: g.rpi, minimum: 4), stitches: caston)
            b.section = "\(name) · Hand"
            b.work(["Knit"], rows: max(fit.band, Sizing.rows(hand * 0.2, per: g.rpi, minimum: 2)), stitches: caston)
            b.section = "\(name) · Thumb Opening"
            // Two knit stitches at each edge keep the sides of the slit from rolling.
            b.work(["Knit to the end of the round, turn", "K2, purl to the last 2 stitches, k2, turn"], rows: Sizing.rows(hand * 0.25, per: g.rpi, even: true, minimum: 4), stitches: caston)
            b.section = "\(name) · Upper Hand"
            b.row("Knit to the end of the round and join in the round again", stitches: caston)
            b.work(["Knit"], rows: Sizing.rows(hand * 0.15, per: g.rpi, minimum: 2) - 1, stitches: caston)
            b.section = "\(name) · Top"
            b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(hand * 0.1, per: g.rpi, minimum: 3), stitches: caston)
            b.action("Bind off loosely in pattern. Weave in the ends.")
        }
        let yards = Sizing.yards(squareInches: hand * hand * 1.03 * 2, spi: g.spi, factor: 1.15)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "Tapestry needle"], finished: "\(fits(caston, g, "hand", hand)), \(Sizing.inches(hand * 1.03)) long", gauge: g, round: true)
    }

    /// Worked from the top down: a deep rib grips below the knee, and the leg narrows by about 15 percent
    /// toward the ankle, so the tube does not slide down. The start of the round is the back of the leg.
    static func legWarmers(calf: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let caston = Sizing.stitches(calf * 0.9, per: g.spi, multiple: 4, minimum: 20)
        let top = Sizing.rows(min(3, length * 0.25), per: g.rpi, minimum: 4)
        let ankle = Sizing.rows(min(2, length * 0.2), per: g.rpi, minimum: 4)
        let leg = max(2, Sizing.rows(length, per: g.rpi) - top - ankle)
        // The calf is worked straight, then the decreases are spread over the lower part of the leg, at
        // least 2 rounds apart. The ankle keeps a multiple of 4 for its rib.
        let straight = leg * 2 / 5
        let room = leg - straight
        let most = min(2 * Int((Double(caston) * 0.15 / 4).rounded()), room / 2, (caston - 16) / 2)
        // Decrease rounds come in twos, 4 stitches a pair, so the ankle rib still divides.
        let shaping = max(0, most - most % 2)
        let rounds = shaping > 0 ? room / shaping : 0
        let narrow = caston - 2 * shaping
        var b = PlanBuilder()
        for warmer in 1...2 {
            let name = "Leg Warmer \(warmer)"
            b.section = "\(name) · Top"
            b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker at the back of the leg.", stitches: caston)
            b.work(["*K2, p2; repeat from * around"], rows: top, stitches: caston)
            b.section = "\(name) · Leg"
            b.work(["Knit"], rows: leg - shaping * rounds, stitches: caston)
            if shaping > 0 {
                b.work(["K1, k2tog, knit to the last 3 stitches, ssk, k1"] + Array(repeating: "Knit", count: rounds - 1), rows: shaping * rounds, stitches: caston - 2, delta: -2)
            }
            b.section = "\(name) · Ankle"
            b.work(["*K2, p2; repeat from * around"], rows: ankle, stitches: narrow)
            b.action("Bind off loosely in pattern. Weave in the ends.")
        }
        let yards = Sizing.yards(squareInches: calf * length * 2, spi: g.spi, factor: 1.1)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "Stitch marker", "Tapestry needle"], finished: "\(fits(caston, g, "calf", calf)), narrowing to \(Sizing.inches(Double(narrow) / g.spi)) at the ankle, \(Sizing.inches(length)) long", gauge: g, round: true)
    }

    /// A garter triangle worked from the middle of the top edge down, four stitches wider every other row.
    static func shawl(wingspan: Double, gauge g: Gauge) -> PatternPlan {
        let pairs = max(8, Int(((wingspan * g.spi * 1.3 - 5) / 4).rounded()))
        let last = 5 + pairs * 4
        var b = PlanBuilder()
        b.section = "Shawl"
        b.action("Cast on 5 stitches. Mark the center stitch and move the marker up as you go.", stitches: 5)
        b.row("Knit", stitches: 5)
        b.work(["K2, yo, knit to the center stitch, yo, k1, yo, knit to the last 2 stitches, yo, k2", "Knit"], rows: pairs * 2, stitches: 9, delta: 4)
        b.section = "Finishing"
        b.action("Bind off all \(last) stitches loosely. Weave in the ends and block to open up the fabric.")
        let yards = Sizing.yards(squareInches: wingspan * wingspan / 4, spi: g.spi, factor: 0.9)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(40)) circular needle, worked flat", "Removable stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(wingspan)) across, \(Sizing.inches(wingspan / 2)) deep after blocking", gauge: g)
    }

    /// A garter scarf that starts at a point, widens to the middle and narrows back, to tie at the neck.
    static func neckScarf(length: Double, width: Double, gauge g: Gauge) -> PatternPlan {
        let widest = Sizing.stitches(width, per: g.spi, minimum: 8)
        let total = Sizing.rows(length, per: g.spi * 2, even: true)
        // Shape on every `interval`th row so each taper takes about two fifths of the length.
        let interval = min(12, max(2, 2 * Int(Double(total) * 0.4 / Double(widest - 3) / 2)))
        let taper = (widest - 3) * interval
        let middle = max(2, even(Double(total - taper * 2)))
        let plain = Array(repeating: "Knit", count: interval - 1)
        var b = PlanBuilder()
        b.section = "Increase"
        b.action("Cast on 3 stitches.", stitches: 3)
        b.work(["K1, M1, knit to the end"] + plain, rows: taper, stitches: 4, delta: 1)
        b.section = "Middle"
        b.work(["Knit"], rows: middle, stitches: widest)
        b.section = "Decrease"
        b.work(["K1, k2tog, knit to the end"] + plain, rows: taper, stitches: widest - 1, delta: -1)
        b.section = "Finishing"
        b.action("Bind off the last 3 stitches. Weave in the ends.")
        let yards = Sizing.yards(squareInches: width * length * 0.6, spi: g.spi, factor: 1.25)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) needles", "Tapestry needle"], finished: "\(Sizing.inches(Double(taper * 2 + middle) / (g.spi * 2))) long, \(Sizing.inches(width)) at the widest", gauge: g)
    }

    /// A headband of rope cables on a purl ground, knit flat and seamed at the back.
    static func cableHeadband(head: Double, width: Double, gauge g: Gauge) -> PatternPlan {
        // Cables pull the fabric in by about a fifth.
        let target = width * g.spi * 1.2
        let cables = max(1, Int((target - 6) / 8))
        // Up to 3 extra purl stitches a side, so the band tracks the width asked for between cable counts.
        let side = min(3, max(0, Int(((target - Double(cables * 8 + 6)) / 2).rounded())))
        let caston = cables * 8 + 6 + side * 2
        let rows = max(16, 8 * Int((head * 0.92 * g.rpi / 8).rounded()))
        let close = side > 0 ? "to the last \(side + 2) stitches, p\(side), k2" : "to the last 2 stitches, k2"
        let right = "K2, p\(side + 2), *k6, p2; repeat from * \(close)"
        let wrong = "K\(side + 4), *p6, k2; repeat from * to the last \(side + 2) stitches, k\(side + 2)"
        let cross = "K2, p\(side + 2), *C6F, p2; repeat from * \(close)"
        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work([right, wrong, right, wrong, right, wrong, cross, wrong], rows: rows, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off in pattern. Sew the cast-on edge to the bound-off edge and weave in the ends.")
        let yards = Sizing.yards(squareInches: head * Double(caston) / (g.spi * 1.2), spi: g.spi, factor: 1.4)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) needles", "Cable needle", "Tapestry needle"], finished: "Fits a \(Sizing.inches(head)) head, \(Sizing.inches(Double(caston) / (g.spi * 1.2))) wide", gauge: g)
    }

    /// A hood worked in the round from the neck up, opened for the face and closed like a hat.
    static func balaclava(head: Double, gauge g: Gauge) -> PatternPlan {
        let around = Sizing.stitches(head * 0.9, per: g.spi, multiple: 8, minimum: 40)
        let face = even(Double(around) * 0.3, minimum: 8)
        let faceRows = Sizing.rows(head * 0.2, per: g.rpi, even: true, minimum: 6)
        let crown = crownRounds(wedge: around / 8)
        let top = max(2, Sizing.rows(head * 0.24, per: g.rpi) - crown.count)
        let side = Int((Double(faceRows) * 0.75).rounded())
        let edging = (face + side) * 2

        var b = PlanBuilder()
        b.section = "Neck"
        b.action("Loosely cast on \(around) stitches, so the neck stretches over the head. Join in the round without twisting and place a marker.", stitches: around)
        b.work(["*K2, p2; repeat from * around"], rows: Sizing.rows(head * 0.2, per: g.rpi, minimum: 6), stitches: around)
        b.work(["Knit"], rows: Sizing.rows(head * 0.07, per: g.rpi, minimum: 2), stitches: around)
        b.section = "Face Opening"
        b.row("Bind off \(face) stitches, knit to the end, turn", stitches: around - face)
        // An odd count of rows here ends on a purl row, so the right side faces for the rejoin.
        b.work(["Purl to the end, turn", "Knit to the end, turn"], rows: faceRows - 1, stitches: around - face)
        b.row("Knit to the end. Do not turn", stitches: around - face)
        b.action("With the right side still facing, cast on \(face) stitches with the backward loop method, then join in the round again. Move the marker here: this is the new start of the round.", stitches: around)
        b.section = "Top"
        b.work(["Knit"], rows: top, stitches: around)
        b.section = "Crown"
        for round in switching(crown, g) { b.row(round.text, stitches: round.stitches) }
        b.action("Cut the yarn, thread it through the last 8 stitches and pull tight.")
        b.section = "Face Edging"
        b.action("Join new yarn at a lower corner of the face opening. With the smaller needles, pick up and knit \(edging) stitches around the face opening. Join in the round.", stitches: edging)
        b.work(["*K1, p1; repeat from * around"], rows: Sizing.rows(0.75, per: g.rpi, minimum: 3), stitches: edging)
        b.section = "Finishing"
        b.action("Bind off loosely in pattern. Weave in the ends.")

        let yards = Sizing.yards(squareInches: Double(around) / g.spi * head * 0.75, spi: g.spi, factor: 1.1)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(16)) circular needle", "Double-pointed needles in the same size for the crown", "\(g.ribNeedle.label) double-pointed needles for the face edging", "Stitch marker", "Tapestry needle"], finished: fits(around, g, "head", head), gauge: g, round: true)
    }

    // MARK: Sweater

    /// Which yoke rounds increase the body and which the sleeves. The part that needs more increases
    /// works them every other round, and every round at the start when the yoke is too short for that.
    /// The other part increases on some of those rounds, spread evenly from the neck to the underarm,
    /// so a large sleeve does not finish growing long before the body does.
    static func raglanSchedule(body: Int, sleeves: Int, rounds: Int) -> [(body: Bool, sleeves: Bool)] {
        let major = max(body, sleeves), minor = min(body, sleeves)
        let packed = max(0, 2 * major - rounds)
        let majorAt = Array(0..<packed) + (0..<max(0, major - packed)).map { packed + 2 * $0 }
        let span = Double((majorAt.last ?? 0) + 1)
        // Never on back-to-back rounds when there is room to space them out.
        let gap = minor > 0 && span / Double(minor) >= 2 ? 2 : 1
        var minorAt = Set<Int>()
        var next = 0, previous = -gap
        for k in 0..<minor {
            let target = (Double(k) + 0.5) * span / Double(minor) - 0.5
            let last = major - minor + k
            while next < last, majorAt[next] < previous + gap { next += 1 }
            var best = next
            for index in next...last where abs(Double(majorAt[index]) - target) < abs(Double(majorAt[best]) - target) { best = index }
            minorAt.insert(majorAt[best])
            previous = majorAt[best]
            next = best + 1
        }
        let majorSet = Set(majorAt)
        return (0..<rounds).map { round in
            let a = majorSet.contains(round), b = minorAt.contains(round)
            return body >= sleeves ? (a, b) : (b, a)
        }
    }

    /// Writes rounds as steps: a run of one round, or of an increase round and a plain one, becomes one step.
    private static func grouped(_ b: inout PlanBuilder, _ rounds: [(text: String, stitches: Int)], from start: Int) {
        var index = 0
        while index < rounds.count {
            let first = rounds[index]
            let gain = first.stitches - (index == 0 ? start : rounds[index - 1].stitches)
            var same = 1
            while index + same < rounds.count, rounds[index + same].text == first.text { same += 1 }
            var pairs = 0
            while gain > 0, index + 2 * pairs + 1 < rounds.count, rounds[index + 2 * pairs].text == first.text, rounds[index + 2 * pairs + 1].text == "Knit" { pairs += 1 }
            if 2 * pairs > same {
                b.work([first.text, "Knit"], rows: 2 * pairs, stitches: first.stitches, delta: gain)
                index += 2 * pairs
            } else {
                b.work([first.text], rows: same, stitches: first.stitches, delta: gain)
                index += same
            }
        }
    }

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
    /// `chest` is the finished chest. `wearer` is the chest it was sized from, when the knitter gave one.
    static func raglan(chest: Double, wearer: Double? = nil, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> Raglan {
        let body = Sizing.stitches(chest, per: g.spi, multiple: 4)
        // Larger sizes need a little more room in the upper arm than a straight line gives.
        let arm = max(chest * 0.31 + 1.6, chest > 48 ? chest * 0.34 : 0)
        let sleeve = even(arm * g.spi, minimum: 12)
        let underarm = min(even(Double(body) * 0.07), sleeve - 8)
        let panel = (body - 2 * underarm) / 2
        let sleeveTop = sleeve - underarm
        let backAtNeck = min(even(min(chest * 0.1 + 3.5, 8.5) * g.spi, minimum: 4), panel - 2)
        let sleeveAtNeck = min(even(2 * g.spi, minimum: 4), sleeveTop - 2)
        let bodyIncreases = (panel - backAtNeck) / 2
        let sleeveIncreases = (sleeveTop - sleeveAtNeck) / 2
        let neck = 2 * backAtNeck + 2 * sleeveAtNeck

        let total = max(bodyIncreases, sleeveIncreases)
        let depth = chest * 0.125 + 3.5
        let yokeRounds = max(Sizing.rows(depth, per: g.rpi), total)

        var b = PlanBuilder()
        b.section = "Neckband"
        b.action("With the smaller \(Sizing.cable(16)) needle, loosely cast on \(neck) stitches, so the neck stretches over the head. Join in the round without twisting and place a marker.", stitches: neck)
        b.work(["*K1, p1; repeat from * around"], rows: Sizing.rows(1, per: g.rpi, minimum: 4), stitches: neck)

        // Short rows across the back and sleeves raise the back of the neck, so the front sits lower
        // at the throat. Each pair turns a little further into the front than the last.
        b.section = "Back Neck"
        b.row("Change to the larger needle. K\(sleeveAtNeck) sleeve, place marker, k\(backAtNeck) front, place marker, k\(sleeveAtNeck) sleeve, place marker, k\(backAtNeck) back", stitches: neck)
        let pairs = min(4, max(2, Sizing.rows(1, per: g.rpi) / 2))
        let reach = max(1, min(Int((0.5 * g.spi).rounded()), (backAtNeck / 2 - 1) / (pairs - 1)))
        b.row("Short row: knit to the marker before the front, turn", stitches: neck)
        b.row("Make a double stitch, then purl to the marker on the other side of the front, turn", stitches: neck)
        b.work(["Make a double stitch, knit to the double stitch, knit it as one stitch, k\(reach), turn", "Make a double stitch, purl to the double stitch, purl it as one stitch, p\(reach), turn"], rows: 2 * (pairs - 1), stitches: neck)
        b.row("Make a double stitch, then knit to the start of the round", stitches: neck)
        b.row("Knit 1 round, knitting each double stitch as one stitch", stitches: neck)

        b.section = "Yoke"
        var onNeedle = neck
        var rounds: [(text: String, stitches: Int)] = []
        var moved = false
        for (body, sleeves) in raglanSchedule(body: bodyIncreases, sleeves: sleeveIncreases, rounds: yokeRounds) {
            onNeedle += (body ? 4 : 0) + (sleeves ? 4 : 0)
            var text = switch (body, sleeves) {
            case (true, true): "*Inc across; repeat from * 3 more times"
            case (true, false): "Knit the sleeve. Inc across the front. Knit the sleeve. Inc across the back"
            case (false, true): "Inc across the sleeve. Knit the front. Inc across the sleeve. Knit the back"
            case (false, false): "Knit"
            }
            // Said once, on the round where the stitches outgrow the short needle.
            if !moved, Double(onNeedle) / g.spi > 24 {
                text += ". Move the stitches to the \(Sizing.cable(32)) needle"
                moved = true
            }
            rounds.append((text, onNeedle))
        }
        grouped(&b, rounds, from: neck)

        b.section = "Divide"
        b.action("Slip the \(sleeveTop) stitches of the first sleeve to waste yarn, removing the markers on each side.")
        b.action("Under the arm, cast on \(underarm) stitches with the backward loop method. Knit the \(panel) front stitches.")
        b.action("Slip the \(sleeveTop) stitches of the second sleeve to waste yarn, removing the markers on each side.")
        b.row("Under the arm, cast on \(underarm) stitches. Knit the \(panel) back stitches. Place a marker here for the new start of the round", stitches: body)

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
        // A cuff no wider than 10.5 in, reached with decreases at least 4 rounds apart: a short sleeve
        // keeps the stitches it has no room to lose, where packing the decreases would make a funnel.
        let wanted = max(0, (sleeve - even(min(chest * 0.14 + 3, 10.5) * g.spi, minimum: 8)) / 2)
        let decreases = min(wanted, max(0, (sleeveRounds - straight) / 4))
        let spacing = decreases > 0 ? (sleeveRounds - straight) / decreases : 0
        let cuff = sleeve - 2 * decreases
        for name in ["First Sleeve", "Second Sleeve"] {
            b.section = name
            b.action("Return the \(sleeveTop) held sleeve stitches to the larger needles. Join new yarn at the middle of the underarm.", stitches: sleeveTop)
            b.action("Pick up and knit \(underarm / 2) stitches, knit the \(sleeveTop) sleeve stitches, then pick up and knit \(underarm / 2) more. Place a marker for the start of the round.", stitches: sleeve)
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
        let fit = wearer.map { ", to fit a \(Sizing.inches($0)) chest with \(Sizing.inches(finishedChest - $0)) of ease" } ?? ""
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: ["\(g.needle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(32))", "\(g.ribNeedle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(32)), for the ribbing", "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop", "4 stitch markers, waste yarn, tapestry needle"],
            finished: "Finished chest \(Sizing.inches(finishedChest))\(fit). Body \(Sizing.inches(length)) and sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            gauge: g, round: true
        )
        return Raglan(plan: plan, neck: neck, body: body, sleeve: sleeve, cuff: cuff, underarm: underarm, backAtNeck: backAtNeck, sleeveAtNeck: sleeveAtNeck, bodyIncreases: bodyIncreases, sleeveIncreases: sleeveIncreases, yokeRounds: yokeRounds)
    }
}
