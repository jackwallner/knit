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

    init(name: String, rows: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.rows = rows
        self.createdAt = createdAt
        self.yarn = ""
        self.needles = ""
        self.notes = ""
        self.patternPage = 0
    }

    var isFinished: Bool { finishedAt != nil }

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
