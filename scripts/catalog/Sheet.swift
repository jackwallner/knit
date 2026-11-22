import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Draws a batch's contact sheet: each design's sample photo (when docs/photos has it), its drawn preview,
// title, sizes and yarn weights.
// Usage: sheet <out.png> <id>... where an id is a Design raw value or a bundled collection record id.
@main
struct Sheet {
    static let yarn: [String: String] = [
        "madder": "#A33B3D", "marigold": "#DB9C33", "moss": "#70824D", "spruce": "#2B6661",
        "indigo": "#3B4D8F", "plum": "#734275", "oat": "#C9B391", "charcoal": "#4D4D52",
    ]

    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count >= 2 else { print("usage: sheet <out.png> <id>..."); exit(2) }
        let records = Topical.parse(try Data(contentsOf: URL(fileURLWithPath: "Ravel/collection.json"))).compactMap(\.topical)
        var items: [Topical] = []
        for id in arguments.dropFirst() {
            if let record = records.first(where: { $0.id == id }) {
                items.append(record)
            } else if let design = Design(rawValue: id) {
                let shade = Shade(name: design.yarn.rawValue, hex: yarn[design.yarn.rawValue] ?? "#888888")
                var topical = Topical(id: id, title: design.name, base: design, work: Colorwork(palette: [shade]), weights: YarnWeight.allCases, tag: "", starts: nil, ends: nil, isFree: false)
                topical.photo = design.sitePhoto
                items.append(topical)
            } else {
                print("unknown id \(id)"); exit(2)
            }
        }
        let card = (width: 900, height: 380), columns = 2
        let rows = (items.count + columns - 1) / columns
        let width = card.width * columns, height = card.height * rows
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
        context.setFillColor(CGColor(srgbRed: 0.975, green: 0.96, blue: 0.935, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        for (index, item) in items.enumerated() {
            let x = CGFloat(index % columns * card.width), top = CGFloat(height - index / columns * card.height)
            draw(item, at: CGRect(x: x, y: top - CGFloat(card.height), width: CGFloat(card.width), height: CGFloat(card.height)), in: context)
        }
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: arguments[0]) as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        print("wrote \(arguments[0]), \(items.count) designs")
    }

    static func draw(_ item: Topical, at card: CGRect, in context: CGContext) {
        context.setStrokeColor(CGColor(gray: 0, alpha: 0.12))
        context.stroke(card.insetBy(dx: 8, dy: 8), width: 1)
        let photoBox = CGRect(x: card.minX + 24, y: card.minY + 70, width: 240, height: 240)
        let drawBox = CGRect(x: card.minX + 280, y: card.minY + 70, width: 240, height: 240)

        // The sample photo, or its empty frame while the photo waits.
        let photo = item.photo.map { URL(fileURLWithPath: "docs/\($0)") }
        if let photo, let source = CGImageSourceCreateWithURL(photo as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            context.draw(image, in: photoBox)
        } else {
            context.setFillColor(CGColor(gray: 0.9, alpha: 1))
            context.fill(photoBox)
            text("Photo waiting", size: 16, at: CGPoint(x: photoBox.minX + 70, y: photoBox.midY), in: context, color: CGColor(gray: 0.5, alpha: 1))
        }

        let gauge = item.defaultWeight.gauge
        let plan = item.plan(measures: item.base.defaultSize.values, gauge: gauge)
        let palette = plan.palette ?? item.work.palette
        context.saveGState()
        context.translateBy(x: 0, y: drawBox.minY * 2 + drawBox.height)
        context.scaleBy(x: 1, y: -1)
        let outline = GarmentShape.body(item.silhouette, in: drawBox)
        context.addPath(outline)
        context.clip(using: .evenOdd)
        if let picture = Picture(plan, silhouette: item.silhouette) {
            let box = outline.boundingBoxOfPath
            let cw = box.width / CGFloat(picture.columns), ch = box.height / CGFloat(picture.lines.count)
            for (r, line) in picture.lines.enumerated() {
                for (c, cell) in line.enumerated() where cell < palette.count {
                    context.setFillColor(color(palette[cell]))
                    context.fill(CGRect(x: box.minX + CGFloat(c) * cw, y: box.minY + CGFloat(r) * ch, width: cw + 0.5, height: ch + 0.5))
                }
            }
        } else if let stitch = item.stitch {
            texture(stitch, shade: palette[0], in: drawBox, context: context)
        } else {
            context.setFillColor(color(palette[0]))
            context.fill(drawBox)
        }
        context.restoreGState()

        let left = card.minX + 540
        var y = card.maxY - 60
        text(item.title, size: 26, weight: 0.3, at: CGPoint(x: left, y: y), in: context)
        y -= 32
        let kind = item.stitch.map { "\($0.name) on the \(item.base.name)" } ?? item.base.shelf.rawValue
        text(kind, size: 15, at: CGPoint(x: left, y: y), in: context, color: CGColor(gray: 0.38, alpha: 1))
        y -= 22
        text("\(item.level.rawValue.capitalized) · \(item.defaultWeight.label) · \(Sizing.yardage(plan.yards, units: .imperial))", size: 15, at: CGPoint(x: left, y: y), in: context, color: CGColor(gray: 0.38, alpha: 1))
        y -= 36
        text("Sizes", size: 15, weight: 0.3, at: CGPoint(x: left, y: y), in: context)
        for size in item.base.sizes {
            y -= 21
            let values = item.base.measures.compactMap { m in size.values[m.key].map { "\(m.label.lowercased()) \($0.formatted())" } }.joined(separator: ", ")
            text("\(size.name): \(values)", size: 14, at: CGPoint(x: left, y: y), in: context)
        }
        y -= 32
        text("Weights", size: 15, weight: 0.3, at: CGPoint(x: left, y: y), in: context)
        y -= 21
        let weights = item.weights.count == YarnWeight.allCases.count ? "Every weight, lace to super bulky" : item.weights.map(\.label).joined(separator: ", ")
        text(weights, size: 14, at: CGPoint(x: left, y: y), in: context)
    }

