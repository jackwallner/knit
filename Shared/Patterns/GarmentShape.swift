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
        case .hat, .topDown:
            path.move(to: p(0.16, 0.712))
            path.addCurve(to: p(0.5, 0.1), control1: p(0.14, 0.34), control2: p(0.3, 0.1))
            path.addCurve(to: p(0.84, 0.712), control1: p(0.7, 0.1), control2: p(0.86, 0.34))
            path.closeSubpath()
            path.addRoundedRect(in: box(0.1, 0.7, 0.8, 0.2), cornerWidth: unit * 0.06, cornerHeight: unit * 0.06)
        case .knot:
            // A straight baby hat that narrows into a tube tied in a knot on top.
            let body = CGMutablePath()
            body.move(to: p(0.2, 0.74))
            body.addLine(to: p(0.22, 0.44))
            body.addCurve(to: p(0.44, 0.24), control1: p(0.24, 0.3), control2: p(0.36, 0.25))
            body.addLine(to: p(0.56, 0.24))
            body.addCurve(to: p(0.78, 0.44), control1: p(0.64, 0.25), control2: p(0.76, 0.3))
            body.addLine(to: p(0.8, 0.74))
            body.closeSubpath()
            let knot = CGPath(ellipseIn: box(0.38, 0.08, 0.24, 0.19), transform: nil)
                .union(CGPath(roundedRect: box(0.58, 0.13, 0.16, 0.07), cornerWidth: unit * 0.03, cornerHeight: unit * 0.03, transform: nil))
            path.addPath(body.union(knot))
            path.addRoundedRect(in: box(0.16, 0.72, 0.68, 0.16), cornerWidth: unit * 0.05, cornerHeight: unit * 0.05)
        case .asymmetric:
            // A long, shallow triangle: the straight edge across the top, the end on the left, the slope below.
            path.move(to: p(0.04, 0.3))
            path.addLine(to: p(0.96, 0.3))
            path.addLine(to: p(0.04, 0.62))
            path.closeSubpath()
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
        case .socks, .toeUp:
            // One sock seen from the side: the leg, a rounded heel and the foot running out to the toe.
            path.move(to: p(0.3, 0.08))
            path.addLine(to: p(0.58, 0.08))
            path.addLine(to: p(0.58, 0.52))
            path.addLine(to: p(0.76, 0.55))
            path.addCurve(to: p(0.78, 0.88), control1: p(0.93, 0.57), control2: p(0.95, 0.88))
            path.addLine(to: p(0.44, 0.88))
            path.addCurve(to: p(0.3, 0.64), control1: p(0.34, 0.88), control2: p(0.29, 0.78))
            path.closeSubpath()
        case .stocking:
            // A stocking hung by its loop: a deep cuff over a leg, the heel to the left and the toe out to the right.
            let leg = CGMutablePath()
            leg.move(to: p(0.28, 0.12))
            leg.addLine(to: p(0.6, 0.12))
            leg.addLine(to: p(0.6, 0.52))
            leg.addLine(to: p(0.78, 0.56))
            leg.addCurve(to: p(0.8, 0.9), control1: p(0.95, 0.58), control2: p(0.97, 0.9))
            leg.addLine(to: p(0.42, 0.9))
            leg.addCurve(to: p(0.28, 0.64), control1: p(0.32, 0.9), control2: p(0.26, 0.78))
            leg.closeSubpath()
            let cuff = CGPath(roundedRect: box(0.24, 0.06, 0.4, 0.16), cornerWidth: unit * 0.03, cornerHeight: unit * 0.03, transform: nil)
            path.addPath(leg.union(cuff))
        case .mittens:
            // A pair, thumbs toward each other. Each thumb merges into its hand, so the outline has no seam.
            for (x, thumb) in [(CGFloat(0.08), CGFloat(0.31)), (0.6, 0.0)] {
                let hand = CGMutablePath()
                hand.move(to: p(x, 0.88))
                hand.addLine(to: p(x, 0.36))
                hand.addQuadCurve(to: p(x + 0.16, 0.1), control: p(x, 0.1))
                hand.addQuadCurve(to: p(x + 0.32, 0.36), control: p(x + 0.32, 0.1))
                hand.addLine(to: p(x + 0.32, 0.88))
                hand.closeSubpath()
                let side = CGPath(roundedRect: box(x + thumb - 0.03, 0.4, 0.07, 0.22), cornerWidth: unit * 0.035, cornerHeight: unit * 0.035, transform: nil)
                path.addPath(hand.union(side))
            }
        case .cardigan:
            // The sweater, opened by a V at the neck and a slit down the front.
            let opening = CGMutablePath()
            opening.move(to: p(0.4, 0.05))
            opening.addLine(to: p(0.6, 0.05))
            opening.addLine(to: p(0.508, 0.42))
            opening.addLine(to: p(0.508, 0.95))
            opening.addLine(to: p(0.492, 0.95))
            opening.addLine(to: p(0.492, 0.42))
            opening.closeSubpath()
            path.addPath(GarmentShape.path(.sweater, in: rect).subtracting(opening))
        case .vest:
            path.move(to: p(0.37, 0.1))
            path.addLine(to: p(0.5, 0.44))
            path.addLine(to: p(0.63, 0.1))
            path.addLine(to: p(0.74, 0.13))
            path.addQuadCurve(to: p(0.82, 0.44), control: p(0.72, 0.42))
            path.addLine(to: p(0.8, 0.9))
            path.addLine(to: p(0.2, 0.9))
            path.addLine(to: p(0.18, 0.44))
            path.addQuadCurve(to: p(0.26, 0.13), control: p(0.28, 0.42))
            path.closeSubpath()
        case .earflap:
            // The dome, with a flap over each ear and a tie hanging from its tip.
            let hat = CGMutablePath()
            hat.move(to: p(0.16, 0.64))
            hat.addCurve(to: p(0.5, 0.08), control1: p(0.14, 0.3), control2: p(0.3, 0.08))
            hat.addCurve(to: p(0.84, 0.64), control1: p(0.7, 0.08), control2: p(0.86, 0.3))
            hat.closeSubpath()
            var whole: CGPath = hat
            for x in [CGFloat(0.16), 0.62] {
                let flap = CGMutablePath()
                flap.move(to: p(x, 0.6))
                flap.addLine(to: p(x + 0.22, 0.6))
                flap.addQuadCurve(to: p(x + 0.11, 0.84), control: p(x + 0.22, 0.82))
                flap.addQuadCurve(to: p(x, 0.6), control: p(x, 0.82))
                flap.closeSubpath()
                whole = whole.union(flap).union(CGPath(rect: box(x + 0.1, 0.82, 0.02, 0.14), transform: nil))
            }
            path.addPath(whole)
        case .wrap:
            path.addRoundedRect(in: box(0.22, 0.07, 0.56, 0.86), cornerWidth: unit * 0.02, cornerHeight: unit * 0.02)
        case .poncho:
            // Laid flat from the front: shoulders sloping out from the neck to a point at the center.
            let cape = CGMutablePath()
            cape.move(to: p(0.04, 0.4))
            cape.addLine(to: p(0.34, 0.14))
            cape.addLine(to: p(0.66, 0.14))
            cape.addLine(to: p(0.96, 0.4))
            cape.addLine(to: p(0.5, 0.92))
            cape.closeSubpath()
            path.addPath(cape.subtracting(CGPath(ellipseIn: box(0.37, 0.07, 0.26, 0.16), transform: nil)))
        case .crescent:
            path.move(to: p(0.03, 0.28))
            path.addQuadCurve(to: p(0.97, 0.28), control: p(0.5, 1.0))
            path.addQuadCurve(to: p(0.03, 0.28), control: p(0.5, 0.46))
            path.closeSubpath()
        case .bag:
            // A body with a handle arching over it.
            let body = CGPath(roundedRect: box(0.17, 0.42, 0.66, 0.48), cornerWidth: unit * 0.08, cornerHeight: unit * 0.08, transform: nil)
            let handle = CGPath(ellipseIn: box(0.3, 0.1, 0.4, 0.5), transform: nil).subtracting(CGPath(ellipseIn: box(0.36, 0.16, 0.28, 0.38), transform: nil))
            path.addPath(body.union(handle))
        case .pillow:
            // A cushion: four corners pulled out, the sides between them drawn in.
            path.move(to: p(0.1, 0.13))
            path.addQuadCurve(to: p(0.9, 0.13), control: p(0.5, 0.22))
            path.addQuadCurve(to: p(0.9, 0.87), control: p(0.81, 0.5))
            path.addQuadCurve(to: p(0.1, 0.87), control: p(0.5, 0.78))
            path.addQuadCurve(to: p(0.1, 0.13), control: p(0.19, 0.5))
            path.closeSubpath()
        case .bonnet:
            // A hood seen from the front, open around the face and under the chin, with a pompom tie at each corner.
            let hood = CGMutablePath()
            hood.move(to: p(0.14, 0.74))
            hood.addCurve(to: p(0.5, 0.1), control1: p(0.08, 0.3), control2: p(0.26, 0.1))
            hood.addCurve(to: p(0.86, 0.74), control1: p(0.74, 0.1), control2: p(0.92, 0.3))
            hood.closeSubpath()
            var whole: CGPath = hood.subtracting(CGPath(ellipseIn: box(0.27, 0.3, 0.46, 0.62), transform: nil))
            for x in [CGFloat(0.165), 0.815] {
                whole = whole.union(CGPath(rect: box(x - 0.012, 0.72, 0.024, 0.14), transform: nil))
                whole = whole.union(CGPath(ellipseIn: box(x - 0.05, 0.84, 0.1, 0.1), transform: nil))
            }
            path.addPath(whole)
        case .dropShoulder:
            // A boxy body whose shoulders run straight out, with wide sleeves hanging from below the shoulder line.
            path.move(to: p(0.4, 0.14))
            path.addCurve(to: p(0.6, 0.14), control1: p(0.45, 0.21), control2: p(0.55, 0.21))
            path.addLine(to: p(0.82, 0.16))
            path.addLine(to: p(0.97, 0.7))
            path.addLine(to: p(0.86, 0.73))
            path.addLine(to: p(0.77, 0.42))
            path.addLine(to: p(0.77, 0.88))
            path.addLine(to: p(0.23, 0.88))
            path.addLine(to: p(0.23, 0.42))
            path.addLine(to: p(0.14, 0.73))
            path.addLine(to: p(0.03, 0.7))
            path.addLine(to: p(0.18, 0.16))
            path.closeSubpath()
        case .keyhole:
            // A short strip with a slit near the top; the slit is a hole, so the even-odd fill leaves it open.
            path.addRoundedRect(in: box(0.38, 0.06, 0.24, 0.88), cornerWidth: unit * 0.03, cornerHeight: unit * 0.03)
            path.addRoundedRect(in: box(0.485, 0.2, 0.03, 0.16), cornerWidth: unit * 0.012, cornerHeight: unit * 0.012)
        case .slipper:
            // A pair seen from above, toes up: the foot, the opening over the heel and a pompom on each toe.
            var pair: CGPath = CGMutablePath()
            for x in [CGFloat(0.17), 0.57] {
                let foot = CGPath(roundedRect: box(x, 0.16, 0.26, 0.74), cornerWidth: unit * 0.13, cornerHeight: unit * 0.15, transform: nil)
                let shoe = foot.subtracting(CGPath(ellipseIn: box(x + 0.055, 0.46, 0.15, 0.38), transform: nil))
                pair = pair.union(shoe.union(CGPath(ellipseIn: box(x + 0.08, 0.08, 0.1, 0.1), transform: nil)))
            }
            path.addPath(pair)
        case .beret:
            // A wide, flat crown on a narrow band, with the little stem at its center.
            let top = CGPath(ellipseIn: box(0.06, 0.26, 0.88, 0.4), transform: nil)
            let band = CGPath(roundedRect: box(0.24, 0.58, 0.52, 0.14), cornerWidth: unit * 0.05, cornerHeight: unit * 0.05, transform: nil)
            let stem = CGPath(roundedRect: box(0.485, 0.2, 0.03, 0.08), cornerWidth: unit * 0.012, cornerHeight: unit * 0.012, transform: nil)
            path.addPath(top.union(band).union(stem))
        case .ears:
            // A beanie with two round ears on its crown: the ears merge into the dome, the brim sits apart.
            var top = dome(in: rect)
            for ear in ears(in: rect) { top = top.union(CGPath(ellipseIn: ear, transform: nil)) }
            path.addPath(top)
            path.addRoundedRect(in: box(0.1, 0.7, 0.8, 0.2), cornerWidth: unit * 0.06, cornerHeight: unit * 0.06)
        }
        return path
    }

    /// The piece the main fabric fills: the whole outline, less anything sewn on.
    static func body(_ silhouette: Design.Silhouette, in rect: CGRect) -> CGPath {
        guard silhouette == .ears else { return path(silhouette, in: rect) }
        let body = CGMutablePath()
        body.addPath(dome(in: rect))
        let brim = CGRect(x: rect.minX + 0.1 * rect.width, y: rect.minY + 0.7 * rect.height, width: 0.8 * rect.width, height: 0.2 * rect.height)
        body.addRoundedRect(in: brim, cornerWidth: rect.width * 0.06, cornerHeight: rect.width * 0.06)
        return body
    }

    private static func dome(in rect: CGRect) -> CGPath {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        let dome = CGMutablePath()
        dome.move(to: p(0.16, 0.712))
        dome.addCurve(to: p(0.5, 0.16), control1: p(0.14, 0.36), control2: p(0.3, 0.16))
        dome.addCurve(to: p(0.84, 0.712), control1: p(0.7, 0.16), control2: p(0.86, 0.36))
        dome.closeSubpath()
        return dome
    }

    /// The two ears of the `.ears` outline, as the squares their circles sit in.
    static func ears(in rect: CGRect) -> [CGRect] {
        [0.15, 0.65].map { CGRect(x: rect.minX + $0 * rect.width, y: rect.minY + 0.11 * rect.height, width: 0.2 * rect.width, height: 0.2 * rect.height) }
    }

    /// The ear's own color inside its rim.
    static func earInside(_ ear: CGRect) -> CGRect { ear.insetBy(dx: ear.width * 0.17, dy: ear.height * 0.17) }
}

