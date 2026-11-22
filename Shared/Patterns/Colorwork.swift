import Foundation

/// One yarn of a colorwork pattern, the way a knitter would name it in the instructions.
struct Shade: Codable, Equatable, Hashable, Sendable {
    /// Lowercase, as it reads inside a row: "k3 cream".
    var name: String
    /// "#RRGGBB".
    var hex: String

    var rgb: (red: Double, green: Double, blue: Double)? {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return (Double(value >> 16 & 0xFF) / 255, Double(value >> 8 & 0xFF) / 255, Double(value & 0xFF) / 255)
    }
}

/// Stripes and a charted motif laid over one of the library's shapes. The shape's engine writes the
/// stitches; colorwork only decides which yarn each stitch is worked in.
struct Colorwork: Equatable, Hashable, Sendable {
    struct Stripe: Equatable, Hashable, Sendable {
        var color: Int
        /// Inches rather than rows, so a stripe keeps its proportions at every gauge.
        var inches: Double
    }

    struct Chart: Equatable, Hashable, Sendable {
        enum Placement: String, Sendable {
            /// The motif runs all the way around, so the stitch count must be a multiple of its width.
            case repeating = "repeat"
            /// One motif centered on the front, on a ground of the stripe underneath.
            case motif
        }

        var placement: Placement
        /// The chart as it looks on the right side, top row first. -1 is the color of the stripe underneath.
        var rows: [[Int]]
        /// The stripe the chart is centered on. Nil centers it on the longest stretch of stockinette.
        var stripe: Int?
        /// Embroidered over the finished fabric in duplicate stitch, not knitted in: for a small motif on a
        /// round, where knitting it would carry a second yarn all the way around for a few stitches.
        var duplicate = false
        /// Repeats up the whole stretch of stockinette as well as across it, so a flat piece is covered.
        var tiled = false

        var width: Int { rows.first?.count ?? 0 }
        var height: Int { rows.count }
    }

    /// Two to four yarns, color A first. A is the main color: the cast on, and every row no stripe covers.
    var palette: [Shade]
    /// The color of the shape's edging: the brim, cuff or lower border it starts with. Nil leaves it to the stripes.
    var brim: Int?
    /// Stripes from the cast-on edge up, or from the top of the edging when it has a color of its own.
    /// After the last one the main color carries on, unless they repeat.
    var stripes: [Stripe] = []
    var repeatsStripes = false
    var chart: Chart?
    var ears = false
    /// The color of the ears themselves. Nil works them in the main color.
    var ear: Int?
    /// The color of the rim picked up around each ear. Nil works it in the main color.
    var rim: Int?
    /// Stripes stay out of ribbed edgings (hems, cuffs, bands) wherever they fall in the pattern: they keep the
    /// brim's color, or the main one. On for shapes that take stripes only, where the edging comes last as well as first.
    var plainEdges = false

    static func letter(_ index: Int) -> String { String(UnicodeScalar(UInt8(65 + index))) }

    static func index(_ letter: Character) -> Int? {
        guard let ascii = letter.asciiValue, ascii >= 65, ascii < 65 + 4 else { return nil }
        return Int(ascii) - 65
    }
}

/// Turns a plan in one color into the same plan in several: it names the yarn on every row that changes
/// color, writes out each chart row, and counts the yarn of each color from the rows it wrote.
enum Painter {
    struct Result {
        var plan: PatternPlan
        /// Anything that kept the colorwork from fitting this size and gauge. The plan is still knittable
        /// (a chart that does not fit is left out), but a published design must have none.
        var issues: [String]
    }

    private struct Row {
        var step: Int
        var row: Int
        var text: String
        var stitches: Int
        var piece: Int
        /// Knitted rows into its piece, from 0.
        var index: Int
        var flat: Bool
        var chartable: Bool
        /// Edge stitches kept in garter on a flat stockinette panel.
        var border: Int
        /// Part of the edging the piece starts with: its first stretch of texture, below the main fabric.
        var brim = false
        var trim = Trim.none
        /// A wrong-side row of flat work, where a new yarn would show its tail on the face: a stripe waits for the next right-side row.
        var wrongSide = false
        /// A ribbed row: knit and purl stitches in a repeat, as an edging has.
        var textured = false
    }

