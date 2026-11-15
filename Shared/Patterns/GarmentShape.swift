import CoreGraphics
import Foundation

/// The outline each design is drawn in: the thing itself, as a knitter would recognize it. Shared by the
/// app's drawings and the preview the topical design check renders, so both show the same piece.
enum GarmentShape {
    static func path(_ silhouette: Design.Silhouette, in rect: CGRect) -> CGPath {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height, width: w * rect.width, height: h * rect.height)
        }
        let unit = rect.width
        let path = CGMutablePath()
        switch silhouette {
        case .hat:
            path.move(to: p(0.16, 0.74))
            path.addCurve(to: p(0.5, 0.1), control1: p(0.14, 0.34), control2: p(0.3, 0.1))
            path.addCurve(to: p(0.84, 0.74), control1: p(0.7, 0.1), control2: p(0.86, 0.34))
            path.closeSubpath()
            path.addRoundedRect(in: box(0.1, 0.7, 0.8, 0.2), cornerWidth: unit * 0.06, cornerHeight: unit * 0.06)
        case .slouch:
            path.move(to: p(0.18, 0.76))
            path.addCurve(to: p(0.66, 0.08), control1: p(0.04, 0.3), control2: p(0.36, 0.04))
            path.addCurve(to: p(0.84, 0.76), control1: p(0.98, 0.14), control2: p(0.94, 0.5))
            path.closeSubpath()
            path.addRoundedRect(in: box(0.14, 0.74, 0.72, 0.15), cornerWidth: unit * 0.05, cornerHeight: unit * 0.05)
        case .scarf:
            // A long strip with fringe at both ends. The strands meet the strip edge to edge, never overlapping,
            // so the even-odd fill leaves no gaps.
            path.addRoundedRect(in: box(0.33, 0.13, 0.34, 0.72), cornerWidth: unit * 0.02, cornerHeight: unit * 0.02)
            for index in 0..<5 {
                let x = 0.355 + CGFloat(index) * 0.065
                path.addRect(box(x, 0.04, 0.03, 0.09))
                path.addRect(box(x, 0.85, 0.03, 0.09))
            }
        case .cowl:
            path.addEllipse(in: box(0.08, 0.2, 0.84, 0.62))
            path.addEllipse(in: box(0.26, 0.26, 0.48, 0.2))
        case .band:
            path.addEllipse(in: box(0.06, 0.3, 0.88, 0.42))
            path.addEllipse(in: box(0.2, 0.35, 0.6, 0.12))
        case .blanket:
            path.addRoundedRect(in: box(0.1, 0.16, 0.8, 0.68), cornerWidth: unit * 0.04, cornerHeight: unit * 0.04)
        case .cloth:
            path.addRoundedRect(in: box(0.2, 0.2, 0.6, 0.6), cornerWidth: unit * 0.04, cornerHeight: unit * 0.04)
        case .tubes:
            path.addRoundedRect(in: box(0.18, 0.1, 0.26, 0.8), cornerWidth: unit * 0.06, cornerHeight: unit * 0.06)
            path.addRoundedRect(in: box(0.56, 0.1, 0.26, 0.8), cornerWidth: unit * 0.06, cornerHeight: unit * 0.06)
        case .mitts:
            for (x, thumb) in [(CGFloat(0.14), CGFloat(1)), (0.58, -1)] {
                path.addRoundedRect(in: box(x, 0.16, 0.28, 0.7), cornerWidth: unit * 0.07, cornerHeight: unit * 0.07)
                let side = thumb > 0 ? x + 0.24 : x - 0.08
                path.addRoundedRect(in: box(side, 0.36, 0.12, 0.2), cornerWidth: unit * 0.05, cornerHeight: unit * 0.05)
            }
        case .shawl:
            path.move(to: p(0.04, 0.24))
            path.addLine(to: p(0.96, 0.24))
            path.addLine(to: p(0.5, 0.8))
            path.closeSubpath()
        case .hood:
            path.move(to: p(0.2, 0.92))
            path.addCurve(to: p(0.5, 0.06), control1: p(0.06, 0.4), control2: p(0.26, 0.06))
            path.addCurve(to: p(0.8, 0.92), control1: p(0.74, 0.06), control2: p(0.94, 0.4))
            path.closeSubpath()
            path.addEllipse(in: box(0.33, 0.3, 0.34, 0.3))
        case .kerchief:
            path.move(to: p(0.03, 0.46))
            path.addQuadCurve(to: p(0.97, 0.46), control: p(0.5, 0.3))
            path.addQuadCurve(to: p(0.03, 0.46), control: p(0.5, 0.86))
            path.closeSubpath()
        case .sweater:
            path.move(to: p(0.38, 0.12))
            path.addCurve(to: p(0.62, 0.12), control1: p(0.44, 0.2), control2: p(0.56, 0.2))
            path.addLine(to: p(0.76, 0.17))
            path.addLine(to: p(0.98, 0.62))
            path.addLine(to: p(0.86, 0.69))
            path.addLine(to: p(0.74, 0.44))
            path.addLine(to: p(0.74, 0.9))
            path.addLine(to: p(0.26, 0.9))
            path.addLine(to: p(0.26, 0.44))
            path.addLine(to: p(0.14, 0.69))
            path.addLine(to: p(0.02, 0.62))
            path.addLine(to: p(0.24, 0.17))
            path.closeSubpath()
        case .ears:
            // A flat-topped beanie whose two top corners stand up as ears.
            path.move(to: p(0.18, 0.74))
            path.addLine(to: p(0.17, 0.14))
            path.addQuadCurve(to: p(0.36, 0.28), control: p(0.24, 0.17))
            path.addQuadCurve(to: p(0.64, 0.28), control: p(0.5, 0.25))
            path.addQuadCurve(to: p(0.83, 0.14), control: p(0.76, 0.17))
            path.addLine(to: p(0.82, 0.74))
            path.closeSubpath()
            path.addRoundedRect(in: box(0.12, 0.7, 0.76, 0.2), cornerWidth: unit * 0.06, cornerHeight: unit * 0.06)
        }
        return path
    }
}

