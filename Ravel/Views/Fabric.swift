import SwiftUI

/// Stockinette hanging from a needle. The newest row sits at the needle and the
/// work grows downward, the way it does in a knitter's hands. `rows` animates,
/// so a new row slides out from under the needle and an undone row slides back.
struct Fabric: View, Animatable {
    var rows: Double
    var yarn: YarnColor
    /// A row number is tagged on the edge every this many rows. 0 turns tags off.
    var markEvery = 10
    var stitch: CGFloat = 24
    var showsNeedle = true

    nonisolated var animatableData: Double {
        get { rows }
        set { rows = newValue }
    }

    var body: some View {
        let rows = max(0, rows), yarn = yarn, markEvery = markEvery, stitch = stitch, showsNeedle = showsNeedle
        Canvas { context, size in
            Self.draw(&context, size: size, rows: rows, yarn: yarn, markEvery: markEvery, w: stitch, needle: showsNeedle)
        }
        .accessibilityHidden(true)
    }

    nonisolated private static func draw(_ context: inout GraphicsContext, size: CGSize, rows: Double, yarn: YarnColor, markEvery: Int, w: CGFloat, needle: Bool) {
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
            var left = Path()
            var right = Path()
            for column in 0..<columns {
                let x = x0 + CGFloat(column) * w
                left.move(to: CGPoint(x: x + w * 0.15, y: y + h * 0.1))
                left.addLine(to: CGPoint(x: x + w * 0.41, y: y + h * 1.12))
                right.move(to: CGPoint(x: x + w * 0.85, y: y + h * 0.1))
                right.addLine(to: CGPoint(x: x + w * 0.59, y: y + h * 1.12))
            }
            cloth.stroke(left, with: .color(yarn.shade), style: edge)
            cloth.stroke(left, with: .color(yarn.color), style: strand)
            cloth.stroke(right, with: .color(yarn.shade), style: edge)
            cloth.stroke(right, with: .color(yarn.lowlight), style: strand)
            let number = newest - index
            if markEvery > 0, number % markEvery == 0 { tags.append((number, y)) }
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
