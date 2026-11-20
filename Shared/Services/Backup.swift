import Foundation
import SwiftData
import UniformTypeIdentifiers

extension UTType {
    /// One file holding every project, pattern and stash entry.
    static let ravelBackup = UTType(exportedAs: "com.jackwallner.knit.backup")
}

/// A backup is one file the knitter keeps wherever they like: every project with its count, its frozen
/// pattern, its PDF, row band, second counter and notes, and the stash. There is no sync. A backup is saved
/// and restored by hand, and a restore only ever adds: a project already on the device is left exactly as
/// it is, so restoring can never take a count backwards.
///
/// A backup saved by any shipped version must keep opening: a field added after version 1 is optional here.
struct Backup: Codable {
    static let fileExtension = "ravelbackup"

    var version = 1
    var saved = Date.now
    var projects: [Kept] = []
    var yarns: [Skein] = []
    var needles: [Tool] = []
    /// Pattern PDFs and finish photos, by the file name the projects use.
    var files: [String: Data] = [:]

    struct Kept: Codable {
        var name: String
        var rows: Int
        var createdAt: Date
        var finishedAt: Date?
        var yarn: String
        var needles: String
        var notes: String
        var patternFile: String?
        var patternPage: Int
        var colorRaw: String
        var repeatLength: Int
        var repeatStart: Int
        var markPage: Int
        var markY: Double
        var markHeight: Double
        var designRaw: String?
        var planData: Data?
        var tallyOn: Bool
        var tallyName: String
        var tallyCount: Int
        var workedAt: Date?
        var readerZoom: Double
        var readerX: Double
        var readerY: Double
        var markSteps: Bool
        var markRow: Int
        var finishPhoto: String?
        /// The stash yarn, as its place in `yarns`.
        var stash: Int?
    }

    struct Skein: Codable {
        var name: String
        var brand: String
        var colorway: String
        var weightRaw: String
        var skeins: Int
        var createdAt: Date
        var yardsPerSkein: Int
        var fiber: String
        var dyeLot: String
    }

    struct Tool: Codable {
        var kindRaw: String
        var millimeters: Double
        var lengthInches: Int
        var createdAt: Date
    }
}

