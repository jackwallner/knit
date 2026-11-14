import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Draws the app icon: a close-up of stockinette in the app's madder yarn,
// the same stitches the counter screen knits. Run from the repo root:
//   swift scripts/draw-icon.swift
// CoreGraphics, not an AppKit bitmap: an alpha-less NSBitmapImageRep context
// drew nothing and shipped a black icon in builds 1 to 6.
let size = 1024
let s = CGFloat(size)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Draw top down, like the app.
ctx.translateBy(x: 0, y: s)
ctx.scaleBy(x: 1, y: -1)

func yarn(_ factor: CGFloat) -> CGColor {
    CGColor(colorSpace: space, components: [0.64 * factor, 0.23 * factor, 0.24 * factor, 1])!
}
ctx.setFillColor(yarn(0.55))
ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

let columns: CGFloat = 4
let w = s / columns
let h = w * 0.8
ctx.setLineCap(.round)
func leg(from: CGPoint, to: CGPoint, color: CGColor) {
    for (stroke, width) in [(yarn(0.55), w * 0.43), (color, w * 0.33)] {
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
    for column in 0..<Int(columns) {
        let x = CGFloat(column) * w
        leg(from: CGPoint(x: x + w * 0.15, y: y + h * 0.1), to: CGPoint(x: x + w * 0.41, y: y + h * 1.12), color: yarn(1))
    }
    for column in 0..<Int(columns) {
        let x = CGFloat(column) * w
        leg(from: CGPoint(x: x + w * 0.85, y: y + h * 0.1), to: CGPoint(x: x + w * 0.59, y: y + h * 1.12), color: yarn(0.9))
    }
    row += 1
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

let icon = ctx.makeImage()!
write(icon, to: "Ravel/Assets.xcassets/AppIcon.appiconset/icon.png")
write(scaled(icon, to: 256), to: "docs/icon_256.png")
write(scaled(icon, to: 64), to: "docs/icon_64.png")