    /// Small pieces knit apart and sewn on (a section named "... Ear"): the main color, with the rim
    /// picked up around them in a color of its own. Stripes and charts are for the main piece.
    private enum Trim { case none, ear, rim }

    /// The words that tell a knitter to strand: said once on any plan with a chart row.
    static let carrying = "Carry the unused yarn loosely across the back, and catch it every 3 to 4 stitches on longer runs"

    /// `rate` is rows to the inch of the shape's own fabric, so stripes come out the height they say.
    /// `float` is the longest run a yarn may be carried behind the work.
    /// `garter` asks for stripes an even number of rows high in the round too, so they change on a knit round.
    static func paint(_ plan: PatternPlan, with work: Colorwork, gauge g: Gauge, rate: Double, float: Int, garter: Bool = false) -> Result {
        var issues: [String] = []
        let rows = flatten(plan)
        let names = work.palette.map(\.name)
        var even: [Int: Bool] = [:]
        for row in rows where even[row.piece] == nil { even[row.piece] = row.flat || garter }

        // The yarn of each row from the stripes, then the chart over them.
        var lift: [Int: Int] = [:]
        if work.brim != nil { for row in rows where row.brim { lift[row.piece, default: 0] += 1 } }
        let scheduled = rows.map { row in
            switch row.trim {
            case .ear: return work.ear ?? 0
            case .rim: return work.rim ?? 0
            case .none: break
            }
            if let brim = work.brim, row.brim { return brim }
            if work.plainEdges, row.textured { return work.brim ?? 0 }
            return stripeColor(at: row.index - (lift[row.piece] ?? 0), even: even[row.piece] ?? false, work: work, rate: rate)
        }
        var color = scheduled
        for at in rows.indices.dropFirst() where rows[at].wrongSide && rows[at - 1].piece == rows[at].piece && rows[at - 1].trim == rows[at].trim && scheduled[at] != color[at - 1] {
            color[at] = color[at - 1]
        }
        var cells: [Int: [Int]] = [:]
        if let chart = work.chart, chart.width > 0, chart.height > 0 {
            for piece in Set(rows.map(\.piece)).sorted() {
                let mine = rows.indices.filter { rows[$0].piece == piece }
                guard mine.contains(where: { rows[$0].trim == .none }) else { continue }
                var lines: [(at: Int, line: [Int])] = []
                if chart.tiled {
                    // The chart repeats up the longest stretch of stockinette, from its first row to its last.
                    var best = 0..<0, run = 0
                    for (offset, at) in mine.enumerated() {
                        run = rows[at].chartable ? run + 1 : 0
                        if run > best.count { best = (offset - run + 1)..<(offset + 1) }
                    }
                    guard best.count >= chart.height else {
                        issues.append("The \(chart.height)-row chart does not fit the rows of plain stockinette")
                        continue
                    }
                    let bottomUp = Array(chart.rows.reversed())
                    lines = best.enumerated().map { (mine[$1], bottomUp[$0 % chart.height]) }
                } else {
                    guard let start = place(chart, rows: rows, indices: mine, lift: lift[piece] ?? 0, work: work, rate: rate, even: even[piece] ?? false, issues: &issues) else { continue }
                    lines = chart.rows.reversed().enumerated().map { (mine[start + $0], $1) }
                }
                for (at, line) in lines {
                    let row = rows[at]
                    if let filled = fill(line, row: row, under: color[at], placement: chart.placement, issues: &issues) {
                        if !chart.duplicate, let longest = longestFloat(filled, around: !row.flat && chart.placement == .repeating), longest > float {
                            issues.append("A float of \(longest) stitches on a row of \(row.stitches) (the most is \(float))")
                        }
                        cells[at] = filled
                    }
                }
            }
        }

        // Stripes that run out before the top leave the main color showing there, as the design intends.
        if !work.repeatsStripes, !work.stripes.isEmpty {
            let main = rows.filter { $0.piece == 0 && $0.trim == .none }.count
            let top = main - (lift[0] ?? 0) - stripeRows(work, rate: rate, even: even[0] ?? false).reduce(0, +)
            let least = max(2, Int((0.75 * rate).rounded()))
            if top < least { issues.append("The stripes leave \(max(0, top)) rows of \(names[0]) at the top, fewer than \(least)") }
        }

        // Instructions: a row that starts a new yarn says so, and a chart row spells out every color.
        let embroidered = work.chart?.duplicate == true
        var texts: [String?] = Array(repeating: nil, count: rows.count)
        var previous: Int?
        for (at, row) in rows.enumerated() {
            if row.index == 0 { previous = color[at] }
            // A chart added afterward leaves its rows as the engine wrote them.
            if let filled = cells[at], !embroidered {
                texts[at] = chartText(filled, row: row, names: names, placement: work.chart?.placement ?? .motif, width: work.chart?.width ?? 1)
                // Two yarns were live: the next plain row says which one goes on.
                previous = Set(filled).count > 1 ? nil : color[at]
                continue
            }
            guard color[at] != previous else { continue }
            if row.trim == .rim, work.rim != nil {
                // The pick-up that starts the rim names its yarn.
                previous = color[at]
                continue
            }
            let name = names[color[at]]
            if !row.flat, row.text.range(of: "\\bp\\d|^\\*?P", options: [.regularExpression, .caseInsensitive]) != nil {
                // A purl stitch in a new color shows the old one through it: the first round is knit.
                texts[at] = "With \(name), knit"
            } else {
                texts[at] = "With \(name), " + lowerFirst(row.text)
            }
            previous = color[at]
        }

        // Every color must be used somewhere, or it should not be on the list.
        var used = Set(color)
        for filled in cells.values { used.formUnion(filled) }
        for index in work.palette.indices where !used.contains(index) {
            issues.append("Color \(Colorwork.letter(index)) (\(names[index])) is never used")
        }

        var painted = plan
        painted.steps = regroup(plan.steps, rows: rows, colors: color, cells: cells, texts: texts, names: names, rim: work.rim)
        if embroidered, !cells.isEmpty {
            let added = embroidery(cells, rows: rows, colors: color, names: names)
            let at = painted.steps.firstIndex { $0.section == "Finishing" } ?? painted.steps.count
            painted.steps.insert(contentsOf: added.map { Step(section: "Finishing", texts: [$0], rows: 1, isAction: true) }, at: at)
        }
        painted.palette = work.palette

        // Yarn per color, from the rows as written: worked stitches, plus the strands carried behind them.
        var worked = Array(repeating: 0.0, count: work.palette.count)
        for (at, row) in rows.enumerated() {
            guard let filled = cells[at] else {
                worked[color[at]] += Double(row.stitches) * 4.3
                continue
            }
            if embroidered {
                // The row is knitted whole in its own yarn; each stitch sewn over it takes a little more than a stitch.
                worked[color[at]] += Double(row.stitches) * 4.3
                for index in filled where index != color[at] { worked[index] += 5 }
                continue
            }
            for index in Set(filled) {
                let count = filled.filter { $0 == index }.count
                let first = filled.firstIndex(of: index) ?? 0, last = filled.lastIndex(of: index) ?? 0
                let carried = (!row.flat && work.chart?.placement == .repeating) ? row.stitches - count : (last - first + 1) - count
                worked[index] += Double(count) * 4.3 + Double(max(0, carried))
            }
        }
        var yards = worked.map { max(10, Int(($0 / g.spi / 36 * 1.15 / 10).rounded(.up)) * 10) }
        let spare = plan.yards - yards.reduce(0, +)
        // What the plain shape needs beyond the rows counted goes to the yarn that works the most of them.
        if spare > 0, let most = worked.indices.max(by: { worked[$0] < worked[$1] }) {
            yards[most] += Int((Double(spare) / 10).rounded(.up)) * 10
        }
        let lines = work.palette.indices.map { index in
            "\(names[index].capitalized), color \(Colorwork.letter(index)): " + lowerFirst(Engines.yarnLine(yards[index], g))
        }
        painted.materials = lines + plan.materials.dropFirst() + (cells.isEmpty || embroidered ? [] : [carrying])
        painted.yards = yards.reduce(0, +)
        return Result(plan: painted, issues: issues)
    }

