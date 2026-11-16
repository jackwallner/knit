// Draws a store-screenshot header (max two lines, centred) with CoreText so every script shapes
// correctly (Pillow here has no raqm). Mirrors the shared renderer's header: same face for Latin,
// size steps of 4 from the layout size down to its minimum, line pitch 1.05 x size.
// stdin: JSON array of {text, locale, width, height, top, size, minSize, margin, color:[r,g,b], out}
// stdout: JSON array of {locale, out, size, lines, width, fits}
import AppKit
import Foundation

struct Job: Codable { let text, locale, out: String; let width, height, top, limit, size, minSize, margin: Int; let color: [Int] }
struct Result: Codable { let locale, out: String; let split: [String]; let size, lines, width, bottom: Int; let fits: Bool }

func nsColor(_ c: [Int]) -> NSColor { NSColor(srgbRed: CGFloat(c[0]) / 255, green: CGFloat(c[1]) / 255, blue: CGFloat(c[2]) / 255, alpha: 1) }

let named: [String: String] = [
    "ja": "HiraginoSans-W8", "zh-Hans": "PingFangSC-Semibold", "zh-Hant": "PingFangTC-Semibold",
    "ko": "AppleSDGothicNeo-ExtraBold", "th": "SukhumvitSet-Bold", "hi": "KohinoorDevanagari-Bold", "mr-IN": "KohinoorDevanagari-Bold",
    "bn-BD": "KohinoorBangla-Semibold", "gu-IN": "KohinoorGujarati-Bold", "kn-IN": "KohinoorKannada-Bold" ,
    "ml-IN": "MalayalamSangamMN-Bold", "or-IN": "OriyaSangamMN-Bold", "pa-IN": "GurmukhiSangamMN-Bold",
    "ta-IN": "InaiMathi-Bold", "te-IN": "KohinoorTelugu-Semibold", "ur-PK": "GeezaPro-Bold",
    "ar-SA": "GeezaPro-Bold", "he": "ArialHebrew-Bold", "ru": "HelveticaNeue-CondensedBold", "uk": "HelveticaNeue-CondensedBold",
    "el": "ArialNarrow-Bold",
]
let rtl: Set<String> = ["ar-SA", "he", "ur-PK"]

func font(_ locale: String, _ size: CGFloat) -> NSFont {
    if let n = named[locale], let f = NSFont(name: n, size: size) { return f }
    return NSFont(name: "AvenirNextCondensed-Bold", size: size) ?? NSFont.systemFont(ofSize: size, weight: .bold)
}

func attributed(_ job: Job, _ size: Int) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.baseWritingDirection = rtl.contains(job.locale) ? .rightToLeft : .leftToRight
    return NSAttributedString(string: job.text, attributes: [
        .font: font(job.locale, CGFloat(size)), .foregroundColor: nsColor(job.color),
        .paragraphStyle: style, .languageIdentifier: job.locale,
    ])
}

func lines(_ s: NSAttributedString, width: Double) -> [CTLine] {
    let ts = CTTypesetterCreateWithAttributedString(s)
    var out: [CTLine] = [], start = 0
    while start < s.length {
        let n = CTTypesetterSuggestLineBreak(ts, start, width)
        if n <= 0 { break }
        out.append(CTTypesetterCreateLine(ts, CFRange(location: start, length: n)))
        start += n
    }
    return out
}

func inkWidth(_ l: CTLine, _ ctx: CGContext) -> Double { ctx.textPosition = .zero; return Double(CTLineGetImageBounds(l, ctx).width) }

func validBreaks(_ s: NSAttributedString, _ ls: [CTLine]) -> Bool {
    // a line may only end at a space, a hyphen or an explicit newline, never inside a word
    let ns = s.string as NSString
    if !ns.contains(" ") && !ns.contains("\n") { return true }  // unspaced scripts: dictionary breaks
    for l in ls.dropLast() {
        let r = CTLineGetStringRange(l), end = r.location + r.length
        let last = ns.substring(with: NSRange(location: end - 1, length: 1))
        let next = end < ns.length ? ns.substring(with: NSRange(location: end, length: 1)) : " "
        if !([" ", "\n", "-"].contains(last) || [" ", "\n"].contains(next)) { return false }
    }
    return true
}

