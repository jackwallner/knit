import Foundation

/// A stitch pattern a shape's main fabric can be worked in: double moss on a scarf, waffle on a beanie.
/// The shape's engine still sizes the piece; the stitch decides what each row of the fabric says, how
/// many stitches a repeat takes, and how the fabric's gauge differs from stockinette.
/// Raw values are stored in published records and cast-on plans' sources, so they never change.
enum Stitch: String, CaseIterable, Sendable {
    case seed, doubleMoss, brokenRib, waffle, honeycomb, linen, twistedRib, mistakeRib, seededRib
    case garterRidge, basketweave, diamondBrocade, featherFan, eyelet, chevronLace, ropeCable, hurdle

    /// One row of a stitch pattern as written: what comes before the repeat, the repeat, and what follows
    /// it, each as the knitter reads it ("k1", "sl1 wyif, k1"). A plain row of knit or purl has no repeat.
    struct Row: Equatable, Sendable {
        enum Plain: Sendable { case knit, purl }
        var plain: Plain?
        var start = ""
        var repeating = ""
        var end = ""

        static let knit = Row(plain: .knit)
        static let purl = Row(plain: .purl)

        /// "k1 | sl1 wyif, k1 | k1": start, repeat and end.
        init(_ written: String) {
            let parts = written.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            start = parts[0]
            repeating = parts.count > 1 ? parts[1] : ""
            end = parts.count > 2 ? parts[2] : ""
        }

        init(plain: Plain) { self.plain = plain }
    }

    var name: String {
        switch self {
        case .seed: "Seed Stitch"
        case .doubleMoss: "Double Moss"
        case .brokenRib: "Broken Rib"
        case .waffle: "Waffle"
        case .honeycomb: "Honeycomb"
        case .linen: "Linen Stitch"
        case .twistedRib: "Twisted Rib"
        case .mistakeRib: "Mistake Rib"
        case .seededRib: "Seeded Rib"
        case .garterRidge: "Garter Ridge"
        case .basketweave: "Basketweave"
        case .diamondBrocade: "Diamond Brocade"
        case .featherFan: "Feather and Fan"
        case .eyelet: "Eyelet Lace"
        case .chevronLace: "Chevron Lace"
        case .ropeCable: "Rope Cable"
        case .hurdle: "Hurdle Stitch"
        }
    }

    /// What the stitch asks of a knitter, as the design page lists it.
    var technique: String {
        switch self {
        case .honeycomb, .linen: "Slipped stitches"
        case .twistedRib: "Twisted stitches"
        case .featherFan, .eyelet, .chevronLace: "Lace knitting"
        case .ropeCable: "Cables"
        default: "Knit and purl texture"
        }
    }

    var level: Design.Level {
        switch self {
        case .seed, .doubleMoss, .brokenRib, .garterRidge, .hurdle, .mistakeRib: .beginner
        case .chevronLace, .ropeCable: .intermediate
        default: .easy
        }
    }

    var isLace: Bool { [.featherFan, .eyelet, .chevronLace].contains(self) }

    /// Stitches in one repeat across.
    var multiple: Int {
        switch self {
        case .seed, .brokenRib, .honeycomb, .linen, .twistedRib, .eyelet, .hurdle: 2
        case .waffle: 3
        case .doubleMoss, .mistakeRib, .seededRib: 4
        case .ropeCable: 6
        case .basketweave, .diamondBrocade: 8
        case .chevronLace: 10
        case .featherFan: 12
        case .garterRidge: 1
        }
    }

    /// Stitches a flat row adds to its repeats so it starts and ends alike.
    var extra: Int {
        switch self {
        case .garterRidge, .hurdle: 0
        case .seed, .brokenRib, .honeycomb, .twistedRib, .waffle, .diamondBrocade, .eyelet, .chevronLace: 1
        case .doubleMoss, .linen, .featherFan, .ropeCable: 2
        case .mistakeRib, .seededRib: 3
        case .basketweave: 4
        }
    }

