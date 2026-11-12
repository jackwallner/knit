import AppKit

// Draws the app icon: a ball of yarn on a cream field.
let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let cream = NSColor(calibratedRed: 0.97, green: 0.94, blue: 0.89, alpha: 1)
let wool = NSColor(calibratedRed: 0.58, green: 0.20, blue: 0.24, alpha: 1)
let light = NSColor(calibratedRed: 0.80, green: 0.42, blue: 0.44, alpha: 1)
cream.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

let ball = NSRect(x: 232, y: 262, width: 560, height: 560)
wool.setFill()
NSBezierPath(ovalIn: ball).fill()

NSGraphicsContext.saveGraphicsState()
NSBezierPath(ovalIn: ball).addClip()
light.setStroke()
func strand(_ rect: NSRect, _ degrees: CGFloat) {
    let path = NSBezierPath(ovalIn: rect)
    var turn = AffineTransform(translationByX: 512, byY: 542)
    turn.rotate(byDegrees: degrees)
    turn.translate(x: -512, y: -542)
    path.transform(using: turn)
    path.lineWidth = 26
    path.stroke()
}
for offset in [-150, 0, 150] as [CGFloat] {
    strand(NSRect(x: 112 + offset, y: 202, width: 800, height: 680), 0)
}
for offset in [-170, -20, 130] as [CGFloat] {
    strand(NSRect(x: 172, y: 142 + offset, width: 680, height: 800), 58)
}
NSGraphicsContext.restoreGraphicsState()

wool.setStroke()
let tail = NSBezierPath()
tail.lineWidth = 30
tail.lineCapStyle = .round
tail.move(to: NSPoint(x: 700, y: 330))
tail.curve(to: NSPoint(x: 900, y: 170), controlPoint1: NSPoint(x: 800, y: 250), controlPoint2: NSPoint(x: 780, y: 140))
tail.stroke()
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Ravel/Assets.xcassets/AppIcon.appiconset/icon.png"))
