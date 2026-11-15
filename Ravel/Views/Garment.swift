import SwiftUI

/// A design drawn as the thing itself, cut from knitted fabric.
struct Garment: View {
    var silhouette: Design.Silhouette
    var yarn: YarnColor
    /// Set while it is being knitted: the outline shows faintly and fills with fabric as the rows go on,
    /// from the edge the pattern starts at.
    var progress: Double?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    ZStack {
                        if progress != nil {
                            // Stronger on a dark screen, so a piece not yet started still shows its shape.
                            Outline(silhouette: silhouette).fill(.primary.opacity(scheme == .dark ? 0.18 : 0.08), style: FillStyle(eoFill: true))
                        }
                        Fabric(rows: 80, yarn: yarn, markEvery: 0, stitch: max(6, proxy.size.width / 11), showsNeedle: false)
                            .mask { Outline(silhouette: silhouette).fill(style: FillStyle(eoFill: true)) }
                            .mask(alignment: silhouette.knitsDown ? .top : .bottom) {
                                Rectangle().frame(height: filled(in: proxy.size))
                            }
                    }
                }
            }
            .accessibilityHidden(true)
    }

    /// How much of the frame, from the starting edge, shows fabric: measured over the piece itself,
    /// not its square, so the first row shows at once and the last row finishes it.
    private func filled(in size: CGSize) -> CGFloat {
        guard let progress else { return size.height }
        let piece = Outline(silhouette: silhouette).path(in: CGRect(origin: .zero, size: size)).boundingRect
        let lead = silhouette.knitsDown ? piece.minY : size.height - piece.maxY
        return lead + piece.height * min(1, max(0, progress))
    }
}

extension Design.Silhouette {
    /// A raglan is worked from the neck down; everything else here starts at its lower edge.
    var knitsDown: Bool { self == .sweater }
}

private struct Outline: Shape {
    var silhouette: Design.Silhouette

    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height, width: w * rect.width, height: h * rect.height)
        }
        let unit = rect.width
        var path = Path()
        switch silhouette {
        case .hat:
            path.move(to: p(0.16, 0.74))
            path.addCurve(to: p(0.5, 0.1), control1: p(0.14, 0.34), control2: p(0.3, 0.1))
            path.addCurve(to: p(0.84, 0.74), control1: p(0.7, 0.1), control2: p(0.86, 0.34))
            path.closeSubpath()
            path.addRoundedRect(in: box(0.1, 0.7, 0.8, 0.2), cornerSize: CGSize(width: unit * 0.06, height: unit * 0.06))
        case .slouch:
            path.move(to: p(0.18, 0.76))
            path.addCurve(to: p(0.66, 0.08), control1: p(0.04, 0.3), control2: p(0.36, 0.04))
            path.addCurve(to: p(0.84, 0.76), control1: p(0.98, 0.14), control2: p(0.94, 0.5))
            path.closeSubpath()
            path.addRoundedRect(in: box(0.14, 0.74, 0.72, 0.15), cornerSize: CGSize(width: unit * 0.05, height: unit * 0.05))
        case .scarf:
            // A long strip with fringe at both ends. The strands meet the strip edge to edge, never overlapping,
            // so the even-odd fill leaves no gaps.
            path.addRoundedRect(in: box(0.33, 0.13, 0.34, 0.72), cornerSize: CGSize(width: unit * 0.02, height: unit * 0.02))
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
            path.addRoundedRect(in: box(0.1, 0.16, 0.8, 0.68), cornerSize: CGSize(width: unit * 0.04, height: unit * 0.04))
        case .cloth:
            path.addRoundedRect(in: box(0.2, 0.2, 0.6, 0.6), cornerSize: CGSize(width: unit * 0.04, height: unit * 0.04))
        case .tubes:
            path.addRoundedRect(in: box(0.18, 0.1, 0.26, 0.8), cornerSize: CGSize(width: unit * 0.06, height: unit * 0.06))
            path.addRoundedRect(in: box(0.56, 0.1, 0.26, 0.8), cornerSize: CGSize(width: unit * 0.06, height: unit * 0.06))
        case .mitts:
            for (x, thumb) in [(CGFloat(0.14), CGFloat(1)), (0.58, -1)] {
                path.addRoundedRect(in: box(x, 0.16, 0.28, 0.7), cornerSize: CGSize(width: unit * 0.07, height: unit * 0.07))
                let side = thumb > 0 ? x + 0.24 : x - 0.08
                path.addRoundedRect(in: box(side, 0.36, 0.12, 0.2), cornerSize: CGSize(width: unit * 0.05, height: unit * 0.05))
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
        }
        return path
    }
}
