import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var rows: Int
    var createdAt: Date
    var finishedAt: Date?
    var yarn: String
    var needles: String
    var notes: String
    /// File name inside `PatternStore.directory`, never a full path.
    var patternFile: String?
    var patternPage: Int
    var colorRaw: String = YarnColor.madder.rawValue
    /// Rows in one pattern repeat. 0 means the project has no repeat.
    var repeatLength: Int = 0
    /// The row band the knitter left on the pattern: page index (-1 for none), then its position on that page.
    var markPage: Int = -1
    var markY: Double = 0
    var markHeight: Double = 0

    init(name: String, rows: Int = 0, color: YarnColor = .madder, createdAt: Date = .now) {
        self.name = name
        self.colorRaw = color.rawValue
        self.rows = rows
        self.createdAt = createdAt
        self.yarn = ""
        self.needles = ""
        self.notes = ""
        self.patternPage = 0
    }

    var isFinished: Bool { finishedAt != nil }

    var color: YarnColor {
        get { YarnColor(rawValue: colorRaw) ?? .madder }
        set { colorRaw = newValue.rawValue }
    }

    /// How far into the current repeat the last finished row is, from 1 to `repeatLength`. 0 before the first row or with no repeat.
    var repeatPosition: Int {
        guard repeatLength > 0, rows > 0 else { return 0 }
        return (rows - 1) % repeatLength + 1
    }

    func increment() { rows += 1 }

    func decrement() { rows = max(0, rows - 1) }

    func toggleFinished(at date: Date = .now) { finishedAt = isFinished ? nil : date }
}

@Model
final class Yarn {
    var name: String
    var brand: String
    var colorway: String
    var weightRaw: String
    var skeins: Int
    var createdAt: Date

    init(name: String, brand: String = "", colorway: String = "", weight: YarnWeight = .worsted, skeins: Int = 1, createdAt: Date = .now) {
        self.name = name
        self.brand = brand
        self.colorway = colorway
        self.weightRaw = weight.rawValue
        self.skeins = skeins
        self.createdAt = createdAt
    }

    var weight: YarnWeight {
        get { YarnWeight(rawValue: weightRaw) ?? .worsted }
        set { weightRaw = newValue.rawValue }
    }

    var detail: String {
        [brand, colorway, weight.label]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

enum YarnWeight: String, CaseIterable, Identifiable {
    case lace, fingering, sport, dk, worsted, aran, bulky, superBulky

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lace: "Lace"
        case .fingering: "Fingering"
        case .sport: "Sport"
        case .dk: "DK"
        case .worsted: "Worsted"
        case .aran: "Aran"
        case .bulky: "Bulky"
        case .superBulky: "Super Bulky"
        }
    }
}

/// A needle or hook in the stash.
@Model
final class Needle {
    var kindRaw: String
    var millimeters: Double
    /// Cable or shaft length in inches. 0 when the knitter did not say.
    var lengthInches: Int
    var createdAt: Date

    init(kind: NeedleKind = .circular, millimeters: Double = 4.5, lengthInches: Int = 0, createdAt: Date = .now) {
        self.kindRaw = kind.rawValue
        self.millimeters = millimeters
        self.lengthInches = lengthInches
        self.createdAt = createdAt
    }

    var kind: NeedleKind {
        get { NeedleKind(rawValue: kindRaw) ?? .circular }
        set { kindRaw = newValue.rawValue }
    }

    var size: NeedleSize { NeedleSize.nearest(to: millimeters, hook: kind == .hook) }

    var detail: String {
        lengthInches > 0 ? "\(kind.label) · \(lengthInches) in" : kind.label
    }
}

enum NeedleKind: String, CaseIterable, Identifiable {
    case circular, straight, doublePointed, hook

    var id: String { rawValue }

    var label: String {
        switch self {
        case .circular: "Circular"
        case .straight: "Straight"
        case .doublePointed: "Double-Pointed"
        case .hook: "Crochet Hook"
        }
    }
}

/// A standard size: metric diameter plus the US name knitters and crocheters use for it.
struct NeedleSize: Hashable, Identifiable {
    let millimeters: Double
    let us: String

    var id: Double { millimeters }

    var label: String { "US \(us) · \(millimeters.formatted(.number.precision(.fractionLength(0...2)))) mm" }

    static let needles: [NeedleSize] = [
        .init(millimeters: 2.0, us: "0"), .init(millimeters: 2.25, us: "1"), .init(millimeters: 2.75, us: "2"),
        .init(millimeters: 3.25, us: "3"), .init(millimeters: 3.5, us: "4"), .init(millimeters: 3.75, us: "5"),
        .init(millimeters: 4.0, us: "6"), .init(millimeters: 4.5, us: "7"), .init(millimeters: 5.0, us: "8"),
        .init(millimeters: 5.5, us: "9"), .init(millimeters: 6.0, us: "10"), .init(millimeters: 6.5, us: "10.5"),
        .init(millimeters: 8.0, us: "11"), .init(millimeters: 9.0, us: "13"), .init(millimeters: 10.0, us: "15"),
        .init(millimeters: 12.75, us: "17"), .init(millimeters: 15.0, us: "19"),
    ]

    static let hooks: [NeedleSize] = [
        .init(millimeters: 2.25, us: "B"), .init(millimeters: 2.75, us: "C"), .init(millimeters: 3.25, us: "D"),
        .init(millimeters: 3.5, us: "E"), .init(millimeters: 3.75, us: "F"), .init(millimeters: 4.0, us: "G"),
        .init(millimeters: 4.5, us: "7"), .init(millimeters: 5.0, us: "H"), .init(millimeters: 5.5, us: "I"),
        .init(millimeters: 6.0, us: "J"), .init(millimeters: 6.5, us: "K"), .init(millimeters: 8.0, us: "L"),
        .init(millimeters: 9.0, us: "M"), .init(millimeters: 10.0, us: "N"),
    ]

    static func all(hook: Bool) -> [NeedleSize] { hook ? hooks : needles }

    static func nearest(to millimeters: Double, hook: Bool) -> NeedleSize {
        all(hook: hook).min { abs($0.millimeters - millimeters) < abs($1.millimeters - millimeters) } ?? needles[7]
    }
}
