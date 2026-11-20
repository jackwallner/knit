import SwiftData
import XCTest
@testable import Ravel

/// The Lock Screen counter counts by the same rules, on the same store, as a tap in the app.
@MainActor
final class LockCounterTests: XCTestCase {
    private func store() throws -> ModelContainer {
        let container = try XCTUnwrap(Persistence.container(inMemory: true))
        LockCounter.container = container
        addTeardownBlock { @MainActor in LockCounter.container = nil }
        return container
    }

    func testATapIsOneRowAndIsSaved() async throws {
        let container = try store()
        let project = Project(name: "Scarf", rows: 3, color: .madder, createdAt: .now)
        container.mainContext.insert(project)
        try container.mainContext.save()
        let key = LockCounter.key(project)
        XCTAssertFalse(key.isEmpty)

        await LockCounter.count(key, back: false)
        XCTAssertEqual(project.rows, 4)
        XCTAssertFalse(container.mainContext.hasChanges, "the row is on disk before the tap returns")
        XCTAssertNotNil(project.workedAt)

        await LockCounter.count(key, back: true)
        await LockCounter.count(key, back: true)
        XCTAssertEqual(project.rows, 2)
        XCTAssertFalse(container.mainContext.hasChanges)
    }

    func testAFinishedProjectAndAMissingOneAreLeftAlone() async throws {
        let container = try store()
        let project = Project(name: "Hat", rows: 10, color: .spruce, createdAt: .now)
        container.mainContext.insert(project)
        try container.mainContext.save()
        project.toggleFinished()
        let key = LockCounter.key(project)
        await LockCounter.count(key, back: false)
        XCTAssertEqual(project.rows, 10, "a finished project with no pattern is a record")

        container.mainContext.delete(project)
        try container.mainContext.save()
        await LockCounter.count(key, back: false)
        await LockCounter.count("not a key", back: false)
        XCTAssertNil(LockCounter.project(key))
    }

    func testALibraryPatternStopsAtItsLastRow() async throws {
        let container = try store()
        let hat = Design.ribbedBeanie
        let plan = hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge)
        let project = Project(name: "Beanie", rows: 0, color: .spruce, createdAt: .now)
        project.follow(plan, of: hat)
        container.mainContext.insert(project)
        try container.mainContext.save()
        let key = LockCounter.key(project)

        let first = try XCTUnwrap(LockCounter.state(project))
        XCTAssertEqual(first.line, plan.steps[0].text(at: 0))
        XCTAssertFalse(first.canUndo)

        project.jump(toTap: plan.totalTaps - 1, following: plan)
        XCTAssertNotNil(LockCounter.state(project))
        await LockCounter.count(key, back: false)
        XCTAssertEqual(project.rows, plan.totalTaps)
        XCTAssertTrue(project.isFinished, "the last row finishes the project, as it does in the app")
        XCTAssertNil(LockCounter.state(project), "nothing left to count")
        await LockCounter.count(key, back: false)
        XCTAssertEqual(project.rows, plan.totalTaps, "never past the end")
    }

    /// The card is found again by this text, so it has to come out the same every time.
    func testAProjectsKeyNeverChanges() throws {
        let container = try store()
        let project = Project(name: "Scarf", rows: 3, color: .madder, createdAt: .now)
        container.mainContext.insert(project)
        try container.mainContext.save()
        let keys = Set((0..<200).map { _ in LockCounter.key(project) })
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(LockCounter.project(LockCounter.key(project))?.name, "Scarf")
    }

    func testWhatAPlainCounterShows() throws {
        let container = try store()
        let project = Project(name: "Blanket", rows: 18, color: .oat, createdAt: .now)
        container.mainContext.insert(project)
        let state = try XCTUnwrap(LockCounter.state(project))
        XCTAssertEqual(state.short, "18")
        XCTAssertTrue(state.place.contains("18"))
        XCTAssertEqual(state.line, "")
        XCTAssertTrue(state.canUndo)
        project.toggleFinished()
        XCTAssertNil(LockCounter.state(project))
    }
}
