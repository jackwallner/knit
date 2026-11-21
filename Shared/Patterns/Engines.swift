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
        /// A stitch pattern for the shape's main fabric, in place of its own. Nil keeps the shape as it is.
        var stitch: Stitch?

        static let plain = Fit()
    }

    static func lcm(_ a: Int, _ b: Int) -> Int {
        func gcd(_ x: Int, _ y: Int) -> Int { y == 0 ? x : gcd(y, x % y) }
        return a / gcd(a, max(1, b)) * max(1, b)
    }

    // MARK: Wording

    /// A piece worked in the round counts its gauge in rounds, the way the rest of its pattern does.
    static func gaugeLine(_ g: Gauge, round: Bool) -> String {
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
    static func longCircular(_ stitches: Int, _ g: Gauge, flat: Bool) -> String {
        Double(stitches) / g.spi > 45 ? "\(g.needle.label) \(Sizing.cable(40)) circular needle\(flat ? ", worked flat" : "")"
            : "\(g.needle.label) circular needle, \(Sizing.cable(32)) or longer\(flat ? ", worked flat" : "")"
    }

    /// Closes a pattern. The yarn asked for is never less than what the written rows use, plus a reserve.
    /// `round` is true for a piece worked in the round.
    static func pattern(_ b: PlanBuilder, estimate: Int, yarnNote: String = "", tools: [String], finished: String, gauge g: Gauge, round: Bool = false) -> PatternPlan {
        let yards = max(estimate, Sizing.yards(worked: b.steps, spi: g.spi))
        return PatternPlan(steps: b.steps, materials: [yarnLine(yards, g) + yarnNote] + tools + [gaugeLine(g, round: round)], finished: finished, yards: yards)
    }

    /// "19.5 in around, to fit a 22 in head": the number a knitter checks against the swatch, then who it fits.
    static func fits(_ stitches: Int, _ g: Gauge, _ part: String, _ size: Double) -> String {
        "\(Sizing.inches(Double(stitches) / g.spi)) around, to fit a \(Sizing.inches(size)) \(part)"
    }

    /// Wording for `count` increases spread evenly over `stitches` stitches.
    static func spread(_ count: Int, over stitches: Int) -> String {
        let gap = max(1, stitches / count)
        let rest = stitches - gap * count
        // Leftover stitches go one to a repeat, so the increases never bunch at one side.
        guard rest > 0, rest < count else { return "Work (k\(gap), M1) \(count) times" + (rest > 0 ? ", knit the last \(rest)" : "") }
        return "Work (k\(gap + 1), M1) \(rest) times, then (k\(gap), M1) \(count - rest) times"
    }

    static func even(_ value: Double, minimum: Int = 2) -> Int { max(minimum, 2 * Int((value / 2).rounded())) }

    // MARK: Hats

    /// The negative ease a hat is cast on at: 5 to 15 percent smaller than the head, so it hugs without squeezing.
    static let hatEase = 0.85...0.95

    /// A cast-on count for `head` inches at this gauge: a multiple of `multiple` whose ease lands in
    /// `hatEase`, nearest `share` of the head. A count within 3 percent of that which also divides into
    /// the crown's 8 wedges wins, so most hats need no adjusting round. Nil when no multiple lands in the band.
    static func hatCount(head: Double, share: Double, spi: Double, multiple: Int) -> Int? {
        let low = Int((head * hatEase.lowerBound * spi / Double(multiple)).rounded(.up))
        let high = Int((head * hatEase.upperBound * spi / Double(multiple)).rounded(.down))
        guard low <= high else { return nil }
        let counts = (low...high).map { $0 * multiple }.filter { $0 >= 24 }
        let wanted = head * share * spi
        func nearest(_ list: [Int]) -> Int? { list.min { abs(Double($0) - wanted) < abs(Double($1) - wanted) } }
        return nearest(counts.filter { $0 % 8 == 0 && abs(Double($0) - wanted) <= head * 0.03 * spi }) ?? nearest(counts)
    }

    /// The round that brings a count to a multiple of 8 for the crown, worked as the last round of the body.
    static func adjusting(_ from: Int, to: Int) -> String {
        if to > from { return "Knit, increasing \(to - from) evenly: " + lowerFirst(spread(to - from, over: from)) }
        let count = from - to
        let gap = from / count
        let rest = from - gap * count
        func group(_ width: Int) -> String { width > 2 ? "k\(width - 2), k2tog" : "k2tog" }
        let groups = rest > 0 ? "work (\(group(gap + 1))) \(rest) times, then (\(group(gap))) \(count - rest) times" : "work (\(group(gap))) \(count) times"
        return "Knit, decreasing \(count) evenly: \(groups)"
    }

    static func lowerFirst(_ text: String) -> String { text.prefix(1).lowercased() + text.dropFirst() }

    static func hat(_ style: HatStyle, head: Double, gauge g: Gauge, fit: Fit = .plain) -> PatternPlan {
        if let stitch = fit.stitch, style != .rolled { return texturedHat(style, stitch, head: head, gauge: g, fit: fit) }
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
            b.action("Sew the cast-on edge of each ear to the crown, right side out, one on each side of the top and about \(Sizing.inches(head * 0.2)) apart. Line them up with the face: the front of the hat is the half that begins at the start of the round, so center the pair over it. Weave in the ends.")
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

    /// A pixie bonnet: a rectangle knit flat from the ribbed face edge back, folded and seamed from the
    /// crown down the back of the head. A ribbed band picked up along the neck carries two i-cord ties,
    /// each finished with a pompom.
    static func bonnet(head: Double, gauge g: Gauge) -> PatternPlan {
        let width = head * 0.62
        let depth = head * 0.33
        let caston = Sizing.stitches(width, per: g.spi, multiple: 4, extra: 2, minimum: 26)
        let brim = Sizing.rows(head * 0.055, per: g.rpi, even: true, minimum: 4)
        // An even count of body rows ends on a wrong-side row, so the bind off is worked from the right side.
        let body = max(4, Sizing.rows(depth, per: g.rpi, even: true) - brim)
        let neck = 4 * Int((2 * depth * g.spi * 0.85 / 4).rounded()) + 2
        let neckRows = Sizing.rows(0.75, per: g.rpi, even: true, minimum: 4)
        let tie = Sizing.rows(head * 0.4, per: g.rpi, minimum: 24)
        let pompom = head < 19 ? 1.25 : 1.75

        var b = PlanBuilder()
        b.section = "Brim"
        b.action("With the smaller needles, cast on \(caston) stitches.", stitches: caston)
        b.work(["K2, *p2, k2; repeat from * to the end", "P2, *k2, p2; repeat from * to the end"], rows: brim, stitches: caston)
        b.section = "Body"
        b.action("Change to the larger needles.")
        b.work(["Knit", "Purl"], rows: body, stitches: caston)
        b.section = "Back"
        b.action("Bind off. Fold the piece in half, right sides together, and sew the bound-off edge closed: this seam runs from the crown down the back of the head. Turn the bonnet right side out.")
        b.section = "Neckband"
        b.action("With the smaller needles and the right side facing, pick up and knit \(neck) stitches along the lower edge, from one front corner to the other.", stitches: neck)
        b.work(["P2, *k2, p2; repeat from * to the end", "K2, *p2, k2; repeat from * to the end"], rows: neckRows, stitches: neck)
        b.action("Bind off in pattern.")
        b.section = "Ties"
        b.action("With two double-pointed needles, cast on 3 stitches.", stitches: 3)
        b.work(["Slide the stitches to the other end of the needle, pull the yarn across the back and k3"], rows: tie, stitches: 3)
        b.action("Cut the yarn, thread it through the 3 stitches and pull tight. Make a second tie the same way.")
        b.section = "Finishing"
        b.action("Make two pompoms about \(Sizing.inches(pompom)) across and sew one to the end of each tie. Sew the other end of each tie to a front corner of the neckband. Weave in the ends.")

        let yards = Sizing.yards(squareInches: width * depth * 1.2, spi: g.spi, factor: 1.15)
        return pattern(b, estimate: yards, tools: ["\(g.ribNeedle.label) needles for the ribbing", "\(g.needle.label) needles for the body", "\(g.needle.label) double-pointed needles for the ties", "Pompom maker or a piece of card", "Tapestry needle"], finished: "Fits a \(Sizing.inches(head)) head, \(Sizing.inches(Double(caston) / g.spi)) around the face", gauge: g)
    }

    /// A beret worked from the band up: a snug ribbed band, one round of increases out to the wide body,
    /// then a top decreased in 8 wedges on every other round, which keeps it flat.
    static func beret(head: Double, gauge g: Gauge) -> PatternPlan {
        let band = hatCount(head: head, share: 0.9, spi: g.spi, multiple: 2) ?? Sizing.stitches(head * 0.9, per: g.spi, multiple: 2, minimum: 24)
        let wide = Sizing.stitches(head * 1.3, per: g.spi, multiple: 8, minimum: band + 16)
        let bandRounds = Sizing.rows(head * 0.05, per: g.rpi, minimum: 4)
        let bodyRounds = Sizing.rows(head * 0.1, per: g.rpi, minimum: 4)
        var top: [(text: String, stitches: Int)] = []
        var width = wide / 8
        while width > 1 {
            top.append((width > 2 ? "*K\(width - 2), k2tog; repeat from * around" : "*K2tog; repeat from * around", (width - 1) * 8))
            width -= 1
            if width > 1 { top.append(("Knit", width * 8)) }
        }
        let small = Double(band) / g.spi < 16
        let across = Double(wide) / g.spi / Double.pi

        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(band) stitches with the smaller needle\(small ? "s" : ""). Join in the round without twisting and place a marker.", stitches: band)
        b.work(["*K1, p1; repeat from * around"], rows: bandRounds, stitches: band)
        b.section = "Body"
        b.row("Change to the larger needle. " + spread(wide - band, over: band), stitches: wide)
        b.work(["Knit"], rows: bodyRounds, stitches: wide)
        b.section = "Top"
        for round in switching(top, g) { b.row(round.text, stitches: round.stitches) }
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 8 stitches and pull tight. Weave in the ends. Wet the beret and dry it stretched over a dinner plate about \(Sizing.inches(across.rounded())) across, so the top lies flat.")

        let yards = Sizing.yards(squareInches: Double(wide) / g.spi * head * 0.3, spi: g.spi, factor: 1.1)
        let needles = small
            ? ["\(g.ribNeedle.label) double-pointed needles for the band, or a long circular for magic loop", "\(g.needle.label) \(Sizing.cable(16)) circular needle for the body", "Double-pointed needles in the larger size for the top"]
            : ["\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the band", "\(g.needle.label) \(Sizing.cable(16)) circular needle for the body", "Double-pointed needles in the larger size for the top"]
        return pattern(b, estimate: yards, tools: needles + ["Stitch marker", "Tapestry needle"], finished: fits(band, g, "head", head), gauge: g, round: true)
    }

    /// A rounded ear: stockinette narrowed at both edges to a blunt top, then a garter rim picked up
    /// around it. Its rows sit in a section ending "Ear", which colorwork reads as trim.
    static func ear(_ b: inout PlanBuilder, _ name: String, _ g: Gauge) {
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
    static func switching(_ rounds: [(text: String, stitches: Int)], _ g: Gauge) -> [(text: String, stitches: Int)] {
        var rounds = rounds
        if let index = rounds.firstIndex(where: { Double($0.stitches) / g.spi < 14 && $0.text != "Knit" }) {
            rounds[index].text += ". Change to double-pointed needles when the stitches no longer reach around"
        }
        return rounds
    }

    /// Eight wedges, decreased every other round for the first half and every round after, down to 8 stitches.
    static func crownRounds(wedge: Int) -> [(text: String, stitches: Int)] {
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
        if let stitch = fit.stitch { return texturedScarf(stitch, width: width, length: length, gauge: g) }
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
        if let stitch = fit.stitch { return texturedCowl(stitch, around: around, height: height, gauge: g, fit: fit) }
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
        if let stitch = fit.stitch { return texturedBlanket(stitch, width: width, length: length, gauge: g) }
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
        if let stitch = fit.stitch { return texturedEarWarmer(stitch, head: head, width: width, gauge: g, fit: fit) }
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
    /// Worked `flat`, the packed rows come in pairs, so every spaced increase is on a right-side row.
    static func raglanSchedule(body: Int, sleeves: Int, rounds: Int, flat: Bool = false) -> [(body: Bool, sleeves: Bool)] {
        let major = max(body, sleeves), minor = min(body, sleeves)
        let tight = max(0, 2 * major - rounds)
        let packed = flat ? min(major, tight + tight % 2) : tight
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
    static func grouped(_ b: inout PlanBuilder, _ rounds: [(text: String, stitches: Int)], from start: Int) {
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

    /// Both sleeves of a top-down raglan, from the held stitches to the cuff, in the round. Returns the cuff count.
    static func raglanSleeves(_ b: inout PlanBuilder, _ fit: RaglanFit, chest: Double, length sleeveLength: Double, gauge g: Gauge) -> Int {
        let sleeve = fit.sleeve, sleeveTop = fit.sleeveTop, underarm = fit.underarm
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
        return cuff
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

    /// The numbers every top-down raglan shares, the pullover, the cardigan and the child's raglan: the
    /// stitches at the neck, how many each part gains in the yoke, and the stitches at the underarm.
    struct RaglanFit: Equatable, Sendable {
        var body: Int
        var arm: Double
        var sleeve: Int
        var underarm: Int
        var panel: Int
        var sleeveTop: Int
        var backAtNeck: Int
        var sleeveAtNeck: Int
        var bodyIncreases: Int
        var sleeveIncreases: Int
        var depth: Double
        var yokeRounds: Int

        var neck: Int { 2 * backAtNeck + 2 * sleeveAtNeck }
    }

    /// `chest` is the finished chest. A child's raglan takes its upper arm and yoke depth from the Craft
    /// Yarn Council child sizes, worked from the chest it is for, so a small sweater is not cut like a
    /// shrunken adult one.
    static func raglanFit(chest: Double, wearer: Double?, child: Bool, gauge g: Gauge) -> RaglanFit {
        let body = Sizing.stitches(chest, per: g.spi, multiple: 4)
        let worn = wearer ?? chest - Design.sweaterEase
        // Larger sizes need a little more room in the upper arm than a straight line gives.
        let arm = child ? worn * 0.22 + 3.9 : max(chest * 0.31 + 1.6, chest > 48 ? chest * 0.34 : 0)
        let sleeve = even(arm * g.spi, minimum: 12)
        let underarm = min(even(Double(body) * 0.07), sleeve - 8)
        let panel = (body - 2 * underarm) / 2
        let sleeveTop = sleeve - underarm
        let backAtNeck = min(even(min(chest * 0.1 + 3.5, 8.5) * g.spi, minimum: 4), panel - 2)
        let sleeveAtNeck = min(even(2 * g.spi, minimum: 4), sleeveTop - 2)
        let bodyIncreases = (panel - backAtNeck) / 2
        let sleeveIncreases = (sleeveTop - sleeveAtNeck) / 2
        let total = max(bodyIncreases, sleeveIncreases)
        // A child's armhole is about a quarter of the chest, less an inch; the raglan line sits 3/4 in deeper.
        let depth = child ? worn * 0.25 - 0.25 : chest * 0.125 + 3.5
        let yokeRounds = max(Sizing.rows(depth, per: g.rpi), total)
        return RaglanFit(body: body, arm: arm, sleeve: sleeve, underarm: underarm, panel: panel, sleeveTop: sleeveTop, backAtNeck: backAtNeck, sleeveAtNeck: sleeveAtNeck, bodyIncreases: bodyIncreases, sleeveIncreases: sleeveIncreases, depth: depth, yokeRounds: yokeRounds)
    }

    /// A crew-neck pullover knit from the neck down in one piece. The body and
    /// the sleeves grow at their own rates, so large sizes keep a neck that fits.
    /// `chest` is the finished chest. `wearer` is the chest it was sized from, when the knitter gave one.
    static func raglan(chest: Double, wearer: Double? = nil, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge, child: Bool = false) -> Raglan {
        let shape = raglanFit(chest: chest, wearer: wearer, child: child, gauge: g)
        let body = shape.body, sleeve = shape.sleeve, underarm = shape.underarm, panel = shape.panel, sleeveTop = shape.sleeveTop
        let backAtNeck = shape.backAtNeck, sleeveAtNeck = shape.sleeveAtNeck, bodyIncreases = shape.bodyIncreases, sleeveIncreases = shape.sleeveIncreases
        let neck = shape.neck, depth = shape.depth, yokeRounds = shape.yokeRounds, arm = shape.arm
        // The long needle must be shorter than the body around: a small child's sweater uses a 24 in one.
        let long = child && Double(body) / g.spi < 32 ? 24 : 32

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
                text += ". Move the stitches to the \(Sizing.cable(long)) needle"
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

        let cuff = raglanSleeves(&b, shape, chest: chest, length: sleeveLength, gauge: g)
        b.section = "Finishing"
        b.action("Weave in the ends, closing any gaps at the underarms. Block to the finished measurements.")

        let finishedChest = Double(body) / g.spi
        let area = finishedChest * (length + depth) + (arm + Double(cuff) / g.spi) * sleeveLength + arm * depth
        let fit = wearer.map { ", to fit a \(Sizing.inches($0)) chest with \(Sizing.inches(finishedChest - $0)) of ease" } ?? ""
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: ["\(g.needle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(long))", "\(g.ribNeedle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(long)), for the ribbing", "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop", "4 stitch markers, waste yarn, tapestry needle"],
            finished: "Finished chest \(Sizing.inches(finishedChest))\(fit). Body \(Sizing.inches(length)) and sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            gauge: g, round: true
        )
        return Raglan(plan: plan, neck: neck, body: body, sleeve: sleeve, cuff: cuff, underarm: underarm, backAtNeck: backAtNeck, sleeveAtNeck: sleeveAtNeck, bodyIncreases: bodyIncreases, sleeveIncreases: sleeveIncreases, yokeRounds: yokeRounds)
    }

    // MARK: Building blocks for the larger library

    static func odd(_ value: Double, minimum: Int = 1) -> Int { max(minimum, 2 * Int(((value - 1) / 2).rounded()) + 1) }

    /// Writes rows as steps, folding a run that repeats one row, or a pair of rows whose second keeps the
    /// count, into one step. `start` is the count before the first row.
    static func runs(_ b: inout PlanBuilder, _ rows: [(text: String, stitches: Int)], from start: Int) {
        var index = 0
        var before = start
        while index < rows.count {
            let first = rows[index].stitches
            let delta = first - before
            var best = (period: 1, length: 1)
            for period in 1...2 where index + period <= rows.count {
                if period == 2, rows[index + 1].stitches != first { continue }
                var length = period
                while index + length < rows.count {
                    let row = rows[index + length]
                    guard row.text == rows[index + length % period].text, row.stitches == first + delta * (length / period) else { break }
                    length += 1
                }
                if length > best.length { best = (period, length) }
            }
            b.work((0..<best.period).map { rows[index + $0].text }, rows: best.length, stitches: first, delta: delta)
            before = rows[index + best.length - 1].stitches
            index += best.length
        }
    }

    /// A sock toe or a mitten top closed over its two sides, 4 stitches a decrease round: every other round
    /// until about half the stitches are left, then every round down to `last`. The start of the round and a
    /// marker halfway around are the two sides.
    static func wedge(from start: Int, to last: Int) -> [(text: String, stitches: Int)] {
        let decrease = "K1, ssk, knit to 3 stitches before the marker, k2tog, k1, slip the marker, k1, ssk, knit to the last 3 stitches, k2tog, k1"
        var rounds: [(text: String, stitches: Int)] = []
        var count = start
        while count > last {
            count -= 4
            rounds.append((decrease, count))
            if count > start / 2, count > last { rounds.append(("Knit", count)) }
        }
        return rounds
    }

    /// What a wedge closes on: about a quarter of the stitches, a multiple of 4 and never fewer than 8.
    static func wedgeEnd(_ stitches: Int) -> Int { min(stitches, max(8, 4 * Int((Double(stitches) / 16).rounded()))) }

    /// Spaces `count` buttonholes of 2 stitches each (k2tog, yo) evenly over `stitches`, `edge` stitches in
    /// from each end. Returns the stitches before each hole, then the stitches after the last one.
    static func buttonholeGaps(_ count: Int, over stitches: Int, edge: Int) -> [Int] {
        let inner = stitches - 2 * edge - 2 * count
        guard count > 1 else { return [edge + inner / 2, edge + inner - inner / 2] }
        let gap = inner / (count - 1), extra = inner % (count - 1)
        return [edge] + (0..<(count - 1)).map { gap + ($0 < extra ? 1 : 0) } + [edge]
    }

    /// The row or round that works the buttonholes in rib. `rest` finishes it after the last hole.
    static func buttonholeText(_ gaps: [Int], rest: String) -> String {
        var groups: [(gap: Int, times: Int)] = []
        for gap in gaps.dropFirst().dropLast() {
            if groups.last?.gap == gap { groups[groups.count - 1].times += 1 } else { groups.append((gap, 1)) }
        }
        let middle = groups.map { "(k2tog, yo, work \($0.gap) in rib) \($0.times == 1 ? "once" : "\($0.times) times")" }.joined(separator: ", then ")
        return "Work \(gaps[0]) in rib\(middle.isEmpty ? "" : ", then work " + middle). K2tog, yo, then \(rest)"
    }

    // MARK: Socks and mittens

    /// The rows that turn a round heel over `heel` stitches, and the stitches left. The first two rows set a
    /// cup in the middle, with as many stitches unworked on each side of it; every row after works one more of
    /// them into the cup, until none is left.
    static func heelTurn(_ heel: Int) -> (rows: [String], left: Int) {
        // The stitches purled in the middle of the second row: an odd count, so the cup is about a third of the heel.
        var middle = 1
        for count in stride(from: 1, through: max(1, heel - 5), by: 2) where abs(Double(count + 5) - Double(heel) / 3) < abs(Double(middle + 5) - Double(heel) / 3) {
            middle = count
        }
        let first = (heel + middle - 3) / 2
        let side = heel - first - 4
        var rows = ["Slip 1 purlwise, k\(first), ssk, k1, turn", "Slip 1 purlwise, p\(middle), p2tog, p1, turn"]
        for _ in 0..<(side / 2) {
            rows += ["Slip 1 purlwise, knit to 1 stitch before the gap, ssk, k1, turn", "Slip 1 purlwise, purl to 1 stitch before the gap, p2tog, p1, turn"]
        }
        if side % 2 == 1 {
            rows += ["Slip 1 purlwise, knit to 1 stitch before the gap, ssk, turn", "Slip 1 purlwise, purl to 1 stitch before the gap, p2tog, turn"]
        }
        return (rows, heel - rows.count)
    }

    struct Sock: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var heel: Int
        var flapRows: Int
        var turned: Int
        var pickedUp: Int
        var gussetDecreases: Int
        var toe: Int
    }

    /// Cuff-down socks, worked as a pair: a ribbed cuff and plain leg, a slip-stitch heel flap over half the
    /// stitches, a round heel turn, gusset stitches picked up along the flap and decreased back to the foot
    /// count, and a wedge toe grafted shut. The round starts at the side until the heel, then at the instep.
    static func socks(foot around: Double, length footLength: Double, leg: Double, gauge g: Gauge) -> Sock {
        // A tenth smaller than the foot, so the sock stays up and does not bag.
        let stitches = Sizing.stitches(around * 0.9, per: g.spi, multiple: 4, minimum: 16)
        let heel = stitches / 2
        let flapRows = heel
        let turn = heelTurn(heel)
        // One in each slipped stitch along the flap, and one more in the corner so no hole opens there.
        let pickedUp = flapRows / 2 + 1
        let gusset = (turn.left + 2 * pickedUp - heel) / 2
        let toeEnd = wedgeEnd(stitches)
        let toe = wedge(from: stitches, to: toeEnd)
        let cuff = Sizing.rows(min(1.5, leg * 0.3), per: g.rpi, minimum: 4)
        let legRounds = max(2, Sizing.rows(leg, per: g.rpi) - cuff)
        // The foot is knit 5 percent short and stretches to fit. It is measured from the back of the heel,
        // which sits a heel turn's depth behind the picked-up edge.
        let heelBack = Double(turn.rows.count) / g.rpi
        let afterPickUp = max(gusset, Sizing.rows(footLength * 0.95 - heelBack - Double(toe.count) / g.rpi, per: g.rpi))
        // Gusset decreases every other round, and every round at the start when the foot is too short for that.
        let packed = max(0, 2 * gusset - afterPickUp)
        let picked = turn.left + 2 * pickedUp + heel
        var gussetRounds: [(text: String, stitches: Int)] = []
        var count = picked
        let decrease = "Knit the instep to the marker, k1, ssk, knit to the last 3 stitches, k2tog, k1"
        for index in 0..<gusset {
            count -= 2
            gussetRounds.append((decrease, count))
            if index >= packed { gussetRounds.append(("Knit", count)) }
        }
        let footRounds = afterPickUp - gussetRounds.count

        var b = PlanBuilder()
        for sock in 1...2 {
            let name = "Sock \(sock)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(stitches) stitches. Join in the round without twisting and place a marker.", stitches: stitches)
            b.work(["*K2, p2; repeat from * around"], rows: cuff, stitches: stitches)
            b.section = "\(name) · Leg"
            b.work(["Knit"], rows: legRounds, stitches: stitches)
            b.section = "\(name) · Heel Flap"
            b.action("The heel flap is worked back and forth over the first \(heel) stitches of the round. Leave the other \(heel) on their needle for the instep.")
            b.work(["*Slip 1 purlwise with the yarn in back, k1; repeat from * across the heel, turn", "Slip 1 purlwise with the yarn in front, purl to the end of the heel, turn"], rows: flapRows, stitches: heel)
            b.section = "\(name) · Heel Turn"
            runs(&b, turn.rows.enumerated().map { ($1, heel - 1 - $0) }, from: heel)
            b.section = "\(name) · Gusset"
            b.action("With the right side facing, knit across the \(turn.left) heel stitches, then pick up and knit \(pickedUp) stitches along the edge of the flap, one in each slipped stitch and one in the corner.")
            b.action("Place a marker for the new start of the round. Knit the \(heel) instep stitches and place a marker. Pick up and knit \(pickedUp) stitches along the other edge of the flap the same way, then knit to the start of the round.", stitches: picked)
            runs(&b, gussetRounds, from: picked)
            b.section = "\(name) · Foot"
            b.work(["Knit"], rows: footRounds, stitches: stitches)
            b.section = "\(name) · Toe"
            runs(&b, toe, from: stitches)
            b.action("Cut the yarn, leaving a \(Sizing.inches(12)) tail. Put the \(toeEnd / 2) instep stitches on one needle and the \(toeEnd / 2) sole stitches on another, and graft them together with Kitchener stitch. Weave in the ends.")
        }
        let length = heelBack + Double(afterPickUp + toe.count) / g.rpi
        let yards = Sizing.yards(squareInches: around * 0.9 * (leg + footLength + 2) * 2, spi: g.spi, factor: 1.1)
        let plan = pattern(b, estimate: yards, yarnNote: ", wool with a little nylon wears longest", tools: ["\(g.needle.label) double-pointed needles, or a long circular for magic loop", "2 stitch markers", "Tapestry needle"], finished: "\(fits(stitches, g, "foot", around)). The foot is \(Sizing.inches(length)) from the back of the heel to the tip of the toe, and the leg \(Sizing.inches(Double(cuff + legRounds) / g.rpi)) from the cuff to the heel", gauge: g, round: true)
        return Sock(plan: plan, stitches: stitches, heel: heel, flapRows: flapRows, turned: turn.left, pickedUp: pickedUp, gussetDecreases: gusset, toe: toeEnd)
    }

    struct Mitten: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var increases: Int
        var gusset: Int
        var thumb: Int
        var top: Int
    }

    /// Mittens worked as a pair from the cuff up: a thumb gusset grown from a single stitch, held while the
    /// hand is knit and closed with a wedge top, then the thumb picked up and finished in the round. The thumb
    /// sits at the side, so either mitten fits either hand.
    static func mittens(hand: Double, length: Double, gauge g: Gauge) -> Mitten {
        // Half an inch of room over the hand.
        let stitches = Sizing.stitches(hand + 0.5, per: g.spi, multiple: 4, minimum: 16)
        // A thumb about a third of the hand. The gusset grows from 1 stitch, 2 at a time, and 1 more is
        // picked up over the gap, so the thumb is even.
        let increases = max(2, Int(((Double(stitches) * 0.36 - 2) / 2).rounded()))
        let gusset = 1 + 2 * increases
        let thumb = gusset + 1
        let cuff = Sizing.rows(min(2.5, hand * 0.33), per: g.rpi, minimum: 4)
        let before = Sizing.rows(0.25, per: g.rpi, minimum: 1)
        let gussetRounds = max(2 * increases, Sizing.rows(length * 0.3, per: g.rpi))
        let spacing = min(4, max(2, gussetRounds / increases))
        let extra = max(0, gussetRounds - spacing * increases)
        let topEnd = wedgeEnd(stitches)
        let top = wedge(from: stitches, to: topEnd)
        // From the top of the cuff, at the wrist, to the fingertips, with a quarter inch to spare.
        let worked = before + 1 + spacing * increases + extra + 1
        let handRounds = max(2, Sizing.rows(length + 0.25, per: g.rpi) - worked - top.count)
        var closing: [(text: String, stitches: Int)] = []
        var count = thumb
        while count > 8 {
            closing.append((count % 2 == 0 ? "*K2tog; repeat from * around" : "*K2tog; repeat from * to the last stitch, k1", (count + 1) / 2))
            count = (count + 1) / 2
        }
        let thumbRounds = max(2, Sizing.rows(length * 0.3, per: g.rpi) - closing.count)

        var b = PlanBuilder()
        for mitten in 1...2 {
            let name = "Mitten \(mitten)"
            b.section = "\(name) · Cuff"
            b.action("Cast on \(stitches) stitches with the smaller needles. Join in the round without twisting and place a marker.", stitches: stitches)
            b.work(["*K1, p1; repeat from * around"], rows: cuff, stitches: stitches)
            b.section = "\(name) · Thumb Gusset"
            b.row("Change to the larger needles and knit", stitches: stitches)
            b.work(["Knit"], rows: before - 1, stitches: stitches)
            b.row("K1, place a thumb marker, knit to the end. The stitch before the thumb marker is the gusset", stitches: stitches)
            b.work(["M1L, knit to the thumb marker, M1R, slip the marker, knit to the end"] + Array(repeating: "Knit", count: spacing - 1), rows: spacing * increases, stitches: stitches + 2, delta: 2)
            b.work(["Knit"], rows: extra, stitches: stitches + 2 * increases)
            b.row("Slip the \(gusset) gusset stitches to waste yarn and take out the thumb marker. Cast on 1 stitch over the gap with the backward loop method, then knit to the end", stitches: stitches)
            b.section = "\(name) · Hand"
            b.row("K\(stitches / 2), place a marker halfway around, knit to the end", stitches: stitches)
            b.work(["Knit"], rows: handRounds - 1, stitches: stitches)
            b.section = "\(name) · Top"
            runs(&b, top, from: stitches)
            b.action("Cut the yarn, leaving a \(Sizing.inches(12)) tail. Put the \(topEnd / 2) stitches of the back on one needle and the \(topEnd / 2) of the palm on another, and graft them together with Kitchener stitch.")
            b.section = "\(name) · Thumb"
            // Three picked up at the gap, then two taken away, so the base of the thumb closes without a hole.
            b.action("Return the \(gusset) held thumb stitches to the larger needles. Join new yarn at the gap and pick up and knit 3 stitches: one in the corner, one in the stitch cast on over the gap, and one in the other corner. Place a marker for the start of the round.", stitches: thumb + 2)
            b.row("Knit to the last 4 stitches, k2tog, k2tog", stitches: thumb)
            b.work(["Knit"], rows: thumbRounds - 1, stitches: thumb)
            runs(&b, closing, from: thumb)
            b.action("Cut the yarn, thread it through the last \(count) stitches and pull tight. Weave in the ends, closing any gap at the base of the thumb.")
        }
        let long = Double(worked + handRounds + top.count) / g.rpi
        let yards = Sizing.yards(squareInches: (hand + 0.5) * (length + hand * 0.4) * 2, spi: g.spi, factor: 1.1)
        let plan = pattern(b, estimate: yards, tools: ["\(g.ribNeedle.label) double-pointed needles for the cuff, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the hand and thumb, or a long circular", "2 stitch markers, waste yarn", "Tapestry needle"], finished: "\(fits(stitches, g, "hand", hand)), \(Sizing.inches(long)) from the wrist to the tip", gauge: g, round: true)
        return Mitten(plan: plan, stitches: stitches, increases: increases, gusset: gusset, thumb: thumb, top: topEnd)
    }

    // MARK: More hats

    /// A hat that starts with two garter earflaps, knit flat from their tips. They are joined in the round
    /// with stitches cast on between them for the back and the front, then the hat is worked up to a crown
    /// of 8 wedges. I-cord ties hang from the tips, if the knitter wants them.
    static func earflapHat(head: Double, gauge g: Gauge) -> PatternPlan {
        let around = hatCount(head: head, share: 0.9, spi: g.spi, multiple: 1) ?? Sizing.stitches(head * 0.9, per: g.spi, minimum: 24)
        let top = max(24, 8 * ((around + 3) / 8))
        let crown = crownRounds(wedge: top / 8)
        // Each flap covers about a fifth of the way around, over the ear.
        let flap = max(5, odd(Double(around) * 0.19))
        let increases = (flap - 3) / 2
        var flapRows = max(2 + 2 * increases, Sizing.rows(head * 0.15, per: g.spi * 2))
        flapRows += flapRows % 2
        let rest = around - 2 * flap
        let back = rest / 3
        let front = rest - back
        let border = Sizing.rows(0.75, per: g.spi * 2, even: true, minimum: 4)
        let height = head * 0.37
        let bodyRounds = max(4, Sizing.rows(height - Double(border) / (g.spi * 2), per: g.rpi) - crown.count)
        let small = Double(around) / g.spi < 16
        let tie = Sizing.rows(head * 0.4, per: g.rpi, minimum: 6)

        var b = PlanBuilder()
        for (index, name) in ["First Earflap", "Second Earflap"].enumerated() {
            b.section = name
            b.action("Cast on 3 stitches.", stitches: 3)
            b.row("Knit", stitches: 3)
            b.work(["K1, M1L, knit to the last stitch, M1R, k1", "Knit"], rows: 2 * increases, stitches: 5, delta: 2)
            b.work(["Knit"], rows: flapRows - 1 - 2 * increases, stitches: flap)
            b.action(index == 0 ? "Cut the yarn and slip the \(flap) stitches to a spare needle." : "Cut the yarn and leave the \(flap) stitches on their needle.")
        }
        b.section = "Brim"
        b.action("Join new yarn. With the \(small ? "double-pointed needles" : "\(Sizing.cable(16)) circular needle") in your right hand, cast on \(back / 2) stitches with the backward loop method. Hold the second earflap's needle in your left hand and knit its \(flap) stitches onto the right needle. Cast on \(front) stitches the same way, knit the first earflap's \(flap) stitches off its spare needle the same way, then cast on \(back - back / 2) more. Join in the round, without twisting, and place a marker at the middle of the back.", stitches: around)
        b.work(["Purl", "Knit"], rows: border, stitches: around)
        b.section = "Body"
        b.work(["Knit"], rows: bodyRounds - (top == around ? 0 : 1), stitches: around)
        if top != around { b.row(adjusting(around, to: top), stitches: top) }
        b.section = "Crown"
        for round in small ? crown : switching(crown, g) { b.row(round.text, stitches: round.stitches) }
        b.action("Cut the yarn, thread it through the last 8 stitches and pull tight.")
        b.section = "Ties"
        for side in ["first", "second"] {
            b.action("Optional: with 2 double-pointed needles, pick up and knit 3 stitches at the tip of the \(side) earflap.", stitches: 3)
            b.work(["K3, then slide the stitches to the other end of the needle without turning, pulling the yarn snug behind them"], rows: tie, stitches: 3)
            b.action("Cut the yarn, thread it through the 3 stitches and pull tight.")
        }
        b.section = "Finishing"
        b.action("Weave in the ends.")

        let flapDepth = Double(flapRows) / (g.spi * 2)
        let yards = Sizing.yards(squareInches: Double(around) / g.spi * height + Double(flap) / g.spi * flapDepth, spi: g.spi, factor: 1.15)
        let needles = small ? ["\(g.needle.label) double-pointed needles, or a long circular for magic loop"]
            : ["\(g.needle.label) \(Sizing.cable(16)) circular needle", "Double-pointed needles in the same size for the crown and ties"]
        return pattern(b, estimate: yards, tools: needles + ["A spare needle to hold the first earflap", "Stitch marker", "Tapestry needle"], finished: "\(fits(around, g, "head", head)), with earflaps \(Sizing.inches(flapDepth)) deep", gauge: g)
    }

    struct CabledHat: Equatable, Sendable {
        var plan: PatternPlan
        var cables: Int
        var stitches: Int
    }

    /// A beanie of rope cables, 6 knit stitches and 2 purls each, over a k2, p2 brim whose purls line up with
    /// the cables' purls. The crown narrows inside every cable at once, so each one runs up into the top.
    static func cabledBeanie(head: Double, gauge g: Gauge) -> CabledHat {
        // Cables pull the fabric in by about a fifth: a repeat of 8 stitches spans this many inches.
        let span = 8 / (g.spi * 1.2)
        let low = Int((head * hatEase.lowerBound / span).rounded(.up)), high = Int((head * hatEase.upperBound / span).rounded(.down))
        let wanted = head * 0.9 / span
        let inBand = low <= high ? (low...high).min { abs(Double($0) - wanted) < abs(Double($1) - wanted) } : nil
        let cables = max(3, inBand ?? Int(wanted.rounded()))
        let stitches = cables * 8
        let around = Double(stitches) / (g.spi * 1.2)

        let decreases: [(text: String, each: Int)] = [
            ("*P2tog, k6; repeat from * around", 7), ("*P1, ssk, k2, k2tog; repeat from * around", 5),
            ("*P1, ssk, k2tog; repeat from * around", 3), ("*P1, k2tog; repeat from * around", 2), ("*K2tog; repeat from * around", 1),
        ]
        let plain = [7: "*P1, k6; repeat from * around", 5: "*P1, k4; repeat from * around", 3: "*P1, k2; repeat from * around", 2: "*P1, k1; repeat from * around"]
        var finals: [(text: String, stitches: Int)] = []
        var closing = cables
        while closing > 10 {
            finals.append((closing % 2 == 0 ? "*K2tog; repeat from * around" : "*K2tog; repeat from * to the last stitch, k1", (closing + 1) / 2))
            closing = (closing + 1) / 2
        }
        // A crown about as tall as the hat's radius, with plain rounds spaced between the early decreases.
        let target = Sizing.rows(around / (2 * .pi), per: g.rpi)
        let spare = min(8, max(0, target - decreases.count - finals.count))
        var crown: [(text: String, stitches: Int)] = []
        for (index, decrease) in decreases.enumerated() {
            crown.append((decrease.text, decrease.each * cables))
            guard index < 4, let text = plain[decrease.each] else { continue }
            let gap = spare / 4 + (index < spare % 4 ? 1 : 0)
            crown += Array(repeating: (text, decrease.each * cables), count: gap)
        }
        crown += finals

        let brim = Sizing.rows(head * 0.09, per: g.rpi, minimum: 4)
        let body = max(8, Sizing.rows(head * 0.37, per: g.rpi) - brim - crown.count)
        let small = around < 16
        let ground = "*P2, k6; repeat from * around"
        let cross = "*P2, C6F; repeat from * around"

        var b = PlanBuilder()
        b.section = "Brim"
        b.action("Cast on \(stitches) stitches with the smaller needle. Join in the round without twisting and place a marker.", stitches: stitches)
        b.work(["*P2, k2; repeat from * around"], rows: brim, stitches: stitches)
        b.section = "Body"
        b.row("Change to the larger needle. " + ground, stitches: stitches)
        b.work([ground, ground, cross, ground, ground, ground, ground, ground], rows: body - 1, stitches: stitches)
        b.section = "Crown"
        for round in small ? crown : switching(crown, g) { b.row(round.text, stitches: round.stitches) }
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last \(closing) stitches and pull tight. Weave in the ends.")

        let yards = Sizing.yards(squareInches: around * head * 0.37, spi: g.spi, factor: 1.45)
        let needles = small ? ["\(g.ribNeedle.label) double-pointed needles for the brim, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the body, or a long circular for magic loop"]
            : ["\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the brim", "\(g.needle.label) \(Sizing.cable(16)) circular needle for the body", "Double-pointed needles in the larger size for the crown"]
        let plan = pattern(b, estimate: yards, tools: needles + ["Cable needle", "Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(around)) around with the cables at rest, to fit a \(Sizing.inches(head)) head, with \(cables) cables", gauge: g, round: true)
        return CabledHat(plan: plan, cables: cables, stitches: stitches)
    }

    // MARK: Home and wraps

    /// Blocks of stockinette and reverse stockinette that swap every block row, inside a garter border. An odd
    /// number of blocks each way, so the blanket starts and ends on the same block at every edge.
    static func basketweave(width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let border = max(3, Int((1.25 * g.spi).rounded()))
        let block = max(3, Int((1.5 * g.spi).rounded()))
        let across = odd((width * g.spi - Double(2 * border)) / Double(block), minimum: 3)
        // As many rows as make the block square, an even count so each block row starts on the right side.
        let blockRows = even(Double(block) * g.rpi / g.spi, minimum: 4)
        let up = odd((length - 2 * Double(border) / g.spi) * g.rpi / Double(blockRows), minimum: 3)
        let caston = 2 * border + across * block
        let knits = "K\(border), *k\(block), p\(block); repeat from * to the last \(block + border) stitches, k\(block + border)"
        let purls = "K\(border), *p\(block), k\(block); repeat from * to the last \(block + border) stitches, p\(block), k\(border)"
        // A knit block faces as purls from the wrong side, so the first block row pairs these two rows.
        let first = Array(repeating: [knits, purls], count: blockRows / 2).flatMap { $0 }
        let second = Array(repeating: [purls, knits], count: blockRows / 2).flatMap { $0 }

        var b = PlanBuilder()
        b.section = "Bottom Border"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work(["Knit"], rows: border * 2, stitches: caston)
        b.section = "Body"
        b.work(first + second, rows: up * blockRows, stitches: caston)
        b.section = "Top Border"
        b.work(["Knit"], rows: border * 2, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely. Weave in the ends.")
        let wide = Double(caston) / g.spi, long = 2 * Double(border) / g.spi + Double(up * blockRows) / g.rpi
        let yards = Sizing.yards(squareInches: wide * long, spi: g.spi, factor: 1.15)
        return pattern(b, estimate: yards, tools: [longCircular(caston, g, flat: true), "Tapestry needle"], finished: "\(Sizing.inches(wide)) wide, \(Sizing.inches(long)) long, \(across) blocks across and \(up) up", gauge: g)
    }

    /// A stole in moss stitch, two rows of k1, p1 rib then two of the reverse, inside garter edges.
    static func wrap(width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let edge = max(3, Int((0.75 * g.spi).rounded()))
        let middle = even(width * g.spi - Double(2 * edge), minimum: 10)
        let caston = middle + 2 * edge
        let rate = g.rpi * 1.1
        let rows = Sizing.rows(length - 2 * Double(edge) / g.spi, per: rate, even: true, minimum: 4)
        let one = "K\(edge), *k1, p1; repeat from * to the last \(edge) stitches, k\(edge)"
        let two = "K\(edge), *p1, k1; repeat from * to the last \(edge) stitches, k\(edge)"

        var b = PlanBuilder()
        b.section = "Bottom Border"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work(["Knit"], rows: 2 * edge, stitches: caston)
        b.section = "Body"
        b.work([one, one, two, two], rows: rows, stitches: caston)
        b.section = "Top Border"
        b.work(["Knit"], rows: 2 * edge, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely. Weave in the ends and block flat.")
        let long = 2 * Double(edge) / g.spi + Double(rows) / rate
        let yards = Sizing.yards(squareInches: width * long, spi: g.spi, factor: 1.1)
        return pattern(b, estimate: yards, tools: [longCircular(caston, g, flat: true), "Tapestry needle"], finished: "\(Sizing.inches(Double(caston) / g.spi)) wide, \(Sizing.inches(long)) long", gauge: g)
    }

    /// A garter crescent from the top down. It starts from a garter tab and grows by 4 stitches every row,
    /// all of them near the edges, so the top edge outgrows the depth and curves.
    static func crescent(wingspan: Double, gauge g: Gauge) -> PatternPlan {
        // The bound-off edge is about 80 percent of the wingspan in stitches, before blocking opens it.
        // Each pair of rows adds 6: 4 on the right side and 2 on the wrong side, the usual crescent proportions.
        let pairs = max(4, Int(((wingspan * g.spi * 0.8 - 9) / 6).rounded()))
        let rows = pairs * 2
        let last = 9 + 6 * pairs
        var b = PlanBuilder()
        b.section = "Garter Tab"
        b.action("Cast on 3 stitches.", stitches: 3)
        b.work(["Knit"], rows: 6, stitches: 3)
        b.action("Do not turn. Rotate the strip a quarter turn and pick up and knit 3 stitches along its side, one in each garter ridge. Rotate it again and pick up and knit 3 stitches from the cast-on edge.", stitches: 9)
        b.section = "Shawl"
        // The right-side row adds 4 and the wrong-side row 2, so the right-side row ends 2 short of the pair.
        b.work(["K3, yo, k1, yo, knit to the last 4 stitches, yo, k1, yo, k3", "K3, yo, knit to the last 3 stitches, yo, k3"], rows: rows, stitches: 15, delta: 6, offsets: [-2, 0])
        b.section = "Finishing"
        b.action("Bind off all \(last) stitches very loosely. Weave in the ends and block, pinning the top edge into a gentle curve.")
        // Garter has about twice as many rows to the inch as stitches; blocking opens it about a quarter.
        let depth = Double(rows) / (g.spi * 2) * 1.25
        // Blocking opens the garter far past the fabric on the needles, so the yarn is counted from the rows, with a tenth more.
        let yards = Int((Double(Sizing.yards(worked: b.steps, spi: g.spi)) * 1.1 / 10).rounded(.up)) * 10
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(40)) circular needle, worked flat", "Tapestry needle", "Blocking pins"], finished: "About \(Sizing.inches(wingspan)) across the top and \(Sizing.inches(depth)) deep at the middle, after blocking", gauge: g)
    }

    /// A string bag: a garter base knit flat, stitches picked up all the way around it, an eyelet mesh worked
    /// in the round, a garter band at the top, and two garter handles sewn inside the band.
    static func marketBag(width: Double, height: Double, handle: Double, gauge g: Gauge) -> PatternPlan {
        let base = Sizing.stitches(width, per: g.spi, minimum: 12)
        // A flat base a third as deep as the bag is wide.
        let baseRows = Sizing.rows(width * 0.3, per: g.spi * 2, even: true, minimum: 6)
        let around = 2 * base + baseRows
        let plain = Sizing.rows(0.5, per: g.rpi, minimum: 2)
        let band = Sizing.rows(1, per: g.spi * 2, even: true, minimum: 4)
        // Mesh stretches under a load, so it is knit about 15 percent short of the height.
        let mesh = Sizing.rows((height - Double(plain) / g.rpi - Double(band) / (g.spi * 2)) * 0.85, per: g.rpi, even: true, minimum: 6)
        let strap = max(4, Int(g.spi.rounded()))
        // Garter handles stretch too: knit them a tenth short.
        let strapRows = Sizing.rows(handle * 0.9, per: g.spi * 2, even: true, minimum: 10)

        var b = PlanBuilder()
        b.section = "Base"
        b.action("Cast on \(base) stitches.", stitches: base)
        b.work(["Knit"], rows: baseRows, stitches: base)
        b.section = "Body"
        b.action("Do not turn. Pick up and knit \(baseRows / 2) stitches along the side of the base, one in each garter ridge, \(base) along the cast-on edge and \(baseRows / 2) along the other side. Join in the round and place a marker.", stitches: around)
        b.work(["Knit"], rows: plain, stitches: around)
        b.work(["*Yo, k2tog; repeat from * around", "Knit"], rows: mesh, stitches: around)
        b.section = "Band"
        b.work(["Purl", "Knit"], rows: band, stitches: around)
        b.action("Bind off loosely purlwise.")
        for name in ["First Handle", "Second Handle"] {
            b.section = name
            b.action("Cast on \(strap) stitches.", stitches: strap)
            b.work(["Knit"], rows: strapRows, stitches: strap)
            b.action("Bind off, leaving a long tail to sew with.")
        }
        b.section = "Finishing"
        b.action("Sew the ends of one handle inside the band at the front, each \(Sizing.inches(width * 0.2)) in from a side, and the other handle at the back the same way. Weave in the ends.")
        // What the knitter measures off the needles; mesh and garter open up under the load.
        let knitHeight = Double(plain + mesh) / g.rpi + Double(band) / (g.spi * 2)
        let knitHandle = Double(strapRows) / (g.spi * 2)
        // The base is garter: its stitches as wide as they knit, and its rows as deep as they are in ridges.
        let baseWidth = Double(base) / g.spi
        let baseDepth = Double(baseRows) / (g.spi * 2)
        let yards = Sizing.yards(squareInches: 2 * width * height * 0.8 + width * width * 0.3 + 2 * handle * Double(strap) / g.spi, spi: g.spi, factor: 1.1)
        return pattern(b, estimate: yards, yarnNote: ", cotton or linen so the bag holds its shape", tools: ["\(g.needle.label) \(Sizing.cable(Double(around) / g.spi < 20 ? 16 : 24)) circular needle", "Stitch marker", "Tapestry needle"], finished: "A base \(Sizing.inches(baseWidth)) wide and \(Sizing.inches(baseDepth)) deep, \(Sizing.inches(Double(around) / g.spi)) around, and \(Sizing.inches(knitHeight)) tall as knit, stretching to about \(Sizing.inches(height)) with a load, with handles \(Sizing.inches(knitHandle)) long that stretch to about \(Sizing.inches(handle))", gauge: g)
    }

    struct Pillow: Equatable, Sendable {
        var plan: PatternPlan
        var stitches: Int
        var buttons: Int
        var buttonholes: [Int]
    }

    /// A pillow cover knit in the round as a tube with a garter ridge every sixth round. The cast-on edge is
    /// sewn shut, and the top closes with a ribbed band, buttonholes across the front half.
    static func pillow(side: Double, gauge g: Gauge) -> Pillow {
        // About 8 percent smaller than the form, so the cover sits full and smooth.
        let stitches = Sizing.stitches(2 * side * 0.92, per: g.spi, multiple: 4, minimum: 24)
        let band = Sizing.rows(1.25, per: g.rpi, minimum: 4)
        let body = max(6, Sizing.rows(side * 0.92 - Double(band) / g.rpi, per: g.rpi))
        let buttons = max(3, Int((side / 4.5).rounded()))
        let gaps = buttonholeGaps(buttons, over: stitches / 2, edge: max(2, Int(g.spi.rounded())))
        let before = band / 2
        let rib = "*K1, p1; repeat from * around"
        let flat = Double(stitches / 2) / g.spi

        var b = PlanBuilder()
        b.section = "Body"
        b.action("Cast on \(stitches) stitches. Join in the round without twisting and place a marker. The first \(stitches / 2) stitches are the front.", stitches: stitches)
        b.work(["Knit", "Knit", "Knit", "Knit", "Knit", "Purl"], rows: body, stitches: stitches)
        b.section = "Buttonhole Band"
        b.row("Change to the smaller needle. " + rib, stitches: stitches)
        b.work([rib], rows: before - 1, stitches: stitches)
        b.row(buttonholeText(gaps, rest: "work in rib to the end of the round"), stitches: stitches)
        b.row("*K1, p1; repeat from * around, working each yarn over as a stitch", stitches: stitches)
        b.work([rib], rows: band - before - 2, stitches: stitches)
        b.section = "Finishing"
        b.action("Bind off loosely in pattern.")
        b.action("Turn the cover inside out and sew the cast-on edge closed. Turn it right side out and slip in the pillow form. Sew \(buttons) buttons inside the back band, opposite the buttonholes, and button it shut. Weave in the ends.")
        let circular = Double(stitches) / g.spi > 45 ? longCircular(stitches, g, flat: false) : "\(g.needle.label) \(Sizing.cable(Double(stitches) / g.spi < 34 ? 24 : 32)) circular needle"
        let yards = Sizing.yards(squareInches: 2 * flat * side * 0.92, spi: g.spi, factor: 1.05)
        let plan = pattern(b, estimate: yards, tools: [circular, "\(g.ribNeedle.label) circular needle of the same length, for the band", "\(buttons) buttons, about \(Sizing.inches(max(0.5, 3 / g.spi))) across", "A \(Sizing.inches(side)) square pillow form", "Stitch marker, tapestry needle"], finished: "\(Sizing.inches(flat)) square, for a \(Sizing.inches(side)) pillow form", gauge: g, round: true)
        return Pillow(plan: plan, stitches: stitches, buttons: buttons, buttonholes: gaps)
    }

    // MARK: More sweaters

    struct Cardigan: Equatable, Sendable {
        var plan: PatternPlan
        var fit: RaglanFit
        var neck: Int
        var front: Int
        var frontAtNeck: Int
        var band: Int
        var body: Int
        var bandPickUp: Int
        var buttons: Int
        var buttonholes: [Int]
        var yokeRows: Int
    }

    /// The raglan pullover opened down the front: worked flat from the neck down, with the same yoke, the
    /// sleeves in the round, and ribbed bands picked up along the fronts, one with evenly spaced buttonholes.
    /// The bands overlap, so the fronts are cast on a band's width narrower than the pullover's front.
    static func cardigan(chest: Double, wearer: Double? = nil, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> Cardigan {
        let fit = raglanFit(chest: chest, wearer: wearer, child: false, gauge: g)
        let bandRows = Sizing.rows(1, per: g.rpi, even: true, minimum: 4)
        let band = max(2, min(even(Double(bandRows) / g.rpi * g.spi), fit.backAtNeck - 4))
        let frontAtNeck = (fit.backAtNeck - band) / 2
        let front = frontAtNeck + fit.bodyIncreases
        let neck = fit.backAtNeck + 2 * frontAtNeck + 2 * fit.sleeveAtNeck
        let flatBody = 2 * front + fit.panel + 2 * fit.underarm
        // Worked flat, the yoke ends on a wrong-side row, so the divide is on the right side.
        let yoke = fit.yokeRounds + fit.yokeRounds % 2

        var b = PlanBuilder()
        b.section = "Neckband"
        let neckband = Sizing.rows(1, per: g.rpi, even: true, minimum: 4)
        b.action("With the smaller needle, cast on \(neck) stitches.", stitches: neck)
        b.work(["*K1, p1; repeat from * to the end"], rows: neckband, stitches: neck)

        // Short rows across the back and sleeves raise the back of the neck, turning a little further into
        // each front every time, as on the pullover.
        b.section = "Back Neck"
        b.row("Change to the larger needle. K\(frontAtNeck) front, place marker, k\(fit.sleeveAtNeck) sleeve, place marker, k\(fit.backAtNeck) back, place marker, k\(fit.sleeveAtNeck) sleeve, place marker, k\(frontAtNeck) front", stitches: neck)
        b.row("Purl", stitches: neck)
        let pairs = min(frontAtNeck, min(4, max(2, Sizing.rows(1, per: g.rpi) / 2)))
        let reach = max(1, min(Int((0.5 * g.spi).rounded()), (frontAtNeck - 1) / max(1, pairs - 1)))
        b.row("Short row: knit to the marker before the last front, turn", stitches: neck)
        b.row("Make a double stitch, then purl to the marker before the last front, turn", stitches: neck)
        b.work(["Make a double stitch, knit to the double stitch, knit it as one stitch, k\(reach), turn", "Make a double stitch, purl to the double stitch, purl it as one stitch, p\(reach), turn"], rows: 2 * (pairs - 1), stitches: neck)
        b.row("Make a double stitch, then knit to the end, knitting the double stitch you pass as one stitch", stitches: neck)
        b.row("Purl to the end, purling the last double stitch as one stitch", stitches: neck)

        b.section = "Yoke"
        var onNeedle = neck
        var rows: [(text: String, stitches: Int)] = []
        for (index, grows) in raglanSchedule(body: fit.bodyIncreases, sleeves: fit.sleeveIncreases, rounds: yoke, flat: true).enumerated() {
            onNeedle += (grows.body ? 4 : 0) + (grows.sleeves ? 4 : 0)
            let right = index % 2 == 0
            let text: String = switch (grows.body, grows.sleeves, right) {
            case (true, true, true): "Knit to 1 stitch before the marker, M1R, k1, slip the marker. *Inc across; repeat from * 2 more times. K1, M1L, knit to the end"
            case (true, false, true): "Knit to 1 stitch before the marker, M1R, k1, slip the marker. Knit the sleeve. Inc across the back. Knit the sleeve. K1, M1L, knit to the end"
            case (false, true, true): "Knit the front. Inc across the sleeve. Knit the back. Inc across the sleeve. Knit the front"
            case (false, false, true): "Knit"
            case (true, true, false): "Purl to 1 stitch before the marker, M1P, p1, slip the marker. *Inc purlwise; repeat from * 2 more times. P1, M1P, purl to the end"
            case (true, false, false): "Purl to 1 stitch before the marker, M1P, p1, slip the marker. Purl the sleeve. Inc purlwise across the back. Purl the sleeve. P1, M1P, purl to the end"
            case (false, true, false): "Purl the front. Inc purlwise across the sleeve. Purl the back. Inc purlwise across the sleeve. Purl the front"
            case (false, false, false): "Purl"
            }
            rows.append((text, onNeedle))
        }
        runs(&b, rows, from: neck)

        b.section = "Divide"
        b.action("Knit the \(front) front stitches. Slip the \(fit.sleeveTop) stitches of the first sleeve to waste yarn, removing the markers on each side.")
        b.action("Under the arm, cast on \(fit.underarm) stitches with the backward loop method. Knit the \(fit.panel) back stitches.")
        b.action("Slip the \(fit.sleeveTop) stitches of the second sleeve to waste yarn, removing the markers on each side.")
        b.row("Under the arm, cast on \(fit.underarm) stitches. Knit the \(front) front stitches", stitches: flatBody)

        let hem = Sizing.rows(min(2, length * 0.2), per: g.rpi, minimum: 4)
        let bodyRows = max(2, Sizing.rows(length, per: g.rpi) - hem)
        b.section = "Body"
        b.work(["Purl", "Knit"], rows: bodyRows, stitches: flatBody)
        b.section = "Hem"
        b.row("Change to the smaller needle. *K1, p1; repeat from * to the end", stitches: flatBody)
        b.work(["*K1, p1; repeat from * to the end"], rows: hem - 1, stitches: flatBody)
        b.action("Bind off loosely in pattern.")

        let cuff = raglanSleeves(&b, fit, chest: chest, length: sleeveLength, gauge: g)

        // Each front edge runs from the top of the neckband to the bottom of the hem.
        let edgeRows = neckband + 4 + yoke + 1 + bodyRows + hem
        let edge = Double(edgeRows) / g.rpi
        let picked = Int((edge * g.spi).rounded())
        let pickUp = picked + 1 - picked % 2
        let buttons = max(5, Int((edge / 3.25).rounded()))
        let gaps = buttonholeGaps(buttons, over: pickUp, edge: max(2, Int((0.4 * g.spi).rounded())))
        let wrong = "P1, *k1, p1; repeat from * to the end", right = "K1, *p1, k1; repeat from * to the end"
        let hole = bandRows / 2 - (bandRows / 2 % 2 == 0 ? 1 : 0)
        b.section = "Button Band"
        b.action("With the smaller needle and the right side facing, pick up and knit \(pickUp) stitches along the left front edge, from the top of the neckband down to the hem. For a man's closing, work this band on the right front and the buttonhole band on the left.", stitches: pickUp)
        b.work([wrong, right], rows: bandRows, stitches: pickUp)
        b.action("Bind off in pattern.")
        b.section = "Buttonhole Band"
        b.action("With the smaller needle and the right side facing, pick up and knit \(pickUp) stitches along the right front edge, from the hem up to the top of the neckband.", stitches: pickUp)
        b.work([wrong, right], rows: hole, stitches: pickUp)
        b.row(buttonholeText(gaps, rest: "work the last \(gaps.last ?? 0) in rib"), stitches: pickUp)
        b.row(wrong + ", working each yarn over as a stitch", stitches: pickUp)
        b.work([right, wrong], rows: bandRows - hole - 2, stitches: pickUp)
        b.action("Bind off in pattern.")
        b.section = "Finishing"
        b.action("Sew the \(buttons) buttons to the button band, opposite the buttonholes. Weave in the ends, closing any gaps at the underarms. Block to the finished measurements.")

        let finishedChest = Double(fit.body) / g.spi
        let area = finishedChest * (length + fit.depth) + (fit.arm + Double(cuff) / g.spi) * sleeveLength + fit.arm * fit.depth + 2 * edge * Double(bandRows) / g.rpi
        let worn = wearer.map { ", to fit a \(Sizing.inches($0)) chest with \(Sizing.inches(finishedChest - $0)) of ease" } ?? ""
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: [longCircular(flatBody, g, flat: true), "\(g.ribNeedle.label) circular needle of the same length, for the ribbing and bands", "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop", "\(buttons) buttons, about \(Sizing.inches(max(0.5, 2.5 / g.spi))) across", "4 stitch markers, waste yarn, tapestry needle"],
            finished: "Finished chest \(Sizing.inches(finishedChest)) with the bands buttoned\(worn). Body \(Sizing.inches(length)) and sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            gauge: g
        )
        return Cardigan(plan: plan, fit: fit, neck: neck, front: front, frontAtNeck: frontAtNeck, band: band, body: flatBody, bandPickUp: pickUp, buttons: buttons, buttonholes: gaps, yokeRows: yoke)
    }

    struct Vest: Equatable, Sendable {
        var plan: PatternPlan
        var body: Int
        var piece: Int
        var shoulders: Int
        var shoulder: Int
        var neck: Int
        var armholeRows: Int
        var boundOff: Int
        var armholeDecreases: Int
        var neckDecreases: Int
    }

    /// A V-neck sweater vest knit in the round from the hem to the underarms, then the front and back worked
    /// flat. The V starts at the underarm, its two sides worked one after the other, and the armholes are cut
    /// in narrower than a sweater's. Shoulders are sewn; the armholes and the mitred V get k1, p1 rib.
    static func vest(chest: Double, wearer: Double? = nil, body length: Double, gauge g: Gauge) -> Vest {
        let worn = wearer ?? chest - Design.sweaterEase
        let body = Sizing.stitches(chest, per: g.spi, multiple: 4)
        let piece = body / 2
        // A vest's armhole runs an inch deeper than a sweater's, and its shoulders an inch and a quarter
        // narrower than the Craft Yarn Council cross back.
        let rows = Sizing.rows(worn * 0.125 + 3.75, per: g.rpi, even: true)
        let neck = even(min(8, chest * 0.1 + 3) * g.spi, minimum: 4)
        let shoulders = max(min(even((min(18.5, worn * 0.2 + 8.5) - 1.25) * g.spi), piece - 4), neck + 4)
        let shoulder = (shoulders - neck) / 2
        let armhole = (piece - shoulders) / 2
        let boundOff = (armhole + 1) / 2
        let decreases = armhole - boundOff
        let half = piece / 2
        let narrow = neck / 2
        let bind = "Bind off \(boundOff) stitch\(boundOff == 1 ? "" : "es")"
        // The V narrows on right-side rows spread from the underarm to an inch below the shoulder.
        let straight = Sizing.rows(1, per: g.rpi, minimum: 2)
        let room = max(narrow, (rows - straight + 1) / 2)
        let neckRows = Set((0..<narrow).map { 2 * ($0 * room / narrow) + 1 })

        func side(_ first: Bool) -> [(text: String, stitches: Int)] {
            var out: [(text: String, stitches: Int)] = []
            var count = half
            for row in 1...rows {
                let right = row % 2 == 1
                let neckHere = right && neckRows.contains(row)
                let armHere = right && row >= 3 && row <= 2 * decreases + 1
                let text: String
                switch (row, first) {
                case (1, true):
                    count -= boundOff + 1
                    text = "Leave the other \(half) stitches for the second side. \(bind), then knit to 3 stitches before the middle marker, k2tog, k1, turn"
                case (1, false):
                    count -= 1
                    text = "K1, ssk, knit to the end, turn"
                case (2, false):
                    count -= boundOff
                    text = "\(bind), purl to the end, turn"
                default:
                    count -= (neckHere ? 1 : 0) + (armHere ? 1 : 0)
                    switch (right, armHere, neckHere) {
                    case (false, _, _): text = "Purl to the end, turn"
                    case (true, true, true): text = "K1, ssk, knit to the last 3 stitches, k2tog, k1, turn"
                    case (true, false, false): text = "Knit to the end, turn"
                    case (true, true, false): text = first ? "K1, ssk, knit to the end, turn" : "Knit to the last 3 stitches, k2tog, k1, turn"
                    case (true, false, true): text = first ? "Knit to the last 3 stitches, k2tog, k1, turn" : "K1, ssk, knit to the end, turn"
                    }
                }
                out.append((text, count))
            }
            return out
        }

        var b = PlanBuilder()
        let hem = Sizing.rows(min(2.5, length * 0.2), per: g.rpi, minimum: 4)
        b.section = "Hem"
        b.action("Cast on \(body) stitches with the smaller needle. Join in the round without twisting and place a marker at the side.", stitches: body)
        b.work(["*K2, p2; repeat from * around"], rows: hem, stitches: body)
        b.section = "Body"
        b.row("Change to the larger needle and knit", stitches: body)
        b.work(["Knit"], rows: max(1, Sizing.rows(length, per: g.rpi) - hem - 1), stitches: body)
        b.action("The first \(piece) stitches of the round are the front. Slip the other \(piece), the back, to waste yarn, and place a marker at the middle of the front: the V starts here. The front is worked first, back and forth.")
        b.section = "Front · First Side"
        runs(&b, side(true), from: half)
        b.action("Bind off the \(shoulder) shoulder stitches.")
        b.section = "Front · Second Side"
        b.action("With the right side facing, join new yarn at the middle marker.", stitches: half)
        runs(&b, side(false), from: half)
        b.action("Bind off the \(shoulder) shoulder stitches.")
        b.section = "Back"
        b.action("Return the \(piece) back stitches to the needle. With the right side facing, join new yarn at the underarm.", stitches: piece)
        var back: [(text: String, stitches: Int)] = [("\(bind), knit to the end, turn", piece - boundOff), ("\(bind), purl to the end, turn", piece - 2 * boundOff)]
        var count = piece - 2 * boundOff
        for row in 3...max(3, rows) {
            if row % 2 == 0 { back.append(("Purl to the end, turn", count)); continue }
            if row <= 2 * decreases + 1 { count -= 2; back.append(("K1, ssk, knit to the last 3 stitches, k2tog, k1, turn", count)) } else { back.append(("Knit to the end, turn", count)) }
        }
        runs(&b, back, from: piece)
        b.action("Bind off all \(shoulders) stitches.")
        b.section = "Finishing"
        b.action("Sew the shoulders: the first and last \(shoulder) stitches of the back to the front shoulders. The \(neck) stitches between them are the back neck.")

        let slant = (pow(Double(rows) / g.rpi, 2) + pow(Double(narrow) / g.spi, 2)).squareRoot()
        let along = even(slant * g.spi * 0.9, minimum: 4)
        let around = 2 * along + neck + 2
        let edging = Sizing.rows(0.75, per: g.rpi, minimum: 3)
        b.section = "Neck Edging"
        b.action("With the smaller \(Sizing.cable(16)) needle and the right side facing, start at the left shoulder seam. Pick up and knit \(along) stitches down the left side of the V, 1 at its point, \(along) up the right side and \(neck + 1) across the back neck. Join in the round and place a marker. Mark the stitch at the point.", stitches: around)
        b.row("*K1, p1; repeat from * to 1 stitch before the marked stitch, ending k1. Slip 2 together knitwise, k1, pass the 2 slipped stitches over. *K1, p1; repeat from * to the end", stitches: around - 2)
        b.work(["Knit the knits and purl the purls to 1 stitch before the marked stitch. Slip 2 together knitwise, k1, pass the 2 slipped stitches over. Knit the knits and purl the purls to the end"], rows: edging - 1, stitches: around - 4, delta: -2)
        b.action("Bind off loosely in pattern.")
        let armStitches = even(Double(2 * rows) * g.spi / g.rpi * 0.9 + Double(2 * boundOff))
        for name in ["First Armhole", "Second Armhole"] {
            b.section = name
            b.action("With the smaller \(Sizing.cable(16)) needle or double-pointed needles and the right side facing, pick up and knit \(armStitches) stitches around the armhole, starting at the middle of the underarm. Join in the round and place a marker.", stitches: armStitches)
            b.work(["*K1, p1; repeat from * around"], rows: edging, stitches: armStitches)
            b.action("Bind off loosely in pattern.")
        }
        b.section = "Finishing"
        b.action("Weave in the ends and block to the finished measurements.")

        let finishedChest = Double(body) / g.spi
        let depth = Double(rows) / g.rpi
        let ease = wearer.map { ", to fit a \(Sizing.inches($0)) chest with \(Sizing.inches(finishedChest - $0)) of ease" } ?? ""
        let yards = Sizing.yards(squareInches: finishedChest * (length + depth * 0.8) + 4 * depth, spi: g.spi)
        // The body needle must be shorter than the body is around.
        let long = finishedChest < 34 ? 24 : 32
        let needle = finishedChest > 45 ? longCircular(body, g, flat: false) : "\(g.needle.label) \(Sizing.cable(long)) circular needle"
        let plan = pattern(b, estimate: yards, tools: [needle, "\(g.ribNeedle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(long)), for the ribbing", "2 stitch markers, waste yarn, tapestry needle"], finished: "Finished chest \(Sizing.inches(finishedChest))\(ease). \(Sizing.inches(length)) from the hem to the underarm and \(Sizing.inches(depth)) from the underarm to the shoulder", gauge: g, round: true)
        return Vest(plan: plan, body: body, piece: piece, shoulders: shoulders, shoulder: shoulder, neck: neck, armholeRows: rows, boundOff: boundOff, armholeDecreases: decreases, neckDecreases: narrow)
    }
}

// MARK: Drop-shoulder sweater, keyhole scarf, slippers and booties

extension Engines {
    /// The beginner's sweater: four flat pieces and no armhole shaping. The back is a rectangle, the front the
    /// same rectangle with a crew neck scooped out; the sleeves widen from the cuff and are sewn flat to the
    /// side edges, so the shoulder seam drops over the arm. A ribbed band is picked up around the neck.
    static func dropShoulder(chest: Double, wearer: Double? = nil, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> PatternPlan {
        let worn = wearer ?? chest - Design.dropEase
        let piece = Sizing.stitches(chest / 2, per: g.spi, multiple: 4, extra: 2)
        // The armhole runs half the sleeve's top edge down each side, so it takes the arm and its ease.
        let depth = worn * 0.125 + 4.5
        let hem = Sizing.rows(min(2.5, length * 0.15), per: g.rpi, even: true, minimum: 4)
        let total = Sizing.rows(length + depth, per: g.rpi, even: true)
        let neckRows = Sizing.rows(min(3, 1.5 + worn * 0.03), per: g.rpi, even: true, minimum: 6)
        let neck = even(min(9, worn * 0.1 + 4) * g.spi, minimum: 8)
        let shoulder = (piece - neck) / 2
        let shaped = max(1, min(neckRows / 2 - 1, Int((Double(neck) * 0.2).rounded())))
        let side = shoulder + shaped
        let center = piece - 2 * side

        func half(_ first: Bool) -> [(text: String, stitches: Int)] {
            var out: [(text: String, stitches: Int)] = []
            var count = side
            for row in 1...neckRows {
                let right = row % 2 == 1
                let shaping = right && row >= 3 && (row - 1) / 2 <= shaped
                if shaping { count -= 1 }
                let text: String
                switch (row, right, shaping) {
                case (1, _, _): text = first ? "Knit \(side) stitches and turn, leaving the other \(piece - side) on the needle for the second side" : "Bind off \(center) stitches, knit to the end"
                case (_, false, _): text = "Purl to the end"
                case (_, true, true): text = first ? "Knit to the last 3 stitches, k2tog, k1" : "K1, ssk, knit to the end"
                default: text = "Knit to the end"
                }
                out.append((text, count))
            }
            return out
        }

        var b = PlanBuilder()
        let rib = ["K2, *p2, k2; repeat from * to the end", "P2, *k2, p2; repeat from * to the end"]
        b.section = "Back"
        b.action("With the smaller needles, cast on \(piece) stitches.", stitches: piece)
        b.work(rib, rows: hem, stitches: piece)
        b.action("Change to the larger needles.")
        b.work(["Knit", "Purl"], rows: total - hem, stitches: piece)
        b.action("Bind off all \(piece) stitches.")
        b.section = "Front"
        b.action("With the smaller needles, cast on \(piece) stitches.", stitches: piece)
        b.work(rib, rows: hem, stitches: piece)
        b.action("Change to the larger needles.")
        b.work(["Knit", "Purl"], rows: total - hem - neckRows, stitches: piece)
        b.section = "Front · First Side"
        runs(&b, half(true), from: piece)
        b.action("Bind off the \(shoulder) shoulder stitches.")
        b.section = "Front · Second Side"
        b.action("With the right side facing, join new yarn at the neck edge of the \(piece - side) stitches left.", stitches: piece - side)
        runs(&b, half(false), from: piece - side)
        b.action("Bind off the \(shoulder) shoulder stitches.")

        let wrist = worn * 0.1 + 3
        let cuff = Sizing.stitches(wrist, per: g.spi, multiple: 4, extra: 2, minimum: 18)
        let cuffRows = Sizing.rows(min(2.5, wrist * 0.3), per: g.rpi, even: true, minimum: 4)
        // The body reaches past the shoulder, so the sleeve is that much shorter than an underarm-to-cuff measure.
        let drop = max(0, (Double(piece) / g.spi - (worn * 0.2 + 8.5)) / 2)
        let sleeveRows = max(8, Sizing.rows(max(6, sleeveLength - drop) - Double(cuffRows) / g.rpi, per: g.rpi, even: true))
        var increases = max(0, (even(2 * depth * g.spi) - cuff) / 2)
        let spacing = increases == 0 ? 2 : max(2, 2 * Int(Double(sleeveRows) * 0.85 / Double(increases) / 2))
        increases = min(increases, sleeveRows / spacing)
        let top = cuff + 2 * increases
        let cycle = ["K1, m1, knit to the last stitch, m1, k1"] + (1..<spacing).map { $0 % 2 == 1 ? "Purl" : "Knit" }
        for name in ["First Sleeve", "Second Sleeve"] {
            b.section = name
            b.action("With the smaller needles, cast on \(cuff) stitches.", stitches: cuff)
            b.work(rib, rows: cuffRows, stitches: cuff)
            b.action("Change to the larger needles.")
            b.work(cycle, rows: increases * spacing, stitches: cuff + 2, delta: 2)
            b.work(["Knit", "Purl"], rows: sleeveRows - increases * spacing, stitches: top)
            b.action("Bind off all \(top) stitches loosely.")
        }

        let along = Int((Double(neckRows) * 0.75).rounded()) + shaped
        let around = even(Double(neck + center + 2 * along))
        let band = Sizing.rows(0.75, per: g.rpi, minimum: 3)
        b.section = "Neckband"
        b.action("Sew the shoulder seams, \(shoulder) stitches on each side.")
        b.action("With the smaller \(Sizing.cable(16)) circular needle and the right side facing, start at the left shoulder seam. Pick up and knit \(along) stitches down the left side of the neck, \(center) across the front, \(along) up the right side and \(neck) across the back. Join in the round and place a marker.", stitches: around)
        b.work(["*K1, p1; repeat from * around"], rows: band, stitches: around)
        b.action("Bind off loosely in pattern.")
        b.section = "Finishing"
        b.action("Place a marker on each side edge of the front and the back, \(Sizing.inches(Double(top) / g.spi / 2)) below the shoulder seam. Sew the bound-off top of each sleeve between the markers, with its middle at the shoulder seam. Sew each side and sleeve seam in one line from the hem to the cuff. Weave in the ends and block.")

        let finishedChest = 2 * Double(piece) / g.spi
        let ease = wearer.map { ", to fit a \(Sizing.inches($0)) chest with \(Sizing.inches(finishedChest - $0)) of ease" } ?? ""
        let sleeveArea = Double(cuff + top) / 2 / g.spi * (Double(cuffRows + sleeveRows) / g.rpi)
        let yards = Sizing.yards(squareInches: 2 * Double(piece) / g.spi * Double(total) / g.rpi + 2 * sleeveArea, spi: g.spi)
        let needle = Double(piece) / g.spi > 14 ? longCircular(piece, g, flat: true) : "\(g.needle.label) needles"
        return pattern(b, estimate: yards, tools: [needle, "\(g.ribNeedle.label) needles for the ribbing", "\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the neckband", "4 locking stitch markers, a stitch marker, tapestry needle"], finished: "Finished chest \(Sizing.inches(finishedChest))\(ease). \(Sizing.inches(Double(total) / g.rpi)) from the hem to the shoulder", gauge: g)
    }

    /// A short garter scarf with a slit near one end: the two halves are knit side by side, each from its own
    /// ball, then joined again. The far end pulls through the slit, so the scarf sits closed without a knot.
    static func keyholeScarf(width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let caston = Sizing.stitches(width, per: g.spi, multiple: 2, minimum: 10)
        let perInch = g.spi * 2
        let total = Sizing.rows(length, per: perInch, even: true)
        let slit = Sizing.rows(max(2.5, width * 0.7), per: perInch, even: true)
        let before = Sizing.rows(length * 0.22, per: perInch, even: true)
        let after = max(2, total - before - slit)
        let left = caston / 2
        let right = caston - left

        var b = PlanBuilder()
        b.section = "Scarf"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work(["Knit"], rows: before, stitches: caston)
        b.section = "Keyhole"
        b.row("Knit \(left) stitches and turn, leaving the other \(right) unworked", stitches: left)
        b.work(["Knit"], rows: slit - 1, stitches: left)
        b.action("Leave this yarn attached at the outer edge. With the right side facing, join a second ball of yarn at the slit.", stitches: right)
        b.work(["Knit"], rows: slit, stitches: right)
        b.action("Cut the second yarn, leaving a tail to weave in.")
        b.section = "Long End"
        b.row("With the first yarn, knit across all \(caston) stitches, closing the slit", stitches: caston)
        b.work(["Knit"], rows: after - 1, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely. Weave in the ends, closing any gap at the top and bottom of the slit. To wear, wrap the scarf around the neck and pull the long end through the slit.")
        let yards = Sizing.yards(squareInches: width * length, spi: g.spi, factor: 1.25)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) needles", "Tapestry needle"], finished: "\(Sizing.inches(width)) wide, \(Sizing.inches(length)) long, with a \(Sizing.inches(Double(slit) / perInch)) slit", gauge: g)
    }

    /// The rectangle slipper: a garter piece knit from the heel to the toe, the toe gathered closed, the top of
    /// the foot seamed back from the toe and the cast-on edge folded and seamed for the heel. Booties get a
    /// ribbed cuff picked up around the opening, so they stay on; slippers get a pompom on the toe.
    static func slipper(foot around: Double, length footLength: Double, gauge g: Gauge, bootie: Bool) -> PatternPlan {
        let caston = Sizing.stitches(around * 0.95, per: g.spi, multiple: 4, minimum: 16)
        let perInch = g.spi * 2
        let rows = Sizing.rows(footLength * 0.95 - 0.5, per: perInch, even: true, minimum: 8)
        let instep = footLength * 0.45
        let open = max(1.5, footLength - instep)
        let pickup = 4 * max(4, Int((2 * open * g.spi * 0.75 / 4).rounded()))
        let cuffRounds = Sizing.rows(min(2, footLength * 0.35), per: g.rpi, minimum: 4)
        let name = bootie ? "Bootie" : "Slipper"

        var b = PlanBuilder()
        for index in 1...2 {
            b.section = "\(name) \(index) · Foot"
            b.action("Cast on \(caston) stitches, leaving a long tail for the heel seam.", stitches: caston)
            b.work(["Knit"], rows: rows, stitches: caston)
            b.section = "\(name) \(index) · Toe"
            b.row("*K2tog; repeat from * to the end", stitches: caston / 2)
            b.row("Knit", stitches: caston / 2)
            b.row("*K2tog; repeat from * to the end", stitches: caston / 4)
            b.action("Cut the yarn, leaving a long tail. Thread it through the \(caston / 4) stitches and pull tight.")
            b.section = "\(name) \(index) · Finishing"
            b.action("Fold the piece in half along its length. With the toe tail, sew the long edges together from the toe for \(Sizing.inches(instep)), over the top of the foot. Fold the cast-on edge in half and sew it closed with the cast-on tail: this is the heel.")
            if bootie {
                b.section = "\(name) \(index) · Cuff"
                b.action("With double-pointed needles and the right side facing, start at the heel seam and pick up and knit \(pickup) stitches around the opening. Join in the round and place a marker.", stitches: pickup)
                b.work(["*K2, p2; repeat from * around"], rows: cuffRounds, stitches: pickup)
                b.action("Bind off loosely in pattern. Weave in the ends.")
            } else {
                b.action("Make a pompom about \(Sizing.inches(1.5)) across and sew it to the top of the toe. Weave in the ends.")
            }
        }
        let yards = Sizing.yards(squareInches: around * footLength * 2.3, spi: g.spi, factor: 1.25)
        var tools = ["\(g.needle.label) needles", "Tapestry needle"]
        if bootie { tools.insert("\(g.needle.label) double-pointed needles for the cuff", at: 1) } else { tools.insert("Pompom maker or a piece of card", at: 1) }
        return pattern(b, estimate: yards, tools: tools, finished: "Fits a foot \(Sizing.inches(around)) around and \(Sizing.inches(footLength)) long", gauge: g)
    }
}
