import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Checks topical design records the way the app's tests do and draws a preview of each.
// Usage: topical-check [--previews <dir>] [--print <id>] [--fit-weights] <file.json>...
// --fit-weights prints, for each record, every yarn weight it passes at, to set its "weights" from.
// Exits 1 when any record is unusable or fails at any size and yarn weight.

var files: [String] = []
var previews: String?
var printing: String?
var fitWeights = false
var arguments = CommandLine.arguments.dropFirst().makeIterator()
while let argument = arguments.next() {
    switch argument {
    case "--previews": previews = arguments.next()
    case "--print": printing = arguments.next()
    case "--fit-weights": fitWeights = true
    default: files.append(argument)
    }
}

var failed = false
var checked = 0
for file in files {
    guard let data = FileManager.default.contents(atPath: file) else {
        print("FAIL \(file): cannot read")
        failed = true
        continue
    }
    let parsed = Topical.parse(data)
    if (try? JSONDecoder().decode(Topical.Listing.self, from: data)) == nil {
        print("FAIL \(file): not a list of designs")
        failed = true
    }
    for record in parsed {
        checked += 1
        guard let topical = record.topical else {
            print("FAIL \(record.id) (\(file))")
            for problem in record.problems { print("  \(problem)") }
            failed = true
            continue
        }
        if fitWeights {
            let passing = YarnWeight.allCases.filter { weight in
                var one = Topical(id: topical.id, title: topical.title, base: topical.base, work: topical.work, weights: [weight], tag: topical.tag, starts: nil, ends: nil, isFree: false)
                one.stitch = topical.stitch
                return TopicalCheck.problems(one).isEmpty
            }
            print("weights \(topical.id): \(passing.map(\.rawValue).joined(separator: " "))")
            continue
        }
        let problems = TopicalCheck.problems(topical)
        if problems.isEmpty {
            print("ok   \(topical.id): \(topical.title), \(TopicalCheck.inputs(for: topical.base).count) sizes x \(topical.weights.count) weights")
        } else {
            print("FAIL \(topical.id) (\(file))")
            for problem in problems.prefix(40) { print("  \(problem)") }
            if problems.count > 40 { print("  and \(problems.count - 40) more") }
            failed = true
        }
        if printing == topical.id { printPattern(topical) }
        if let previews { render(topical, to: URL(fileURLWithPath: previews)) }
    }
}
print(failed ? "\(checked) checked, failures above" : "\(checked) checked, all pass")
exit(failed ? 1 : 0)

/// The pattern in its own colors at the smallest and the largest size, as a knitter reads it.
func printPattern(_ topical: Topical) {
    let sizes = topical.base.sizes
    for size in [sizes.first, sizes.count > 1 ? sizes.last : nil].compactMap({ $0 }) {
        let plan = topical.plan(measures: size.values, gauge: topical.defaultWeight.gauge)
        print("\n== \(topical.id), \(size.name), \(topical.defaultWeight.label), \(plan.yards) yd\n\(plan.finished)")
        for line in plan.materials { print("  \(line)") }
        for step in plan.steps {
            let end = step.stitches(after: step.rows - 1)
            let count = step.stitches.map { " [\($0)\(end.map { $0 == step.stitches ? "" : " to \($0)" } ?? "")]" } ?? ""
            print("\(step.section) x\(step.rows)\(count): \(step.texts.joined(separator: " / "))")
        }
    }
}

// MARK: Preview

func cgColor(_ shade: Shade) -> CGColor {
    let rgb = shade.rgb ?? (0.5, 0.5, 0.5)
    return CGColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
}

func text(_ string: String, size: CGFloat, weight: CGFloat = 0, at point: CGPoint, in context: CGContext, color: CGColor = CGColor(gray: 0.15, alpha: 1)) {
    let traits = [kCTFontWeightTrait: weight] as CFDictionary
    let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontTraitsAttribute: traits, kCTFontFamilyNameAttribute: "Helvetica Neue"] as CFDictionary)
    let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
    let attributed = NSAttributedString(string: string, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font, NSAttributedString.Key(kCTForegroundColorAttributeName as String): color])
    let line = CTLineCreateWithAttributedString(attributed)
    context.textPosition = point
    CTLineDraw(line, context)
}

