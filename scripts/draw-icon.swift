import AppKit

// Draws the app icon: a close-up of stockinette in the app's madder yarn,
// the same stitches the counter screen knits.
let size: CGFloat = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

func yarn(_ factor: CGFloat) -> NSColor { NSColor(srgbRed: 0.64 * factor, green: 0.23 * factor, blue: 0.24 * factor, alpha: 1) }
yarn(0.55).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

let columns: CGFloat = 4
let w = size / columns
let h = w * 0.8
func leg(from: NSPoint, to: NSPoint, color: NSColor) {
    for (stroke, width) in [(yarn(0.55), w * 0.43), (color, w * 0.33)] {
        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineWidth = width
        // AppKit draws from the bottom up; the app draws from the top down.
        path.move(to: NSPoint(x: from.x, y: size - from.y))
        path.line(to: NSPoint(x: to.x, y: size - to.y))
        stroke.setStroke()
        path.stroke()
    }
}
var row = -1
while CGFloat(row) * h < size {
    let y = CGFloat(row) * h + h * 0.35
    for column in 0..<Int(columns) {
        let x = CGFloat(column) * w
        leg(from: NSPoint(x: x + w * 0.15, y: y + h * 0.1), to: NSPoint(x: x + w * 0.41, y: y + h * 1.12), color: yarn(1))
    }
    for column in 0..<Int(columns) {
        let x = CGFloat(column) * w
        leg(from: NSPoint(x: x + w * 0.85, y: y + h * 0.1), to: NSPoint(x: x + w * 0.59, y: y + h * 1.12), color: yarn(0.9))
    }
    row += 1
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Ravel/Assets.xcassets/AppIcon.appiconset/icon.png"))
