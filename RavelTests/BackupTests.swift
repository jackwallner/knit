import SwiftData
import XCTest
@testable import Ravel

/// A backup carries everything a knitter would miss, and a restore only ever adds.
@MainActor
final class BackupTests: XCTestCase {
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func filled(files: URL) throws -> ModelContainer {
        let container = try XCTUnwrap(Persistence.container(inMemory: true))
        let context = container.mainContext
        let hat = Design.ribbedBeanie
        let beanie = Project(name: "Hat", rows: 31, color: .spruce, createdAt: Date(timeIntervalSinceReferenceDate: 800_000_000.25))
        beanie.follow(hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge), of: hat)
        let scarf = Project(name: "Scarf", rows: 412, createdAt: Date(timeIntervalSinceReferenceDate: 800_000_100))
        scarf.patternFile = "scarf.pdf"
        scarf.patternPage = 3
        scarf.markPage = 2
        scarf.markY = 310
        scarf.markHeight = 16
        scarf.markSteps = true
        scarf.markRow = 400
        scarf.readerZoom = 1.8
        scarf.repeatLength = 8
        scarf.repeatStart = 12
        scarf.notes = "Blocked flat"
        scarf.tallyOn = true
        scarf.tallyName = "Decreases"
        scarf.tallyCount = 7
        scarf.finishedAt = Date(timeIntervalSinceReferenceDate: 800_500_000)
        scarf.finishPhoto = "scarf.jpg"
        let yarn = Yarn(name: "Merino", colorway: "Moss", weight: .dk, skeins: 5, yardsPerSkein: 220)
        yarn.dyeLot = "4471"
        [beanie, scarf].forEach(context.insert)
        context.insert(yarn)
        context.insert(Needle(kind: .hook, millimeters: 5))
        scarf.stashYarn = yarn
        try context.save()
        try Data("pdf".utf8).write(to: files.appending(path: "scarf.pdf"))
        try Data("jpg".utf8).write(to: files.appending(path: "scarf.jpg"))
        return container
    }

    func testABackupRestoresEveryCountPatternAndStashEntryOnAnEmptyDevice() throws {
        let from = try folder(), to = try folder()
        let source = try filled(files: from)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let read = try PropertyListDecoder().decode(Backup.self, from: encoder.encode(Backup(of: source.mainContext, files: from)))

        let target = try XCTUnwrap(Persistence.container(inMemory: true))
        XCTAssertEqual(try read.restore(into: target.mainContext, files: to), 2)
        let projects = try target.mainContext.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)]))
        XCTAssertEqual(projects.map(\.name), ["Hat", "Scarf"])
        XCTAssertEqual(projects.map(\.rows), [31, 412])
        let hat = projects[0], scarf = projects[1]
        XCTAssertEqual(hat.plan, try source.mainContext.fetch(FetchDescriptor<Project>(predicate: #Predicate { $0.name == "Hat" })).first?.plan)
        XCTAssertEqual(hat.designRaw, Design.ribbedBeanie.rawValue)
        XCTAssertEqual(hat.color, .spruce)
        XCTAssertEqual([scarf.patternPage, scarf.markPage, scarf.markRow, scarf.repeatLength, scarf.repeatStart, scarf.tallyCount], [3, 2, 400, 8, 12, 7])
        XCTAssertEqual([scarf.markY, scarf.markHeight, scarf.readerZoom], [310, 16, 1.8])
        XCTAssertEqual([scarf.notes, scarf.tallyName, scarf.patternFile, scarf.finishPhoto], ["Blocked flat", "Decreases", "scarf.pdf", "scarf.jpg"])
        XCTAssertTrue(scarf.markSteps)
        XCTAssertTrue(scarf.tallyOn)
        XCTAssertTrue(scarf.isFinished)
        XCTAssertEqual(scarf.stashYarn?.label, "Merino, Moss")
        XCTAssertEqual(scarf.stashYarn?.dyeLot, "4471")
        XCTAssertEqual(try target.mainContext.fetch(FetchDescriptor<Needle>()).map(\.kind), [.hook])
        XCTAssertEqual(try Data(contentsOf: to.appending(path: "scarf.pdf")), Data("pdf".utf8))
        XCTAssertEqual(try Data(contentsOf: to.appending(path: "scarf.jpg")), Data("jpg".utf8))
    }

    /// Restoring on the device the backup came from, after more knitting, changes nothing: the count on the
    /// device is never taken back to the backup's.
    func testARestoreNeverChangesAProjectAlreadyHere() throws {
        let files = try folder()
        let container = try filled(files: files)
        let context = container.mainContext
        let backup = try Backup(of: context, files: files)
        let hat = try XCTUnwrap(context.fetch(FetchDescriptor<Project>(predicate: #Predicate { $0.name == "Hat" })).first)
        hat.knit(following: hat.plan)
        hat.knit(following: hat.plan)
        try Data("newer".utf8).write(to: files.appending(path: "scarf.pdf"))
        XCTAssertEqual(try backup.restore(into: context, files: files), 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 2)
        XCTAssertEqual(hat.rows, 33)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Yarn>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Needle>()).count, 1)
        XCTAssertEqual(try Data(contentsOf: files.appending(path: "scarf.pdf")), Data("newer".utf8))
        // A project deleted since comes back, with the count it had.
        context.delete(hat)
        try context.save()
        XCTAssertEqual(try backup.restore(into: context, files: files), 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>(predicate: #Predicate { $0.name == "Hat" })).first?.rows, 31)
    }

    func testTheBackupFileIsNamedByItsDateAndReadsBack() throws {
        let container = try XCTUnwrap(Persistence.container(inMemory: true))
        container.mainContext.insert(Project(name: "Socks", rows: 77))
        try container.mainContext.save()
        let url = try Backup.write(from: container.mainContext, on: Date(timeIntervalSince1970: 1_795_000_000))
        XCTAssertEqual(url.pathExtension, Backup.fileExtension)
        XCTAssertTrue(url.lastPathComponent.hasPrefix("Ravel 2026-11-"), url.lastPathComponent)
        XCTAssertEqual(try Backup.read(url).projects.map(\.rows), [77])
        XCTAssertThrowsError(try Backup.read(FileManager.default.temporaryDirectory.appending(path: "missing.ravelbackup")))
    }
}