extension Design.Silhouette {
    /// A raglan and a cardigan are worked from the neck down, a sock from the cuff to the toe, a crescent
    /// from its top edge; everything else here starts at its lower edge.
    var knitsDown: Bool { [.sweater, .cardigan, .socks, .crescent, .topDown, .stocking].contains(self) }
}

/// A colorwork piece seen from the front: a grid of palette indices, the cast-on row last, sized to fit
/// its outline. Each knitted row of the first piece is one line; a row in the round shows its front half.
struct Picture: Equatable, Sendable {
    var columns: Int
    /// Top line first.
    var lines: [[Int]]
    /// Pieces sewn on: the color of an ear and of its rim.
    var ear: Int?
    var rim: Int?

    init?(_ plan: PatternPlan, silhouette: Design.Silhouette) {
        guard plan.palette != nil else { return nil }
        var rows: [(paint: String, stitches: Int, round: Bool)] = []
        var round = false, pieces = 0, last = 0, pickedUp = false
        for step in plan.steps {
            if step.section.hasSuffix(" Ear") {
                if step.isAction {
                    if step.texts[0].range(of: "pick up", options: .caseInsensitive) != nil { pickedUp = true }
                } else if let paint = step.paint(at: 0), paint.count == 1 {
                    if pickedUp { rim = rim ?? Colorwork.index(Character(paint)) } else { ear = ear ?? Colorwork.index(Character(paint)) }
                }
                continue
            }
            if step.isAction {
                if step.texts[0].range(of: "^(Loosely )?cast on", options: [.regularExpression, .caseInsensitive]) != nil {
                    pieces += 1
                    round = step.texts[0].contains("Join in the round")
                }
                last = step.stitches ?? last
                continue
            }
            // Pairs are knit alike: the first piece stands for both.
            guard pieces <= 1 else { continue }
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