extension Backup {
    /// Everything in the store, with the files its projects point at.
    @MainActor
    init(of context: ModelContext, files directory: URL = PatternStore.directory) throws {
        let stash = try context.fetch(FetchDescriptor<Yarn>(sortBy: [SortDescriptor(\.createdAt)]))
        yarns = stash.map {
            Skein(name: $0.name, brand: $0.brand, colorway: $0.colorway, weightRaw: $0.weightRaw, skeins: $0.skeins, createdAt: $0.createdAt,
                  yardsPerSkein: $0.yardsPerSkein, fiber: $0.fiber, dyeLot: $0.dyeLot)
        }
        needles = try context.fetch(FetchDescriptor<Needle>(sortBy: [SortDescriptor(\.createdAt)])).map {
            Tool(kindRaw: $0.kindRaw, millimeters: $0.millimeters, lengthInches: $0.lengthInches, createdAt: $0.createdAt)
        }
        for project in try context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)])) {
            projects.append(Kept(
                name: project.name, rows: project.rows, createdAt: project.createdAt, finishedAt: project.finishedAt, yarn: project.yarn,
                needles: project.needles, notes: project.notes, patternFile: project.patternFile, patternPage: project.patternPage,
                colorRaw: project.colorRaw, repeatLength: project.repeatLength, repeatStart: project.repeatStart, markPage: project.markPage,
                markY: project.markY, markHeight: project.markHeight, designRaw: project.designRaw, planData: project.planData,
                tallyOn: project.tallyOn, tallyName: project.tallyName, tallyCount: project.tallyCount, workedAt: project.workedAt,
                readerZoom: project.readerZoom, readerX: project.readerX, readerY: project.readerY, markSteps: project.markSteps,
                markRow: project.markRow, finishPhoto: project.finishPhoto,
                stash: project.stashYarn.flatMap { yarn in stash.firstIndex { $0 === yarn } }))
            for file in [project.patternFile, project.finishPhoto].compactMap({ $0 }) where files[file] == nil {
                // A pattern file that has gone missing does not stop the rest from being kept.
                if let data = try? Data(contentsOf: directory.appending(path: file)) { files[file] = data }
            }
        }
    }

    /// Writes the backup to a file ready to be moved wherever the knitter picks, named by its date.
    @MainActor
    static func write(from context: ModelContext, on date: Date = .now) throws -> URL {
        var backup = try Backup(of: context)
        backup.saved = date
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let name = "Ravel \(date.formatted(.iso8601.year().month().day())).\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appending(path: name)
        try encoder.encode(backup).write(to: url, options: .atomic)
        return url
    }

    static func read(_ url: URL) throws -> Backup {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try PropertyListDecoder().decode(Backup.self, from: Data(contentsOf: url))
    }

    /// Adds what this device does not have and returns how many projects that was. A project, yarn or needle
    /// already here (the same name made at the same moment) is not touched.
    @MainActor
    @discardableResult
    func restore(into context: ModelContext, files directory: URL = PatternStore.directory) throws -> Int {
        func same(_ a: Date, _ b: Date) -> Bool { abs(a.timeIntervalSince(b)) < 0.001 }
        var stash = try context.fetch(FetchDescriptor<Yarn>())
        var placed: [Yarn] = []
        for kept in yarns {
            if let here = stash.first(where: { $0.name == kept.name && same($0.createdAt, kept.createdAt) }) {
                placed.append(here)
                continue
            }
            let yarn = Yarn(name: kept.name, brand: kept.brand, colorway: kept.colorway, skeins: kept.skeins, yardsPerSkein: kept.yardsPerSkein, createdAt: kept.createdAt)
            yarn.weightRaw = kept.weightRaw
            yarn.fiber = kept.fiber
            yarn.dyeLot = kept.dyeLot
            context.insert(yarn)
            stash.append(yarn)
            placed.append(yarn)
        }
        let tools = try context.fetch(FetchDescriptor<Needle>())
        for kept in needles where !tools.contains(where: { $0.kindRaw == kept.kindRaw && $0.millimeters == kept.millimeters && same($0.createdAt, kept.createdAt) }) {
            let needle = Needle(millimeters: kept.millimeters, lengthInches: kept.lengthInches, createdAt: kept.createdAt)
            needle.kindRaw = kept.kindRaw
            context.insert(needle)
        }
        let here = try context.fetch(FetchDescriptor<Project>())
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var added = 0
        for kept in projects where !here.contains(where: { $0.name == kept.name && same($0.createdAt, kept.createdAt) }) {
            let project = Project(name: kept.name, rows: kept.rows, createdAt: kept.createdAt)
            project.finishedAt = kept.finishedAt
            project.yarn = kept.yarn
            project.needles = kept.needles
            project.notes = kept.notes
            project.patternFile = kept.patternFile
            project.patternPage = kept.patternPage
            project.colorRaw = kept.colorRaw
            project.repeatLength = kept.repeatLength
            project.repeatStart = kept.repeatStart
            project.markPage = kept.markPage
            project.markY = kept.markY
            project.markHeight = kept.markHeight
            project.designRaw = kept.designRaw
            project.planData = kept.planData
            project.tallyOn = kept.tallyOn
            project.tallyName = kept.tallyName
            project.tallyCount = kept.tallyCount
            project.workedAt = kept.workedAt
            project.readerZoom = kept.readerZoom
            project.readerX = kept.readerX
            project.readerY = kept.readerY
            project.markSteps = kept.markSteps
            project.markRow = kept.markRow
            project.finishPhoto = kept.finishPhoto
            context.insert(project)
            if let index = kept.stash, placed.indices.contains(index) { project.stashYarn = placed[index] }
            for file in [kept.patternFile, kept.finishPhoto].compactMap({ $0 }) {
                let url = directory.appending(path: file)
                // A file name is a pattern's own for good: one already here is the same pattern.
                if let data = files[file], !FileManager.default.fileExists(atPath: url.path) { try data.write(to: url, options: .atomic) }
            }
            added += 1
        }
        try context.save()
        return added
    }
}
