import SwiftData
import PDFKit
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

    func testLibraryProjectKeepsItsPlan() throws {
        let container = Persistence.container(inMemory: true)
        let design = Design.ribbedBeanie
        let plan = design.plan(measures: ["head": 22], gauge: YarnWeight.worsted.gauge)
        let project = Project(name: design.name)
        project.follow(plan, of: design)
        container.mainContext.insert(project)
        try container.mainContext.save()
        let fetched = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Project>()).first)
        XCTAssertEqual(fetched.plan, plan)
        XCTAssertEqual(fetched.designRaw, "ribbedBeanie")
        XCTAssertNil(Project(name: "Own pattern").plan)
    }

    func testOnlyTheLibraryIsPaid() {
        let subscription = SubscriptionService.shared
        subscription.setLocalOverride(isPro: false)
        XCTAssertTrue(subscription.canOpen(.garterScarf))
        XCTAssertFalse(subscription.canOpen(.raglanPullover))
        subscription.setLocalOverride(isPro: true)
        XCTAssertTrue(Design.allCases.allSatisfy(subscription.canOpen))
        subscription.setLocalOverride(isPro: false)
        XCTAssertEqual(Design.allCases.filter(\.isFree).count, 2)
    }

    func testReviewAskWaitsForASecondLaunchAndAMoment() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "review-\(UUID().uuidString)"))
        let prompt = ReviewPrompt(defaults: defaults)
        prompt.recordLaunch()
        prompt.recordPositiveMoment()
        XCTAssertFalse(prompt.shouldAsk())
        prompt.recordLaunch()
        XCTAssertTrue(prompt.shouldAsk())
        prompt.markAsked(now: .now)
        prompt.recordPositiveMoment()
        XCTAssertFalse(prompt.shouldAsk(now: .now.addingTimeInterval(29 * 86_400)))
        XCTAssertTrue(prompt.shouldAsk(now: .now.addingTimeInterval(31 * 86_400)))
        prompt.markOpenedStore()
        XCTAssertFalse(prompt.shouldAsk(now: .now.addingTimeInterval(31 * 86_400)))
    }

    func testAbbreviationsListOnlyWhatThePatternUses() {
        let hat = Design.ribbedBeanie.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(hat.abbreviations.map(\.term), ["k2tog"])
        let sweater = Design.raglanPullover.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(Set(sweater.abbreviations.map(\.term)), ["k2tog", "ssk", "M1L", "M1R"])
        XCTAssertTrue(Design.garterScarf.plan(measures: [:], gauge: YarnWeight.worsted.gauge).abbreviations.isEmpty)
    }

    func testPatternStoreSavesAndDeletes() throws {
        let source = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".pdf")
        try UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200)).pdfData { $0.beginPage() }.write(to: source)
        let file = try PatternStore.save(from: source)
        XCTAssertTrue(FileManager.default.fileExists(atPath: PatternStore.url(for: file).path))
        PatternStore.delete(file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: PatternStore.url(for: file).path))
    }

    func testPatternStoreRefusesAFileThatIsNotAPattern() throws {
        let source = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".pdf")
        try Data("%PDF-1.4".utf8).write(to: source)
        XCTAssertThrowsError(try PatternStore.save(from: source))
    }

    func testPhotosBecomeOnePageEach() throws {
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 80)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 60, height: 80))
        }
        let file = try PatternStore.save(pages: [photo, photo, photo])
        XCTAssertEqual(PDFDocument(url: PatternStore.url(for: file))?.pageCount, 3)
        PatternStore.delete(file)

        let picture = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".png")
        try XCTUnwrap(photo.pngData()).write(to: picture)
        let single = try PatternStore.save(from: picture)
        XCTAssertEqual(PDFDocument(url: PatternStore.url(for: single))?.pageCount, 1)
        PatternStore.delete(single)
        XCTAssertThrowsError(try PatternStore.save(pages: []))
    }
}
