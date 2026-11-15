import SwiftUI

/// A design drawn as the thing itself, cut from knitted fabric.
struct Garment: View {
    var silhouette: Design.Silhouette
    var yarn: YarnColor
    /// Set while it is being knitted: the outline shows faintly and fills with fabric as the rows go on,
    /// from the edge the pattern starts at.
    var progress: Double?
    /// A colorwork pattern draws as its own rows, stripes and motif in place, instead of plain fabric.
    var colorwork: PatternPlan?
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
                        cloth(in: proxy.size)
                            .mask { Outline(silhouette: silhouette).fill(style: FillStyle(eoFill: true)) }
                            .mask(alignment: silhouette.knitsDown ? .top : .bottom) {
                                Rectangle().frame(height: filled(in: proxy.size))
                            }
                    }
                }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cloth(in size: CGSize) -> some View {
        if let colorwork, let palette = colorwork.palette, let picture = Picture(colorwork, silhouette: silhouette) {
            let frame = CGRect(origin: .zero, size: size)
            let body = Path(GarmentShape.body(silhouette, in: frame))
            let piece = body.boundingRect
            let tints = palette.map(\.tint)
            ZStack {
                if silhouette == .ears, let ear = picture.ear, ear < tints.count {
                    let rim = picture.rim.map { tints.indices.contains($0) ? $0 : ear } ?? ear
                    Canvas { context, _ in
                        for box in GarmentShape.ears(in: frame) {
                            context.fill(Path(ellipseIn: box), with: .color(tints[rim].color))
                            // A pale rim would vanish into a pale tile: a hairline keeps the ear's edge.
                            context.stroke(Path(ellipseIn: box.insetBy(dx: 0.5, dy: 0.5)), with: .color(.black.opacity(0.14)), lineWidth: 1)
                            context.fill(Path(ellipseIn: GarmentShape.earInside(box)), with: .color(tints[ear].color))
                        }
                    }
                }
                Knitwork(picture: picture, tints: tints)
                    .frame(width: piece.width, height: piece.height)
                    .position(x: piece.midX, y: piece.midY)
                    .mask { body }
            }
        } else {
            Fabric(rows: 80, yarn: yarn, markEvery: 0, stitch: max(6, size.width / 11), showsNeedle: false)
        }
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

private struct Outline: Shape {
    var silhouette: Design.Silhouette

    func path(in rect: CGRect) -> Path { Path(GarmentShape.path(silhouette, in: rect)) }
}

/// Colorwork fabric, one small stitch per cell of the picture, laid over the whole piece.
private struct Knitwork: View {
    var picture: Picture
    var tints: [Tint]

    var body: some View {
        let picture = picture, tints = tints
        Canvas { context, size in
            let w = size.width / CGFloat(picture.columns), h = size.height / CGFloat(max(1, picture.lines.count))
            var fills = Array(repeating: Path(), count: tints.count)
            var legs = Path()
            for (r, line) in picture.lines.enumerated() {
                let y = CGFloat(r) * h
                for (c, cell) in line.enumerated() where cell < tints.count {
                    let x = CGFloat(c) * w
                    fills[cell].addRect(CGRect(x: x, y: y, width: w + 0.4, height: h + 0.4))
                    legs.move(to: CGPoint(x: x + w * 0.2, y: y + h * 0.15))
                    legs.addLine(to: CGPoint(x: x + w * 0.5, y: y + h * 0.9))
                    legs.addLine(to: CGPoint(x: x + w * 0.8, y: y + h * 0.15))
                }
            }
            for (index, path) in fills.enumerated() { context.fill(path, with: .color(tints[index].color)) }
            // The V of each stitch, so it reads as knitting and not as pixels.
            context.stroke(legs, with: .color(.black.opacity(0.14)), lineWidth: max(0.5, w * 0.12))
        }
    }
}
