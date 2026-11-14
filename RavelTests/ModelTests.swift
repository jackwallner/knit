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
        let container = try XCTUnwrap(Persistence.container(inMemory: true))
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

    /// A repeat set after a ribbed hem counts from the next row, not from the cast on.
    func testRepeatStartsWithTheNextRow() {
        let project = Project(name: "Cables", rows: 12)
        project.setRepeat(6)
        XCTAssertEqual(project.repeatPosition, 0)
        project.increment()
        XCTAssertEqual(project.repeatPosition, 1)
        (0..<6).forEach { _ in project.increment() }
        XCTAssertEqual(project.repeatPosition, 1)
        // Correcting the length keeps where the repeat began.
        project.setRepeat(8)
        XCTAssertEqual(project.repeatPosition, 7)
        // Setting the row moves the count, never where the repeat began.
        project.setRows(8)
        XCTAssertEqual(project.repeatPosition, 0)
        project.setRows(16)
        XCTAssertEqual(project.repeatPosition, 4)
        project.resetCount(following: nil)
        project.increment()
        XCTAssertEqual(project.repeatPosition, 1)
        project.setRepeat(900)
        XCTAssertEqual(project.repeatLength, 200)
    }

    func testCounterRulesForAPlainProject() {
        let project = Project(name: "Scarf")
        project.knit(following: nil)
        project.knit(following: nil)
        XCTAssertEqual(project.rows, 2)
        project.unknit(following: nil)
        XCTAssertEqual(project.rows, 1)
        project.jump(to: 250_000, following: nil)
        XCTAssertEqual(project.rows, Project.rowLimit)
        project.knit(following: nil)
        XCTAssertEqual(project.rows, Project.rowLimit)
        // A finished project is a record: a stray touch does not change it.
        project.jump(to: 40, following: nil)
        project.toggleFinished()
        project.knit(following: nil)
        XCTAssertEqual(project.rows, 40)
        // Resetting it puts it back on the needles, so the counter is never left dead.
        project.resetCount(following: nil)
        XCTAssertFalse(project.isFinished)
        project.knit(following: nil)
        XCTAssertEqual(project.rows, 1)
    }

    func testCounterRulesForALibraryPattern() {
        let plan = Engines.hat(.ribbed, head: 22, gauge: YarnWeight.worsted.gauge)
        let project = Project(name: "Hat")
        (0..<plan.totalTaps + 5).forEach { _ in project.knit(following: plan) }
        XCTAssertEqual(project.rows, plan.totalTaps)
        XCTAssertTrue(project.isFinished)
        project.unknit(following: plan)
        XCTAssertFalse(project.isFinished)
        project.knit(following: plan)
        XCTAssertTrue(project.isFinished)
        // Resetting a finished pattern puts it back on the needles.
        project.resetCount(following: plan)
        XCTAssertEqual(project.rows, 0)
        XCTAssertFalse(project.isFinished)
        // Go to Row counts within the section and stays inside it.
        project.jump(toTap: plan.sections[1].tap, following: plan)
        project.jump(to: 5, following: plan)
        XCTAssertEqual(project.rows, plan.sections[1].tap + 4)
        project.jump(to: 9_999, following: plan)
        XCTAssertEqual(plan.position(at: project.rows).map { plan.steps[$0.step].section }, "Body")
    }

    /// The store on disk has to hand back exactly what was put in, after the app is gone and back.
    func testProjectsSurviveClosingTheStore() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".store")
        let hat = Design.ribbedBeanie
        do {
            let container = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
            let project = Project(name: "Hat")
            project.follow(hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge), of: hat)
            container.mainContext.insert(project)
            container.mainContext.insert(Yarn(name: "Wool", skeins: 3))
            (0..<7).forEach { _ in project.knit(following: project.plan) }
        }
        let reopened = try XCTUnwrap(Persistence.container(inMemory: false, at: url))
        let projects = try reopened.mainContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(projects.map(\.rows), [7])
        XCTAssertEqual(projects.first?.plan, hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge))
        XCTAssertEqual(try reopened.mainContext.fetch(FetchDescriptor<Yarn>()).map(\.skeins), [3])
    }

    func testCameraPhotosAreCutToReadingSize() throws {
        let big = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 4000), format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }()).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 4000))
            // A dark head, to tell the top of the page from the bottom.
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 1000))
        }
        let data = try XCTUnwrap(PatternStore.page(from: try XCTUnwrap(big.jpegData(compressionQuality: 0.5))))
        let page = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(page.size.height * page.scale, 2200)
        XCTAssertEqual(page.size.width * page.scale, 1650)
        XCTAssertNil(PatternStore.page(from: Data("not a picture".utf8)))
        // Three photos bind into three upright pages of that size.
        let file = try PatternStore.save(pages: [data, data, data])
        defer { PatternStore.delete(file) }
        let document = try XCTUnwrap(PDFDocument(url: PatternStore.url(for: file)))
        XCTAssertEqual(document.pageCount, 3)
        // A page is letter width in points, so a row band reads the same as on any PDF.
        XCTAssertEqual(document.page(at: 0)?.bounds(for: .mediaBox).size, CGSize(width: 612, height: 816))
        XCTAssertThrowsError(try PatternStore.save(pages: [Data("junk".utf8)]))

        // The photo sits the right way up, and a row band shows over it as it does over text.
        let first = try XCTUnwrap(document.page(at: 0))
        let band = PDFAnnotation(bounds: CGRect(x: 0, y: 300, width: 612, height: 16), forType: .highlight, withProperties: nil)
        band.color = UIColor.red.withAlphaComponent(0.3)
        first.addAnnotation(band)
        let drawn = first.thumbnail(of: CGSize(width: 612, height: 816), for: .mediaBox)
        XCTAssertLessThan(try brightness(of: drawn, down: 0.1).green, 0.2, "the dark head is at the top")
        XCTAssertGreaterThan(try brightness(of: drawn, down: 0.9).green, 0.9, "the foot of the page is white")
        let banded = try brightness(of: drawn, down: 1 - 308.0 / 816)
        XCTAssertGreaterThan(banded.red - banded.green, 0.1, "the band tints the photo")
    }

    /// The color at the middle of an image, a share of the way down from its top.
    private func brightness(of image: UIImage, down share: Double) throws -> (red: Double, green: Double) {
        let source = try XCTUnwrap(image.cgImage)
        let spot = CGRect(x: source.width / 2, y: Int(Double(source.height) * share), width: 1, height: 1)
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(try XCTUnwrap(source.cropping(to: spot)), in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Double(pixel[0]) / 255, Double(pixel[1]) / 255)
    }

    func testNeedleSizesUseTheRightChart() {
        XCTAssertEqual(Needle(kind: .circular, millimeters: 4.5).size.label, "US 7 · 4.5 mm")
        XCTAssertEqual(Needle(kind: .hook, millimeters: 5.0).size.label, "US H · 5 mm")
        XCTAssertEqual(NeedleSize.nearest(to: 12.0, hook: false).us, "17")
        XCTAssertEqual(Needle(kind: .circular, millimeters: 4.5, lengthInches: 32).detail, "Circular · 32 in")
        XCTAssertEqual(Needle(kind: .straight).detail, "Straight")
    }

    func testLibraryProjectKeepsItsPlan() throws {
        let container = try XCTUnwrap(Persistence.container(inMemory: true))
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
        XCTAssertEqual(Set(hat.abbreviations.map(\.term)), ["k2tog", "k", "p", "repeat from", "marker", "join in the round"])
        let sweater = Design.raglanPullover.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        XCTAssertTrue(Set(sweater.abbreviations.map(\.term)).isSuperset(of: ["k2tog", "ssk", "M1L", "M1R", "pick up and knit", "in pattern"]))
        XCTAssertFalse(sweater.abbreviations.contains { $0.term == "yo" || $0.term == "C6F" || $0.term == "turn" })
        // A plain garter scarf says "Knit" in full and needs no glossary at all.
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
        XCTAssertThrowsError(try PatternStore.save(pages: [] as [Data]))
    }
}
