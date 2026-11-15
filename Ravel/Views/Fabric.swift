import SwiftUI

/// Stockinette hanging from a needle. The newest row sits at the needle and the
/// work grows downward, the way it does in a knitter's hands. `rows` animates,
/// so a new row slides out from under the needle and an undone row slides back.
struct Fabric: View, Animatable {
    var rows: Double
    var yarn: YarnColor
    /// A row number is tagged on the edge every this many rows. 0 turns tags off.
    var markEvery = 10
    /// The row a repeat started after: the tags count from there, as the repeat dots do.
    var markFrom = 0
    /// Stitch width. 0 sizes the stitches to the space, about nine across.
    var stitch: CGFloat = 24
    var showsNeedle = true
    /// Rules the paper the work will grow into, like a knitting chart: a line where the edge will
    /// sit after each row, with the next tagged rows outlined.
    var chart = false
    /// Colorwork: each knitted row's palette letters, oldest first, and the yarns they name. A row of one
    /// letter is all that color; a longer row is shown around `focus`, the part of the row that faces front.
    var paints: [String] = []
    var palette: [Shade] = []
    var focus = 0.5

    nonisolated var animatableData: Double {
        get { rows }
        set { rows = newValue }
    }

    var body: some View {
        let rows = max(0, rows), yarn = yarn, markEvery = markEvery, markFrom = markFrom, stitch = stitch, showsNeedle = showsNeedle, chart = chart
        let colors = FabricColors(paints: paints, tints: palette.map(\.tint), yarn: yarn.tint, focus: focus)
        Canvas { context, size in
            let w = stitch > 0 ? stitch : max(24, size.width / 9)
            if chart { Self.chart(&context, size: size, rows: rows, w: w, markEvery: markEvery, markFrom: markFrom) }
            Self.draw(&context, size: size, rows: rows, colors: colors, markEvery: markEvery, markFrom: markFrom, w: w, needle: showsNeedle)
        }
        .accessibilityHidden(true)
    }

    /// Whether a row carries a number: every `every` rows, counted from the row a repeat started after.
    nonisolated static func tagged(_ row: Int, every: Int, from start: Int) -> Bool {
        every > 0 && row > start && (row - start) % every == 0
    }