    /// The rows worked flat, right side first.
    var flat: [Row] {
        switch self {
        case .seed: [Row("| k1, p1 | k1"), Row("| k1, p1 | k1")]
        case .doubleMoss: [Row("| k2, p2 | k2"), Row("| p2, k2 | p2"), Row("| p2, k2 | p2"), Row("| k2, p2 | k2")]
        case .brokenRib: [.knit, Row("| p1, k1 | p1")]
        case .waffle: [Row("| p1, k2 | p1"), Row("| k1, p2 | k1"), Row("| p1, k2 | p1"), .knit]
        case .honeycomb: [Row("k1 | sl1 wyif, k1 |"), .purl, Row("k2 | sl1 wyif, k1 | k1"), .purl]
        case .linen: [Row("| k1, sl1 wyif | k2"), Row("| p1, sl1 wyib | p2")]
        case .twistedRib: [Row("| k1 tbl, p1 | k1 tbl"), Row("| p1 tbl, k1 | p1 tbl")]
        case .mistakeRib: [Row("| k2, p2 | k2, p1"), Row("| k2, p2 | k2, p1")]
        case .seededRib: [Row("| k3, p1 | k3"), Row("k1 | p1, k3 | p1, k1")]
        case .garterRidge: [.knit, .purl, .knit, .purl, .purl, .knit]
        case .basketweave:
            Array(repeating: [Row("| k4, p4 | k4"), Row("| p4, k4 | p4")], count: 3).flatMap { $0 }
                + Array(repeating: [Row("| p4, k4 | p4"), Row("| k4, p4 | k4")], count: 3).flatMap { $0 }
        case .diamondBrocade:
            [Row("k4 | p1, k7 | p1, k4"), Row("p3 | k1, p1, k1, p5 | k1, p1, k1, p3"), Row("k2 | p1, k3 | p1, k2"), Row("p1 | k1, p5, k1, p1 |"),
             Row("| p1, k7 | p1"), Row("p1 | k1, p5, k1, p1 |"), Row("k2 | p1, k3 | p1, k2"), Row("p3 | k1, p1, k1, p5 | k1, p1, k1, p3")]
        case .featherFan: [.knit, .purl, Row("k1 | k2tog twice, (yo, k1) 4 times, k2tog twice | k1"), .knit]
        case .eyelet: [.knit, .purl, .knit, .purl, Row("k1 | yo, k2tog |"), .purl]
        case .chevronLace: [Row("k1 | yo, k3, sk2p, k3, yo, k1 |"), .purl]
        case .ropeCable: [Row("| p2, C4F | p2"), Row("| k2, p4 | k2"), Row("| p2, k4 | p2"), Row("| k2, p4 | k2"), Row("| p2, k4 | p2"), Row("| k2, p4 | k2")]
        case .hurdle: [.knit, .knit, Row("| k1, p1 |"), Row("| k1, p1 |")]
        }
    }

    /// The rounds worked in the round, every one from the right side.
    var round: [Row] {
        switch self {
        case .seed: [Row("| k1, p1 |"), Row("| p1, k1 |")]
        case .doubleMoss: [Row("| k2, p2 |"), Row("| k2, p2 |"), Row("| p2, k2 |"), Row("| p2, k2 |")]
        case .brokenRib: [.knit, Row("| k1, p1 |")]
        case .waffle: [Row("| p1, k2 |"), Row("| p1, k2 |"), Row("| p1, k2 |"), .purl]
        case .honeycomb: [Row("| k1, sl1 wyif |"), .knit, Row("| sl1 wyif, k1 |"), .knit]
        case .linen: [Row("| k1, sl1 wyif |"), Row("| sl1 wyif, k1 |")]
        case .twistedRib: [Row("| k1 tbl, p1 |")]
        case .mistakeRib: [Row("| k2, p2 |"), Row("| k1, p2, k1 |")]
        case .seededRib: [Row("| k3, p1 |"), Row("| p1, k1, p2 |")]
        case .garterRidge: [.knit, .knit, .knit, .knit, .purl, .purl]
        case .basketweave: Array(repeating: Row("| k4, p4 |"), count: 6) + Array(repeating: Row("| p4, k4 |"), count: 6)
        case .diamondBrocade:
            [Row("| k4, p1, k3 |"), Row("| k3, p1, k1, p1, k2 |"), Row("| k2, p1, k3, p1, k1 |"), Row("| k1, p1, k5, p1 |"),
             Row("| p1, k7 |"), Row("| k1, p1, k5, p1 |"), Row("| k2, p1, k3, p1, k1 |"), Row("| k3, p1, k1, p1, k2 |")]
        case .featherFan: [.knit, .knit, Row("| k2tog twice, (yo, k1) 4 times, k2tog twice |"), .purl]
        case .eyelet: [.knit, .knit, .knit, .knit, Row("| yo, k2tog |"), .knit]
        case .chevronLace: [Row("| yo, k3, sk2p, k3, yo, k1 |"), .knit]
        case .ropeCable: [Row("| p2, C4F |")] + Array(repeating: Row("| p2, k4 |"), count: 5)
        case .hurdle: [.knit, .purl, Row("| k1, p1 |"), Row("| k1, p1 |")]
        }
    }