/// The garment in its colors at the default size, the chart, and the yarn of each color.
func render(_ topical: Topical, to directory: URL) {
    let width = 1400, height = 860
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
    context.setFillColor(CGColor(srgbRed: 0.975, green: 0.96, blue: 0.935, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    let gauge = topical.defaultWeight.gauge
    let plan = topical.plan(measures: topical.base.defaultSize.values, gauge: gauge)
    let palette = plan.palette ?? []

    // Garment, drawn in a flipped frame so the outline's top-left coordinates hold.
    let frame = CGRect(x: 40, y: 60, width: 760, height: 760)
    context.saveGState()
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    let outline = GarmentShape.body(topical.silhouette, in: frame)
    if let picture = Picture(plan, silhouette: topical.silhouette) {
        if topical.silhouette == .ears, let ear = picture.ear, ear < palette.count {
            for box in GarmentShape.ears(in: frame) {
                context.setFillColor(cgColor(palette[picture.rim ?? ear]))
                context.fillEllipse(in: box)
                context.setFillColor(cgColor(palette[ear]))
                context.fillEllipse(in: GarmentShape.earInside(box))
            }
        }
        context.addPath(outline)
        context.clip(using: .evenOdd)
        let box = outline.boundingBoxOfPath
        let cw = box.width / CGFloat(picture.columns), ch = box.height / CGFloat(picture.lines.count)
        for (r, line) in picture.lines.enumerated() {
            for (c, cell) in line.enumerated() where cell < palette.count {
                context.setFillColor(cgColor(palette[cell]))
                context.fill(CGRect(x: box.minX + CGFloat(c) * cw, y: box.minY + CGFloat(r) * ch, width: cw + 0.5, height: ch + 0.5))
            }
        }
        // A faint V on each stitch, so it reads as knitting rather than pixels.
        context.setStrokeColor(CGColor(gray: 0, alpha: 0.12))
        context.setLineWidth(max(0.5, cw * 0.12))
        for r in 0..<picture.lines.count {
            for c in 0..<picture.columns {
                let x = box.minX + CGFloat(c) * cw, y = box.minY + CGFloat(r) * ch
                context.move(to: CGPoint(x: x + cw * 0.2, y: y + ch * 0.15))
                context.addLine(to: CGPoint(x: x + cw * 0.5, y: y + ch * 0.9))
                context.addLine(to: CGPoint(x: x + cw * 0.8, y: y + ch * 0.15))
            }
        }
        context.strokePath()
    }
    context.restoreGState()

    // Title, size and yarn.
    var y = CGFloat(height) - 90
    text(topical.title, size: 40, weight: 0.3, at: CGPoint(x: 840, y: y), in: context)
    y -= 38
    text("\(topical.tag) · \(topical.base.name) · \(topical.base.defaultSize.name) · \(topical.defaultWeight.label) · \(Sizing.yardage(plan.yards, units: .imperial))", size: 19, at: CGPoint(x: 840, y: y), in: context, color: CGColor(gray: 0.38, alpha: 1))
    y -= 50
    for (index, line) in plan.materials.prefix(palette.count).enumerated() {
        context.setFillColor(cgColor(palette[index]))
        context.fill(CGRect(x: 840, y: y - 6, width: 26, height: 26))
        context.setStrokeColor(CGColor(gray: 0, alpha: 0.2))
        context.stroke(CGRect(x: 840, y: y - 6, width: 26, height: 26))
        text(line.replacingOccurrences(of: " of \(Engines.weightName(gauge)) weight yarn", with: ""), size: 17, at: CGPoint(x: 878, y: y), in: context)
        y -= 40
    }

    // The chart, top row first, as it looks on the right side.
    if let chart = topical.work.chart {
        y -= 16
        text("Chart, \(chart.width) stitches x \(chart.height) rows, \(chart.placement == .repeating ? "repeated around" : "centered on the front")", size: 17, weight: 0.2, at: CGPoint(x: 840, y: y), in: context)
        let cell = min(36, 520 / CGFloat(max(chart.width, chart.height)))
        let top = y - 20
        for (r, row) in chart.rows.enumerated() {
            for (c, value) in row.enumerated() {
                let rect = CGRect(x: 840 + CGFloat(c) * cell, y: top - CGFloat(r + 1) * cell, width: cell, height: cell)
                context.setFillColor(value < 0 ? CGColor(gray: 1, alpha: 1) : cgColor(palette[value]))
                context.fill(rect)
                context.setStrokeColor(CGColor(gray: 0, alpha: 0.25))
                context.stroke(rect, width: 1)
            }
        }
        text("White squares take the stripe's color.", size: 14, at: CGPoint(x: 840, y: top - CGFloat(chart.height) * cell - 24), in: context, color: CGColor(gray: 0.38, alpha: 1))
    }

    guard let image = context.makeImage() else { return }
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appending(path: "\(topical.id).png")
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("     preview \(url.path)")
}
