import SwiftData
import XCTest
@testable import Ravel

/// A store written by a build before the schemas were versioned: no `repeatStart`, no later field.
enum BeforeVersions {
    @Model final class Project {
        var name: String
        var rows: Int
        var createdAt: Date
        var finishedAt: Date?
        var yarn: String
        var needles: String
        var notes: String
        var patternFile: String?
        var patternPage: Int
        init(name: String, rows: Int) {
            self.name = name
            self.rows = rows
            createdAt = .now
            yarn = "Wool"
            needles = "US 7"
            notes = ""
            patternPage = 0
        }
    }

    @Model final class Yarn {
        var name: String
        var brand: String
        var colorway: String
        var weightRaw: String
        var skeins: Int
        var createdAt: Date
        init(name: String) {
            self.name = name
            brand = ""
            colorway = ""
            weightRaw = "worsted"
            skeins = 2
            createdAt = .now
        }
    }

    @Model final class Needle {
        var kindRaw: String
        var millimeters: Double
        var lengthInches: Int
        var createdAt: Date
        init() {
            kindRaw = "circular"
            millimeters = 4.5
            lengthInches = 0
            createdAt = .now
        }
    }
}

@MainActor
final class SchemaTests: XCTestCase {
    private func storeURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".store")
    }

    func testVersionOneNamesTheEntitiesTheFirstBuildsWrote() {
        XCTAssertEqual(Schema(versionedSchema: SchemaV1.self).entities.map(\.name).sorted(), ["Needle", "Project", "Yarn"])
        XCTAssertEqual(RavelSchema.current.entities.map(\.name).sorted(), ["Needle", "Project", "Yarn"])
    }

    /// A store written with the version 1 models opens with every project and count intact.
    func testStoreWrittenByVersionOneOpensWithEveryCount() throws {
        let url = storeURL()
        let hat = Design.ribbedBeanie
        let plan = hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge)
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let context = container.mainContext
            let scarf = SchemaV1.Project(name: "Scarf", rows: 412)
            scarf.repeatLength = 8
            scarf.repeatStart = 12
            scarf.yarn = "Merino"
            scarf.notes = "Blocked flat"
            scarf.patternFile = "scarf.pdf"
            scarf.markPage = 2
            let beanie = SchemaV1.Project(name: "Hat", rows: 9)
            beanie.designRaw = hat.rawValue
            beanie.planData = try JSONEncoder().encode(plan)
            let done = SchemaV1.Project(name: "Blanket", rows: 240)
            done.finishedAt = Date(timeIntervalSince1970: 1_000_000)
            [scarf, beanie, done].forEach(context.insert)
            context.insert(SchemaV1.Yarn(name: "Wool", brand: "Hillside", colorway: "Moss", skeins: 4))
            context.insert(SchemaV1.Needle(kindRaw: "hook", millimeters: 5, lengthInches: 0))
            try context.save()
        }
        let container = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
        let projects = try container.mainContext.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)]))
        XCTAssertEqual(projects.map(\.name), ["Blanket", "Hat", "Scarf"])
        XCTAssertEqual(projects.map(\.rows), [240, 9, 412])
        let scarf = try XCTUnwrap(projects.last)
        XCTAssertEqual([scarf.repeatLength, scarf.repeatStart, scarf.markPage], [8, 12, 2])
        XCTAssertEqual([scarf.yarn, scarf.notes, scarf.patternFile], ["Merino", "Blocked flat", "scarf.pdf"])
        XCTAssertEqual(projects[1].plan, plan)
        XCTAssertEqual(projects[1].designRaw, hat.rawValue)
        XCTAssertTrue(projects[0].isFinished)
        for project in projects {
            XCTAssertNil(project.stashYarn)
            XCTAssertFalse(project.tallyOn)
            XCTAssertEqual(project.tallyCount, 0)
        }
        let yarn = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Yarn>()).first)
        XCTAssertEqual([yarn.name, yarn.brand, yarn.colorway], ["Wool", "Hillside", "Moss"])
        XCTAssertEqual(yarn.skeins, 4)
        XCTAssertEqual(yarn.yardsPerSkein, 0)
        XCTAssertNil(yarn.totalLength)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Needle>()).map(\.kindRaw), ["hook"])
    }

    /// A store written by builds 1 to 29 opens with every count, the stash link and the second counter.
    func testStoreWrittenByVersionTwoOpensWithEveryCount() throws {
        let url = storeURL()
        do {
            let schema = Schema(versionedSchema: SchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let context = container.mainContext
            let scarf = SchemaV2.Project(name: "Scarf", rows: 412)
            scarf.patternFile = "scarf.pdf"
            scarf.patternPage = 3
            scarf.markPage = 2
            scarf.markY = 310
            scarf.tallyOn = true
            scarf.tallyName = "Decreases"
            scarf.tallyCount = 7
            let yarn = SchemaV2.Yarn(name: "Wool", skeins: 4)
            yarn.yardsPerSkein = 220
            yarn.dyeLot = "4471"
            context.insert(scarf)
            context.insert(yarn)
            scarf.stashYarn = yarn
            context.insert(SchemaV2.Needle(kindRaw: "hook", millimeters: 5))
            try context.save()
        }
        let container = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
        let scarf = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual([scarf.rows, scarf.patternPage, scarf.markPage, scarf.tallyCount], [412, 3, 2, 7])
        XCTAssertEqual([scarf.patternFile, scarf.tallyName, scarf.stashYarn?.name], ["scarf.pdf", "Decreases", "Wool"])
        XCTAssertEqual(scarf.markY, 310)
        XCTAssertNil(scarf.workedAt)
        XCTAssertEqual(scarf.lastWorked, scarf.createdAt)
        XCTAssertEqual([scarf.readerZoom, scarf.readerX, scarf.readerY], [0, 0, 0])
        XCTAssertFalse(scarf.markSteps)
        XCTAssertNil(scarf.finishPhoto)
        let yarn = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Yarn>()).first)
        XCTAssertEqual([yarn.skeins, yarn.yardsPerSkein], [4, 220])
        XCTAssertEqual(yarn.dyeLot, "4471")
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Needle>()).map(\.kindRaw), ["hook"])
    }

    /// The first builds carried less than version 1; their stores open on the same file, never an empty one.
    func testStoreFromBeforeTheVersionsStillOpens() throws {
        let url = storeURL()
        do {
            let schema = Schema([BeforeVersions.Project.self, BeforeVersions.Yarn.self, BeforeVersions.Needle.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            container.mainContext.insert(BeforeVersions.Project(name: "Socks", rows: 77))
            container.mainContext.insert(BeforeVersions.Yarn(name: "Sock Yarn"))
            container.mainContext.insert(BeforeVersions.Needle())
            try container.mainContext.save()
        }
        let container = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
        let project = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual([project.name, project.yarn], ["Socks", "Wool"])
        XCTAssertEqual(project.rows, 77)
        XCTAssertEqual(project.repeatStart, 0)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Yarn>()).map(\.skeins), [2])
    }

    func testLinkedYarnShowsItsNameAndDeletingItLeavesTheProjectWhole() throws {
        let container = try XCTUnwrap(Persistence.container(inMemory: true))
        let context = container.mainContext
        let project = Project(name: "Sweater", rows: 120)
        project.yarn = "typed yarn"
        let yarn = Yarn(name: "Merino", colorway: "Moss", skeins: 5)
        context.insert(project)
        context.insert(yarn)
        XCTAssertEqual(project.yarnLabel, "typed yarn")
        project.stashYarn = yarn
        try context.save()
        XCTAssertEqual(project.yarnLabel, "Merino, Moss")
        XCTAssertEqual(yarn.projects.map(\.name), ["Sweater"])
        context.delete(yarn)
        try context.save()
        let kept = try XCTUnwrap(context.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual(kept.rows, 120)
        XCTAssertNil(kept.stashYarn)
        XCTAssertEqual(kept.yarnLabel, "typed yarn")
        // And the other way: deleting the project leaves the yarn in the stash.
        let other = Yarn(name: "Alpaca")
        context.insert(other)
        kept.stashYarn = other
        try context.save()
        context.delete(kept)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Yarn>()).map(\.name), ["Alpaca"])
    }

    func testSecondCounterNeverTouchesTheRowsAndSurvivesReopening() throws {
        let url = storeURL()
        do {
            let container = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
            let project = Project(name: "Sleeve")
            container.mainContext.insert(project)
            (0..<30).forEach { _ in project.knit(following: nil) }
            project.tally(by: 1)
            XCTAssertEqual(project.tallyCount, 0, "no counter yet")
            project.addTally(named: "  Decreases  ")
            XCTAssertEqual(project.tallyName, "Decreases")
            (0..<5).forEach { _ in project.tally(by: 1) }
            project.tally(by: -1)
            XCTAssertEqual([project.rows, project.tallyCount], [30, 4])
            (0..<10).forEach { _ in project.tally(by: -1) }
            XCTAssertEqual(project.tallyCount, 0)
            project.tally(by: 3)
            // Nothing saved beyond the counter's own calls: they persist by themselves.
        }
        let reopened = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
        let project = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual([project.rows, project.tallyCount], [30, 3])
        XCTAssertEqual(project.tallyTitle, "Decreases")
        project.resetTally()
        XCTAssertEqual([project.rows, project.tallyCount], [30, 0])
        project.tally(by: 2)
        project.removeTally()
        XCTAssertFalse(project.tallyOn)
        XCTAssertEqual([project.rows, project.tallyCount], [30, 0])
        project.addTally(named: "")
        XCTAssertEqual(project.tallyTitle, "Counter")
        // The main count's own rules leave the second counter alone.
        project.tally(by: 4)
        project.unknit(following: nil)
        project.jump(to: 50, following: nil)
        XCTAssertEqual([project.rows, project.tallyCount], [50, 4])
    }

    func testYarnLengthIsKeptInYardsAndShownInTheKnittersUnits() {
        let yarn = Yarn(name: "Merino", skeins: 6, yardsPerSkein: 200)
        XCTAssertEqual(yarn.totalYards, 1200)
        XCTAssertEqual(yarn.totalLength, Sizing.yardage(1200))
        XCTAssertNil(Yarn(name: "Mystery", skeins: 3).totalLength)
        XCTAssertEqual(Sizing.yardage(1200, units: .imperial), "1,200 yd")
        XCTAssertEqual(Yarn.shown(yards: 200, units: .imperial), 200)
        XCTAssertEqual(Yarn.yards(shown: 200, units: .imperial), 200)
        // Typed in meters, read back as the same meters.
        for meters in [50, 100, 137, 183, 250, 1000] {
            XCTAssertEqual(Yarn.shown(yards: Yarn.yards(shown: meters, units: .metric), units: .metric), meters)
        }
        XCTAssertEqual(Yarn.yards(shown: -5, units: .metric), 0)
    }

    func testLibraryListShowsKnittedRowsAndOtherProjectsTheCount() {
        let design = Design.ribbedBeanie
        let plan = design.plan(measures: design.defaultSize.values, gauge: design.weight.gauge)
        let project = Project(name: "Hat")
        project.follow(plan, of: design)
        project.rows = plan.totalTaps
        XCTAssertEqual(project.knittedRows(plan), plan.knitRows(upTo: plan.totalTaps))
        XCTAssertLessThan(project.knittedRows(plan), plan.totalTaps, "setup steps are taps, not rows")
        project.rows = 1
        XCTAssertEqual(project.knittedRows(plan), 0, "the cast on is not a row")
        let own = Project(name: "Own", rows: 33)
        XCTAssertEqual(own.knittedRows(nil), 33)
    }
}