    /// Rows to the inch against stockinette's: slipped stitches and garter ridges pack more rows in.
    var rowFactor: Double {
        switch self {
        case .seed, .doubleMoss: 1.1
        case .waffle: 1.15
        case .honeycomb: 1.2
        case .linen: 1.7
        case .hurdle: 1.25
        case .mistakeRib, .seededRib, .garterRidge, .basketweave: 1.05
        case .featherFan: 0.95
        default: 1.0
        }
    }

    /// Stitches to the inch against stockinette's: ribs and cables draw in, lace opens out.
    var widthFactor: Double {
        switch self {
        case .linen: 1.35
        case .twistedRib: 1.3
        case .mistakeRib, .ropeCable: 1.2
        case .seededRib: 1.15
        case .brokenRib: 1.1
        case .waffle, .honeycomb, .hurdle: 1.05
        case .featherFan, .chevronLace: 0.95
        default: 1.0
        }
    }

    /// Yarn over an area against stockinette's.
    var yarnFactor: Double {
        switch self {
        case .ropeCable: 1.25
        case .waffle, .linen, .twistedRib, .mistakeRib, .hurdle: 1.2
        case .seed, .doubleMoss, .honeycomb, .seededRib, .basketweave: 1.15
        case .brokenRib, .garterRidge: 1.1
        case .diamondBrocade: 1.05
        default: 1.0
        }
    }

    /// Stockinette-based fabric curls at a flat edge, so a flat piece gets a garter border and a round one
    /// garter edges. Knit and purl textures, ribs, cables and linen stitch lie flat on their own.
    var curls: Bool { [.honeycomb, .garterRidge, .diamondBrocade, .featherFan, .eyelet, .chevronLace].contains(self) }

    var bindOff: String { isLace ? "Bind off loosely knitwise" : "Bind off loosely in pattern" }

    // MARK: Writing rows

    /// The rows of one repeat, written for a piece of `stitches` stitches with `border` garter stitches
    /// kept at each edge of a flat row. Nil when the count does not fit the repeat.
    func texts(stitches: Int, flat: Bool, border: Int = 0) -> [String]? {
        let rows = flat ? self.flat : round
        var out: [String] = []
        for row in rows {
            guard let text = Self.write(row, stitches: stitches, flat: flat, border: flat ? border : 0) else { return nil }
            out.append(text)
        }
        return out
    }

    /// Whether `stitches` works the pattern with whole repeats on every row.
    func fits(_ stitches: Int, flat: Bool, border: Int = 0) -> Bool { texts(stitches: stitches, flat: flat, border: border) != nil }

    /// The stitch count nearest `wanted` that the pattern fits, flat with a border or in the round, at
    /// least `repeats` repeats across, and more when a row that opens and closes with part of a repeat
    /// needs them to hold a whole one. `multiple` is any other count the shape needs it to divide.
    func count(near wanted: Double, flat: Bool, border: Int = 0, multiple other: Int = 1, repeats: Int = 1) -> Int {
        let step = flat ? multiple : Self.lcm(multiple, other)
        let fixed = flat ? extra + 2 * border : 0
        var n = max(repeats, Int(((wanted - Double(fixed)) / Double(step)).rounded()))
        while !fits(fixed + n * step, flat: flat, border: border), n < repeats + 8 { n += 1 }
        return fixed + n * step
    }

    /// Rows for `inches` of fabric at a stockinette row gauge, in whole repeats (at least one), and an
    /// even count when flat so the last row is a wrong-side row.
    func rows(_ inches: Double, rpi: Double, flat: Bool) -> Int {
        let height = (flat ? self.flat : round).count
        let repeats = max(1, Int((inches * rpi * rowFactor / Double(height)).rounded()))
        var total = repeats * height
        if flat, total % 2 == 1 { total += height }
        return total
    }

