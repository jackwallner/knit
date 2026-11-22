import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Draws the app icon, a close-up of stockinette (the same stitches the counter
// screen knits) in mixed oranges. Run from the repo root:
//   swift scripts/draw-icon.swift
// CoreGraphics, not an AppKit bitmap: an alpha-less NSBitmapImageRep context
// drew nothing and shipped a black icon in builds 1 to 6.
typealias RGB = (CGFloat, CGFloat, CGFloat)
let size = 1024
let s = CGFloat(size)
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ c: RGB, _ factor: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [min(c.0 * factor, 1), min(c.1 * factor, 1), min(c.2 * factor, 1), 1])!
}

/// Four columns of V stitches on `ground`. Rows take their yarn from `rows` in turn;
/// the right leg of each stitch is `shade` times its yarn.
func icon(ground: RGB, rows: [RGB], shade: CGFloat = 0.92) -> CGImage {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // Draw top down, like the app.
    ctx.translateBy(x: 0, y: s)
    ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(color(ground))
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
    let columns = 4
    let w = s / CGFloat(columns)
    let h = w * 0.8
    ctx.setLineCap(.round)
    func leg(from: CGPoint, to: CGPoint, yarn: CGColor) {
        for (stroke, width) in [(color(ground), w * 0.43), (yarn, w * 0.33)] {
            ctx.setStrokeColor(stroke)
            ctx.setLineWidth(width)
            ctx.move(to: from)
            ctx.addLine(to: to)
            ctx.strokePath()
        }
    }
    var row = -1
    while CGFloat(row) * h < s {
        let y = CGFloat(row) * h + h * 0.35
        let yarn = rows[(row + 1) % rows.count]
        for column in 0..<columns {
            let x = CGFloat(column) * w
            leg(from: CGPoint(x: x + w * 0.15, y: y + h * 0.1), to: CGPoint(x: x + w * 0.41, y: y + h * 1.12), yarn: color(yarn))
        }
        for column in 0..<columns {
            let x = CGFloat(column) * w
            leg(from: CGPoint(x: x + w * 0.85, y: y + h * 0.1), to: CGPoint(x: x + w * 0.59, y: y + h * 1.12), yarn: color(yarn, shade))
        }
        row += 1
    }
    return ctx.makeImage()!
}

func write(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "could not write \(path)")
}

func scaled(_ image: CGImage, to side: Int) -> CGImage {
    let small = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    small.interpolationQuality = .high
    small.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    return small.makeImage()!
}

let orange: RGB = (0.93, 0.50, 0.20)
let pumpkin: RGB = (0.88, 0.42, 0.16)
let apricot: RGB = (0.97, 0.68, 0.42)
let rust: RGB = (0.55, 0.24, 0.10)

let assets = "Ravel/Assets.xcassets"
let main = icon(ground: rust, rows: [pumpkin, orange, apricot, orange])
write(main, to: "\(assets)/AppIcon.appiconset/icon.png")
write(scaled(main, to: 256), to: "docs/icon_256.png")
write(scaled(main, to: 64), to: "docs/icon_64.png")
