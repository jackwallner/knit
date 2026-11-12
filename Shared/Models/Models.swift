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