    static func lcm(_ a: Int, _ b: Int) -> Int {
        func gcd(_ x: Int, _ y: Int) -> Int { y == 0 ? x : gcd(y, x % y) }
        return a / gcd(a, max(1, b)) * max(1, b)
    }

    private static func write(_ row: Row, stitches n: Int, flat: Bool, border: Int) -> String? {
        if let plain = row.plain {
            switch (plain, border) {
            case (.knit, _): return "Knit"
            case (.purl, 0): return "Purl"
            case (.purl, let b): return "K\(b), purl to the last \(b) stitches, k\(b)"
            }
        }
        let edge = border > 0 ? ["k\(border)"] : []
        let before = merge(edge + segments(row.start)), after = merge(segments(row.end) + edge)
        func width(_ parts: [String]) -> Int { parts.flatMap { Op.parse($0) }.reduce(0) { $0 + $1.takes } }
        let repeat_ = width([row.repeating])
        let middle = n - width(before) - width(after)
        guard repeat_ > 0, middle >= repeat_, middle % repeat_ == 0 else { return nil }
        let left = width(after)
        let tail = left == 0 ? (flat ? "to the end" : "around") : left == 1 ? "to the last stitch" : "to the last \(left) stitches"
        let text = (before + ["*" + row.repeating + "; repeat from * " + tail] + after).joined(separator: ", ")
        // "*K1, p1": the first letter is a capital, after the asterisk too.
        guard let first = text.firstIndex(where: \.isLetter) else { return text }
        return text[..<first] + text[first...first].uppercased() + text[text.index(after: first)...]
    }

    /// The comma-separated parts of a written row, a group in parentheses kept whole.
    private static func segments(_ text: String) -> [String] {
        var parts: [String] = [], current = "", depth = 0
        for c in text {
            if c == "(" { depth += 1 }
            if c == ")" { depth -= 1 }
            if c == ",", depth == 0 {
                parts.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(c)
            }
        }
        let last = current.trimmingCharacters(in: .whitespaces)
        if !last.isEmpty { parts.append(last) }
        return parts
    }

    /// Runs of plain knits or purls side by side read as one: "k3, k1" is "k4".
    private static func merge(_ parts: [String]) -> [String] {
        var out: [String] = []
        for part in parts {
            if let last = out.last, let a = Op.single(last)?.plainKind, let b = Op.single(part)?.plainKind, a == b,
               let x = Int(last.dropFirst()), let y = Int(part.dropFirst()) {
                out[out.count - 1] = "\(a)\(x + y)"
            } else {
                out.append(part)
            }
        }
        return out
    }

    // MARK: Stitches as worked

    /// One instruction within a row, and how many stitches it works and leaves.
    struct Op: Equatable, Sendable {
        var text: String
        var takes: Int
        var makes: Int

        /// "k" or "p" for a plain run of knits or purls.
        var plainKind: String? {
            guard let first = text.first, first == "k" || first == "p", text.dropFirst().allSatisfy(\.isNumber), text.count > 1 else { return nil }
            return String(first)
        }

        /// What each stitch looks like, seen from the side it is worked on, in the order worked.
        var looks: [Look] {
            if let kind = plainKind { return Array(repeating: kind == "k" ? .knit : .purl, count: takes) }
            switch text {
            case "k1 tbl": return [.twisted]
            case "p1 tbl": return [.twistedPurl]
            case "sl1 wyif": return [.slipFront]
            case "sl1 wyib": return [.slipBack]
            case "yo": return [.hole]
            case "k2tog", "ssk", "sk2p": return [.knit]
            case "C4F": return Array(repeating: .cable, count: 4)
            default: return []
            }
        }

        private static let known: [String: (takes: Int, makes: Int)] = [
            "k1 tbl": (1, 1), "p1 tbl": (1, 1), "sl1 wyif": (1, 1), "sl1 wyib": (1, 1),
            "yo": (0, 1), "k2tog": (2, 1), "ssk": (2, 1), "sk2p": (3, 1), "C4F": (4, 4),
        ]