func layout(_ job: Job, _ size: Int, _ ctx: CGContext) -> [CTLine]? {
    let s = attributed(job, size)
    let maxW = Double(job.width - 2 * job.margin)
    // the narrowest wrap that still gives two clean lines is the balanced split
    var best: [CTLine]? = nil
    var w = maxW
    while w > 200 {
        let ls = lines(s, width: w)
        if ls.count <= 2 && validBreaks(s, ls) && ls.allSatisfy({ inkWidth($0, ctx) <= maxW }) { best = ls }
        if ls.count > 2 { break }
        w -= 4
    }
    return best
}

func draw(_ job: Job) -> Result {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: job.width, pixelsHigh: job.height, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    struct Placed { let size: Int; let ls: [CTLine]; let boxes: [CGRect]; let b1: Double; let pitch: Double; let bottom: Double }
    func place(_ size: Int) -> Placed? {
        guard let ls = layout(job, size, ctx) else { return nil }
        let f = font(job.locale, CGFloat(size))
        let boxes = ls.map { l -> CGRect in ctx.textPosition = .zero; return CTLineGetImageBounds(l, ctx) }
        // Latin keeps the shared renderer's placement (first baseline at top + ascender, pitch 1.05 x size).
        // Other scripts have taller marks, so their ink block is centred in the band above the device.
        var b1 = Double(job.top) + Double(f.ascender)
        var pitch = Double(size) * 1.05
        if named[job.locale] != nil && ls.count == 2 {
            pitch = max(Double(size) * 0.9, -Double(boxes[0].minY) + Double(boxes[1].maxY) + 8)
            let height = Double(boxes[0].maxY) + pitch - Double(boxes[1].minY)
            let band = Double(job.limit - 16 - job.top)
            b1 = Double(job.top) + max(0, (band - height) / 2) + Double(boxes[0].maxY)
        }
        let bottom = zip(ls.indices, boxes).map { b1 + Double($0.0) * pitch - Double($0.1.minY) }.max() ?? 0
        return Placed(size: size, ls: ls, boxes: boxes, b1: b1, pitch: pitch, bottom: bottom)
    }
    var placed: Placed? = nil
    var size = job.size
    while size >= job.minSize {
        if let p = place(size), p.bottom <= Double(job.limit - 6) { placed = p; break }
        size -= 4
    }
    guard let p = placed else {
        NSGraphicsContext.current = nil
        return Result(locale: job.locale, out: job.out, split: [], size: job.minSize, lines: 3, width: 0, bottom: 0, fits: false)
    }
    size = p.size
    let ls = p.ls
    var widest = 0.0
    for (i, l) in ls.enumerated() {
        let box = p.boxes[i]
        let baseline = p.b1 + Double(i) * p.pitch
        ctx.textMatrix = .identity
        let x = (Double(job.width) - Double(box.width)) / 2 - Double(box.minX)
        ctx.textPosition = CGPoint(x: x, y: Double(job.height) - baseline)
        CTLineDraw(l, ctx)
        widest = max(widest, Double(box.width))
    }
    let inkBottom = p.bottom
    NSGraphicsContext.current = nil
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: job.out))
    let attr = attributed(job, size).string as NSString
    var parts: [String] = []
    for l in ls { let r = CTLineGetStringRange(l); parts.append(attr.substring(with: NSRange(location: r.location, length: r.length)).trimmingCharacters(in: .whitespaces)) }
    return Result(locale: job.locale, out: job.out, split: parts, size: size, lines: ls.count, width: Int(widest), bottom: Int(inkBottom), fits: true)
}

let jobs = try! JSONDecoder().decode([Job].self, from: FileHandle.standardInput.readDataToEndOfFile())
print(String(data: try! JSONEncoder().encode(jobs.map(draw)), encoding: .utf8)!)
