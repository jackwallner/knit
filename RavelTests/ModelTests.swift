import SwiftData
import XCTest
@testable import Ravel

@MainActor
final class ModelTests: XCTestCase {
    func testCounterNeverGoesBelowZero() {
        let project = Project(name: "Hat")
        project.decrement()
        XCTAssertEqual(project.rows, 0)
        project.increment()
        project.increment()
        project.decrement()
        XCTAssertEqual(project.rows, 1)
    }

    func testFinishingTogglesBothWays() {
        let project = Project(name: "Hat")
        XCTAssertFalse(project.isFinished)
        project.toggleFinished()
        XCTAssertTrue(project.isFinished)
        project.toggleFinished()
        XCTAssertNil(project.finishedAt)
    }

    func testCountSurvivesASave() throws {
        let container = Persistence.container(inMemory: true)
        let project = Project(name: "Scarf")
        container.mainContext.insert(project)
        (0..<12).forEach { _ in project.increment() }
        try container.mainContext.save()
        let fetched = try container.mainContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(fetched.map(\.rows), [12])
    }

    func testYarnDetailSkipsEmptyFields() {
        XCTAssertEqual(Yarn(name: "Wool", colorway: "Moss", weight: .dk).detail, "Moss · DK")
        XCTAssertEqual(Yarn(name: "Wool", brand: " ", weight: .superBulky).detail, "Super Bulky")
    }

    func testUnknownWeightFallsBackToWorsted() {
        let yarn = Yarn(name: "Wool")
        yarn.weightRaw = "cobweb"
        XCTAssertEqual(yarn.weight, .worsted)
    }

    func testRepeatPositionWrapsAtTheRepeatLength() {
        let project = Project(name: "Lace")
        project.repeatLength = 6
        XCTAssertEqual(project.repeatPosition, 0)
        project.rows = 6
        XCTAssertEqual(project.repeatPosition, 6)
        project.rows = 7
        XCTAssertEqual(project.repeatPosition, 1)
        project.repeatLength = 0
        XCTAssertEqual(project.repeatPosition, 0)
    }

    func testNeedleSizesUseTheRightChart() {
        XCTAssertEqual(Needle(kind: .circular, millimeters: 4.5).size.label, "US 7 · 4.5 mm")
        XCTAssertEqual(Needle(kind: .hook, millimeters: 5.0).size.label, "US H · 5 mm")
        XCTAssertEqual(NeedleSize.nearest(to: 12.0, hook: false).us, "17")
        XCTAssertEqual(Needle(kind: .circular, millimeters: 4.5, lengthInches: 32).detail, "Circular · 32 in")
        XCTAssertEqual(Needle(kind: .straight).detail, "Straight")
    }

    func testPatternStoreSavesAndDeletes() throws {
        let source = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".pdf")
        try Data("%PDF-1.4".utf8).write(to: source)
        let file = try PatternStore.save(from: source)
        XCTAssertTrue(FileManager.default.fileExists(atPath: PatternStore.url(for: file).path))
        PatternStore.delete(file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: PatternStore.url(for: file).path))
    }
}
