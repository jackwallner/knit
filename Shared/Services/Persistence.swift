import Foundation
import SwiftData
import UIKit

enum Persistence {
    /// Opens the knitter's store. Nil when the store on disk will not open: the app then says so
    /// and leaves the file alone, where a quiet in-memory stand-in would look like every project
    /// was gone and would lose whatever was counted next.
    @MainActor
    static func container(inMemory: Bool, at url: URL? = nil) -> ModelContainer? {
        let schema = Schema([Project.self, Yarn.self, Needle.self])
        if inMemory {
            return try? ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
        // A fresh install has no Application Support folder; without it the first open logs a failed attempt.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) } ?? ModelConfiguration(schema: schema)
        return try? ModelContainer(for: schema, configurations: configuration)
    }

    #if DEBUG
    /// `-SeedDemo`: sample data for screenshots and visual checks.
    @MainActor
    static func seedDemo(_ context: ModelContext) {
        let sweater = Project(name: "Raglan Sweater", rows: 44, color: .madder, createdAt: .now)
        sweater.repeatLength = 6
        sweater.yarn = "Merino Worsted, Oatmeal"
        sweater.needles = "US 7 circular"
        if !ProcessInfo.processInfo.arguments.contains("-NoPattern") {
            sweater.patternFile = samplePattern()
            markSampleRow(3, on: sweater)
        }
        let beanie = Project(name: "Ribbed Beanie", rows: 18, color: .spruce, createdAt: .now.addingTimeInterval(-86_400))
        let hat = Design.ribbedBeanie
        beanie.follow(hat.plan(measures: hat.defaultSize.values, gauge: hat.weight.gauge), of: hat)
        let blanket = Project(name: "Baby Blanket", rows: 240, color: .oat, createdAt: .now.addingTimeInterval(-30 * 86_400))
        blanket.finishedAt = .now.addingTimeInterval(-2 * 86_400)
        [sweater, beanie, blanket].forEach(context.insert)
        context.insert(Yarn(name: "Merino Worsted", brand: "Hillside Wool", colorway: "Oatmeal", weight: .worsted, skeins: 6))
        context.insert(Yarn(name: "Sock Yarn", brand: "Tidewater", colorway: "Harbor", weight: .fingering, skeins: 2, createdAt: .now.addingTimeInterval(-86_400)))
        context.insert(Needle(kind: .circular, millimeters: 4.5, lengthInches: 32))
        context.insert(Needle(kind: .doublePointed, millimeters: 3.25, createdAt: .now.addingTimeInterval(-86_400)))
        context.insert(Needle(kind: .hook, millimeters: 5.0, createdAt: .now.addingTimeInterval(-2 * 86_400)))
        context.insert(Yarn(name: "Chunky Alpaca", colorway: "Charcoal", weight: .bulky, skeins: 3, createdAt: .now.addingTimeInterval(-2 * 86_400)))
    }

    private static let samplePage = CGRect(x: 0, y: 0, width: 420, height: 595)
    private static let sampleRows = [
        "Cast on 88 sts. Join in the round.",
        "Rows 1-12: K2, P2 rib.",
        "Row 13: Knit, placing 4 raglan markers.",
        "Row 14: *Knit to 1 st before marker,",
        "M1R, K1, SM, K1, M1L; rep from *.",
        "Row 15: Knit.",
        "Repeat rows 14-15 until the yoke",
        "measures 8 in from the cast on.",
    ]
    private static func sampleRowTop(_ index: Int) -> CGFloat { 196 + CGFloat(index) * 32 }

    /// A three-page stand-in pattern so the reader can be checked without importing a file.
    private static func samplePattern() -> String? {
        let body = UIFont.systemFont(ofSize: 17)
        let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.gray]
        let data = UIGraphicsPDFRenderer(bounds: samplePage).pdfData { context in
            for (number, part) in ["Yoke", "Body", "Sleeves"].enumerated() {
                context.beginPage()
                ("Raglan Sweater" as NSString).draw(at: CGPoint(x: 36, y: 44), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 28)])
                ("Worsted · US 7 circular · 18 sts and 24 rows over 4 in" as NSString).draw(at: CGPoint(x: 36, y: 84), withAttributes: small)
                (part as NSString).draw(at: CGPoint(x: 36, y: 140), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
                for (index, line) in sampleRows.enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 36, y: sampleRowTop(index)), withAttributes: [.font: body])
                }
                ("\(number + 1)" as NSString).draw(at: CGPoint(x: 36, y: 548), withAttributes: small)
            }
        }
        let source = FileManager.default.temporaryDirectory.appending(path: "sample-pattern.pdf")
        guard (try? data.write(to: source)) != nil else { return nil }
        return try? PatternStore.save(from: source)
    }

    /// Leaves the row band on one line of the sample pattern, the way a tap would.
    private static func markSampleRow(_ index: Int, on project: Project) {
        let line = UIFont.systemFont(ofSize: 17).lineHeight
        project.markPage = 0
        project.markHeight = line + 4
        project.markY = samplePage.height - sampleRowTop(index) - line - 2
    }
    #endif
}