    /// Faint rules on the paper below the work, one where the fabric's edge will sit after each coming row.
    /// The next tagged rows get an outlined tag, so the knitter sees how far it is to the next ten or the
    /// end of the repeat. Drawn first, so the fabric covers the rules as it grows.
    nonisolated private static func chart(_ context: inout GraphicsContext, size: CGSize, rows: Double, w: CGFloat, markEvery: Int, markFrom: Int) {
        let h = w * 0.8
        let top: CGFloat = 26
        var lines = Path()
        var tags: [(number: Int, y: CGFloat)] = []
        var row = Int(rows.rounded(.down)) + 1
        while top + CGFloat(row) * h <= size.height + h {
            let y = top + CGFloat(row) * h
            lines.move(to: CGPoint(x: 0, y: y))
            lines.addLine(to: CGPoint(x: size.width, y: y))
            if tagged(row, every: markEvery, from: markFrom) { tags.append((row, y - h)) }
            row += 1
        }
        context.stroke(lines, with: .color(.primary.opacity(0.07)), lineWidth: 1)
        for tag in tags {
            let text = context.resolve(Text(tag.number, format: .number).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.primary.opacity(0.4)))
            let textSize = text.measure(in: size)
            let pill = CGRect(x: size.width - textSize.width - 22, y: tag.y + (h - textSize.height) / 2 - 2, width: textSize.width + 12, height: textSize.height + 4)
            context.fill(Path(roundedRect: pill, cornerRadius: pill.height / 2), with: .color(Theme.paper))
            context.stroke(Path(roundedRect: pill, cornerRadius: pill.height / 2), with: .color(.primary.opacity(0.2)), lineWidth: 1)
            context.draw(text, at: CGPoint(x: pill.midX, y: pill.midY))
        }
    }

    nonisolated private static func draw(_ context: inout GraphicsContext, size: CGSize, rows: Double, colors: FabricColors, markEvery: Int, markFrom: Int, w: CGFloat, needle: Bool) {
        let h = w * 0.8
        let top: CGFloat = needle ? 26 : 0
        let columns = Int((size.width / w).rounded(.up)) + 1
        let x0 = (size.width - CGFloat(columns) * w) / 2
        let partial = rows - rows.rounded(.down)
        let newest = Int(rows.rounded(.up))
        // A row in progress starts hidden above the needle and slides down into place.
        let slide = partial > 0 ? (partial - 1) * h : 0

        var cloth = context
        cloth.clip(to: Path(CGRect(x: 0, y: top - 1, width: size.width, height: size.height)))
        let depth = min(size.height - top, CGFloat(rows) * h)
        let yarn = colors.newest(newest)
        if depth > 0 {
            cloth.fill(Path(CGRect(x: 0, y: top, width: size.width, height: depth)), with: .color(yarn.shade))
        }

        // Each leg of a stitch is a plump strand with a dark edge, drawn newest row first so every
        // stitch tucks behind the one below it, the way the loops actually sit.
        let strand = StrokeStyle(lineWidth: w * 0.33, lineCap: .round)
        let edge = StrokeStyle(lineWidth: w * 0.33 + max(1.5, w * 0.1), lineCap: .round)
        var tags: [(number: Int, y: CGFloat)] = []
        var index = 0
        while newest - index >= 1 {
            let y = top + CGFloat(index) * h + slide
            if y > size.height { break }
            let number = newest - index
            // Stitches are drawn in batches of one yarn: a row in one color is a single batch.
            let tints = colors.row(number, columns: columns)
            var batches: [(tint: Tint, left: Path, right: Path)] = []
            var batchOf: [Int: Int] = [:]
            for column in 0..<columns {
                let x = x0 + CGFloat(column) * w
                let key = Int(tints[column].red * 255) << 16 | Int(tints[column].green * 255) << 8 | Int(tints[column].blue * 255)
                let batch = batchOf[key] ?? {
                    batches.append((tints[column], Path(), Path()))
                    batchOf[key] = batches.count - 1
                    return batches.count - 1
                }()
                batches[batch].left.move(to: CGPoint(x: x + w * 0.15, y: y + h * 0.1))
                batches[batch].left.addLine(to: CGPoint(x: x + w * 0.41, y: y + h * 1.12))
                batches[batch].right.move(to: CGPoint(x: x + w * 0.85, y: y + h * 0.1))
                batches[batch].right.addLine(to: CGPoint(x: x + w * 0.59, y: y + h * 1.12))
            }
            for batch in batches {
                cloth.stroke(batch.left, with: .color(batch.tint.shade), style: edge)
                cloth.stroke(batch.left, with: .color(batch.tint.color), style: strand)
                cloth.stroke(batch.right, with: .color(batch.tint.shade), style: edge)
                cloth.stroke(batch.right, with: .color(batch.tint.lowlight), style: strand)
            }
            if tagged(number, every: markEvery, from: markFrom) { tags.append((number, y)) }
            index += 1
        }

        for tag in tags where w >= 18 {
            let text = cloth.resolve(Text(tag.number, format: .number).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.white))
            let textSize = text.measure(in: size)
            let pill = CGRect(x: size.width - textSize.width - 22, y: tag.y + (h - textSize.height) / 2 - 2, width: textSize.width + 12, height: textSize.height + 4)
            cloth.fill(Path(roundedRect: pill, cornerRadius: pill.height / 2), with: .color(yarn.shade.opacity(0.92)))
            cloth.draw(text, at: CGPoint(x: pill.midX, y: pill.midY))
        }

        guard needle else { return }
        let needleY = top - 9
        var shaft = Path()
        shaft.move(to: CGPoint(x: 22, y: needleY))
        shaft.addLine(to: CGPoint(x: size.width - 26, y: needleY))
        context.stroke(shaft, with: .color(.primary.opacity(0.82)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        var point = Path()
        point.move(to: CGPoint(x: size.width - 28, y: needleY - 3.5))
        point.addLine(to: CGPoint(x: size.width - 10, y: needleY))
        point.addLine(to: CGPoint(x: size.width - 28, y: needleY + 3.5))
        point.closeSubpath()
        context.fill(point, with: .color(.primary.opacity(0.82)))
        context.fill(Path(ellipseIn: CGRect(x: 10, y: needleY - 8, width: 16, height: 16)), with: .color(.primary.opacity(0.82)))

        // The live stitches: one loop over the needle per column.
        var loops = Path()
        for column in 0..<columns {
            let x = x0 + CGFloat(column) * w
            guard x > 30, x + w < size.width - 34 else { continue }
            loops.move(to: CGPoint(x: x + w * 0.36, y: needleY - 6))
            loops.addLine(to: CGPoint(x: x + w * 0.64, y: needleY + 11))
        }
        context.stroke(loops, with: .color(yarn.color), style: StrokeStyle(lineWidth: w * 0.3, lineCap: .round))
    }
}

/// A small square of a project's fabric, for lists.
struct Swatch: View {
    var yarn: YarnColor
    var size: CGFloat = 52

    var body: some View {
        Fabric(rows: 40, yarn: yarn, markEvery: 0, stitch: size / 4, showsNeedle: false)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
    }
}

/// Which yarn each stitch is drawn in.
struct FabricColors: Sendable {
    var paints: [String]
    var tints: [Tint]
    var yarn: Tint
    var focus: Double

    /// The tints of row `number` (from 1), one per column on screen.
    func row(_ number: Int, columns: Int) -> [Tint] {
        guard number >= 1, number <= paints.count, !tints.isEmpty else { return Array(repeating: yarn, count: columns) }
        let letters = Array(paints[number - 1])
        func tint(_ letter: Character) -> Tint { Colorwork.index(letter).flatMap { $0 < tints.count ? tints[$0] : nil } ?? tints[0] }
        guard letters.count > 1 else { return Array(repeating: tint(letters.first ?? "A"), count: columns) }
        let start = Int(Double(letters.count) * focus) - columns / 2
        return (0..<columns).map { tint(letters[((start + $0) % letters.count + letters.count) % letters.count]) }
    }

    /// The yarn on the needle: the newest row's main color.
    func newest(_ number: Int) -> Tint { row(number, columns: 1)[0] }
}