    /// The stitch pattern's texture, drawn the way the app's `Garment` draws it.
    static func texture(_ stitch: Stitch, shade: Shade, in box: CGRect, context: CGContext) {
        let rgb = shade.rgb ?? (0.5, 0.5, 0.5)
        func scaled(_ f: Double) -> CGColor { CGColor(srgbRed: rgb.red * f, green: rgb.green * f, blue: rgb.blue * f, alpha: 1) }
        let w = max(5, box.width / 16)
        context.saveGState()
        context.translateBy(x: box.minX, y: box.minY)
        context.setFillColor(scaled(0.55))
        context.fill(CGRect(origin: .zero, size: box.size))
        context.setLineCap(.round)
        func strand(_ path: CGPath, _ f: Double, _ width: CGFloat) {
            for (color, line) in [(scaled(0.55), width + max(1, w * 0.1)), (scaled(f), width)] {
                context.addPath(path)
                context.setStrokeColor(color)
                context.setLineWidth(line)
                context.strokePath()
            }
        }
        for row in StitchTexture.rows(stitch, in: box.size, stitch: w) {
            strand(row.left, 1, w * StitchTexture.leg)
            strand(row.right, 0.9, w * StitchTexture.leg)
            strand(row.bumps, 0.9, w * StitchTexture.bump)
            context.addPath(row.holes)
            context.setFillColor(CGColor(gray: 0, alpha: 0.45))
            context.fillPath()
            strand(row.floats, 1, w * StitchTexture.leg * 0.8)
            strand(row.cables, 1, w * StitchTexture.cable)
        }
        context.restoreGState()
    }

    static func color(_ shade: Shade) -> CGColor {
        let rgb = shade.rgb ?? (0.5, 0.5, 0.5)
        return CGColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }

    static func text(_ string: String, size: CGFloat, weight: CGFloat = 0, at point: CGPoint, in context: CGContext, color: CGColor = CGColor(gray: 0.15, alpha: 1)) {
        let traits = [kCTFontWeightTrait: weight] as CFDictionary
        let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontTraitsAttribute: traits, kCTFontFamilyNameAttribute: "Helvetica Neue"] as CFDictionary)
        let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        let attributed = NSAttributedString(string: string, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font, NSAttributedString.Key(kCTForegroundColorAttributeName as String): color])
        context.textPosition = point
        CTLineDraw(CTLineCreateWithAttributedString(attributed), context)
    }
}
