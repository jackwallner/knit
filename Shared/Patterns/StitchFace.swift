import CoreGraphics

extension Stitch {
    /// One repeat of the fabric as the right side shows it, top row first, one letter per stitch: k a knit V,
    /// p a purl bump, t a twisted knit, f a slipped stitch with the yarn stranded across its front, o a yarn-over
    /// hole, c a stitch in a cable crossing. Read from `round`, the pattern worked from the right side.
    var face: [String] {
        switch self {
        case .seed: ["pk", "kp"]
        case .doubleMoss: ["ppkk", "ppkk", "kkpp", "kkpp"]
        case .brokenRib: ["kp", "kk"]
        case .waffle: ["ppp", "pkk", "pkk", "pkk"]
        case .honeycomb: ["kk", "fk", "kk", "kf"]
        case .linen: ["fk", "kf"]
        case .twistedRib: ["tp"]
        case .mistakeRib: ["kppk", "kkpp"]
        case .seededRib: ["pkpp", "kkkp"]
        case .garterRidge: ["p", "p", "k", "k", "k", "k"]
        case .basketweave: Array(repeating: "ppppkkkk", count: 6) + Array(repeating: "kkkkpppp", count: 6)
        case .diamondBrocade:
            ["kkkpkpkk", "kkpkkkpk", "kpkkkkkp", "pkkkkkkk", "kpkkkkkp", "kkpkkkpk", "kkkpkpkk", "kkkkpkkk"]
        case .featherFan: ["pppppppppppp", "kkokokokokkk", "kkkkkkkkkkkk", "kkkkkkkkkkkk"]
        case .eyelet: ["kk", "ok", "kk", "kk", "kk", "kk"]
        case .chevronLace: ["kkkkkkkkkk", "okkkkkkkok"]
        case .ropeCable: Array(repeating: "ppkkkk", count: 5) + ["ppcccc"]
        case .hurdle: ["kp", "kp", "pp", "kk"]
        }
    }
}

/// A stitch pattern drawn as yarn: the strands of each row, top row first, so a drawing can lay every row
/// over the one above it the way the loops sit. The cast-on edge is the bottom of the space.
struct StitchTexture {
    struct Row {
        /// The two legs of each knit stitch, drawn in the yarn's color and a shade darker.
        var left = CGMutablePath()
        var right = CGMutablePath()
        /// The horizontal loop of each purl stitch.
        var bumps = CGMutablePath()
        /// Yarn stranded across the front of a slipped stitch, and the stitches crossing in a cable.
        var floats = CGMutablePath()
        var cables = CGMutablePath()
        /// Yarn-over holes, filled dark.
        var holes = CGMutablePath()
    }

    /// Strand width over stitch width, for each kind of path.
    static let leg: CGFloat = 0.33, bump: CGFloat = 0.36, cable: CGFloat = 0.75

    static func rows(_ stitch: Stitch, in size: CGSize, stitch w: CGFloat) -> [Row] {
        let face = stitch.face.map(Array.init)
        let h = w * 0.8
        let count = Int((size.height / h).rounded(.up)) + 1
        let columns = Int((size.width / w).rounded(.up)) + 1
        let width = face[0].count
        // Top row first; row `j` from the bottom sits just above the cast-on edge when j is 0.
        return (0..<count).reversed().map { j in
            let row = Row()
            let cells = face[face.count - 1 - j % face.count]
            let y = size.height - CGFloat(j + 1) * h
            var run: CGFloat?
            for column in 0...columns {
                let x = CGFloat(column) * w
                let cell = column < columns ? cells[column % width] : " "
                if cell == "c" {
                    if run == nil { run = x }
                } else if let start = run {
                    // A cable's front stitches cross on a slant over the stitches behind them.
                    row.cables.move(to: CGPoint(x: start + w * 0.3, y: y + h * 1.05))
                    row.cables.addLine(to: CGPoint(x: x - w * 0.3, y: y - h * 0.05))
                    run = nil
                }
                switch cell {
                case "k", "f", "c":
                    row.left.move(to: CGPoint(x: x + w * 0.15, y: y + h * 0.1))
                    row.left.addLine(to: CGPoint(x: x + w * 0.41, y: y + h * 1.12))
                    row.right.move(to: CGPoint(x: x + w * 0.85, y: y + h * 0.1))
                    row.right.addLine(to: CGPoint(x: x + w * 0.59, y: y + h * 1.12))
                    if cell == "f" {
                        row.floats.move(to: CGPoint(x: x - w * 0.05, y: y + h * 0.6))
                        row.floats.addLine(to: CGPoint(x: x + w * 1.05, y: y + h * 0.6))
                    }
                case "t":
                    row.left.move(to: CGPoint(x: x + w * 0.3, y: y + h * 0.1))
                    row.left.addLine(to: CGPoint(x: x + w * 0.62, y: y + h * 1.12))
                    row.right.move(to: CGPoint(x: x + w * 0.7, y: y + h * 0.1))
                    row.right.addLine(to: CGPoint(x: x + w * 0.38, y: y + h * 1.12))
                case "p":
                    row.bumps.move(to: CGPoint(x: x + w * 0.2, y: y + h * 0.55))
                    row.bumps.addLine(to: CGPoint(x: x + w * 0.8, y: y + h * 0.55))
                case "o":
                    row.holes.addEllipse(in: CGRect(x: x + w * 0.2, y: y + h * 0.15, width: w * 0.6, height: h * 0.8))
                default:
                    break
                }
            }
            return row
        }
    }
}