        /// Reads "k2tog twice, (yo, k1) 4 times, p2" into single instructions, groups spelled out.
        static func parse(_ text: String) -> [Op] {
            var ops: [Op] = []
            var rest = Substring(text)
            func skip() { while let c = rest.first, c == "," || c == " " { rest = rest.dropFirst() } }
            skip()
            while !rest.isEmpty {
                var group: [Op]
                if rest.first == "(" {
                    guard let close = rest.firstIndex(of: ")") else { return ops }
                    group = parse(String(rest[rest.index(after: rest.startIndex)..<close]))
                    rest = rest[rest.index(after: close)...]
                } else {
                    let stop = rest.firstIndex { $0 == "," } ?? rest.endIndex
                    var word = String(rest[..<stop]).trimmingCharacters(in: .whitespaces)
                    rest = rest[stop...]
                    var times = 1
                    if word.hasSuffix(" twice") {
                        times = 2
                        word = String(word.dropLast(6))
                    }
                    guard let op = single(word) else { return ops }
                    group = Array(repeating: op, count: times)
                }
                skip()
                // "(yo, k1) 4 times"
                let digits = rest.prefix(while: \.isNumber)
                if !digits.isEmpty, rest.dropFirst(digits.count).hasPrefix(" times"), let times = Int(digits) {
                    rest = rest.dropFirst(digits.count + 6)
                    group = Array(repeating: group, count: times).flatMap { $0 }
                    skip()
                }
                ops += group
            }
            return ops
        }

        static func single(_ word: String) -> Op? {
            if let known = known[word] { return Op(text: word, takes: known.takes, makes: known.makes) }
            guard let first = word.first, first == "k" || first == "p", let count = Int(word.dropFirst()), count > 0 else { return nil }
            return Op(text: word, takes: count, makes: count)
        }
    }

    /// How a stitch shows on the right side, for drawing the fabric and checking a pattern's rows.
    enum Look: Character, Sendable {
        case knit = "v", purl = "-", twisted = "x", twistedPurl = "=", slipFront = "s", slipBack = "S", hole = "o", cable = "c"

        /// The same stitch seen from the other side of the fabric.
        var flipped: Look {
            switch self {
            case .knit: .purl
            case .purl: .knit
            case .twisted: .twistedPurl
            case .twistedPurl: .twisted
            case .slipFront: .slipBack
            case .slipBack: .slipFront
            case .hole, .cable: self
            }
        }
    }

    /// The fabric as the right side shows it, cast-on row last, for `stitches` stitches over `height`
    /// repeats. Each line is one row, left to right as the right side faces. Nil when a row does not fit.
    func looks(stitches n: Int, flat: Bool, border: Int = 0, repeats: Int = 1) -> [[Look]]? {
        let rows = flat ? self.flat : round
        var lines: [[Look]] = []
        for index in 0..<(rows.count * repeats) {
            let row = rows[index % rows.count]
            let rightSide = !flat || index % 2 == 0
            guard let worked = Self.work(row, stitches: n, flat: flat, border: border) else { return nil }
            // Worked from the right-hand end on the right side, from the left-hand end on the wrong side.
            let seen = rightSide ? worked : worked.map(\.flipped)
            lines.append(rightSide ? seen : seen.reversed())
        }
        return lines.reversed()
    }

    /// The stitches a row leaves, in the order worked. Nil when the row does not use exactly `n` stitches.
    private static func work(_ row: Row, stitches n: Int, flat: Bool, border: Int) -> [Look]? {
        if let plain = row.plain {
            if plain == .knit { return Array(repeating: .knit, count: n) }
            let b = flat ? border : 0
            return Array(repeating: Look.knit, count: b) + Array(repeating: .purl, count: n - 2 * b) + Array(repeating: .knit, count: b)
        }
        let edge = border > 0 && flat ? [Op(text: "k\(border)", takes: border, makes: border)] : []
        let start = edge + Op.parse(row.start), repeating = Op.parse(row.repeating), end = Op.parse(row.end) + edge
        let width = repeating.reduce(0) { $0 + $1.takes }
        let fixed = (start + end).reduce(0) { $0 + $1.takes }
        guard width > 0, n - fixed >= width, (n - fixed) % width == 0 else { return nil }
        let ops = start + Array(repeating: repeating, count: (n - fixed) / width).flatMap { $0 } + end
        guard ops.reduce(0, { $0 + $1.takes }) == n, ops.reduce(0, { $0 + $1.makes }) == n else { return nil }
        return ops.flatMap(\.looks)
    }
}