    // MARK: Rows

    private static func flatten(_ plan: PatternPlan) -> [Row] {
        var rows: [Row] = []
        var piece = -1, index = 0, round = false, last = 0
        var firstKnit = true, pickedUp = false
        // Rows into the current stretch of flat work in one section: the first is a right-side row.
        var flatRun = 0, flatSection = ""
        for (s, step) in plan.steps.enumerated() {
            if step.isAction {
                let text = step.texts[0]
                if text.range(of: "^(With [^,]+, )?(Loosely )?cast on", options: [.regularExpression, .caseInsensitive]) != nil {
                    piece += 1
                    index = 0
                    round = text.contains("Join in the round")
                    firstKnit = true
                    pickedUp = false
                }
                if text.hasPrefix("Pick up") { pickedUp = true }
                last = step.stitches ?? last
                continue
            }
            let border = step.texts.lazy.compactMap(borderOf).first ?? 0
            let trim: Trim = !step.section.hasSuffix(" Ear") ? .none : pickedUp ? .rim : .ear
            let brim = firstKnit && step.texts != ["Knit"] && trim == .none
            firstKnit = false
            for r in 0..<step.rows {
                let text = step.text(at: r)
                let stitches = step.stitches(after: r) ?? last
                let flat = !round || text.hasSuffix("turn")
                let chartable = flat ? border > 0 : (text == "Knit" && step.delta == 0)
                if !flat || step.section != flatSection { flatRun = 0 }
                flatSection = step.section
                let wrong = flat && flatRun % 2 == 1
                if flat { flatRun += 1 }
                rows.append(Row(step: s, row: r, text: text, stitches: stitches, piece: max(0, piece), index: index, flat: flat, chartable: chartable && trim == .none, border: border, brim: brim, trim: trim, wrongSide: wrong, textured: text.range(of: #"\bk\d+, \*?p\d+\b|\bp\d+, \*?k\d+\b|in rib"#, options: [.regularExpression, .caseInsensitive]) != nil))
                index += 1
                last = stitches
            }
        }
        // A piece worked in one stitch throughout has no edging of its own.
        for piece in Set(rows.map(\.piece)) {
            let mine = rows.indices.filter { rows[$0].piece == piece }
            if mine.allSatisfy({ rows[$0].brim }) { for at in mine { rows[at].brim = false } }
        }
        return rows
    }

    /// The garter edge of a stockinette panel: "K5, purl to the last 5 stitches, k5" gives 5.
    private static func borderOf(_ text: String) -> Int? {
        guard let match = text.firstMatch(of: /^K(\d+), purl to the last (\d+) stitches, k(\d+)$/), match.1 == match.2, match.2 == match.3 else { return nil }
        return Int(match.1)
    }

    // MARK: Stripes

    /// Rows in each stripe at this rate. A stripe on flat fabric is an even number of rows, so every
    /// change of yarn falls on a right-side row.
    private static func stripeRows(_ work: Colorwork, rate: Double, even: Bool) -> [Int] {
        work.stripes.map { stripe in
            let rows = max(even ? 2 : 1, Int((stripe.inches * rate).rounded()))
            return even && rows % 2 == 1 ? rows + 1 : rows
        }
    }

    private static func stripeColor(at index: Int, even: Bool, work: Colorwork, rate: Double) -> Int {
        let heights = stripeRows(work, rate: rate, even: even)
        let total = heights.reduce(0, +)
        guard total > 0 else { return 0 }
        var at = index
        if work.repeatsStripes { at %= total } else if at >= total { return 0 }
        for (stripe, height) in zip(work.stripes, heights) {
            if at < height { return stripe.color }
            at -= height
        }
        return 0
    }

    // MARK: Chart

    /// Where the chart's bottom row falls in a piece, as an offset into its rows.
    private static func start(_ chart: Colorwork.Chart, rows: [Row], indices: [Int], lift: Int, work: Colorwork, rate: Double, even: Bool) -> Int? {
        let span: Range<Int>
        if let stripe = chart.stripe {
            let heights = stripeRows(work, rate: rate, even: even)
            guard stripe < heights.count else { return nil }
            let start = lift + heights.prefix(stripe).reduce(0, +)
            span = start..<min(indices.count, start + heights[stripe])
        } else {
            // The longest stretch of stockinette in the piece.
            var best = 0..<0, run = 0
            for (offset, at) in indices.enumerated() {
                run = rows[at].chartable ? run + 1 : 0
                if run > best.count { best = (offset - run + 1)..<(offset + 1) }
            }
            span = best
        }
        guard span.count >= chart.height else { return nil }
        return span.lowerBound + (span.count - chart.height) / 2
    }

    /// The offset of the chart's bottom row, once it is known to sit on stockinette. Nil, with the reason, when it cannot.
    private static func place(_ chart: Colorwork.Chart, rows: [Row], indices: [Int], lift: Int, work: Colorwork, rate: Double, even: Bool, issues: inout [String]) -> Int? {
        guard let start = start(chart, rows: rows, indices: indices, lift: lift, work: work, rate: rate, even: even) else {
            issues.append("The \(chart.height)-row chart does not fit the rows of \(chart.stripe.map { "stripe \($0 + 1)" } ?? "plain stockinette")")
            return nil
        }
        let covered = indices[start..<(start + chart.height)]
        guard covered.allSatisfy({ rows[$0].chartable }) else {
            issues.append("The chart lands on rows that are not stockinette")
            return nil
        }
        return start
    }

    /// One row of stitch colors, left to right as the right side faces.
    private static func fill(_ line: [Int], row: Row, under: Int, placement: Colorwork.Chart.Placement, issues: inout [String]) -> [Int]? {
        let n = row.stitches, w = line.count
        var out = Array(repeating: under, count: n)
        func put(_ cell: Int, at p: Int) { out[p] = cell < 0 ? under : cell }
        switch (placement, row.flat) {
        case (.repeating, false):
            guard n % w == 0 else {
                issues.append("\(n) stitches do not divide into the chart's \(w)-stitch repeat")
                return nil
            }
            for p in 0..<n { put(line[p % w], at: p) }
        case (.repeating, true):
            let middle = n - 2 * row.border
            let repeats = middle / w
            guard repeats > 0 else {
                issues.append("The chart's \(w) stitches do not fit between the borders of \(n)")
                return nil
            }
            let left = row.border + (middle - repeats * w) / 2
            for p in left..<(left + repeats * w) { put(line[(p - left) % w], at: p) }
        case (.motif, _):
            let room = n - 2 * row.border
            guard w + 4 <= (row.flat ? room : n / 2) else {
                issues.append("The \(w)-stitch motif does not fit on \(room) stitches")
                return nil
            }
            // In the round the front is the first half of the round, which faces right of the marker:
            // the motif is centered there, so a hat joined flat at the sides has it in the middle.
            let left = row.flat ? (n - w) / 2 : n / 2 + (n / 2 - w) / 2
            for c in 0..<w { put(line[c], at: left + c) }
        }
        return out
    }

    /// The longest run of stitches a yarn is carried past, counted between its own stitches.
    private static func longestFloat(_ cells: [Int], around: Bool) -> Int? {
        let colors = Set(cells)
        guard colors.count > 1 else { return nil }
        var longest = 0
        for color in colors {
            let at = cells.indices.filter { cells[$0] == color }
            for (a, b) in zip(at, at.dropFirst()) { longest = max(longest, b - a - 1) }
            if around, let first = at.first, let last = at.last { longest = max(longest, cells.count - 1 - last + first) }
        }
        return longest
    }

    /// "K3 cream, k1 green, k3 cream", in the order the stitches are worked.
    private static func chartText(_ cells: [Int], row: Row, names: [String], placement: Colorwork.Chart.Placement, width: Int) -> String {
        // Worked right to left as the right side faces, so a right-side row reads the chart backward.
        let rightSide = !row.flat || row.index % 2 == 0
        let order = rightSide ? Array(cells.reversed()) : cells
        func kind(_ position: Int) -> String {
            if rightSide { return "k" }
            return position < row.border || position >= cells.count - row.border ? "k" : "p"
        }
        func runs(_ range: Range<Int>) -> String {
            var parts: [(kind: String, color: Int, count: Int)] = []
            for p in range {
                let k = kind(p), c = order[p]
                if let last = parts.last, last.kind == k, last.color == c { parts[parts.count - 1].count += 1 } else { parts.append((k, c, 1)) }
            }
            return parts.map { "\($0.kind)\($0.count) \(names[$0.color])" }.joined(separator: ", ")
        }
        let n = order.count
        guard placement == .repeating else { return upperFirst(runs(0..<n)) }
        if !row.flat { return "*" + upperFirst(runs(0..<width)) + "; repeat from * around" }
        // Flat: plain stitches at each side of whole repeats, the way `fill` laid them out.
        let middle = n - 2 * row.border, repeats = middle / width
        let left = row.border + (middle - repeats * width) / 2
        let lead = rightSide ? n - left - repeats * width : left
        let tail = n - lead - repeats * width
        let opening = lead > 0 ? upperFirst(runs(0..<lead)) + ", *" + runs(lead..<(lead + width)) : "*" + upperFirst(runs(lead..<(lead + width)))
        return opening + (tail > 0 ? "; repeat from * to the last \(tail) stitches, " + runs((n - tail)..<n) : "; repeat from * to the end")
    }

    // MARK: Duplicate stitch

    /// A chart sewn over the finished fabric: where it goes, then each of its rows from the bottom, read
    /// left to right as the right side faces.
    private static func embroidery(_ cells: [Int: [Int]], rows: [Row], colors: [Int], names: [String]) -> [String] {
        let covered = cells.keys.sorted()
        guard let bottom = covered.first else { return [] }
        let row = rows[bottom], ground = colors[bottom]
        var left = Int.max, right = -1
        var yarns: [Int] = []
        for at in covered {
            for (p, cell) in (cells[at] ?? []).enumerated() where cell != colors[at] {
                left = min(left, p)
                right = max(right, p)
                if !yarns.contains(cell) { yarns.append(cell) }
            }
        }
        guard right >= left else { return [] }
        let width = right - left + 1
        let line = row.flat ? "row" : "round"
        // Rows of the same yarn straight under the chart, so the knitter can count up from where the color starts.
        var under = 0
        var at = bottom - 1
        while at >= 0, rows[at].piece == row.piece, colors[at] == ground, cells[at] == nil {
            under += 1
            at -= 1
        }
        // A ground that runs down to the cast on is the piece's own fabric, not a stripe: count from the cast on.
        let fromStart = at < 0 || rows[at].piece != row.piece
        let solid = covered.allSatisfy { colors[$0] == ground }
        let band = !solid ? "the front" : fromStart ? "the \(names[ground]) fabric" : "the \(names[ground]) stripe"
        // A round is worked right to left as it faces, so its first stitch is at the right-hand end.
        let first = row.stitches - right
        let across = row.flat
            ? "It is centered, \(left) stitches in from each edge"
            : "It covers stitches \(first) to \(first + width - 1) of the round, counted from the marker"
        let below = under == 0 ? "" : fromStart
            ? ", and starts on \(line) \(under + 1) above the cast on"
            : ", with \(under) \(under == 1 ? line : line + "s") of \(names[ground]) under it"
        var texts = ["With \(list(yarns.map { names[$0] })) and a tapestry needle, work the chart in duplicate stitch over \(band): \(covered.count) \(covered.count == 1 ? line : line + "s") high and \(width) stitches wide. \(across)\(below)."]
        for (number, at) in covered.enumerated() {
            var parts: [(color: Int?, count: Int)] = []
            for p in left...right {
                let cell = cells[at]?[p] ?? colors[at]
                let color: Int? = cell == colors[at] ? nil : cell
                if let last = parts.last, last.color == color { parts[parts.count - 1].count += 1 } else { parts.append((color, 1)) }
            }
            let words = parts.map { part in part.color.map { "\(part.count) \(names[$0])" } ?? "skip \(part.count)" }.joined(separator: ", ")
            texts.append("Chart \(line) \(number + 1)\(number == 0 ? ", the bottom one" : ""), left to right: \(words).")
        }
        return texts
    }

    private static func list(_ words: [String]) -> String {
        words.count < 2 ? words.joined() : words.dropLast().joined(separator: ", ") + " and " + (words.last ?? "")
    }

    // MARK: Steps

    private static func regroup(_ steps: [Step], rows: [Row], colors: [Int], cells: [Int: [Int]], texts: [String?], names: [String], rim: Int?) -> [Step] {
        var byStep: [Int: [Int]] = [:]
        for (at, row) in rows.enumerated() { byStep[row.step, default: []].append(at) }
        var out: [Step] = []
        var castOn = 0
        for (s, step) in steps.enumerated() {
            guard let mine = byStep[s] else {
                var action = step
                if action.isAction, action.texts[0].range(of: "^(With [^,]+, )?(Loosely )?cast on", options: [.regularExpression, .caseInsensitive]) != nil {
                    // The cast on is in the color of the piece's first row.
                    let first = rows.firstIndex { $0.piece == castOn && $0.index == 0 }.map { colors[$0] } ?? 0
                    if let range = action.texts[0].range(of: " stitches") { action.texts[0].replaceSubrange(range, with: " stitches in \(names[first])") }
                    castOn += 1
                }
                if let rim, action.isAction, action.section.hasSuffix(" Ear"), action.texts[0].hasPrefix("Pick up") {
                    action.texts[0] = "With \(names[rim]), " + lowerFirst(action.texts[0])
                }
                out.append(action)
                continue
            }
            var run: [Int] = []
            func flush() {
                guard let first = run.first else { return }
                let r0 = rows[first].row
                let letter = Colorwork.letter(colors[first])
                // A chart sewn on afterward shows on its rows in the picture, though they are knitted plain.
                func look(_ at: Int) -> String { cells[at].map { $0.map(Colorwork.letter).joined() } ?? letter }
                let paint = run.contains { cells[$0] != nil } ? run.map(look) : [letter]
                if run.count == step.rows {
                    var whole = step
                    whole.paint = paint
                    out.append(whole)
                } else if step.delta == 0 {
                    let rotated = (0..<step.texts.count).map { step.texts[(r0 + $0) % step.texts.count] }
                    out.append(Step(section: step.section, texts: rotated, rows: run.count, stitches: step.stitches, paint: paint))
                } else {
                    for at in run { out.append(Step(section: step.section, texts: [rows[at].text], rows: 1, stitches: rows[at].stitches, paint: [look(at)])) }
                }
                run = []
            }
            for at in mine {
                if let text = texts[at] {
                    flush()
                    let paint = cells[at].map { $0.map(Colorwork.letter).joined() } ?? Colorwork.letter(colors[at])
                    out.append(Step(section: step.section, texts: [text], rows: 1, stitches: rows[at].stitches, paint: [paint]))
                } else {
                    if let last = run.last, colors[last] != colors[at] { flush() }
                    run.append(at)
                }
            }
            flush()
        }
        return out
    }

    private static func lowerFirst(_ text: String) -> String { text.prefix(1).lowercased() + text.dropFirst() }
    private static func upperFirst(_ text: String) -> String { text.prefix(1).uppercased() + text.dropFirst() }
}