extension Design.Silhouette {
    /// A raglan is worked from the neck down; everything else here starts at its lower edge.
    var knitsDown: Bool { self == .sweater }
}

/// A colorwork piece seen from the front: a grid of palette indices, the cast-on row last, sized to fit
/// its outline. Each knitted row of the first piece is one line; a row in the round shows its front half.
struct Picture: Equatable, Sendable {
    var columns: Int
    /// Top line first.
    var lines: [[Int]]

    init?(_ plan: PatternPlan, silhouette: Design.Silhouette) {
        guard plan.palette != nil else { return nil }
        var rows: [(paint: String, stitches: Int, round: Bool)] = []
        var round = false, pieces = 0, last = 0
        for step in plan.steps {
            if step.isAction {
                if step.texts[0].range(of: "^(Loosely )?cast on", options: [.regularExpression, .caseInsensitive]) != nil {
                    pieces += 1
                    round = step.texts[0].contains("Join in the round")
                }
                last = step.stitches ?? last
                continue
            }
            // Pairs are knit alike: the first piece stands for both.
            guard pieces <= 1 else { break }
            for row in 0..<step.rows {
                let stitches = step.stitches(after: row) ?? last
                rows.append((step.paint(at: row) ?? "A", stitches, round))
                last = stitches
            }
        }
        guard !rows.isEmpty else { return nil }
        let widest = rows.map { $0.round ? $0.stitches / 2 : $0.stitches }.max() ?? 1
        columns = max(1, min(widest, 80))
        let columns = columns
        lines = rows.reversed().map { row in
            let cells = Array(row.paint).map { Colorwork.index($0) ?? 0 }
            guard cells.count > 1 else { return Array(repeating: cells.first ?? 0, count: columns) }
            // The front: the middle of the round, or all of a flat row, sampled across the columns.
            let shown = row.round ? row.stitches / 2 : row.stitches
            // The front of a round is its first half, which sits at the right-hand end as the right side faces.
            let from = row.round ? cells.count - shown : (cells.count - shown) / 2
            return (0..<columns).map { c in cells[min(cells.count - 1, from + c * shown / columns)] }
        }
        if silhouette.knitsDown { lines.reverse() }
    }
}
